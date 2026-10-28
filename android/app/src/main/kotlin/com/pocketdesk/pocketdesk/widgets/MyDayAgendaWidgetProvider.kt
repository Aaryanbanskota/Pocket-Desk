package com.pocketdesk.pocketdesk.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.pocketdesk.pocketdesk.MainActivity
import com.pocketdesk.pocketdesk.R
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MyDayAgendaWidgetProvider : AppWidgetProvider() {
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

    data class AgendaItem(
        val id: String,
        val title: String,
        val time: String,
        val colorHex: String = "#FF6B00"
    )

    companion object {
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, MyDayAgendaWidgetProvider::class.java))
            for (id in ids) {
                updateAppWidget(context, appWidgetManager, id)
            }
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_agenda)

            // 1. Dynamic Date Header (AD and BS)
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val savedAdDate = prefs.getString("flutter.widget_ad_date", null)
            val savedBsDate = prefs.getString("flutter.widget_bs_date", null)

            val adDisplay = if (!savedAdDate.isNullOrEmpty()) {
                savedAdDate
            } else {
                val dayFormat = SimpleDateFormat("EEEE, d MMMM", Locale.getDefault())
                dayFormat.format(Date())
            }

            val bsDisplay = if (!savedBsDate.isNullOrEmpty()) {
                savedBsDate
            } else {
                "Today's Agenda"
            }

            views.setTextViewText(R.id.tv_ad_date, adDisplay)
            views.setTextViewText(R.id.tv_bs_date, bsDisplay)

            // 2. Click Intents
            val rootIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("action", "calendar")
            }
            val rootPendingIntent = PendingIntent.getActivity(
                context, 200, rootIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_agenda_root, rootPendingIntent)

            val addIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("action", "add_event")
            }
            val addPendingIntent = PendingIntent.getActivity(
                context, 201, addIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_agenda_add, addPendingIntent)

            // 3. Load Real User Events
            val events = loadRealUserEvents(context)

            if (events.isEmpty()) {
                views.setViewVisibility(R.id.layout_agenda_empty, View.VISIBLE)
                views.setViewVisibility(R.id.layout_agenda_list, View.GONE)
            } else {
                views.setViewVisibility(R.id.layout_agenda_empty, View.GONE)
                views.setViewVisibility(R.id.layout_agenda_list, View.VISIBLE)

                val rowIds = listOf(R.id.agenda_item_1, R.id.agenda_item_2, R.id.agenda_item_3, R.id.agenda_item_4)
                val titleIds = listOf(R.id.tv_item_1_title, R.id.tv_item_2_title, R.id.tv_item_3_title, R.id.tv_item_4_title)
                val timeIds = listOf(R.id.tv_item_1_time, R.id.tv_item_2_time, R.id.tv_item_3_time, R.id.tv_item_4_time)

                for (i in 0 until 4) {
                    if (i < events.size) {
                        val ev = events[i]
                        views.setViewVisibility(rowIds[i], View.VISIBLE)
                        views.setTextViewText(titleIds[i], ev.title)
                        views.setTextViewText(timeIds[i], if (ev.time.isNotEmpty()) ev.time else "Today")
                    } else {
                        views.setViewVisibility(rowIds[i], View.GONE)
                    }
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun loadRealUserEvents(context: Context): List<AgendaItem> {
            val list = mutableListOf<AgendaItem>()

            // A. Check FlutterSharedPreferences first
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val jsonStr = prefs.getString("flutter.widget_agenda_json", null)
                if (!jsonStr.isNullOrEmpty()) {
                    val arr = JSONArray(jsonStr)
                    for (i in 0 until arr.length()) {
                        val obj = arr.getJSONObject(i)
                        list.add(
                            AgendaItem(
                                id = obj.optString("id", i.toString()),
                                title = obj.optString("title", "Event"),
                                time = obj.optString("time", "Today"),
                                colorHex = obj.optString("color", "#FF6B00")
                            )
                        )
                    }
                    if (list.isNotEmpty()) return list
                }
            } catch (_: Exception) {}

            // B. Direct SQLite Query Fallback (tasks where tags_json contains 'event' or all pending items)
            try {
                val dbFile = findDatabaseFile(context)
                if (dbFile != null && dbFile.exists()) {
                    val db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READONLY)
                    val cursor = db.rawQuery(
                        "SELECT id, title, due_date, tags_json FROM tasks WHERE is_deleted = 0 AND (tags_json LIKE '%event%' OR kind = 'timed') ORDER BY due_date ASC, created_at DESC LIMIT 4",
                        null
                    )
                    while (cursor.moveToNext()) {
                        val id = cursor.getString(0)
                        val title = cursor.getString(1)
                        val dueDate = cursor.getString(2) ?: "Today"
                        list.add(AgendaItem(id = id, title = title, time = dueDate))
                    }
                    cursor.close()
                    db.close()
                }
            } catch (_: Exception) {}

            return list
        }

        private fun findDatabaseFile(context: Context): File? {
            val candidates = listOf(
                File(context.filesDir.parentFile, "app_flutter/myday_production.sqlite"),
                File(context.filesDir, "myday_production.sqlite"),
                File(context.filesDir, "app_flutter/myday_production.sqlite")
            )
            return candidates.firstOrNull { it.exists() }
        }
    }
}
