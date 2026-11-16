import 'dart:convert';

/// One countdown. [date] is a calendar day (only year, month, day count);
/// [minutes] is the optional time of day in minutes after midnight (local time).
class CountdownEvent {
  const CountdownEvent({
    required this.id,
    required this.title,
    required this.date,
    this.minutes,
    this.emoji = '🎉',
    this.color = 0,
    this.yearly = false,
    this.note = '',
    required this.created,
    this.notify = true,
    this.before = 0,
  });

  final String id;
  final String title;
  final DateTime date;
  final int? minutes;

  /// Palette index into `context.colors.chart`.
  final int color;
  final String emoji;
  final bool yearly;
  final String note;
  final DateTime created;

  /// Notify on the day.
  final bool notify;

  /// Also notify this many days before (0 = off).
  final int before;

  CountdownEvent copyWith({
    String? title,
    DateTime? date,
    int? minutes,
    bool clearTime = false,
    String? emoji,
    int? color,
    bool? yearly,
    String? note,
    bool? notify,
    int? before,
  }) => CountdownEvent(
    id: id,
    title: title ?? this.title,
    date: date ?? this.date,
    minutes: clearTime ? null : (minutes ?? this.minutes),
    emoji: emoji ?? this.emoji,
    color: color ?? this.color,
    yearly: yearly ?? this.yearly,
    note: note ?? this.note,
    created: created,
    notify: notify ?? this.notify,
    before: before ?? this.before,
  );

  static String _d(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Stored form. Kotlin (`Events.kt`) reads the same keys.
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'date': _d(date),
    'time': minutes,
    'emoji': emoji,
    'color': color,
    'yearly': yearly,
    'note': note,
    'created': created.millisecondsSinceEpoch,
    'notify': notify,
    'before': before,
  };

  static CountdownEvent fromJson(Map<String, dynamic> j) {
    final p = (j['date'] as String).split('-').map(int.parse).toList();
    return CountdownEvent(
      id: j['id'] as String,
      title: j['title'] as String? ?? '',
      date: DateTime(p[0], p[1], p[2]),
      minutes: (j['time'] as num?)?.toInt(),
      emoji: j['emoji'] as String? ?? '🎉',
      color: (j['color'] as num?)?.toInt() ?? 0,
      yearly: j['yearly'] as bool? ?? false,
      note: j['note'] as String? ?? '',
      created: DateTime.fromMillisecondsSinceEpoch((j['created'] as num?)?.toInt() ?? 0),
      notify: j['notify'] as bool? ?? true,
      before: (j['before'] as num?)?.toInt() ?? 0,
    );
  }

  static String encodeAll(List<CountdownEvent> events) => jsonEncode([for (final e in events) e.toJson()]);

  /// Decodes a stored list. Bad entries are skipped.
  static List<CountdownEvent> decodeAll(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final out = <CountdownEvent>[];
      for (final item in list) {
        try {
          out.add(fromJson(item as Map<String, dynamic>));
        } catch (_) {}
      }
      return out;
    } catch (_) {
      return [];
    }
  }
}
