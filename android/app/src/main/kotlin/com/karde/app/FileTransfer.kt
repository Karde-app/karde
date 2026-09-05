package com.karde.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

/**
 * Storage Access Framework bridge for reading and writing the backup file.
 *
 * Deliberately implemented against the platform rather than a file-picker plugin:
 * the backup is the one file in this app that contains the whole vault, so the
 * code that moves it stays in the repository where it can be reviewed, instead of
 * arriving as third-party plugin code with its own transitive dependencies and
 * manifest permissions.
 *
 * SAF also means Karde needs no storage permission at all. The user chooses the
 * destination in the system picker, the app receives a one-shot URI for exactly
 * that document, and the backup never passes through app-private storage where a
 * later crash or uninstall could strand a plaintext-adjacent copy.
 */
class FileTransfer(private val activity: Activity) {

    companion object {
        private const val REQUEST_CREATE = 0xBA01
        private const val REQUEST_OPEN = 0xBA02

        /**
         * A backup of a hand-entered vault is measured in kilobytes. The cap stops a
         * mistakenly chosen video from being pulled into memory as a string.
         */
        private const val MAX_IMPORT_BYTES = 8 * 1024 * 1024
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingContent: String? = null

    fun save(suggestedName: String, content: String, result: MethodChannel.Result) {
        if (!claim(result)) return
        pendingContent = content

        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/octet-stream"
            putExtra(Intent.EXTRA_TITLE, suggestedName)
        }
        launch(intent, REQUEST_CREATE)
    }

    fun open(result: MethodChannel.Result) {
        if (!claim(result)) return

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            // Backups carry a custom extension, and providers such as Drive report
            // that as octet-stream while a local Files pick may report text/plain.
            // Accepting anything and validating the envelope afterwards is more
            // reliable than filtering on a MIME type we do not control.
            type = "*/*"
        }
        launch(intent, REQUEST_OPEN)
    }

    /** Returns true if this result belonged to us and has been handled. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CREATE && requestCode != REQUEST_OPEN) return false

        val result = pendingResult
        val content = pendingContent
        pendingResult = null
        pendingContent = null
        if (result == null) return true

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            // A dismissed picker is a decision, not a failure.
            result.success(null)
            return true
        }

        if (requestCode == REQUEST_CREATE) {
            writeAsync(uri, content ?: "", result)
        } else {
            readAsync(uri, result)
        }
        return true
    }

    /**
     * Fails any request still outstanding when a new one arrives, so a stranded
     * Dart future cannot leave the UI stuck on a spinner forever.
     */
    private fun claim(result: MethodChannel.Result): Boolean {
        pendingResult?.error("FILE_CANCELLED", "Superseded by a newer request", null)
        pendingResult = result
        pendingContent = null
        return true
    }

    private fun launch(intent: Intent, requestCode: Int) {
        try {
            activity.startActivityForResult(intent, requestCode)
        } catch (e: Exception) {
            val result = pendingResult
            pendingResult = null
            pendingContent = null
            result?.error("NO_FILE_PICKER", "No app on this device can pick a file", null)
        }
    }

    private fun writeAsync(uri: Uri, content: String, result: MethodChannel.Result) {
        onBackground({
            activity.contentResolver.openOutputStream(uri, "wt")?.use { stream ->
                stream.write(content.toByteArray(Charsets.UTF_8))
                stream.flush()
            } ?: throw IOException("Could not open the chosen location for writing")
            displayName(uri) ?: "backup"
        }, result, "FILE_WRITE_FAILED")
    }

    private fun readAsync(uri: Uri, result: MethodChannel.Result) {
        onBackground({
            val bytes = activity.contentResolver.openInputStream(uri)?.use { stream ->
                val buffer = stream.readLimited(MAX_IMPORT_BYTES)
                if (buffer.size > MAX_IMPORT_BYTES) {
                    throw IOException("That file is too large to be a Karde backup")
                }
                buffer
            } ?: throw IOException("Could not open the chosen file")
            String(bytes, Charsets.UTF_8)
        }, result, "FILE_READ_FAILED")
    }

    /**
     * Drive and other cloud providers stream over the network, so this must not run
     * on the main thread. [MethodChannel.Result] is main-thread only, so the outcome
     * is posted back.
     */
    private fun onBackground(
        work: () -> String,
        result: MethodChannel.Result,
        errorCode: String
    ) {
        val main = Handler(Looper.getMainLooper())
        Thread {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error(errorCode, e.message, null) }
            }
        }.start()
    }

    private fun displayName(uri: Uri): String? =
        try {
            activity.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    if (cursor.moveToFirst()) cursor.getString(0) else null
                }
        } catch (e: Exception) {
            null
        }

    /** Reads at most [limit] bytes plus one, so the caller can detect an overrun. */
    private fun java.io.InputStream.readLimited(limit: Int): ByteArray {
        val out = java.io.ByteArrayOutputStream()
        val chunk = ByteArray(8192)
        var total = 0
        while (true) {
            val read = read(chunk)
            if (read == -1) break
            total += read
            if (total > limit) {
                out.write(chunk, 0, read)
                break
            }
            out.write(chunk, 0, read)
        }
        return out.toByteArray()
    }
}
