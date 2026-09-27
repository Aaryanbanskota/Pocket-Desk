package com.pocketdesk.pocketdesk

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.TimeZone

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pocketdesk/device")
            .setMethodCallHandler { call, result ->
                if (call.method == "localTimezone") {
                    result.success(TimeZone.getDefault().id)
                } else if (call.method == "installApk") {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("invalid_apk", "APK path is missing.", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val apk = File(path).canonicalFile
                        val cache = cacheDir.canonicalFile
                        if (!apk.isFile ||
                            !apk.path.startsWith("${cache.path}${File.separator}")
                        ) {
                            result.error(
                                "invalid_apk",
                                "APK file is not in app cache.",
                                null
                            )
                            return@setMethodCallHandler
                        }
                        val apkUri: Uri = FileProvider.getUriForFile(
                            this,
                            "$packageName.fileProvider",
                            apk,
                        )
                        startActivity(Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(
                                apkUri,
                                "application/vnd.android.package-archive",
                            )
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        })
                        result.success(null)
                    } catch (e: Exception) {
                        result.error(
                            "apk_install_failed",
                            e.localizedMessage ?: "Android could not open the APK installer.",
                            null
                        )
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
