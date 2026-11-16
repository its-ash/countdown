import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'countdown_math.dart';
import 'event.dart';
import 'platform.dart';

/// UI state: the event list. Every change is saved natively, which also
/// redraws the widgets and reschedules notifications.
class EventStore extends ChangeNotifier {
  EventStore({CountdownPlatform? platform, DateTime Function()? clock})
    : _platform = platform ?? ChannelPlatform(),
      _clock = clock ?? DateTime.now;

  final CountdownPlatform _platform;
  final DateTime Function() _clock;

  List<CountdownEvent> _events = [];
  bool ready = false;

  List<CountdownEvent> get events => List.unmodifiable(_events);
  DateTime get now => _clock();

  CountdownEvent? byId(String id) {
    for (final e in _events) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Events in display order (soonest first).
  List<Countdown> get countdowns => Countdown.sorted(_events, now);

  Future<void> load() async {
    _events = CountdownEvent.decodeAll(await _platform.load());
    final first = !ready;
    ready = true;
    notifyListeners();
    // Reschedule on start: new year, new alerts to plan.
    if (first) await _save();
  }

  String newId() => _clock().microsecondsSinceEpoch.toString();

  Future<void> upsert(CountdownEvent e) async {
    final i = _events.indexWhere((x) => x.id == e.id);
    _events = [..._events];
    if (i < 0) {
      _events.add(e);
    } else {
      _events[i] = e;
    }
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _events = [for (final e in _events) if (e.id != id) e];
    notifyListeners();
    await _save();
  }

  Future<void> _save() => _platform.save(
    events: CountdownEvent.encodeAll(_events),
    alerts: jsonEncode([for (final a in buildAlerts(_events, now)) a.toJson()]),
  );

  Future<bool> notificationsGranted() => _platform.notificationsGranted();
  Future<void> requestNotifications() => _platform.requestNotifications();
}
