package com.pocketdesk.pocketdesk.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.graphics.Color
import android.graphics.Paint
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.pocketdesk.pocketdesk.MainActivity
import com.pocketdesk.pocketdesk.R
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

class MyDayTasksWidgetProvider : AppWidgetProvider() {
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

    data class TaskItem(
        val id: String,
        val title: String,
        val isDone: Boolean,
        val time: String = ""
    )

    companion object {
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, MyDayTasksWidgetProvider::class.java))
            for (id in ids) {
                updateAppWidget(context, appWidgetManager, id)
            }
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_tasks)

            // 1. Root and Add Click Intents
            val rootIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("action", "tasks")
            }
            val rootPendingIntent = PendingIntent.getActivity(
                context, 300, rootIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_tasks_root, rootPendingIntent)

            val addIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("action", "add_task")
            }
            val addPendingIntent = PendingIntent.getActivity(
                context, 301, addIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_tasks_add, addPendingIntent)

            // 2. Fetch User Tasks (from SharedPreferences or SQLite database)
            val tasks = loadRealUserTasks(context)

            val pendingCount = tasks.count { !it.isDone }
            if (tasks.isNotEmpty()) {
                if (pendingCount > 0) {
                    views.setTextViewText(R.id.tv_tasks_badge, "$pendingCount left")
                } else {
                    views.setTextViewText(R.id.tv_tasks_badge, "All done! ✓")
                }
            } else {
                views.setTextViewText(R.id.tv_tasks_badge, "0 items")
            }

            if (tasks.isEmpty()) {
                views.setViewVisibility(R.id.layout_tasks_empty, View.VISIBLE)
                views.setViewVisibility(R.id.layout_tasks_list, View.GONE)
            } else {
                views.setViewVisibility(R.id.layout_tasks_empty, View.GONE)
                views.setViewVisibility(R.id.layout_tasks_list, View.VISIBLE)

                val rowIds = listOf(R.id.task_row_1, R.id.task_row_2, R.id.task_row_3, R.id.task_row_4)
                val checkIds = listOf(R.id.iv_task_1_check, R.id.iv_task_2_check, R.id.iv_task_3_check, R.id.iv_task_4_check)
                val titleIds = listOf(R.id.tv_task_1_title, R.id.tv_task_2_title, R.id.tv_task_3_title, R.id.tv_task_4_title)
                val timeIds = listOf(R.id.tv_task_1_time, R.id.tv_task_2_time, R.id.tv_task_3_time, R.id.tv_task_4_time)

                for (i in 0 until 4) {
                    if (i < tasks.size) {
                        val task = tasks[i]
                        views.setViewVisibility(rowIds[i], View.VISIBLE)
                        views.setTextViewText(titleIds[i], task.title)

                        if (task.time.isNotEmpty()) {
                            views.setViewVisibility(timeIds[i], View.VISIBLE)
                            views.setTextViewText(timeIds[i], task.time)
                        } else {
                            views.setViewVisibility(timeIds[i], View.GONE)
                        }

                        if (task.isDone) {
                            views.setImageViewResource(checkIds[i], R.drawable.ic_widget_checked)
                            views.setTextColor(titleIds[i], Color.parseColor("#8E9096"))
                        } else {
                            views.setImageViewResource(checkIds[i], R.drawable.ic_widget_circle)
                            views.setTextColor(titleIds[i], Color.parseColor("#F3F3F2"))
                        }
                    } else {
                        views.setViewVisibility(rowIds[i], View.GONE)
                    }
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun loadRealUserTasks(context: Context): List<TaskItem> {
            val list = mutableListOf<TaskItem>()

            // A. Check FlutterSharedPreferences first
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val jsonStr = prefs.getString("flutter.widget_tasks_json", null)
                if (!jsonStr.isNullOrEmpty()) {
                    val arr = JSONArray(jsonStr)
                    for (i in 0 until arr.length()) {
                        val obj = arr.getJSONObject(i)
                        list.add(
                            TaskItem(
                                id = obj.optString("id", i.toString()),
                                title = obj.optString("title", "Task"),
                                isDone = obj.optBoolean("isDone", false),
                                time = obj.optString("time", "")
                            )
                        )
                    }
                    if (list.isNotEmpty()) return list
                }
            } catch (_: Exception) {}

            // B. Direct SQLite Query Fallback
            try {
                val dbFile = findDatabaseFile(context)
                if (dbFile != null && dbFile.exists()) {
                    val db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READONLY)
                    val cursor = db.rawQuery(
                        "SELECT id, title, is_done, due_date FROM tasks WHERE is_deleted = 0 ORDER BY is_done ASC, created_at DESC LIMIT 4",
                        null
                    )
                    while (cursor.moveToNext()) {
                        val id = cursor.getString(0)
                        val title = cursor.getString(1)
                        val isDone = cursor.getInt(2) == 1
                        val dueDate = cursor.getString(3) ?: ""
                        list.add(TaskItem(id = id, title = title, isDone = isDone, time = dueDate))
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
