package com.pocketdesk.pocketdesk

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.view.WindowManager
import androidx.core.content.FileProvider
import com.pocketdesk.pocketdesk.widgets.MyDayAgendaWidgetProvider
import com.pocketdesk.pocketdesk.widgets.MyDayBudgetWidgetProvider
import com.pocketdesk.pocketdesk.widgets.MyDayCalendarMonthWidgetProvider
import com.pocketdesk.pocketdesk.widgets.MyDayClockPieWidgetProvider
import com.pocketdesk.pocketdesk.widgets.MyDayNotesWidgetProvider
import com.pocketdesk.pocketdesk.widgets.MyDayQuickActionsWidgetProvider
import com.pocketdesk.pocketdesk.widgets.MyDayTasksWidgetProvider
import com.pocketdesk.pocketdesk.voice.VoiceCallManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.TimeZone

class MainActivity : FlutterFragmentActivity() {
    private var pendingAction: String? = null
    private var channel: MethodChannel? = null
    private var voiceCallManager: VoiceCallManager? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = intent.getStringExtra("action") ?: intent.action
        if (action != null) {
            pendingAction = action
            channel?.invokeMethod("onAction", action)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        voiceCallManager = VoiceCallManager(this, flutterEngine.dartExecutor.binaryMessenger)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pocketdesk/device").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "wakeScreenForIncomingCall" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                                setShowWhenLocked(true)
                                setTurnScreenOn(true)
                            }
                            @Suppress("DEPRECATION")
                            window.addFlags(
                                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
                            )

                            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                            val wakeLock = powerManager?.newWakeLock(
                                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                                "Pocketdesk:IncomingCallWakeLock"
                            )
                            wakeLock?.acquire(20000)

                            val intent = Intent(this@MainActivity, MainActivity::class.java).apply {
                                action = "action_incoming_call"
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                            }
                            startActivity(intent)

                            result.success(true)
                        } catch (e: Exception) {
                            e.printStackTrace()
                            result.success(false)
                        }
                    }
                    "clearCallWakeFlags" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                                setShowWhenLocked(false)
                                setTurnScreenOn(false)
                            }
                            @Suppress("DEPRECATION")
                            window.clearFlags(
                                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "localTimezone" -> {
                        result.success(TimeZone.getDefault().id)
                    }
                    "updateWidgets" -> {
                        MyDayTasksWidgetProvider.updateAllWidgets(this@MainActivity)
                        MyDayAgendaWidgetProvider.updateAllWidgets(this@MainActivity)
                        MyDayClockPieWidgetProvider.updateAllWidgets(this@MainActivity)
                        MyDayCalendarMonthWidgetProvider.updateAllWidgets(this@MainActivity)
                        MyDayNotesWidgetProvider.updateAllWidgets(this@MainActivity)
                        MyDayBudgetWidgetProvider.updateAllWidgets(this@MainActivity)
                        MyDayQuickActionsWidgetProvider.updateAllWidgets(this@MainActivity)
                        result.success(true)
                    }
                    "getInitialAction" -> {
                        val act = intent?.getStringExtra("action") ?: intent?.action ?: pendingAction
                        result.success(act)
                    }
                    "isRequestPinSupported" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val appWidgetManager = getSystemService(AppWidgetManager::class.java)
                            result.success(appWidgetManager?.isRequestPinAppWidgetSupported == true)
                        } else {
                            result.success(false)
                        }
                    }
                    "requestPinWidget" -> {
                        val widgetType = call.argument<String>("type") ?: "quick_actions"
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val appWidgetManager = getSystemService(AppWidgetManager::class.java)
                            if (appWidgetManager?.isRequestPinAppWidgetSupported == true) {
                                val providerClass = when (widgetType) {
                                    "agenda" -> MyDayAgendaWidgetProvider::class.java
                                    "tasks" -> MyDayTasksWidgetProvider::class.java
                                    "clock_pie" -> MyDayClockPieWidgetProvider::class.java
                                    "calendar_month" -> MyDayCalendarMonthWidgetProvider::class.java
                                    "notes" -> MyDayNotesWidgetProvider::class.java
                                    "budget" -> MyDayBudgetWidgetProvider::class.java
                                    else -> MyDayQuickActionsWidgetProvider::class.java
                                }
                                val provider = ComponentName(this@MainActivity, providerClass)
                                val success = appWidgetManager.requestPinAppWidget(provider, null, null)
                                result.success(success)
                                return@setMethodCallHandler
                            }
                        }
                        result.success(false)
                    }
                    "installApk" -> {
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
                                this@MainActivity,
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
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        voiceCallManager?.stopVoiceCall()
        voiceCallManager = null
        super.onDestroy()
    }
}
