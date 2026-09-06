package com.karde.app

import android.util.Base64
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.SecureRandom
import java.security.spec.MGF1ParameterSpec
import java.security.spec.PKCS8EncodedKeySpec
import java.security.spec.X509EncodedKeySpec
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.OAEPParameterSpec
import javax.crypto.spec.PSource
import javax.crypto.spec.SecretKeySpec

/**
 * The key pair behind automatic backup.
 *
 * Karde saves a backup every time an item is added, changed or removed. That
 * rules out re-exporting the whole vault, which costs one authentication prompt
 * per item, so each item is sealed on its own at the moment the user saves it —
 * when Karde already holds it in plain form and needs nothing from the Keystore.
 *
 * The problem that creates is what Karde must keep to hand in order to do the
 * sealing. Holding a key derived from the passphrase would mean something
 * capable of reading the entire backup sits in the app's memory for as long as
 * the app is open.
 *
 * So the sealing key and the opening key are different halves of a pair:
 *
 *  - The **public half** is kept in the clear and used all day. It can seal a new
 *    record and can do nothing else. Compromising the running app yields nothing
 *    that opens a backup.
 *  - The **private half** never exists at rest. It is sealed with the user's
 *    passphrase by [BackupCrypto] — the same 600,000-round derivation the manual
 *    backup already uses — and lives inside the backup file, so restoring on a
 *    new phone needs the file and the passphrase and nothing else.
 *
 * The pair is generated on the user's own phone. A single pair shipped inside
 * Karde would put the private half in every copy of the APK, where extracting it
 * once would open every user's backups and reduce the passphrase to decoration.
 *
 * Each record gets its own AES-256-GCM key, and that key is what the public half
 * wraps. RSA cannot encrypt bulk data, and a per-record key also means two
 * records never share an IV/key pair.
 */
object BackupIdentity {

    /**
     * 3072-bit RSA, generated once during setup.
     *
     * Takes a second or two, which is affordable exactly once and never again —
     * every later save only wraps a 32-byte key, which is instant. RSA rather
     * than X25519 because key agreement through the JCA needs API 33 for XDH,
     * while RSA-OAEP is available on every version Karde supports.
     */
    private const val RSA_BITS = 3072

    private const val AES_KEY_BYTES = 32
    private const val IV_BYTES = 12
    private const val TAG_BITS = 128

    /**
     * SHA-256 for both the digest and the mask generation function.
     *
     * Stated explicitly rather than left to "OAEPWithSHA-256AndMGF1Padding",
     * whose MGF1 digest differs between providers — SHA-1 on some, SHA-256 on
     * others. A default that varies is a decryption failure waiting for a device
     * we have not tested on.
     */
    private fun oaepParams() = OAEPParameterSpec(
        "SHA-256",
        "MGF1",
        MGF1ParameterSpec.SHA256,
        PSource.PSpecified.DEFAULT,
    )

    private fun rsaCipher() =
        Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding")

    /** The backup file is not one of ours, or has been damaged. */
    class MalformedException(message: String) : Exception(message)

    /**
     * This phone produced a backup it could not read back.
     *
     * Distinct from every other failure because it is not the user's doing and
     * they can do nothing about it. It means setup must not complete.
     */
    class SelfTestFailedException :
        Exception("This phone could not read back a backup it had just written")

    /** Proves the round trip before the user is allowed to depend on it. */
    private const val PROBE = "karde.backup.selftest"

    /**
     * Creates the pair and returns `{publicKey, sealedPrivateKey}`.
     *
     * `sealedPrivateKey` is a [BackupCrypto] envelope, so it carries its own salt
     * and iteration count and can be opened by any future build that still
     * understands that format.
     */
    fun create(passphrase: String): String {
        val generator = KeyPairGenerator.getInstance("RSA")
        generator.initialize(RSA_BITS)
        val pair = generator.generateKeyPair()

        val publicB64 = Base64.encodeToString(pair.public.encoded, Base64.NO_WRAP)
        val privateB64 = Base64.encodeToString(pair.private.encoded, Base64.NO_WRAP)

        val sealedPrivateKey = BackupCrypto.encrypt(privateB64, passphrase)

        // Prove it works on THIS phone before the user starts relying on it.
        //
        // Not ceremony. "OAEPWithSHA-256AndMGF1Padding" does not mean the same
        // thing on every Android provider — some use SHA-1 for the mask
        // generation function and some SHA-256 — so a pairing that seals
        // perfectly well here could fail to open on a device we have never
        // tested. The parameters are stated explicitly to avoid exactly that,
        // and this checks the assumption rather than trusting it.
        //
        // The cost is one extra key derivation during setup, once. The
        // alternative is discovering the problem on the day someone needs their
        // backup, which is the one day it must not be discovered.
        val probe = seal(publicB64, PROBE)
        val readBack = try {
            open(sealedPrivateKey, passphrase, "[$probe]")
        } catch (e: Exception) {
            throw SelfTestFailedException()
        }
        if (readBack != JSONArray().put(PROBE).toString()) {
            throw SelfTestFailedException()
        }

        return JSONObject()
            .put("publicKey", publicB64)
            .put("sealedPrivateKey", sealedPrivateKey)
            .toString()
    }

    /**
     * Seals one record with the public half. Costs no authentication and no
     * passphrase, which is the whole point: this runs on every save.
     */
    fun seal(publicKeyB64: String, plaintext: String): String {
        val publicKey = try {
            KeyFactory.getInstance("RSA").generatePublic(
                X509EncodedKeySpec(Base64.decode(publicKeyB64, Base64.NO_WRAP))
            )
        } catch (e: Exception) {
            throw MalformedException("Backup public key is unusable")
        }

        val random = SecureRandom()
        val recordKey = ByteArray(AES_KEY_BYTES).also { random.nextBytes(it) }
        val iv = ByteArray(IV_BYTES).also { random.nextBytes(it) }

        val aes = Cipher.getInstance("AES/GCM/NoPadding")
        aes.init(
            Cipher.ENCRYPT_MODE,
            SecretKeySpec(recordKey, "AES"),
            GCMParameterSpec(TAG_BITS, iv),
        )
        val ciphertext = aes.doFinal(plaintext.toByteArray(Charsets.UTF_8))

        val rsa = rsaCipher()
        rsa.init(Cipher.ENCRYPT_MODE, publicKey, oaepParams())
        val wrappedKey = rsa.doFinal(recordKey)
        recordKey.fill(0)

        return JSONObject()
            .put("k", Base64.encodeToString(wrappedKey, Base64.NO_WRAP))
            .put("iv", Base64.encodeToString(iv, Base64.NO_WRAP))
            .put("d", Base64.encodeToString(ciphertext, Base64.NO_WRAP))
            .toString()
    }

    /**
     * Opens many records at once.
     *
     * Deliberately not one record at a time. Recovering the private half costs
     * 600,000 rounds of key derivation, and paying that per record would turn a
     * restore of twenty items into twenty times the wait for no benefit — the
     * same key opens all of them.
     *
     * A record that will not open aborts the whole call rather than being
     * skipped. A restore that silently dropped the two items it could not read
     * would leave the user believing they had recovered everything.
     */
    fun open(sealedPrivateKey: String, passphrase: String, recordsJson: String): String {
        val privateKey = try {
            KeyFactory.getInstance("RSA").generatePrivate(
                PKCS8EncodedKeySpec(
                    Base64.decode(
                        BackupCrypto.decrypt(sealedPrivateKey, passphrase),
                        Base64.NO_WRAP,
                    )
                )
            )
        } catch (e: BackupCrypto.BadPassphraseException) {
            throw e
        } catch (e: BackupCrypto.MalformedBackupException) {
            throw e
        } catch (e: Exception) {
            throw MalformedException("Backup key could not be read")
        }

        val records = try {
            JSONArray(recordsJson)
        } catch (e: JSONException) {
            throw MalformedException("Backup records are not a list")
        }

        val rsa = rsaCipher()
        rsa.init(Cipher.DECRYPT_MODE, privateKey, oaepParams())

        val out = JSONArray()
        for (i in 0 until records.length()) {
            val record = try {
                records.getJSONObject(i)
            } catch (e: JSONException) {
                throw MalformedException("Backup record $i is not an object")
            }
            out.put(openOne(rsa, record, i))
        }
        return out.toString()
    }

    private fun openOne(rsa: Cipher, record: JSONObject, index: Int): String {
        val wrappedKey: ByteArray
        val iv: ByteArray
        val ciphertext: ByteArray
        try {
            wrappedKey = Base64.decode(record.getString("k"), Base64.NO_WRAP)
            iv = Base64.decode(record.getString("iv"), Base64.NO_WRAP)
            ciphertext = Base64.decode(record.getString("d"), Base64.NO_WRAP)
        } catch (e: Exception) {
            throw MalformedException("Backup record $index is incomplete")
        }

        val recordKey = try {
            rsa.doFinal(wrappedKey)
        } catch (e: Exception) {
            // The private half opened, so the passphrase was right. This record
            // was written by a different pair, or has been altered.
            throw MalformedException("Backup record $index was not sealed for this vault")
        }

        return try {
            val aes = Cipher.getInstance("AES/GCM/NoPadding")
            aes.init(
                Cipher.DECRYPT_MODE,
                SecretKeySpec(recordKey, "AES"),
                GCMParameterSpec(TAG_BITS, iv),
            )
            String(aes.doFinal(ciphertext), Charsets.UTF_8)
        } catch (e: AEADBadTagException) {
            throw MalformedException("Backup record $index has been altered")
        } catch (e: Exception) {
            throw MalformedException("Backup record $index could not be read")
        } finally {
            recordKey.fill(0)
        }
    }
}
