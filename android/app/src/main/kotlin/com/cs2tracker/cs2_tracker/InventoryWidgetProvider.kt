package com.cs2tracker.cs2_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget de pantalla de inicio: muestra el valor total del inventario (y si
 * hay algún drop pendiente) sin abrir la app. Los datos los guarda Flutter
 * vía el plugin home_widget (ver lib/services/home_widget_service.dart);
 * aquí solo se leen de SharedPreferences y se pintan en el layout.
 */
class InventoryWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.inventory_widget).apply {
                val value = widgetData.getString("inventory_value", null) ?: "—"
                val pending = widgetData.getString("pending_label", null) ?: ""
                setTextViewText(R.id.widget_value, value)
                setTextViewText(R.id.widget_pending, pending)

                val openApp = PendingIntent.getActivity(
                    context,
                    0,
                    Intent(context, MainActivity::class.java),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, openApp)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
