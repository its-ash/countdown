import 'dart:convert';

import 'package:countdown/core/event.dart';
import 'package:countdown/core/event_store.dart';
import 'package:countdown/core/platform.dart';
import 'package:countdown/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePlatform implements CountdownPlatform {
  String? events;
  String? alerts;
  int saves = 0;

  @override
  Future<String?> load() async => events;

  @override
  Future<void> save({required String events, required String alerts}) async {
    this.events = events;
    this.alerts = alerts;
    saves++;
  }

  @override
  Future<bool> notificationsGranted() async => true;

  @override
  Future<void> requestNotifications() async {}
}

void main() {
  final clock = DateTime(2026, 11, 16, 10);

  test('store saves events and alerts natively, and loads them back', () async {
    final fake = FakePlatform();
    final store = EventStore(platform: fake, clock: () => clock);
    await store.load();
    expect(store.ready, isTrue);

    final e = CountdownEvent(id: 'a', title: 'Trip', date: DateTime(2026, 12, 20), created: clock, before: 2);
    await store.upsert(e);
    expect(store.countdowns.single.days, 34);
    expect(jsonDecode(fake.alerts!), hasLength(2));

    await store.upsert(e.copyWith(title: 'Trip!'));
    expect(store.events.single.title, 'Trip!');

    final again = EventStore(platform: fake, clock: () => clock);
    await again.load();
    expect(again.events.single.title, 'Trip!');

    await again.remove('a');
    expect(again.events, isEmpty);
    expect(fake.events, '[]');
  });

  testWidgets('home shows the empty state, then an event', (tester) async {
    final fake = FakePlatform();
    final store = EventStore(platform: fake, clock: DateTime.now);
    await tester.pumpWidget(CountdownApp(store: store));
    await tester.pump();
    await tester.pump();
    expect(find.text('No countdowns yet'), findsOneWidget);

    final today = DateTime.now();
    await store.upsert(
      CountdownEvent(id: 'b', title: 'Holiday', date: DateTime(today.year, today.month, today.day + 10), created: today),
    );
    await tester.pump();
    expect(find.text('Holiday'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
