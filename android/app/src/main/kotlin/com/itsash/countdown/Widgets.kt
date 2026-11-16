package com.itsash.countdown

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.widget.RemoteViews
import java.time.LocalDateTime

private fun isDark(context: Context): Boolean =
    (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

/** Small widget: one event picked when the widget is added (SmallConfigActivity). */
class SmallWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) manager.updateAppWidget(id, build(context, id))
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val prefs = CountdownPrefs(context)
        for (id in appWidgetIds) prefs.clearWidget(id)
    }

    companion object {
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            for (id in manager.getAppWidgetIds(ComponentName(context, SmallWidget::class.java))) {
                manager.updateAppWidget(id, build(context, id))
            }
        }

        fun build(context: Context, widgetId: Int): RemoteViews {
            val prefs = CountdownPrefs(context)
            val now = LocalDateTime.now()
            val ev = prefs.widgetEvent(widgetId)?.let { id -> prefs.events().firstOrNull { it.id == id } }
            val views = RemoteViews(context.packageName, R.layout.widget_small)
            if (ev == null) {
                views.setTextViewText(R.id.small_emoji, "⏳")
                views.setTextViewText(R.id.small_title, context.getString(R.string.widget_pick))
                views.setTextViewText(R.id.small_value, "")
                views.setTextViewText(R.id.small_unit, "")
                val pick = Intent(context, SmallConfigActivity::class.java)
                    .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                    .setAction("com.itsash.countdown.PICK_$widgetId")
                views.setOnClickPendingIntent(
                    R.id.small_root,
                    PendingIntent.getActivity(context, widgetId, pick, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE),
                )
                return views
            }
            val info = Calc.of(ev, now)
            val (value, unit) = Calc.label(info, now)
            views.setTextViewText(R.id.small_emoji, ev.emoji)
            views.setTextViewText(R.id.small_title, ev.title)
            views.setTextViewText(R.id.small_value, value)
            views.setTextColor(R.id.small_value, Calc.color(ev.color, isDark(context)))
            views.setTextViewText(R.id.small_unit, unit)
            views.setOnClickPendingIntent(R.id.small_root, CountdownSync.openApp(context))
            return views
        }
    }
}

/** 4x2 widget: the next events, soonest first. */
class ListWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        val views = build(context)
        for (id in appWidgetIds) manager.updateAppWidget(id, views)
    }

    companion object {
        private val ROWS = intArrayOf(R.id.row0, R.id.row1, R.id.row2, R.id.row3)
        private val EMOJI = intArrayOf(R.id.row0_emoji, R.id.row1_emoji, R.id.row2_emoji, R.id.row3_emoji)
        private val TITLE = intArrayOf(R.id.row0_title, R.id.row1_title, R.id.row2_title, R.id.row3_title)
        private val VALUE = intArrayOf(R.id.row0_value, R.id.row1_value, R.id.row2_value, R.id.row3_value)

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, ListWidget::class.java))
            if (ids.isEmpty()) return
            val views = build(context)
            for (id in ids) manager.updateAppWidget(id, views)
        }

        private fun build(context: Context): RemoteViews {
            val now = LocalDateTime.now()
            val dark = isDark(context)
            // Upcoming and today only; past events fill in when there are fewer than four.
            val items = Calc.sorted(CountdownPrefs(context).events(), now).take(ROWS.size)
            val views = RemoteViews(context.packageName, R.layout.widget_list)
            views.setViewVisibility(R.id.list_empty, if (items.isEmpty()) android.view.View.VISIBLE else android.view.View.GONE)
            for (i in ROWS.indices) {
                val item = items.getOrNull(i)
                views.setViewVisibility(ROWS[i], if (item == null) android.view.View.GONE else android.view.View.VISIBLE)
                if (item == null) continue
                views.setTextViewText(EMOJI[i], item.ev.emoji)
                views.setTextViewText(TITLE[i], item.ev.title)
                views.setTextViewText(VALUE[i], Calc.short(item, now))
                views.setTextColor(VALUE[i], Calc.color(item.ev.color, dark))
            }
            views.setOnClickPendingIntent(R.id.list_root, CountdownSync.openApp(context))
            return views
        }
    }
}
