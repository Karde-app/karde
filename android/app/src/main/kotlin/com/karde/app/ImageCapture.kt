package com.karde.app

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.graphics.Rect
import android.media.ExifInterface
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.IOException

/**
 * Gets a photo into the app, from the gallery or the camera, and hands Dart a
 * downscaled JPEG.
 *
 * Implemented against the platform rather than an image-picker plugin, for the
 * same reason [FileTransfer] is: a photo of a passport or a bank card is exactly
 * the kind of data this app exists to protect, so the code that carries it stays
 * in this repository where it can be reviewed, instead of arriving as third-party
 * plugin code with its own transitive dependencies and manifest permissions.
 *
 * Two consequences of that choice are worth stating plainly.
 *
 * **No permissions are needed.** `ACTION_GET_CONTENT` returns a one-shot URI for
 * the single image the user picked, so Karde never asks for gallery access.
 * `ACTION_IMAGE_CAPTURE` is served by whatever camera app the user already has,
 * writing into a Karde-owned cache file exposed through a [FileProvider]; because
 * Karde does not declare `CAMERA` in its manifest, Android does not require the
 * permission of it either.
 *
 * **Re-encoding strips metadata.** The picked image is decoded, scaled and
 * re-compressed, and the JPEG that reaches Dart is built from pixels alone. Every
 * EXIF tag on the original is dropped in the process — including the GPS
 * coordinates a phone routinely writes into a photo, which on a picture of an ID
 * document would record where its owner lives. That is a side effect of the
 * downscaling, but it is a deliberate one and must not be optimised away.
 */
class ImageCapture(private val activity: Activity) {

    companion object {
        private const val TAG = "KardeImageCapture"

        // Must not collide with FileTransfer's request codes (0xBA01 / 0xBA02).
        private const val REQUEST_PICK = 0xBA03
        private const val REQUEST_CAPTURE = 0xBA04

        /**
         * Longest edge of the stored image. A document has to stay legible when
         * zoomed, but every extra pixel is paid for in the encrypted file, in the
         * backup that carries it, and in the time the user waits at an
         * authentication prompt. 1400 is comfortably enough to read the small
         * print on a passport.
         *
         * It matters more than it looks: the photo is base64-encoded into its
         * record's encrypted payload, so every kilobyte here becomes about 1.8
         * in the database row and again in any backup that carries it.
         */
        private const val MAX_EDGE = 1400

        /** Compression is stepped down until the JPEG fits, or quality bottoms out. */
        private const val TARGET_MAX_BYTES = 400 * 1024
        private const val START_QUALITY = 88
        private const val MIN_QUALITY = 45

        private const val CAPTURE_DIR = "captures"
        private const val CAPTURE_FILE = "pending-capture.jpg"
    }

    private var pendingResult: MethodChannel.Result? = null
    private var captureUri: Uri? = null

    fun pick(result: MethodChannel.Result) {
        if (!claim(result)) return

        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
        }
        launch(intent, REQUEST_PICK)
    }

    fun capture(result: MethodChannel.Result) {
        if (!claim(result)) return

        val uri = try {
            newCaptureUri()
        } catch (e: Exception) {
            finishWithError("CAMERA_UNAVAILABLE", "Could not prepare the camera")
            return
        }
        captureUri = uri

        val intent = Intent(android.provider.MediaStore.ACTION_IMAGE_CAPTURE).apply {
            putExtra(android.provider.MediaStore.EXTRA_OUTPUT, uri)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        launch(intent, REQUEST_CAPTURE)
    }

    /** Returns true if this result belonged to us and has been handled. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK && requestCode != REQUEST_CAPTURE) return false

        val result = pendingResult
        val captured = captureUri
        pendingResult = null
        captureUri = null
        if (result == null) return true

        if (resultCode != Activity.RESULT_OK) {
            // A dismissed picker is a decision, not a failure.
            discardCaptureFile()
            result.success(null)
            return true
        }

        // A camera app writes into the file we handed it and usually returns no
        // data at all, so the capture URI is the authority for that path.
        val uri = if (requestCode == REQUEST_CAPTURE) captured else data?.data
        if (uri == null) {
            discardCaptureFile()
            result.success(null)
            return true
        }

        readAsync(uri, requestCode == REQUEST_CAPTURE, result)
        return true
    }

    /**
     * Fails any request still outstanding when a new one arrives, so a stranded
     * Dart future cannot leave the UI stuck on a spinner forever.
     */
    private fun claim(result: MethodChannel.Result): Boolean {
        pendingResult?.error("IMAGE_CANCELLED", "Superseded by a newer request", null)
        pendingResult = result
        captureUri = null
        return true
    }

    private fun launch(intent: Intent, requestCode: Int) {
        try {
            activity.startActivityForResult(intent, requestCode)
        } catch (e: Exception) {
            val what = if (requestCode == REQUEST_CAPTURE) {
                "This device has no camera app"
            } else {
                "No app on this device can pick an image"
            }
            finishWithError("NO_IMAGE_SOURCE", what)
        }
    }

    private fun finishWithError(code: String, message: String) {
        val result = pendingResult
        pendingResult = null
        captureUri = null
        discardCaptureFile()
        result?.error(code, message, null)
    }

    /**
     * Decoding and re-compressing a full-resolution photo is far too slow for the
     * main thread. [MethodChannel.Result] is main-thread only, so the outcome is
     * posted back.
     */
    private fun readAsync(uri: Uri, fromCamera: Boolean, result: MethodChannel.Result) {
        val main = Handler(Looper.getMainLooper())
        Thread {
            try {
                val jpeg = loadScaledJpeg(uri)
                main.post { result.success(jpeg) }
            } catch (e: OutOfMemoryError) {
                // A very large image can still exhaust the heap even with
                // subsampling. Say so rather than taking the process down.
                Log.w(TAG, "Image too large to decode", e)
                main.post {
                    result.error("IMAGE_TOO_LARGE", "That image is too large to add", null)
                }
            } catch (e: Exception) {
                // Logged as well as returned. A MethodChannel error travels to Dart
                // and no further, so a failure here left nothing in logcat at all —
                // which is precisely why the bounds-decode bug above could only be
                // found by reading the code. Never make that trade again.
                Log.w(TAG, "Could not read the chosen image", e)
                main.post { result.error("IMAGE_READ_FAILED", e.message, null) }
            } finally {
                // The camera's copy is plaintext on disk and has served its
                // purpose the moment it is decoded.
                if (fromCamera) discardCaptureFile()
            }
        }.start()
    }

    /**
     * Takes the photo Karde's own camera screen just captured and keeps the part
     * the user framed.
     *
     * The rectangle arrives as fractions rather than pixels, because the screen
     * that drew it knows where it put it and this does not. They are fractions of
     * the **preview**, though, and a phone is under no obligation to photograph
     * in the shape it previews — 16:9 on screen and a 4:3 still is ordinary. So
     * [previewAspect] comes with them and the preview's own region of the photo
     * is worked out first; the fractions are then applied inside that. When the
     * two shapes agree, which is the common case, this reduces to the identity.
     *
     * Order matters and is not the same as [loadScaledJpeg]'s. The rotation is
     * baked in **first**, because the fractions describe the upright picture the
     * user was looking at, and a portrait photo whose orientation had not yet
     * been applied would be cropped ninety degrees out.
     *
     * The temporary file the camera wrote is deleted either way. It is a full
     * resolution photograph of somebody's passport sitting in cache.
     */
    fun cropCapture(
        path: String,
        left: Double,
        top: Double,
        width: Double,
        height: Double,
        previewAspect: Double,
        result: MethodChannel.Result,
    ) {
        // Off the main thread, like readAsync and for the same reason: decoding
        // and re-compressing a full-resolution photograph is far too slow to do
        // between frames, and doing it here would freeze the shutter button for
        // as long as it took.
        val main = Handler(Looper.getMainLooper())
        Thread { cropCaptureBlocking(path, left, top, width, height, previewAspect, main, result) }
            .start()
    }

    private fun cropCaptureBlocking(
        path: String,
        left: Double,
        top: Double,
        width: Double,
        height: Double,
        previewAspect: Double,
        main: Handler,
        result: MethodChannel.Result,
    ) {
        val file = File(path)
        try {
            val uri = Uri.fromFile(file)

            // The stream is null-checked on its own line, for the same reason it
            // is in loadScaledJpeg. In bounds-only mode decodeStream returns null
            // by contract, so `openInputStream(uri)?.use { decode(...) } ?: throw`
            // tests the decode result and not the stream, and fires on every
            // photograph ever taken. That is exactly what shipped here: every
            // shutter press came back "That photo could not be taken."
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            val header = activity.contentResolver.openInputStream(uri)
                ?: throw IOException("Could not open the photo")
            header.use { BitmapFactory.decodeStream(it, null, bounds) }
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
                throw IOException("That capture is not an image")
            }

            // Sampled against twice the final edge, not once. The crop throws
            // away most of the frame, so decoding straight down to MAX_EDGE
            // would leave the part actually kept softer than a photo taken the
            // old way.
            val options = BitmapFactory.Options().apply {
                inSampleSize = sampleSizeFor(bounds.outWidth / 2, bounds.outHeight / 2)
            }
            var bitmap = activity.contentResolver.openInputStream(uri)?.use {
                BitmapFactory.decodeStream(it, null, options)
            } ?: throw IOException("Could not read the photo")

            try {
                bitmap = applyExifRotation(uri, bitmap)

                // What the preview showed, in this photo's pixels. The preview
                // fills its box, so whichever edge is relatively longer here is
                // the one that ran off the sides of the screen and was never
                // visible; the crop must not reach into it.
                val shown = visibleRegion(bitmap.width, bitmap.height, previewAspect)

                val x = (shown.left + left * shown.width())
                    .toInt().coerceIn(0, bitmap.width - 1)
                val y = (shown.top + top * shown.height())
                    .toInt().coerceIn(0, bitmap.height - 1)
                val w = (width * shown.width()).toInt().coerceIn(1, bitmap.width - x)
                val h = (height * shown.height()).toInt().coerceIn(1, bitmap.height - y)

                val cropped = Bitmap.createBitmap(bitmap, x, y, w, h)
                if (cropped != bitmap) {
                    bitmap.recycle()
                    bitmap = cropped
                }

                bitmap = scaleToMaxEdge(bitmap)
                val jpeg = compress(bitmap)
                main.post { result.success(jpeg) }
            } finally {
                bitmap.recycle()
            }
        } catch (e: OutOfMemoryError) {
            Log.w(TAG, "Capture too large to crop", e)
            main.post {
                result.error("IMAGE_TOO_LARGE", "That photo is too large to add", null)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not crop the capture", e)
            main.post {
                result.error("IMAGE_UNREADABLE", "That photo could not be read", null)
            }
        } finally {
            runCatching { file.delete() }
        }
    }

    /**
     * The part of an upright photograph that the camera preview was showing.
     *
     * The preview fills its box on screen, so when the still is a different shape
     * from the preview one pair of edges falls outside what the user could see.
     * A guide drawn on the preview describes a fraction of the *visible* picture,
     * not of the whole file, and applying it to the whole file would slide the
     * crop away from whatever was lined up inside the brackets.
     *
     * [previewAspect] arrives the way the camera reports it — the sensor's long
     * edge over its short one — while the picture here is upright, so it is
     * inverted before use.
     *
     * Both dimensions are in pixels of the already-rotated bitmap.
     */
    internal fun visibleRegion(imageWidth: Int, imageHeight: Int, previewAspect: Double): Rect {
        val whole = Rect(0, 0, imageWidth, imageHeight)
        if (imageWidth <= 0 || imageHeight <= 0 || previewAspect <= 0) return whole

        val wanted = 1.0 / previewAspect
        val actual = imageWidth.toDouble() / imageHeight

        // A hair either way is rounding, not a different shape, and trimming for
        // it would only cost pixels.
        if (kotlin.math.abs(actual - wanted) < 0.01) return whole

        return if (actual > wanted) {
            // The photo is wider than the preview: its sides were off-screen.
            val w = (imageHeight * wanted).toInt().coerceIn(1, imageWidth)
            val inset = (imageWidth - w) / 2
            Rect(inset, 0, inset + w, imageHeight)
        } else {
            // Taller than the preview: top and bottom were off-screen.
            val h = (imageWidth / wanted).toInt().coerceIn(1, imageHeight)
            val inset = (imageHeight - h) / 2
            Rect(0, inset, imageWidth, inset + h)
        }
    }

    private fun loadScaledJpeg(uri: Uri): ByteArray {
        // Read the header first so the full-size bitmap is never decoded: a 50 MP
        // photo would be 200 MB in memory before any scaling could happen.
        //
        // The stream is null-checked on its own line, deliberately. Writing this as
        // `openInputStream(uri)?.use { decodeStream(...) } ?: throw` reads as "throw
        // if the image could not be opened" but does not mean it: in bounds-only
        // mode decodeStream returns null by contract, so the elvis sees the decode
        // result rather than the stream and fires every single time. That shipped,
        // and made every photo — gallery or camera — fail with "That image could
        // not be read".
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        val header = activity.contentResolver.openInputStream(uri)
            ?: throw IOException("Could not open the chosen image")
        header.use { BitmapFactory.decodeStream(it, null, bounds) }

        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
            throw IOException("That file is not an image")
        }

        val options = BitmapFactory.Options().apply {
            inSampleSize = sampleSizeFor(bounds.outWidth, bounds.outHeight)
        }
        var bitmap = activity.contentResolver.openInputStream(uri)?.use {
            BitmapFactory.decodeStream(it, null, options)
        } ?: throw IOException("Could not read the chosen image")

        try {
            bitmap = scaleToMaxEdge(bitmap)
            bitmap = applyExifRotation(uri, bitmap)
            return compress(bitmap)
        } finally {
            bitmap.recycle()
        }
    }

    /** Largest power-of-two subsample that still leaves the longest edge over [MAX_EDGE]. */
    private fun sampleSizeFor(width: Int, height: Int): Int {
        val longest = maxOf(width, height)
        var sample = 1
        while (longest / (sample * 2) >= MAX_EDGE) sample *= 2
        return sample
    }

    private fun scaleToMaxEdge(bitmap: Bitmap): Bitmap {
        val longest = maxOf(bitmap.width, bitmap.height)
        if (longest <= MAX_EDGE) return bitmap

        val ratio = MAX_EDGE.toFloat() / longest
        val scaled = Bitmap.createScaledBitmap(
            bitmap,
            (bitmap.width * ratio).toInt().coerceAtLeast(1),
            (bitmap.height * ratio).toInt().coerceAtLeast(1),
            true
        )
        if (scaled != bitmap) bitmap.recycle()
        return scaled
    }

    /**
     * Bakes the EXIF orientation into the pixels.
     *
     * Necessary because the re-compressed JPEG carries no EXIF at all, so an
     * orientation tag left unapplied would not be dropped harmlessly — it would
     * silently turn every portrait photo on its side.
     *
     * `android.media.ExifInterface` accepts an `InputStream` from API 24, which is
     * this app's minimum, so no extra dependency is needed to read a content URI.
     */
    private fun applyExifRotation(uri: Uri, bitmap: Bitmap): Bitmap {
        val orientation = try {
            activity.contentResolver.openInputStream(uri)?.use { stream ->
                ExifInterface(stream).getAttributeInt(
                    ExifInterface.TAG_ORIENTATION,
                    ExifInterface.ORIENTATION_NORMAL
                )
            } ?: ExifInterface.ORIENTATION_NORMAL
        } catch (e: Exception) {
            ExifInterface.ORIENTATION_NORMAL
        }

        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.postScale(-1f, 1f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.postScale(1f, -1f)
            else -> return bitmap
        }

        val rotated = Bitmap.createBitmap(
            bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true
        )
        if (rotated != bitmap) bitmap.recycle()
        return rotated
    }

    private fun compress(bitmap: Bitmap): ByteArray {
        var quality = START_QUALITY
        var out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, quality, out)

        while (out.size() > TARGET_MAX_BYTES && quality > MIN_QUALITY) {
            quality -= 10
            out = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.JPEG, quality, out)
        }
        return out.toByteArray()
    }

    private fun captureFile(): File {
        val dir = File(activity.cacheDir, CAPTURE_DIR)
        if (!dir.exists()) dir.mkdirs()
        return File(dir, CAPTURE_FILE)
    }

    private fun newCaptureUri(): Uri {
        val file = captureFile()
        if (file.exists()) file.delete()
        return FileProvider.getUriForFile(
            activity,
            "${activity.packageName}.fileprovider",
            file
        )
    }

    /**
     * Removes the camera's plaintext copy from the cache.
     *
     * Called on every exit from a capture — success, cancel or failure — because
     * the only reason that file exists is that a camera app cannot write into an
     * encrypted store directly.
     */
    private fun discardCaptureFile() {
        try {
            val file = captureFile()
            if (file.exists()) file.delete()
        } catch (e: Exception) {
            // Best effort. A stale cache file is not worth failing the operation.
        }
    }
}
