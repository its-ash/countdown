import 'package:countdown/core/countdown_math.dart';
import 'package:countdown/core/event.dart';
import 'package:countdown/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

CountdownEvent ev(
  DateTime date, {
  int? minutes,
  bool yearly = false,
  bool notify = true,
  int before = 0,
  String title = 'Event',
  DateTime? created,
}) => CountdownEvent(
  id: title,
  title: title,
  date: date,
  minutes: minutes,
  yearly: yearly,
  notify: notify,
  before: before,
  created: created ?? DateTime(2026, 1, 1),
);

void main() {
  final now = DateTime(2026, 11, 16, 10, 30);

  group('days left', () {
    test('upcoming date', () {
      final c = Countdown.of(ev(DateTime(2026, 12, 25)), now);
      expect(c.state, CountdownState.upcoming);
      expect(c.days, 39);
      expect(bigLabel(c).value, '39');
      expect(bigLabel(c).unit, 'days left');
    });

    test('one day left uses the singular', () {
      final c = Countdown.of(ev(DateTime(2026, 11, 17)), now);
      expect(c.days, 1);
      expect(bigLabel(c).unit, 'day left');
    });

    test('today without time', () {
      final c = Countdown.of(ev(DateTime(2026, 11, 16)), now);
      expect(c.state, CountdownState.today);
      expect(c.days, 0);
      expect(bigLabel(c).value, 'Today');
    });

    test('today with a later time shows hours left', () {
      final c = Countdown.of(ev(DateTime(2026, 11, 16), minutes: 18 * 60), now);
      expect(c.state, CountdownState.today);
      expect(c.remaining, const Duration(hours: 7, minutes: 30));
      expect(bigLabel(c).value, '7');
      expect(bigLabel(c).unit, 'hours left');
    });

    test('today with a time less than an hour away shows minutes', () {
      final c = Countdown.of(ev(DateTime(2026, 11, 16), minutes: 10 * 60 + 45), now);
      expect(bigLabel(c).unit, 'min left');
    });

    test('today after the time has passed is still today, not past', () {
      final c = Countdown.of(ev(DateTime(2026, 11, 16), minutes: 8 * 60), now);
      expect(c.state, CountdownState.today);
      expect(c.remaining, Duration.zero);
      expect(bigLabel(c).value, 'Today');
    });
  });

  group('past dates', () {
    test('show days since', () {
      final c = Countdown.of(ev(DateTime(2026, 11, 6)), now);
      expect(c.state, CountdownState.past);
      expect(c.isPast, isTrue);
      expect(c.days, 10);
      expect(bigLabel(c).unit, 'days since');
      expect(c.progress, 1);
      expect(c.elapsedSince, greaterThan(const Duration(days: 10)));
    });

    test('a past date is not repeated unless yearly', () {
      final c = Countdown.of(ev(DateTime(2020, 1, 1)), now);
      expect(c.isPast, isTrue);
      expect(c.days, calendarDays(DateTime(2020, 1, 1), now));
    });
  });

  group('yearly repeat', () {
    test('birthday later this year counts to this year', () {
      final c = Countdown.of(ev(DateTime(1990, 12, 2), yearly: true), now);
      expect(c.target, DateTime(2026, 12, 2));
      expect(c.days, 16);
    });

    test('birthday already gone counts to next year', () {
      final c = Countdown.of(ev(DateTime(1990, 3, 4), yearly: true), now);
      expect(c.target, DateTime(2027, 3, 4));
      expect(c.days, 108);
      expect(c.isPast, isFalse);
    });

    test('birthday today is today, and tomorrow it rolls over', () {
      final e = ev(DateTime(2000, 11, 16), yearly: true);
      final today = Countdown.of(e, now);
      expect(today.state, CountdownState.today);
      expect(today.target.year, 2026);
      final tomorrow = Countdown.of(e, DateTime(2026, 11, 17, 0, 0));
      expect(tomorrow.state, CountdownState.upcoming);
      expect(tomorrow.target.year, 2027);
      expect(tomorrow.days, 364);
    });

    test('yearly never becomes past', () {
      for (var d = 0; d < 400; d += 7) {
        final at = DateTime(2026, 1, 1).add(Duration(days: d));
        expect(Countdown.of(ev(DateTime(1999, 6, 15), yearly: true), at).isPast, isFalse);
      }
    });

    test('progress runs from the previous occurrence', () {
      final c = Countdown.of(ev(DateTime(2000, 7, 1), yearly: true), DateTime(2026, 1, 1));
      expect(c.start, DateTime(2025, 7, 1));
      expect(c.progress, closeTo(0.5, 0.02));
    });
  });

  group('Feb 29', () {
    test('yearly falls on Feb 28 in a common year', () {
      final e = ev(DateTime(2000, 2, 29), yearly: true);
      expect(Countdown.of(e, now).target, DateTime(2027, 2, 28));
      expect(Countdown.of(e, DateTime(2027, 11, 1)).target, DateTime(2028, 2, 29));
      expect(Countdown.of(e, DateTime(2024, 1, 10)).target, DateTime(2024, 2, 29));
      expect(Countdown.of(e, DateTime(2027, 2, 28, 9)).state, CountdownState.today);
    });

    test('plain Feb 29 date counts the leap day', () {
      final c = Countdown.of(ev(DateTime(2028, 2, 29)), DateTime(2027, 12, 31, 12));
      expect(c.days, 60);
    });

    test('leap years', () {
      expect(isLeapYear(2024), isTrue);
      expect(isLeapYear(1900), isFalse);
      expect(isLeapYear(2000), isTrue);
      expect(isLeapYear(2027), isFalse);
    });
  });

  group('midnight', () {
    final e = ev(DateTime(2026, 11, 17));

    test('one second before midnight is still one day away', () {
      final c = Countdown.of(e, DateTime(2026, 11, 16, 23, 59, 59));
      expect(c.state, CountdownState.upcoming);
      expect(c.days, 1);
      expect(c.remaining, const Duration(seconds: 1));
    });

    test('at midnight it flips to today', () {
      final c = Countdown.of(e, DateTime(2026, 11, 17));
      expect(c.state, CountdownState.today);
      expect(c.days, 0);
    });

    test('the next midnight it is one day past', () {
      final c = Countdown.of(e, DateTime(2026, 11, 18));
      expect(c.state, CountdownState.past);
      expect(c.days, 1);
    });

    test('calendar days ignore daylight saving shifts (any zone)', () {
      expect(calendarDays(DateTime(2026, 3, 7), DateTime(2026, 3, 9)), 2);
      expect(calendarDays(DateTime(2026, 3, 28, 23, 30), DateTime(2026, 3, 30, 0, 15)), 2);
      expect(calendarDays(DateTime(2026, 10, 24, 23, 30), DateTime(2026, 10, 26, 0, 15)), 2);
      expect(calendarDays(DateTime(2026, 10, 31, 23, 30), DateTime(2026, 11, 2, 0, 15)), 2);
      expect(calendarDays(DateTime(2026, 12, 31), DateTime(2027, 1, 1)), 1);
      expect(calendarDays(DateTime(2026, 11, 20), DateTime(2026, 11, 16)), -4);
    });
  });

  group('progress and order', () {
    test('progress between creation and the date', () {
      final e = ev(DateTime(2026, 1, 11), created: DateTime(2026, 1, 1));
      final c = Countdown.of(e, DateTime(2026, 1, 6));
      expect(c.progress, closeTo(0.5, 1e-9));
      expect(Countdown.of(e, DateTime(2025, 12, 1)).progress, 0);
    });

    test('sorted: soonest first, past last (most recent first)', () {
      final list = Countdown.sorted([
        ev(DateTime(2026, 11, 1), title: 'old'),
        ev(DateTime(2027, 1, 1), title: 'far'),
        ev(DateTime(2026, 11, 20), title: 'soon'),
        ev(DateTime(2026, 11, 10), title: 'recent'),
        ev(DateTime(2026, 11, 16), title: 'today'),
      ], now);
      expect([for (final c in list) c.event.title], ['today', 'soon', 'far', 'recent', 'old']);
    });
  });

  group('alerts', () {
    test('on the day at the event time, and before at 09:00', () {
      final alerts = buildAlerts([ev(DateTime(2026, 12, 25), minutes: 18 * 60 + 30, before: 3, title: 'Party')], now);
      expect(alerts.length, 2);
      expect(DateTime.fromMillisecondsSinceEpoch(alerts[0].at), DateTime(2026, 12, 22, 9));
      expect(alerts[0].body, 'In 3 days');
      expect(DateTime.fromMillisecondsSinceEpoch(alerts[1].at), DateTime(2026, 12, 25, 18, 30));
      expect(alerts[1].body, 'Today at 18:30');
    });

    test('all-day events notify at 09:00 and past ones are skipped', () {
      final a = buildAlerts([ev(DateTime(2026, 12, 25)), ev(DateTime(2026, 1, 1), title: 'gone')], now);
      expect(a.length, 1);
      expect(DateTime.fromMillisecondsSinceEpoch(a.single.at), DateTime(2026, 12, 25, 9));
    });

    test('yearly events are planned for several years, Feb 29 included', () {
      final a = buildAlerts([ev(DateTime(2000, 2, 29), yearly: true)], now, years: 4);
      final days = [for (final x in a) DateTime.fromMillisecondsSinceEpoch(x.at)];
      expect(days, [DateTime(2027, 2, 28, 9), DateTime(2028, 2, 29, 9), DateTime(2029, 2, 28, 9), DateTime(2030, 2, 28, 9)]);
    });

    test('nothing when notifications are off, and the list is capped', () {
      expect(buildAlerts([ev(DateTime(2026, 12, 25), notify: false)], now), isEmpty);
      final many = [for (var i = 0; i < 50; i++) ev(DateTime(2026, 12, 1).add(Duration(days: i)), title: 'e$i', yearly: true)];
      expect(buildAlerts(many, now, cap: 20).length, 20);
    });

    test('1 day before says Tomorrow', () {
      final a = buildAlerts([ev(DateTime(2026, 12, 25), notify: false, before: 1)], now);
      expect(a.single.body, 'Tomorrow');
    });
  });

  group('storage', () {
    test('json round trip', () {
      final e = ev(DateTime(2026, 12, 25), minutes: 90, yearly: true, before: 2, title: 'Xmas').copyWith(note: 'hi', color: 3, emoji: '🎄');
      final back = CountdownEvent.decodeAll(CountdownEvent.encodeAll([e])).single;
      expect(back.toJson(), e.toJson());
      expect(back.date, DateTime(2026, 12, 25));
    });

    test('bad data gives an empty list', () {
      expect(CountdownEvent.decodeAll('nope'), isEmpty);
      expect(CountdownEvent.decodeAll(null), isEmpty);
    });
  });
}
