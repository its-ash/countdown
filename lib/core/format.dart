import 'package:theme/theme.dart';

import 'countdown_math.dart';
import 'event.dart';

/// The big number of a card and its small caption.
class BigLabel {
  const BigLabel(this.value, this.unit);
  final String value;
  final String unit;
}

String _plural(int n, String one, String many) => n == 1 ? one : many;

BigLabel bigLabel(Countdown c) {
  switch (c.state) {
    case CountdownState.past:
      return BigLabel('${c.days}', _plural(c.days, 'day since', 'days since'));
    case CountdownState.today:
      final left = c.remaining;
      if (c.event.minutes != null && left > Duration.zero) {
        if (left.inHours >= 1) return BigLabel('${left.inHours}', _plural(left.inHours, 'hour left', 'hours left'));
        final m = left.inMinutes + 1;
        return BigLabel('$m', 'min left');
      }
      return const BigLabel('Today', '');
    case CountdownState.upcoming:
      return BigLabel('${c.days}', _plural(c.days, 'day left', 'days left'));
  }
}

/// "Mar 4, 2027" or "Mar 4, 2027 at 18:30". For yearly events the date of the next occurrence.
String dateText(Countdown c) {
  final d = UiDateFormat.date(c.target);
  final m = c.event.minutes;
  final base = m == null ? d : '$d at ${clockText(m)}';
  return c.event.yearly ? '$base · every year' : base;
}

String twoDigits(int n) => n.toString().padLeft(2, '0');

/// Emoji picks offered in the editor.
const emojiChoices = ['🎉', '🎂', '💍', '❤️', '✈️', '🏖️', '🎓', '🏠', '👶', '🎄', '🎁', '⚽', '🎬', '💼', '📅', '⭐'];

CountdownEvent blankEvent(String id, DateTime now) => CountdownEvent(
  id: id,
  title: '',
  date: DateTime(now.year, now.month, now.day).add(const Duration(days: 7)),
  created: now,
);
