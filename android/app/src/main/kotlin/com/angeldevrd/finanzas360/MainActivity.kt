package com.angeldevrd.finanzas360

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "finanzas360/native_share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "shareFile") {
                val path = call.argument<String>("path")
                val text = call.argument<String>("text")
                if (path == null) {
                    result.error("invalid_args", "Falta la ruta del archivo", null)
                    return@setMethodCallHandler
                }
                try {
                    shareFile(path, text)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("share_failed", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun shareFile(path: String, text: String?) {
        val file = File(path)
        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            file,
        )
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            putExtra(Intent.EXTRA_STREAM, uri)
            if (!text.isNullOrEmpty()) putExtra(Intent.EXTRA_TEXT, text)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(intent, text))
    }
}
