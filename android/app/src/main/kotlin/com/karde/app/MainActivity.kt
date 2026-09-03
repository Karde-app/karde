package com.karde.app

import android.os.Bundle
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class MainActivity: FlutterFragmentActivity() {
    private val ENCRYPTION_CHANNEL = "com.ibank.security/encryption"
    private val WINDOW_CHANNEL = "com.ibank.security/window"
    private val KEY_ALIAS = "ibank_master_key"
    private val ANDROID_KEYSTORE = "AndroidKeyStore"
    private val TRANSFORMATION = "AES/GCM/NoPadding"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ENCRYPTION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "encrypt" -> {
                    val data = call.argument<String>("data")
                    if (data != null) {
                        try {
                            val encrypted = encryptData(data)
                            result.success(encrypted)
                        } catch (e: Exception) {
                            result.error("ENCRYPTION_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Data is null", null)
                    }
                }
                "decrypt" -> {
                    val data = call.argument<String>("data")
                    if (data != null) {
                        try {
                            val decrypted = decryptData(data)
                            result.success(decrypted)
                        } catch (e: Exception) {
                            result.error("DECRYPTION_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Data is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WINDOW_CHANNEL).setMethodCallHandler { call, result ->
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
    }

    private fun getSecretKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE)
        keyStore.load(null)

        if (!keyStore.containsAlias(KEY_ALIAS)) {
            val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
            val keyGenParameterSpec = KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
            keyGenerator.init(keyGenParameterSpec)
            return keyGenerator.generateKey()
        }

        return keyStore.getKey(KEY_ALIAS, null) as SecretKey
    }

    private fun encryptData(data: String): String {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, getSecretKey())
        val iv = cipher.iv
        val encryptedData = cipher.doFinal(data.toByteArray(Charsets.UTF_8))
        
        val ivString = Base64.encodeToString(iv, Base64.NO_WRAP)
        val dataString = Base64.encodeToString(encryptedData, Base64.NO_WRAP)
        
        return "$ivString:$dataString"
    }

    private fun decryptData(data: String): String {
        val parts = data.split(":")
        if (parts.size != 2) throw IllegalArgumentException("Invalid encrypted data format")
        
        val iv = Base64.decode(parts[0], Base64.NO_WRAP)
        val encryptedData = Base64.decode(parts[1], Base64.NO_WRAP)
        
        val cipher = Cipher.getInstance(TRANSFORMATION)
        val spec = GCMParameterSpec(128, iv)
        cipher.init(Cipher.DECRYPT_MODE, getSecretKey(), spec)
        
        val decryptedData = cipher.doFinal(encryptedData)
        return String(decryptedData, Charsets.UTF_8)
    }
}
