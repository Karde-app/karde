package com.karde.app

import android.util.Base64
import org.json.JSONException
import org.json.JSONObject
import java.security.SecureRandom
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.Mac
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * Passphrase-based encryption for the portable backup bundle.
 *
 * The vault's normal encryption uses a hardware Keystore key that, by design,
 * can never leave the device. A backup that has to be restorable on a *different*
 * phone therefore cannot use it, so the bundle is re-encrypted under a key
 * derived from a passphrase the user supplies and remembers.
 *
 * Two deliberate choices:
 *
 * 1. PBKDF2 is implemented here with [Mac] rather than through
 *    `SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")`. The platform factory
 *    takes a `char[]` and, on Android, keeps only the low 8 bits of each
 *    character, so a passphrase containing non-ASCII characters is silently
 *    weakened before it is ever stretched. Deriving straight from UTF-8 bytes
 *    avoids that, and also removes the API 26 floor on the SHA-256 factory,
 *    which matters because minSdk here is 24.
 *
 * 2. The KDF and cipher parameters are stored in the envelope in clear (they have
 *    to be, to decrypt) but are also fed to GCM as additional authenticated data.
 *    An attacker who edits the stored iteration count down to 1 to make an
 *    offline guessing attack cheap will therefore fail the tag check instead of
 *    being obeyed.
 */
object BackupCrypto {
    const val FORMAT = "karde.backup"
    const val ENVELOPE_VERSION = 1

    private const val KDF = "pbkdf2-hmac-sha256"
    private const val CIPHER_NAME = "aes-256-gcm"

    /** OWASP's 2023 guidance for PBKDF2-HMAC-SHA256. Costs well under a second natively. */
    const val ITERATIONS = 600_000

    private const val SALT_BYTES = 16
    private const val IV_BYTES = 12
    private const val TAG_BITS = 128
    private const val KEY_BYTES = 32

    /** The passphrase was wrong, or the file was tampered with. Indistinguishable by design. */
    class BadPassphraseException : Exception("Backup could not be decrypted")

    /** The file is not a Karde backup, or its envelope is damaged. */
    class MalformedBackupException(message: String) : Exception(message)

    fun encrypt(plaintext: String, passphrase: String): String {
        val random = SecureRandom()
        val salt = ByteArray(SALT_BYTES).also { random.nextBytes(it) }
        val iv = ByteArray(IV_BYTES).also { random.nextBytes(it) }

        val saltB64 = Base64.encodeToString(salt, Base64.NO_WRAP)
        val ivB64 = Base64.encodeToString(iv, Base64.NO_WRAP)
        val key = deriveKey(passphrase, salt, ITERATIONS)

        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(TAG_BITS, iv))
        cipher.updateAAD(aad(ENVELOPE_VERSION, KDF, ITERATIONS, saltB64, CIPHER_NAME, ivB64))
        val ciphertext = cipher.doFinal(plaintext.toByteArray(Charsets.UTF_8))
        key.fill(0)

        return JSONObject()
            .put("format", FORMAT)
            .put("envelopeVersion", ENVELOPE_VERSION)
            .put("kdf", KDF)
            .put("iterations", ITERATIONS)
            .put("salt", saltB64)
            .put("cipher", CIPHER_NAME)
            .put("iv", ivB64)
            .put("data", Base64.encodeToString(ciphertext, Base64.NO_WRAP))
            .toString(2)
    }

    fun decrypt(envelopeJson: String, passphrase: String): String {
        val envelope = try {
            JSONObject(envelopeJson)
        } catch (e: JSONException) {
            throw MalformedBackupException("Not a Karde backup file")
        }

        if (envelope.optString("format") != FORMAT) {
            throw MalformedBackupException("Not a Karde backup file")
        }
        val version = envelope.optInt("envelopeVersion", -1)
        if (version != ENVELOPE_VERSION) {
            throw MalformedBackupException("Backup was written by a newer version of Karde")
        }

        val kdf = envelope.optString("kdf")
        val cipherName = envelope.optString("cipher")
        if (kdf != KDF || cipherName != CIPHER_NAME) {
            throw MalformedBackupException("Unsupported backup encryption")
        }

        val iterations = envelope.optInt("iterations", 0)
        if (iterations <= 0) throw MalformedBackupException("Backup envelope is damaged")

        val saltB64 = envelope.optString("salt")
        val ivB64 = envelope.optString("iv")
        val dataB64 = envelope.optString("data")
        if (saltB64.isEmpty() || ivB64.isEmpty() || dataB64.isEmpty()) {
            throw MalformedBackupException("Backup envelope is damaged")
        }

        val salt: ByteArray
        val iv: ByteArray
        val ciphertext: ByteArray
        try {
            salt = Base64.decode(saltB64, Base64.NO_WRAP)
            iv = Base64.decode(ivB64, Base64.NO_WRAP)
            ciphertext = Base64.decode(dataB64, Base64.NO_WRAP)
        } catch (e: IllegalArgumentException) {
            throw MalformedBackupException("Backup envelope is damaged")
        }

        val key = deriveKey(passphrase, salt, iterations)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(TAG_BITS, iv))
        cipher.updateAAD(aad(version, kdf, iterations, saltB64, cipherName, ivB64))
        try {
            return String(cipher.doFinal(ciphertext), Charsets.UTF_8)
        } catch (e: AEADBadTagException) {
            throw BadPassphraseException()
        } finally {
            key.fill(0)
        }
    }

    /**
     * Binds the envelope's own parameters to the ciphertext, so editing any of
     * them — most importantly the iteration count — invalidates the tag.
     */
    private fun aad(
        version: Int,
        kdf: String,
        iterations: Int,
        saltB64: String,
        cipherName: String,
        ivB64: String
    ): ByteArray =
        "$FORMAT|$version|$kdf|$iterations|$saltB64|$cipherName|$ivB64".toByteArray(Charsets.UTF_8)

    private fun deriveKey(passphrase: String, salt: ByteArray, iterations: Int): ByteArray =
        pbkdf2Sha256(passphrase.toByteArray(Charsets.UTF_8), salt, iterations, KEY_BYTES)

    private fun pbkdf2Sha256(
        password: ByteArray,
        salt: ByteArray,
        iterations: Int,
        keyLength: Int
    ): ByteArray {
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(password, "HmacSHA256"))

        val hLen = mac.macLength
        val blockCount = (keyLength + hLen - 1) / hLen
        val output = ByteArray(blockCount * hLen)

        for (blockIndex in 1..blockCount) {
            val counter = byteArrayOf(
                (blockIndex ushr 24).toByte(),
                (blockIndex ushr 16).toByte(),
                (blockIndex ushr 8).toByte(),
                blockIndex.toByte()
            )
            mac.update(salt)
            mac.update(counter)
            var u = mac.doFinal()
            val accumulated = u.copyOf()
            for (round in 1 until iterations) {
                u = mac.doFinal(u)
                for (i in accumulated.indices) {
                    accumulated[i] = (accumulated[i].toInt() xor u[i].toInt()).toByte()
                }
            }
            System.arraycopy(accumulated, 0, output, (blockIndex - 1) * hLen, hLen)
        }

        return output.copyOf(keyLength)
    }
}
