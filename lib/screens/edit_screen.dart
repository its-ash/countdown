import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../core/countdown_math.dart';
import '../core/event.dart';
import '../core/event_store.dart';
import '../core/format.dart';

/// Add or edit one event.
class EditScreen extends StatefulWidget {
  const EditScreen({super.key, required this.store, this.event});

  final EventStore store;

  /// The event to edit, or null to add a new one.
  final CountdownEvent? event;

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late CountdownEvent _e;
  bool _titleError = false;

  bool get _isNew => widget.event == null;

  @override
  void initState() {
    super.initState();
    _e = widget.event ?? blankEvent(widget.store.newId(), widget.store.now);
    _title = TextEditingController(text: _e.title);
    _note = TextEditingController(text: _e.note);
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = true);
      return;
    }
    final needsPermission = (_e.notify || _e.before > 0) && !await widget.store.notificationsGranted();
    if (needsPermission) await widget.store.requestNotifications();
    await widget.store.upsert(_e.copyWith(title: title, note: _note.text.trim()));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final time = _e.minutes == null ? null : TimeOfDay(hour: _e.minutes! ~/ 60, minute: _e.minutes! % 60);
    return UiScaffold(
      appBar: UiAppBar(title: _isNew ? 'New countdown' : 'Edit countdown'),
      scrollable: true,
      body: UiColumn(
        gap: UiSpace.lg,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiTextField(
            label: 'Title',
            hint: 'Mom\'s birthday',
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 60,
            error: _titleError ? 'Give it a title' : null,
            onChanged: (_) {
              if (_titleError) setState(() => _titleError = false);
            },
          ),
          UiDateField(
            label: 'Date',
            value: _e.date,
            clearable: false,
            isRequired: true,
            onChanged: (d) {
              if (d != null) setState(() => _e = _e.copyWith(date: DateTime(d.year, d.month, d.day)));
            },
          ),
          UiTimeField(
            label: 'Time (optional)',
            hint: 'All day',
            value: time,
            onChanged: (t) => setState(
              () => _e = t == null ? _e.copyWith(clearTime: true) : _e.copyWith(minutes: t.hour * 60 + t.minute),
            ),
          ),
          UiSection(
            title: 'Emoji',
            child: UiChoiceChips<String>(
              options: [for (final s in emojiChoices) UiChoice(s, s)],
              value: _e.emoji,
              onChanged: (s) => setState(() => _e = _e.copyWith(emoji: s)),
            ),
          ),
          UiSection(
            title: 'Color',
            child: UiColorPicker(
              value: colors.chart[_e.color % colors.chart.length],
              colors: colors.chart,
              onChanged: (c) => setState(() => _e = _e.copyWith(color: colors.chart.indexWhere((x) => x.toARGB32() == c.toARGB32()))),
            ),
          ),
          UiSwitchTile(
            'Repeat every year',
            subtitle: 'Birthdays and anniversaries',
            icon: Icons.repeat_rounded,
            value: _e.yearly,
            onChanged: (v) => setState(() => _e = _e.copyWith(yearly: v)),
          ),
          UiSection(
            title: 'Notifications',
            child: UiColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UiSwitchTile(
                  'On the day',
                  subtitle: _e.minutes == null ? 'At 09:00' : 'At ${clockText(_e.minutes!)}',
                  icon: Icons.notifications_active_rounded,
                  value: _e.notify,
                  onChanged: (v) => setState(() => _e = _e.copyWith(notify: v)),
                ),
                UiSwitchTile(
                  'Days before',
                  subtitle: 'An extra reminder at 09:00',
                  icon: Icons.event_available_rounded,
                  value: _e.before > 0,
                  onChanged: (v) => setState(() => _e = _e.copyWith(before: v ? 3 : 0)),
                ),
                if (_e.before > 0)
                  UiStepper<int>(
                    value: _e.before,
                    min: 1,
                    max: 60,
                    format: (n) => '$n ${n == 1 ? 'day' : 'days'} before',
                    onChanged: (n) => setState(() => _e = _e.copyWith(before: n)),
                  ),
              ],
            ),
          ),
          UiTextArea(label: 'Note (optional)', controller: _note, maxLength: 300),
          UiButton(_isNew ? 'Add countdown' : 'Save', icon: Icons.check_rounded, expand: true, onPressed: _save),
        ],
      ),
    );
  }
}
