package com.itsash.countdown

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import java.time.LocalDate
import java.time.ZoneId

/** Redraws the widgets and re-plans every alarm. Called after each change and on boot / clock changes. */
object CountdownSync {
    fun refresh(context: Context) {
        SmallWidget.updateAll(context)
        ListWidget.updateAll(context)
        Alerts.process(context)
        scheduleMidnight(context)
    }

    private const val REQUEST_MIDNIGHT = 1

    /** A wake-up just after local midnight so the day counts on the widgets change. */
    private fun scheduleMidnight(context: Context) {
        val zone = ZoneId.systemDefault()
        val at = LocalDate.now(zone).plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli() + 2000
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.setAndAllowWhileIdle(AlarmManager.RTC, at, receiverIntent(context, AlarmReceiver.ACTION_MIDNIGHT, REQUEST_MIDNIGHT))
    }

    fun receiverIntent(context: Context, action: String, request: Int): PendingIntent {
        val i = Intent(context, AlarmReceiver::class.java).setAction(action)
        return PendingIntent.getBroadcast(context, request, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    fun openApp(context: Context): PendingIntent {
        val i = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(Intent.ACTION_MAIN).setPackage(context.packageName)
        return PendingIntent.getActivity(context, 0, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
}

/**
 * Notifications. Dart plans them (lib/core/countdown_math.dart `buildAlerts`) and saves
 * `[{at, title, body}]`; here one alarm is kept for the next one, so it works with the app closed.
 */
object Alerts {
    private const val CHANNEL = "events"
    private const val REQUEST_ALERT = 2
    private const val TOLERANCE_MS = 60_000L
    private const val STALE_MS = 12L * 60 * 60 * 1000

    /** Shows the alerts that are due, then arms the alarm for the next one. */
    fun process(context: Context) {
        val prefs = CountdownPrefs(context)
        val now = System.currentTimeMillis()
        val list = parse(prefs.alertsJson)
        var watermark = maxOf(prefs.lastFired, now)
        val last = prefs.lastFired
        for (a in list) {
            if (a.at > last && a.at <= now + TOLERANCE_MS) {
                if (now - a.at < STALE_MS) show(context, a)
                watermark = maxOf(watermark, a.at)
            }
        }
        prefs.lastFired = watermark
        val next = list.firstOrNull { it.at > watermark }
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = CountdownSync.receiverIntent(context, AlarmReceiver.ACTION_ALERT, REQUEST_ALERT)
        if (next == null) am.cancel(pi) else am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.at, pi)
    }

    private class Alert(val at: Long, val title: String, val body: String)

    private fun parse(raw: String?): List<Alert> {
        if (raw.isNullOrEmpty()) return emptyList()
        val out = ArrayList<Alert>()
        try {
            val arr = JSONArray(raw)
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                out.add(Alert(o.getLong("at"), o.optString("title"), o.optString("body")))
            }
        } catch (_: Exception) {
        }
        return out.sortedBy { it.at }
    }

    private fun show(context: Context, a: Alert) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(CHANNEL, context.getString(R.string.channel_events), NotificationManager.IMPORTANCE_HIGH)
        nm.createNotificationChannel(channel)
        val n = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_countdown)
            .setContentTitle(a.title)
            .setContentText(a.body)
            .setAutoCancel(true)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setContentIntent(CountdownSync.openApp(context))
            .build()
        try {
            nm.notify((a.at xor a.title.hashCode().toLong()).toInt(), n)
        } catch (_: SecurityException) {
        }
    }
}
