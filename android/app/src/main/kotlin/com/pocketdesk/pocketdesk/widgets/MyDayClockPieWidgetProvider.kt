package com.pocketdesk.pocketdesk.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.pocketdesk.pocketdesk.MainActivity
import com.pocketdesk.pocketdesk.R
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.cos
import kotlin.math.sin

class MyDayClockPieWidgetProvider : AppWidgetProvider() {
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

    data class ClockPieTask(
        val title: String,
        val time: String,
        val colorInt: Int
    )

    companion object {
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, MyDayClockPieWidgetProvider::class.java))
            for (id in ids) {
                updateAppWidget(context, appWidgetManager, id)
            }
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_clock_pie)

            val rootIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("action", "clock")
            }
            val rootPendingIntent = PendingIntent.getActivity(
                context, 500, rootIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_clock_pie_root, rootPendingIntent)

            // Current Time & Date
            val now = Date()
            val timeFmt = SimpleDateFormat("h:mm a", Locale.getDefault())
            val dateFmt = SimpleDateFormat("EEE, MMM d", Locale.getDefault())
            views.setTextViewText(R.id.tv_dial_current_time, timeFmt.format(now))
            views.setTextViewText(R.id.tv_dial_date, dateFmt.format(now))

            // Load real items
            val items = loadRealTasks(context)

            // Generate and set the high-definition clock pie bitmap!
            val dialBitmap = renderClockPieDial(context, items)
            views.setImageViewBitmap(R.id.iv_clock_pie_canvas, dialBitmap)

            if (items.isNotEmpty()) {
                val next = items[0]
                views.setTextViewText(R.id.tv_dial_event_title, next.title)
                views.setTextViewText(R.id.tv_dial_event_time, if (next.time.isNotEmpty()) next.time else "Today")
                views.setViewVisibility(R.id.dial_active_card, View.VISIBLE)
                views.setViewVisibility(R.id.dial_empty_state, View.GONE)

                if (items.size > 1) {
                    views.setViewVisibility(R.id.dial_row_1, View.VISIBLE)
                    views.setTextViewText(R.id.tv_dial_row1_title, items[1].title)
                    views.setTextViewText(R.id.tv_dial_row1_time, if (items[1].time.isNotEmpty()) items[1].time else "Scheduled")
                } else {
                    views.setViewVisibility(R.id.dial_row_1, View.GONE)
                }
            } else {
                views.setTextViewText(R.id.tv_dial_event_title, "No scheduled events today")
                views.setTextViewText(R.id.tv_dial_event_time, "All clear")
                views.setViewVisibility(R.id.dial_row_1, View.GONE)
                views.setViewVisibility(R.id.dial_empty_state, View.VISIBLE)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun renderClockPieDial(context: Context, tasks: List<ClockPieTask>): Bitmap {
            val size = 520
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)

            val center = size / 2f
            val radius = size * 0.45f
            val dialRect = RectF(center - radius, center - radius, center + radius, center + radius)

            // 1. Dial Outer Background
            val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#1B1A20")
                style = Paint.Style.FILL
            }
            canvas.drawCircle(center, center, radius, bgPaint)

            // 2. Bezel Border
            val bezelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#33FFFFFF")
                style = Paint.Style.STROKE
                strokeWidth = 3f
            }
            canvas.drawCircle(center, center, radius, bezelPaint)

            // 3. Draw Task Pie Sectors
            val colors = intArrayOf(
                Color.parseColor("#FF6B00"), // Orange
                Color.parseColor("#3B82F6"), // Blue
                Color.parseColor("#10B981"), // Emerald
                Color.parseColor("#8B5CF6"), // Purple
                Color.parseColor("#F59E0B"), // Amber
                Color.parseColor("#EC4899")  // Pink
            )

            val sectorPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.FILL
            }
            val sectorLinePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 2.5f
                color = Color.parseColor("#22000000")
            }

            if (tasks.isNotEmpty()) {
                val count = tasks.size.coerceAtMost(6)
                val sweep = 360f / count.toFloat()
                for (i in 0 until count) {
                    val startAngle = -90f + (i * sweep)
                    sectorPaint.color = Color.argb(165, Color.red(colors[i % colors.size]), Color.green(colors[i % colors.size]), Color.blue(colors[i % colors.size]))
                    canvas.drawArc(dialRect, startAngle, sweep, true, sectorPaint)
                    canvas.drawArc(dialRect, startAngle, sweep, true, sectorLinePaint)
                }
            } else {
                // Default aesthetic day sectors
                val defaultSweeps = floatArrayOf(90f, 90f, 100f, 80f)
                var currentAngle = -90f
                for (i in defaultSweeps.indices) {
                    val c = colors[i % colors.size]
                    sectorPaint.color = Color.argb(140, Color.red(c), Color.green(c), Color.blue(c))
                    canvas.drawArc(dialRect, currentAngle, defaultSweeps[i], true, sectorPaint)
                    currentAngle += defaultSweeps[i]
                }
            }

            // 4. Center Cutout Disc (gives the doughnut gauge pie dial effect)
            val centerDiscRadius = radius * 0.40f
            val centerDiscPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#1B1A20")
                style = Paint.Style.FILL
            }
            canvas.drawCircle(center, center, centerDiscRadius, centerDiscPaint)

            val innerRingPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#3AFFFFFF")
                style = Paint.Style.STROKE
                strokeWidth = 2f
            }
            canvas.drawCircle(center, center, centerDiscRadius, innerRingPaint)

            // 5. Draw 12 Clock Hour Numerals
            val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                textAlign = Paint.Align.CENTER
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            }

            val numeralRadius = radius * 0.74f
            for (h in 1..12) {
                val angleRad = Math.toRadians((h * 30.0) - 90.0)
                val isMajor = (h == 12 || h == 3 || h == 6 || h == 9)
                textPaint.color = if (isMajor) Color.WHITE else Color.parseColor("#EAEAEA")
                textPaint.textSize = if (isMajor) size * 0.082f else size * 0.066f

                val x = center + (numeralRadius * cos(angleRad)).toFloat()
                val y = center + (numeralRadius * sin(angleRad)).toFloat() + (textPaint.textSize / 3f)
                canvas.drawText(h.toString(), x, y, textPaint)
            }

            // 6. Draw Accurate Live Clock Hands (Small Hour, Medium Minute, Large Second)
            val cal = Calendar.getInstance()
            val hour = cal.get(Calendar.HOUR)
            val minute = cal.get(Calendar.MINUTE)
            val second = cal.get(Calendar.SECOND)

            // Hour Hand
            val hourAngleRad = Math.toRadians(((hour + minute / 60.0) * 30.0) - 90.0)
            val hourLen = radius * 0.48f
            val hourPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.WHITE
                style = Paint.Style.STROKE
                strokeWidth = size * 0.026f
                strokeCap = Paint.Cap.ROUND
            }
            canvas.drawLine(
                center, center,
                center + (hourLen * cos(hourAngleRad)).toFloat(),
                center + (hourLen * sin(hourAngleRad)).toFloat(),
                hourPaint
            )

            // Minute Hand
            val minAngleRad = Math.toRadians(((minute + second / 60.0) * 6.0) - 90.0)
            val minLen = radius * 0.72f
            val minPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#E8E8E8")
                style = Paint.Style.STROKE
                strokeWidth = size * 0.018f
                strokeCap = Paint.Cap.ROUND
            }
            canvas.drawLine(
                center, center,
                center + (minLen * cos(minAngleRad)).toFloat(),
                center + (minLen * sin(minAngleRad)).toFloat(),
                minPaint
            )

            // Second Hand (Thin, Vibrant Orange Pointer with tail)
            val secAngleRad = Math.toRadians((second * 6.0) - 90.0)
            val secLen = radius * 0.84f
            val secTail = radius * 0.16f
            val secPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#FF6B00")
                style = Paint.Style.STROKE
                strokeWidth = size * 0.007f
                strokeCap = Paint.Cap.ROUND
            }
            canvas.drawLine(
                center - (secTail * cos(secAngleRad)).toFloat(),
                center - (secTail * sin(secAngleRad)).toFloat(),
                center + (secLen * cos(secAngleRad)).toFloat(),
                center + (secLen * sin(secAngleRad)).toFloat(),
                secPaint
            )

            // Center Pivot Cap
            val capPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#FF6B00")
                style = Paint.Style.FILL
            }
            canvas.drawCircle(center, center, size * 0.030f, capPaint)

            val innerCapPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.WHITE
                style = Paint.Style.FILL
            }
            canvas.drawCircle(center, center, size * 0.012f, innerCapPaint)

            return bitmap
        }

        private fun loadRealTasks(context: Context): List<ClockPieTask> {
            val list = mutableListOf<ClockPieTask>()
            val colors = intArrayOf(
                Color.parseColor("#FF6B00"),
                Color.parseColor("#3B82F6"),
                Color.parseColor("#10B981"),
                Color.parseColor("#8B5CF6")
            )
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val raw = prefs.getString("flutter.widget_tasks_json", null)
                if (!raw.isNullOrEmpty()) {
                    val arr = JSONArray(raw)
                    for (i in 0 until arr.length()) {
                        val obj = arr.getJSONObject(i)
                        val title = obj.optString("title", "Task")
                        val time = obj.optString("time", "")
                        val isDone = obj.optBoolean("is_done", false)
                        if (!isDone) {
                            list.add(ClockPieTask(title, time, colors[list.size % colors.size]))
                        }
                    }
                }
            } catch (_: Exception) {}
            return list
        }
    }
}
