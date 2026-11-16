package com.itsash.countdown

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.TextView
import java.time.LocalDateTime

/** Opens when a small widget is added (and when an unconfigured one is tapped): pick which event it shows. */
class SmallConfigActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val widgetId = intent?.extras?.getInt(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            ?: AppWidgetManager.INVALID_APPWIDGET_ID
        // Backing out cancels, so Android does not add the widget.
        setResult(RESULT_CANCELED, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        setTitle(R.string.widget_pick_title)

        val prefs = CountdownPrefs(this)
        val items = Calc.sorted(prefs.events(), LocalDateTime.now())
        if (items.isEmpty()) {
            val pad = (24 * resources.displayMetrics.density).toInt()
            setContentView(TextView(this).apply {
                setText(R.string.widget_no_events)
                setPadding(pad, pad, pad, pad)
                textSize = 16f
                setOnClickListener { finishWith(widgetId, null) }
            })
            return
        }
        val list = ListView(this)
        list.adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, items.map { "${it.ev.emoji}  ${it.ev.title}" })
        list.setOnItemClickListener { _, _, position, _ -> finishWith(widgetId, items[position].ev.id) }
        setContentView(list)
    }

    private fun finishWith(widgetId: Int, eventId: String?) {
        if (eventId != null) CountdownPrefs(this).setWidgetEvent(widgetId, eventId)
        val manager = AppWidgetManager.getInstance(this)
        manager.updateAppWidget(widgetId, SmallWidget.build(this, widgetId))
        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
        finish()
    }
}
