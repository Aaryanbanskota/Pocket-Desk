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

class MyDayBudgetWidgetProvider : AppWidgetProvider() {
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
            val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, MyDayBudgetWidgetProvider::class.java))
            for (id in ids) {
                updateAppWidget(context, appWidgetManager, id)
            }
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_budget)

            // Click Root -> Open Budget
            val rootIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("action", "budget")
            }
            val rootPendingIntent = PendingIntent.getActivity(
                context, 800, rootIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_budget_root, rootPendingIntent)

            // Click Add Expense
            val addIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("action", "add_expense")
            }
            val addPendingIntent = PendingIntent.getActivity(
                context, 801, addIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_budget_add, addPendingIntent)

            // Load Real Budget Numbers
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val balance = prefs.getString("flutter.widget_budget_balance", "$0.00") ?: "$0.00"
            val spentToday = prefs.getString("flutter.widget_budget_spent", "Today: $0.00") ?: "Today: $0.00"
            val status = prefs.getString("flutter.widget_budget_status", "Within Budget") ?: "Within Budget"

            views.setTextViewText(R.id.tv_budget_net_balance, balance)
            views.setTextViewText(R.id.tv_budget_spent_today, spentToday)
            views.setTextViewText(R.id.tv_budget_monthly_status, status)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
