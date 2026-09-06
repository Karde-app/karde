package com.karde.app

import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import android.util.Base64
import android.view.WindowManager
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class MainActivity : FlutterFragmentActivity() {
    private val ENCRYPTION_CHANNEL = "com.ibank.security/encryption"
    private val WINDOW_CHANNEL = "com.ibank.security/window"
    private val BACKUP_CHANNEL = "com.ibank.security/backup"
    private val FILES_CHANNEL = "com.ibank.security/files"
    private val IMAGES_CHANNEL = "com.ibank.security/images"

    private val fileTransfer by lazy { FileTransfer(this) }
    private val imageCapture by lazy { ImageCapture(this) }

    // FIX 2-1: new alias. The previous key (v2) was created without per-use
    // authentication, so it is deliberately abandoned rather than migrated —
    // any data encrypted under it is intentionally unrecoverable.
    private val KEY_ALIAS = "ibank_master_key_v3"

    /** Holds nothing. Exists only so its death reports a biometric enrolment change. */
    private val CANARY_ALIAS = "karde_biometric_canary_v1"
    private val ANDROID_KEYSTORE = "AndroidKeyStore"
    private val TRANSFORMATION = "AES/GCM/NoPadding"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ENCRYPTION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "encrypt" -> {
                        val data = call.argument<String>("data")
                        if (data == null) {
                            result.error("INVALID_ARGUMENT", "Data is null", null)
                        } else {
                            encryptData(data, result)
                        }
                    }
                    "decrypt" -> {
                        val data = call.argument<String>("data")
                        if (data == null) {
                            result.error("INVALID_ARGUMENT", "Data is null", null)
                        } else {
                            decryptData(data, result)
                        }
                    }
                    "canUseVaultKey" -> result.success(canUseVaultKey())
                    "willPromptEveryUse" -> result.success(willPromptEveryUse())
                    "biometricsChanged" -> result.success(biometricsChanged())
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, IMAGES_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickImage" -> imageCapture.pick(result)
                    "captureImage" -> imageCapture.capture(result)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WINDOW_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "secure" -> {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    "unsecure" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKUP_CHANNEL)
            .setMethodCallHandler { call, result ->
                val passphrase = call.argument<String>("passphrase")
                val data = call.argument<String>("data")
                when (call.method) {
                    "encryptBundle" -> {
                        if (data == null || passphrase == null) {
                            result.error("INVALID_ARGUMENT", "Missing data or passphrase", null)
                        } else {
                            runBundleCrypto(result) { BackupCrypto.encrypt(data, passphrase) }
                        }
                    }
                    "decryptBundle" -> {
                        if (data == null || passphrase == null) {
                            result.error("INVALID_ARGUMENT", "Missing data or passphrase", null)
                        } else {
                            runBundleCrypto(result) { BackupCrypto.decrypt(data, passphrase) }
                        }
                    }
                    // Automatic backup. See BackupIdentity for why the sealing
                    // key and the opening key are different halves of a pair.
                    "createBackupIdentity" -> {
                        if (passphrase == null) {
                            result.error("INVALID_ARGUMENT", "Missing passphrase", null)
                        } else {
                            runBundleCrypto(result) { BackupIdentity.create(passphrase) }
                        }
                    }
                    "sealBackupRecord" -> {
                        val publicKey = call.argument<String>("publicKey")
                        if (data == null || publicKey == null) {
                            result.error("INVALID_ARGUMENT", "Missing data or publicKey", null)
                        } else {
                            runBundleCrypto(result) { BackupIdentity.seal(publicKey, data) }
                        }
                    }
                    "openBackupRecords" -> {
                        val sealedPrivateKey = call.argument<String>("sealedPrivateKey")
                        if (data == null || passphrase == null || sealedPrivateKey == null) {
                            result.error(
                                "INVALID_ARGUMENT",
                                "Missing data, passphrase or sealedPrivateKey",
                                null,
                            )
                        } else {
                            runBundleCrypto(result) {
                                BackupIdentity.open(sealedPrivateKey, passphrase, data)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILES_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveFile" -> {
                        val name = call.argument<String>("suggestedName")
                        val content = call.argument<String>("content")
                        if (name == null || content == null) {
                            result.error("INVALID_ARGUMENT", "Missing name or content", null)
                        } else {
                            fileTransfer.save(name, content, result)
                        }
                    }
                    "openFile" -> fileTransfer.open(result)
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * The backup KDF runs 600,000 HMAC rounds, which is far too long for the main
     * thread. [MethodChannel.Result] must still be completed on it, so the outcome
     * is posted back once the work finishes.
     */
    private fun runBundleCrypto(result: MethodChannel.Result, work: () -> String) {
        val main = Handler(Looper.getMainLooper())
        Thread {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: BackupCrypto.BadPassphraseException) {
                main.post { result.error("BAD_PASSPHRASE", e.message, null) }
            } catch (e: BackupCrypto.MalformedBackupException) {
                main.post { result.error("MALFORMED_BACKUP", e.message, null) }
            } catch (e: BackupIdentity.MalformedException) {
                main.post { result.error("MALFORMED_BACKUP", e.message, null) }
            } catch (e: BackupIdentity.SelfTestFailedException) {
                main.post { result.error("BACKUP_SELF_TEST_FAILED", e.message, null) }
            } catch (e: Exception) {
                main.post { result.error("BUNDLE_CRYPTO_ERROR", e.message, null) }
            }
        }.start()
    }

    /**
     * The Storage Access Framework answers through the activity result path. Plugins
     * such as local_auth rely on it too, so the superclass must always see the call.
     */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (fileTransfer.onActivityResult(requestCode, resultCode, data)) return
        if (imageCapture.onActivityResult(requestCode, resultCode, data)) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    /**
     * Reports whether this device can actually hold an auth-gated vault key.
     *
     * The key requires a secure lock screen. Without one, key generation throws
     * IllegalStateException at save time — after the user has already typed in a
     * whole card. Dart calls this up front so it can warn instead.
     */
    private fun canUseVaultKey(): Boolean {
        val authenticators = BiometricManager.Authenticators.BIOMETRIC_STRONG or
            BiometricManager.Authenticators.DEVICE_CREDENTIAL
        return BiometricManager.from(this).canAuthenticate(authenticators) ==
            BiometricManager.BIOMETRIC_SUCCESS
    }

    /**
     * Whether using the vault key is guaranteed to raise an OS prompt on EVERY
     * single operation.
     *
     * True only from API 30, where the key is built with
     * setUserAuthenticationParameters(0, ...) — timeout zero meaning per-use
     * authentication. On API 24-29 the only mechanism available is the deprecated
     * setUserAuthenticationValidityDurationSeconds(10), which authorises the key
     * for a ten-second window: a second decrypt inside that window succeeds with
     * no prompt at all.
     *
     * Dart uses this to decide whether it may safely skip its own PIN gate. It
     * must not: skipping the app PIN because "the Keystore will prompt anyway"
     * would, on those older devices, reveal secrets with no authentication
     * whatsoever whenever the window happened to still be open.
     *
     * Also false when there is no secure lock screen, because then the key cannot
     * be used at all and no prompt will ever appear.
     */
    private fun willPromptEveryUse(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && canUseVaultKey()

    /**
     * Reports whether the fingerprints or faces enrolled on this device have
     * changed since Karde last looked.
     *
     * This is a *canary*, not a lock. It is a second Keystore key that holds
     * nothing, exists only to be invalidated, and is completely separate from the
     * vault key — so detecting a change never puts a single stored record at risk.
     *
     * Why a canary rather than setInvalidatedByBiometricEnrollment on the vault key
     * itself: that flag destroys the key, and with it every card and ID, the moment
     * a finger is enrolled. Enrolling a finger requires the device's own screen
     * lock, so it is an act the owner consented to — and in any case Karde's vault
     * key already accepts DEVICE_CREDENTIAL, so anyone who knows the screen lock can
     * open the vault without touching biometrics at all. Wiping the vault would cost
     * the user everything and buy almost nothing. Telling them is the honest trade.
     *
     * Costs no authentication prompt. Cipher.init() raises
     * KeyPermanentlyInvalidatedException immediately when the key is dead; a prompt
     * appears only when an authorised cipher is actually used, which never happens
     * here.
     *
     * Returns false on the very first run, which merely plants the canary.
     */
    private fun biometricsChanged(): Boolean {
        // Below API 24 the flag does not exist; nothing to report.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false
        return try {
            val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
            val existing = store.getKey(CANARY_ALIAS, null) as? SecretKey
            if (existing == null) {
                createCanaryKey()
                return false
            }
            val cipher = Cipher.getInstance(
                "${KeyProperties.KEY_ALGORITHM_AES}/${KeyProperties.BLOCK_MODE_GCM}/${KeyProperties.ENCRYPTION_PADDING_NONE}"
            )
            cipher.init(Cipher.ENCRYPT_MODE, existing)
            false
        } catch (e: KeyPermanentlyInvalidatedException) {
            // Enrolment changed. Replant so the next change is caught too.
            Log.i("Karde", "Biometric enrolment changed; canary replanted")
            try {
                KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
                    .deleteEntry(CANARY_ALIAS)
                createCanaryKey()
            } catch (inner: Exception) {
                Log.w("Karde", "Could not replant biometric canary", inner)
            }
            true
        } catch (e: Exception) {
            // Never let a diagnostic break the app. Say "nothing changed" and log.
            Log.w("Karde", "Biometric canary check failed", e)
            false
        }
    }

    /** Plants the canary: an empty key that dies when enrolment changes. */
    private fun createCanaryKey() {
        if (!canUseVaultKey()) return
        val generator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore"
        )
        val builder = KeyGenParameterSpec.Builder(
            CANARY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            // Required: setInvalidatedByBiometricEnrollment only takes effect
            // alongside setUserAuthenticationRequired(true).
            .setUserAuthenticationRequired(true)
            .setInvalidatedByBiometricEnrollment(true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            builder.setUserAuthenticationParameters(
                0,
                KeyProperties.AUTH_BIOMETRIC_STRONG
            )
        } else {
            @Suppress("DEPRECATION")
            builder.setUserAuthenticationValidityDurationSeconds(10)
        }
        generator.init(builder.build())
        generator.generateKey()
    }


    private fun getSecretKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE)
        keyStore.load(null)

        (keyStore.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }

        val keyGenerator =
            KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        val builder = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .setUserAuthenticationRequired(true)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Timeout 0 == authentication required for EVERY use of the key, which is
            // what makes the gating hardware-enforced rather than cosmetic. Only the
            // CryptoObject handed back by BiometricPrompt can drive the cipher.
            builder.setUserAuthenticationParameters(
                0,
                KeyProperties.AUTH_BIOMETRIC_STRONG or KeyProperties.AUTH_DEVICE_CREDENTIAL
            )
        } else {
            // API 24-29 has no per-use option; the deprecated time-window API is the
            // only mechanism available. 10s is short enough to bound exposure while
            // still covering a single authorised operation.
            @Suppress("DEPRECATION")
            builder.setUserAuthenticationValidityDurationSeconds(10)
        }

        // NOTE: setInvalidatedByBiometricEnrollment(true) is deliberately NOT set.
        // It would destroy the key — and therefore the entire vault, permanently —
        // as soon as the user enrols a new fingerprint. Karde currently has no
        // export/backup path, so that would be silent, unrecoverable data loss.
        // Revisit once encrypted export exists.

        keyGenerator.init(builder.build())
        return keyGenerator.generateKey()
    }

    /**
     * Runs [cipher] through a BiometricPrompt-authorised CryptoObject and hands the
     * authorised cipher to [onAuthorised] on the main thread.
     */
    private fun withAuthorisedCipher(
        cipher: Cipher,
        result: MethodChannel.Result,
        onAuthorised: (Cipher) -> Unit
    ) {
        val executor = ContextCompat.getMainExecutor(this)
        val prompt = BiometricPrompt(
            this,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(
                    authResult: BiometricPrompt.AuthenticationResult
                ) {
                    val authorised = authResult.cryptoObject?.cipher
                    if (authorised == null) {
                        result.error("AUTH_ERROR", "No authorised cipher returned", null)
                        return
                    }
                    try {
                        onAuthorised(authorised)
                    } catch (e: Exception) {
                        result.error("CRYPTO_ERROR", e.message, null)
                    }
                }

                override fun onAuthenticationError(code: Int, message: CharSequence) {
                    // Distinguish a deliberate cancel from a real failure so Dart can
                    // stay silent on cancel instead of showing a scary error.
                    val cancelled = code == BiometricPrompt.ERROR_USER_CANCELED ||
                        code == BiometricPrompt.ERROR_NEGATIVE_BUTTON ||
                        code == BiometricPrompt.ERROR_CANCELED
                    result.error(
                        if (cancelled) "AUTH_CANCELLED" else "AUTH_ERROR",
                        message.toString(),
                        null
                    )
                }
            }
        )

        val info = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Unlock Karde Vault")
            .setSubtitle("Authenticate to access your encrypted data")
            .setAllowedAuthenticators(
                BiometricManager.Authenticators.BIOMETRIC_STRONG or
                    BiometricManager.Authenticators.DEVICE_CREDENTIAL
            )
            .build()

        // If authenticate() itself throws, no callback ever fires and the Dart
        // future would hang forever — leaving the UI stuck on a spinner. Always
        // complete the result.
        try {
            prompt.authenticate(info, BiometricPrompt.CryptoObject(cipher))
        } catch (e: Exception) {
            result.error("AUTH_ERROR", e.message ?: "Could not start authentication", null)
        }
    }

    /**
     * Prepares a cipher on the vault key, or completes [result] with the failure
     * and returns null.
     *
     * Every entry point into the vault has to distinguish the same three cases —
     * the key was invalidated, the device has no lock screen, or something else
     * went wrong — and Dart maps each to its own exception type so the UI can say
     * something useful. Doing that in one place keeps the four callers from
     * drifting apart.
     *
     * [iv] is null for encryption, where the cipher generates its own.
     */
    private fun initVaultCipher(
        mode: Int,
        iv: ByteArray?,
        result: MethodChannel.Result,
        errorCode: String
    ): Cipher? {
        return try {
            val cipher = Cipher.getInstance(TRANSFORMATION)
            if (iv == null) {
                cipher.init(mode, getSecretKey())
            } else {
                cipher.init(mode, getSecretKey(), GCMParameterSpec(128, iv))
            }
            cipher
        } catch (e: KeyPermanentlyInvalidatedException) {
            handleInvalidatedKey(result)
            null
        } catch (e: IllegalStateException) {
            result.error("NO_SECURE_LOCK_SCREEN", e.message, null)
            null
        } catch (e: Exception) {
            result.error(errorCode, e.message, null)
            null
        }
    }

    private fun encryptData(data: String, result: MethodChannel.Result) {
        val cipher = initVaultCipher(Cipher.ENCRYPT_MODE, null, result, "ENCRYPTION_ERROR")
            ?: return

        val iv = Base64.encodeToString(cipher.iv, Base64.NO_WRAP)
        withAuthorisedCipher(cipher, result) { authorised ->
            val encrypted = authorised.doFinal(data.toByteArray(Charsets.UTF_8))
            result.success("$iv:${Base64.encodeToString(encrypted, Base64.NO_WRAP)}")
        }
    }

    private fun decryptData(data: String, result: MethodChannel.Result) {
        val parts = data.split(":")
        if (parts.size != 2) {
            result.error("DECRYPTION_ERROR", "Invalid encrypted data format", null)
            return
        }

        val iv = Base64.decode(parts[0], Base64.NO_WRAP)
        val payload = Base64.decode(parts[1], Base64.NO_WRAP)

        val cipher = initVaultCipher(Cipher.DECRYPT_MODE, iv, result, "DECRYPTION_ERROR")
            ?: return

        withAuthorisedCipher(cipher, result) { authorised ->
            result.success(String(authorised.doFinal(payload), Charsets.UTF_8))
        }
    }


    /**
     * The key is gone for good (lock screen removed, or biometrics reset). Drop the
     * alias so a fresh key is minted next time, and tell Dart the vault is orphaned.
     */
    private fun handleInvalidatedKey(result: MethodChannel.Result) {
        try {
            val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE)
            keyStore.load(null)
            keyStore.deleteEntry(KEY_ALIAS)
        } catch (_: Exception) {
            // Nothing useful to do; the error below is what matters to the caller.
        }
        result.error("KEY_INVALIDATED", "Vault key is no longer valid", null)
    }
}
