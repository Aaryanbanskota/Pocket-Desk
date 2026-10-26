package com.pocketdesk.pocketdesk.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.pocketdesk.pocketdesk.MainActivity
import com.pocketdesk.pocketdesk.R
import org.json.JSONArray

class MyDayNotesWidgetProvider : AppWidgetProvider() {
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

    data class NoteItem(
        val title: String,
        val body: String
    )

    companion object {
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, MyDayNotesWidgetProvider::class.java))
            for (id in ids) {
                updateAppWidget(context, appWidgetManager, id)
            }
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_notes)

            // Click Root
            val rootIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("action", "notes")
            }
            val rootPendingIntent = PendingIntent.getActivity(
                context, 700, rootIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_notes_root, rootPendingIntent)

            // Click Add Note
            val addIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("action", "add_note")
            }
            val addPendingIntent = PendingIntent.getActivity(
                context, 701, addIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_notes_add, addPendingIntent)

            // Click Voice Note
            val voiceIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("action", "voice_note")
            }
            val voicePendingIntent = PendingIntent.getActivity(
                context, 702, voiceIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_notes_voice, voicePendingIntent)

            // Load Real Notes
            val notes = loadRealNotes(context)
            if (notes.isNotEmpty()) {
                views.setTextViewText(R.id.tv_notes_badge, "${notes.size} Notes")
                views.setViewVisibility(R.id.notes_empty_state, View.GONE)

                // Note 1
                views.setViewVisibility(R.id.note_row_1, View.VISIBLE)
                views.setTextViewText(R.id.tv_note1_title, notes[0].title)
                views.setTextViewText(R.id.tv_note1_body, notes[0].body)

                // Note 2
                if (notes.size > 1) {
                    views.setViewVisibility(R.id.note_row_2, View.VISIBLE)
                    views.setTextViewText(R.id.tv_note2_title, notes[1].title)
                    views.setTextViewText(R.id.tv_note2_body, notes[1].body)
                } else {
                    views.setViewVisibility(R.id.note_row_2, View.GONE)
                }

                // Note 3
                if (notes.size > 2) {
                    views.setViewVisibility(R.id.note_row_3, View.VISIBLE)
                    views.setTextViewText(R.id.tv_note3_title, notes[2].title)
                    views.setTextViewText(R.id.tv_note3_body, notes[2].body)
                } else {
                    views.setViewVisibility(R.id.note_row_3, View.GONE)
                }
            } else {
                views.setTextViewText(R.id.tv_notes_badge, "0 Notes")
                views.setViewVisibility(R.id.note_row_1, View.GONE)
                views.setViewVisibility(R.id.note_row_2, View.GONE)
                views.setViewVisibility(R.id.note_row_3, View.GONE)
                views.setViewVisibility(R.id.notes_empty_state, View.VISIBLE)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun loadRealNotes(context: Context): List<NoteItem> {
            val list = mutableListOf<NoteItem>()
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val raw = prefs.getString("flutter.widget_notes_json", null)
                if (!raw.isNullOrEmpty()) {
                    val arr = JSONArray(raw)
                    for (i in 0 until arr.length()) {
                        val obj = arr.getJSONObject(i)
                        val title = obj.optString("title", "Untitled Note")
                        val body = obj.optString("body", "No content")
                        list.add(NoteItem(title, body))
                    }
                }
            } catch (_: Exception) {}
            return list
        }
    }
}
