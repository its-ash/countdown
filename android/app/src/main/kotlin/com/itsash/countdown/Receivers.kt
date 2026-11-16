package com.itsash.countdown

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Alarm target: a notification is due, or it is just past midnight. */
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Both cases do the same work: show what is due, redraw, re-arm.
        CountdownSync.refresh(context)
    }

    companion object {
        const val ACTION_ALERT = "com.itsash.countdown.ALERT"
        const val ACTION_MIDNIGHT = "com.itsash.countdown.MIDNIGHT"
    }
}

/** Boot, app update, and clock / time zone / date changes: alarms are lost or wrong, so plan them again. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        CountdownSync.refresh(context)
    }
}
