package com.pocketdesk.pocketdesk.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.RemoteViews
import com.pocketdesk.pocketdesk.MainActivity
import com.pocketdesk.pocketdesk.R
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MyDayCalendarMonthWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle?
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        updateAllWidgets(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        updateAllWidgets(context)
    }

    companion object {
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, MyDayCalendarMonthWidgetProvider::class.java))
            for (id in ids) {
                updateAppWidget(context, appWidgetManager, id)
            }
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_calendar_month)

            val rootIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("action", "calendar")
            }
            val rootPendingIntent = PendingIntent.getActivity(
                context, 600, rootIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_calendar_month_root, rootPendingIntent)
            views.setOnClickPendingIntent(R.id.btn_month_calendar_open, rootPendingIntent)

            // Month and Year
            val monthFmt = SimpleDateFormat("MMMM yyyy", Locale.getDefault())
            views.setTextViewText(R.id.tv_month_title, monthFmt.format(Date()))

            // Dynamic AD & BS subtitle
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val bsText = prefs.getString("flutter.widget_nepali_date", "Kartik 2083 BS") ?: "Kartik 2083 BS"
            views.setTextViewText(R.id.tv_month_nepali_sub, bsText)

            // Real upcoming event
            val rawEvents = prefs.getString("flutter.widget_agenda_json", null)
            var eventTitle = "No events scheduled today"
            var eventSub = "Tap to open monthly calendar & agenda"
            if (!rawEvents.isNullOrEmpty()) {
                try {
                    val arr = JSONArray(rawEvents)
                    if (arr.length() > 0) {
                        val first = arr.getJSONObject(0)
                        eventTitle = first.optString("title", "Today's Event")
                        val time = first.optString("time", "Scheduled")
                        eventSub = "Scheduled at $time"
                    }
                } catch (_: Exception) {}
            }
            views.setTextViewText(R.id.tv_month_today_title, eventTitle)
            views.setTextViewText(R.id.tv_month_today_subtitle, eventSub)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
