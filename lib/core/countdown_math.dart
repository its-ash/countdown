import 'event.dart';

/// Pure date math. Everything takes `now` so tests can pin the clock.
///
/// Calendar days are counted between dates (via UTC midnights), never by
/// dividing a Duration by 24 h, so daylight-saving changes cannot shift a day.
/// `android/.../Calc.kt` repeats these rules for the widgets; keep both in step.

bool isLeapYear(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

/// Month and day of a yearly event in [year]. Feb 29 becomes Feb 28 in a non-leap year.
DateTime yearlyDate(DateTime base, int year) {
  final day = (base.month == 2 && base.day == 29 && !isLeapYear(year)) ? 28 : base.day;
  return DateTime(year, base.month, day);
}

/// Whole calendar days from [a] to [b] (negative if [b] is earlier).
int calendarDays(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

enum CountdownState { upcoming, today, past }

class Countdown {
  Countdown._(this.event, this.target, this.state, this.days, this.start, this.now);

  final CountdownEvent event;

  /// The date and time being counted to (next occurrence for a yearly event).
  final DateTime target;
  final CountdownState state;

  /// Calendar days left (upcoming) or since (past). 0 today.
  final int days;
  final DateTime start;
  final DateTime now;

  factory Countdown.of(CountdownEvent e, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    var day = e.date;
    var startDay = e.created;
    if (e.yearly) {
      day = yearlyDate(e.date, now.year);
      if (day.isBefore(today)) day = yearlyDate(e.date, now.year + 1);
      // A yearly event counts from the previous occurrence.
      startDay = yearlyDate(e.date, day.year - 1);
    }
    final m = e.minutes ?? 0;
    final target = DateTime(day.year, day.month, day.day, m ~/ 60, m % 60);
    final diff = calendarDays(today, day);
    final state = diff > 0
        ? CountdownState.upcoming
        : diff == 0
        ? CountdownState.today
        : CountdownState.past;
    return Countdown._(e, target, state, diff.abs(), startDay, now);
  }

  bool get isPast => state == CountdownState.past;
  bool get isToday => state == CountdownState.today;

  /// Time left to [target], or zero once it has passed.
  Duration get remaining {
    final d = target.difference(now);
    return d.isNegative ? Duration.zero : d;
  }

  /// Time since [target], or zero if it is still ahead.
  Duration get elapsedSince {
    final d = now.difference(target);
    return d.isNegative ? Duration.zero : d;
  }

  /// 0..1 from the start (creation, or the last occurrence) to [target].
  double get progress {
    if (isPast) return 1;
    final total = target.difference(start).inMilliseconds;
    if (total <= 0) return now.isBefore(target) ? 0 : 1;
    return (now.difference(start).inMilliseconds / total).clamp(0.0, 1.0);
  }

  /// Orders upcoming and today first (soonest first), then past (most recent first).
  static int compare(Countdown a, Countdown b) {
    if (a.isPast != b.isPast) return a.isPast ? 1 : -1;
    final c = a.isPast ? b.target.compareTo(a.target) : a.target.compareTo(b.target);
    return c != 0 ? c : a.event.title.toLowerCase().compareTo(b.event.title.toLowerCase());
  }

  static List<Countdown> sorted(Iterable<CountdownEvent> events, DateTime now) =>
      [for (final e in events) Countdown.of(e, now)]..sort(compare);
}

/// A notification to show at [at] (epoch milliseconds, local time).
class Alert {
  const Alert(this.at, this.title, this.body);
  final int at;
  final String title;
  final String body;

  Map<String, Object> toJson() => {'at': at, 'title': title, 'body': body};
}

const reminderHour = 9;

/// Upcoming notifications for [events], earliest first. Yearly events are
/// expanded over the next [years] years so the phone can fire them without the app.
List<Alert> buildAlerts(List<CountdownEvent> events, DateTime now, {int years = 5, int cap = 300}) {
  final out = <Alert>[];
  for (final e in events) {
    if (!e.notify && e.before <= 0) continue;
    final days = e.yearly
        ? [for (var y = now.year; y <= now.year + years; y++) yearlyDate(e.date, y)]
        : [e.date];
    final title = '${e.emoji} ${e.title}'.trim();
    for (final d in days) {
      if (e.notify) {
        final m = e.minutes ?? reminderHour * 60;
        final at = DateTime(d.year, d.month, d.day, m ~/ 60, m % 60);
        if (at.isAfter(now)) {
          out.add(Alert(at.millisecondsSinceEpoch, title, e.minutes == null ? 'Today' : 'Today at ${clockText(e.minutes!)}'));
        }
      }
      if (e.before > 0) {
        final at = DateTime(d.year, d.month, d.day - e.before, reminderHour);
        if (at.isAfter(now)) {
          out.add(Alert(at.millisecondsSinceEpoch, title, e.before == 1 ? 'Tomorrow' : 'In ${e.before} days'));
        }
      }
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out.length > cap ? out.sublist(0, cap) : out;
}

/// `HH:mm` for minutes after midnight.
String clockText(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
