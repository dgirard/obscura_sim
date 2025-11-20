package com.example.obscura_sim

import android.content.ContentUris
import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.OutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.obscurasim.app/mediastore"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToMediaStore" -> {
                    val filePath = call.argument<String>("filePath")
                    val displayName = call.argument<String>("displayName")

                    if (filePath == null || displayName == null) {
                        result.error("INVALID_ARGUMENT", "File path and display name are required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val uri = saveImageToMediaStore(filePath, displayName)
                        result.success(uri.toString())
                    } catch (e: Exception) {
                        result.error("SAVE_ERROR", "Failed to save to MediaStore: ${e.message}", null)
                    }
                }
                "shareWithNativeIntent" -> {
                    val contentUri = call.argument<String>("contentUri")
                    val text = call.argument<String>("text")
                    val subject = call.argument<String>("subject")

                    if (contentUri == null) {
                        result.error("INVALID_ARGUMENT", "Content URI is required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        shareWithNativeIntent(contentUri, text, subject)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SHARE_ERROR", "Failed to share: ${e.message}", null)
                    }
                }
                "deleteFromMediaStore" -> {
                    val fileName = call.argument<String>("fileName")

                    if (fileName == null) {
                        result.error("INVALID_ARGUMENT", "File name is required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val deleted = deleteFromMediaStore(fileName)
                        result.success(deleted)
                    } catch (e: Exception) {
                        result.error("DELETE_ERROR", "Failed to delete from MediaStore: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveImageToMediaStore(filePath: String, displayName: String): Uri {
        val file = File(filePath)
        val contentResolver = applicationContext.contentResolver

        val contentValues = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/ObscuraSim")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
        }

        val imageUri = contentResolver.insert(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            contentValues
        ) ?: throw Exception("Failed to create MediaStore entry")

        try {
            contentResolver.openOutputStream(imageUri)?.use { outputStream ->
                FileInputStream(file).use { inputStream ->
                    inputStream.copyTo(outputStream)
                }
            } ?: throw Exception("Failed to open output stream")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                contentValues.clear()
                contentValues.put(MediaStore.Images.Media.IS_PENDING, 0)
                contentResolver.update(imageUri, contentValues, null, null)
            }

            // Return the content URI directly for sharing
            return imageUri
        } catch (e: Exception) {
            // Clean up on error
            contentResolver.delete(imageUri, null, null)
            throw e
        }
    }

    private fun shareWithNativeIntent(contentUriString: String, text: String?, subject: String?) {
        val uri = android.net.Uri.parse(contentUriString)

        val shareIntent = android.content.Intent().apply {
            action = android.content.Intent.ACTION_SEND
            type = "image/jpeg"
            putExtra(android.content.Intent.EXTRA_STREAM, uri)

            text?.let { putExtra(android.content.Intent.EXTRA_TEXT, it) }
            subject?.let { putExtra(android.content.Intent.EXTRA_SUBJECT, it) }

            // Grant read permission to the receiving app
            addFlags(android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        val chooserIntent = android.content.Intent.createChooser(shareIntent, "Partager la photo")
        chooserIntent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)

        startActivity(chooserIntent)
    }

    private fun deleteFromMediaStore(fileName: String): Boolean {
        val contentResolver = applicationContext.contentResolver

        // Search for the file in MediaStore
        val projection = arrayOf(MediaStore.Images.Media._ID, MediaStore.Images.Media.DISPLAY_NAME)
        val selection = "${MediaStore.Images.Media.DISPLAY_NAME} = ?"
        val selectionArgs = arrayOf(fileName)

        try {
            contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
                    val id = cursor.getLong(idColumn)

                    // Delete the file
                    val uri = android.content.ContentUris.withAppendedId(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                        id
                    )

                    val deletedRows = contentResolver.delete(uri, null, null)
                    return deletedRows > 0
                }
            }
        } catch (e: Exception) {
            throw Exception("Failed to delete from MediaStore: ${e.message}")
        }

        return false
    }
}
