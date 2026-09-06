package com.karde.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

/**
 * The folder the user chose for automatic backups.
 *
 * Karde writes a backup on every change, which means it needs somewhere to write
 * without asking each time. There are two ways to do that on modern Android and
 * only one of them is any use here:
 *
 *  - The app's own external directory needs no permission, and Android **deletes
 *    it when the app is uninstalled**. That is precisely the moment a backup
 *    exists for, so it is worthless.
 *  - A folder the user picks, with a permission that persists. It survives
 *    uninstalling and updating, the user can see the files in their own file
 *    manager, and if they pick a Drive or OneDrive folder the backup leaves the
 *    phone by itself — which covers losing the phone entirely, not just losing
 *    the screen lock.
 *
 * The second, therefore. It also asks for no permission in the manifest: the
 * grant comes from the user pointing at a folder, which is both better for them
 * and one less thing to declare on the Play Store data-safety form.
 *
 * The grant can still be lost — the folder deleted, moved, or its permission
 * revoked in Android's settings. That is not an edge case to shrug at: a silent
 * automatic backup that quietly stopped months ago is worse than none, because
 * the owner believes they are covered. [isUsable] exists so Karde can notice and
 * say so.
 */
class BackupFolder(private val activity: Activity) {

    companion object {
        /// Must be unique across every class that calls startActivityForResult.
        ///
        /// This was 0xBA03, which ImageCapture already used for the gallery
        /// picker — and MainActivity offers each result to the backup folder
        /// before the image capture, so picking a photo from the gallery was
        /// silently swallowed here and never reached the code waiting for it.
        /// In use elsewhere: 0xBA01 and 0xBA02 (FileTransfer), 0xBA03 and
        /// 0xBA04 (ImageCapture).
        private const val REQUEST_PICK_FOLDER = 0xBA05
    }

    private var pendingResult: MethodChannel.Result? = null

    /** Asks the user to choose a folder, and keeps the right to write there. */
    fun choose(result: MethodChannel.Result) {
        pendingResult?.error("FOLDER_CANCELLED", "Superseded by a newer request", null)
        pendingResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
            )
        }
        try {
            activity.startActivityForResult(intent, REQUEST_PICK_FOLDER)
        } catch (e: Exception) {
            pendingResult = null
            result.error("NO_FOLDER_PICKER", "This phone has no folder picker", null)
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK_FOLDER) return false
        val result = pendingResult ?: return true
        pendingResult = null

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.error("FOLDER_CANCELLED", "No folder chosen", null)
            return true
        }

        // Without this the grant dies with the activity, and the first backup
        // after a restart would fail with nothing to explain why.
        try {
            activity.contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        } catch (e: Exception) {
            result.error("FOLDER_NOT_PERSISTABLE", e.message, null)
            return true
        }

        result.success(
            JSONObject()
                .put("uri", uri.toString())
                .put("label", describe(uri))
                .toString()
        )
        return true
    }

    /**
     * Whether Karde can still write to [treeUriString].
     *
     * Checked rather than assumed, because everything about this can be taken
     * away without telling the app.
     */
    fun isUsable(treeUriString: String): Boolean {
        return try {
            val treeUri = Uri.parse(treeUriString)
            val held = activity.contentResolver.persistedUriPermissions.any {
                it.uri == treeUri && it.isWritePermission
            }
            if (!held) return false
            // Holding the permission is not the same as the folder still being
            // there. Ask for its children; a deleted folder throws.
            activity.contentResolver.query(childrenUri(treeUri), arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID
            ), null, null, null)?.use { true } ?: false
        } catch (e: Exception) {
            false
        }
    }

    /** Writes [content] to [name], replacing any file already there. */
    fun write(treeUriString: String, name: String, content: String) {
        val treeUri = Uri.parse(treeUriString)
        val existing = findChild(treeUri, name)
        val target = existing ?: DocumentsContract.createDocument(
            activity.contentResolver,
            DocumentsContract.buildDocumentUriUsingTree(
                treeUri,
                DocumentsContract.getTreeDocumentId(treeUri),
            ),
            "application/json",
            name,
        ) ?: throw IllegalStateException("Could not create $name in the backup folder")

        // "wt" truncates. Without the t a shorter backup would leave the tail of
        // the longer one it replaced, and the file would no longer parse.
        activity.contentResolver.openOutputStream(target, "wt").use { stream ->
            if (stream == null) throw IllegalStateException("Backup folder refused the write")
            stream.write(content.toByteArray(Charsets.UTF_8))
            stream.flush()
        }
    }

    /** Reads [name], or null if it is not there. */
    fun read(treeUriString: String, name: String): String? {
        val child = findChild(Uri.parse(treeUriString), name) ?: return null
        return activity.contentResolver.openInputStream(child)?.use {
            it.readBytes().toString(Charsets.UTF_8)
        }
    }

    /** Names of the files in the folder, so old copies can be pruned. */
    fun list(treeUriString: String): String {
        val out = JSONArray()
        forEachChild(Uri.parse(treeUriString)) { _, name -> out.put(name) }
        return out.toString()
    }

    fun delete(treeUriString: String, name: String): Boolean {
        val child = findChild(Uri.parse(treeUriString), name) ?: return false
        return DocumentsContract.deleteDocument(activity.contentResolver, child)
    }

    // ---------------------------------------------------------------- helpers

    private fun childrenUri(treeUri: Uri): Uri =
        DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri),
        )

    private fun findChild(treeUri: Uri, name: String): Uri? {
        var found: Uri? = null
        forEachChild(treeUri) { uri, childName ->
            if (found == null && childName == name) found = uri
        }
        return found
    }

    private fun forEachChild(treeUri: Uri, action: (Uri, String) -> Unit) {
        val cursor = activity.contentResolver.query(
            childrenUri(treeUri),
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            ),
            null,
            null,
            null,
        ) ?: return
        cursor.use {
            while (it.moveToNext()) {
                val documentId = it.getString(0) ?: continue
                val name = it.getString(1) ?: continue
                action(
                    DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId),
                    name,
                )
            }
        }
    }

    /**
     * A name for the folder that means something to the person who chose it.
     *
     * The raw tree URI is unreadable, and Karde has to be able to say where the
     * backups are going. The last segment of the document id is what the file
     * manager shows, so "primary:Documents/Karde" becomes "Documents/Karde".
     */
    private fun describe(treeUri: Uri): String {
        return try {
            val id = DocumentsContract.getTreeDocumentId(treeUri)
            val path = id.substringAfter(':', id)
            if (path.isBlank()) id else path
        } catch (e: Exception) {
            treeUri.lastPathSegment ?: treeUri.toString()
        }
    }
}
