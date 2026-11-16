package com.itsash.countdown

import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MethodChannel "com.itsash.countdown/control" (Dart side: lib/core/platform.dart):
 *   - load() -> the saved events as a JSON string, or null.
 *   - save({events, alerts}): stores both JSON strings, redraws widgets, re-plans notifications.
 *   - notificationsGranted() -> Boolean.
 *   - requestNotifications(): the system dialog the first time, then the app's notification settings.
 */
class MainActivity : FlutterActivity() {

    private val channelName = "com.itsash.countdown/control"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val prefs = CountdownPrefs(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "load" -> result.success(prefs.eventsJson)
                    "save" -> {
                        prefs.eventsJson = call.argument<String>("events")
                        prefs.alertsJson = call.argument<String>("alerts")
                        CountdownSync.refresh(this)
                        result.success(null)
                    }
                    "notificationsGranted" -> result.success(enabled())
                    "requestNotifications" -> {
                        requestNotifications(prefs)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Throwable) {
                result.error("failed", e.message, null)
            }
        }
    }

    private fun enabled(): Boolean =
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).areNotificationsEnabled()

    private fun requestNotifications(prefs: CountdownPrefs) {
        if (enabled()) return
        if (Build.VERSION.SDK_INT >= 33 && !prefs.askedNotifications) {
            prefs.askedNotifications = true
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
            return
        }
        val i = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(i)
    }
}
