import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The native side (`MainActivity.kt`) owns the stored data, so the widgets and
/// notifications, which run without Dart, always read the same events.
abstract class CountdownPlatform {
  /// The saved events as JSON, or null if none.
  Future<String?> load();

  /// Saves [events] (JSON list) and the [alerts] (JSON list of `{at, title, body}`),
  /// then redraws widgets and reschedules notifications.
  Future<void> save({required String events, required String alerts});

  Future<bool> notificationsGranted();

  /// Shows the system permission dialog once, then the app's notification settings.
  Future<void> requestNotifications();
}

class ChannelPlatform implements CountdownPlatform {
  static const _channel = MethodChannel('com.itsash.countdown/control');

  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<String?> load() async {
    if (!_android) return null;
    try {
      return await _channel.invokeMethod<String>('load');
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> save({required String events, required String alerts}) async {
    if (!_android) return;
    try {
      await _channel.invokeMethod<void>('save', {'events': events, 'alerts': alerts});
    } on MissingPluginException {
      // Not running on Android.
    }
  }

  @override
  Future<bool> notificationsGranted() async {
    if (!_android) return true;
    try {
      return await _channel.invokeMethod<bool>('notificationsGranted') ?? false;
    } on MissingPluginException {
      return true;
    }
  }

  @override
  Future<void> requestNotifications() async {
    if (!_android) return;
    try {
      await _channel.invokeMethod<void>('requestNotifications');
    } on MissingPluginException {
      // Not running on Android.
    }
  }
}
