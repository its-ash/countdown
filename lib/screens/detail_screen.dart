import 'dart:async';

import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../core/countdown_math.dart';
import '../core/event_store.dart';
import '../core/format.dart';
import 'edit_screen.dart';
import 'widgets/event_card.dart';

/// One event with a live days / hours / minutes / seconds clock.
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.store, required this.id});

  final EventStore store;
  final String id;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _delete() async {
    final ok = await UiDialog.confirm(
      context,
      title: 'Delete this countdown?',
      message: 'It also disappears from your widgets.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await widget.store.remove(widget.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final event = widget.store.byId(widget.id);
        if (event == null) return const UiScaffold(appBar: UiAppBar(title: 'Countdown'), body: SizedBox.shrink());
        final c = Countdown.of(event, widget.store.now);
        final color = eventColor(context, event.color);
        final colors = context.colors;
        final span = c.isPast ? c.elapsedSince : c.remaining;
        final headline = c.isToday
            ? 'Today'
            : c.isPast
            ? 'Since'
            : 'Time left';
        return UiScaffold(
          appBar: UiAppBar(
            title: 'Countdown',
            actions: [
              UiIconButton(
                Icons.edit_rounded,
                tooltip: 'Edit',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => EditScreen(store: widget.store, event: event)),
                ),
              ),
              UiIconButton(Icons.delete_outline_rounded, tooltip: 'Delete', onPressed: _delete),
            ],
          ),
          scrollable: true,
          body: UiColumn(
            gap: UiSpace.lg,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  EmojiBadge(event.emoji, color, size: 72),
                  const SizedBox(height: UiSpace.md),
                  Text(event.title, textAlign: TextAlign.center, style: context.text.headlineSmall),
                  const SizedBox(height: 4),
                  Text(dateText(c), textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: colors.textMuted)),
                ],
              ),
              Text(headline, textAlign: TextAlign.center, style: context.text.labelLarge?.copyWith(color: colors.textMuted)),
              Row(
                children: [
                  _Unit('${span.inDays}', 'days', color),
                  const SizedBox(width: UiSpace.sm),
                  _Unit(twoDigits(span.inHours % 24), 'hours', color),
                  const SizedBox(width: UiSpace.sm),
                  _Unit(twoDigits(span.inMinutes % 60), 'min', color),
                  const SizedBox(width: UiSpace.sm),
                  _Unit(twoDigits(span.inSeconds % 60), 'sec', color),
                ],
              ),
              if (!c.isPast) ...[
                ColorBar(c.progress, color),
                Text(
                  '${(c.progress * 100).floor()}% of the way there',
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ],
              UiKeyValueList([
                UiKeyValue('Repeats', event.yearly ? 'Every year' : 'Once'),
                UiKeyValue('On the day', event.notify ? 'Notification' : 'Off'),
                UiKeyValue('Before', event.before > 0 ? '${event.before} ${event.before == 1 ? 'day' : 'days'} before' : 'Off'),
                if (event.note.isNotEmpty) UiKeyValue('Note', event.note, stacked: true, maxLines: 20),
              ]),
            ],
          ),
        );
      },
    );
  }
}

class _Unit extends StatelessWidget {
  const _Unit(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: UiCard(
        padding: const EdgeInsets.symmetric(vertical: UiSpace.md),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: context.text.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
            ),
            Text(label, style: context.text.bodySmall?.copyWith(color: context.colors.textMuted)),
          ],
        ),
      ),
    );
  }
}
