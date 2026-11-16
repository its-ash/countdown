import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../../core/countdown_math.dart';
import '../../core/format.dart';

/// Accent color of an event: its palette index in the current light / dark palette.
Color eventColor(BuildContext context, int index) {
  final chart = context.colors.chart;
  return chart[index % chart.length];
}

/// Round emoji badge tinted with the event color.
class EmojiBadge extends StatelessWidget {
  const EmojiBadge(this.emoji, this.color, {super.key, this.size = 48});

  final String emoji;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

/// Thin rounded progress bar in the event color.
class ColorBar extends StatelessWidget {
  const ColorBar(this.value, this.color, {super.key});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(UiRadius.sm),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 6,
        color: color,
        backgroundColor: color.withValues(alpha: 0.16),
      ),
    );
  }
}

/// One row of the home list: emoji, title, date, big number and progress.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.countdown, required this.onTap});

  final Countdown countdown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = countdown;
    final color = eventColor(context, c.event.color);
    final label = bigLabel(c);
    final colors = context.colors;
    return UiCard(
      onTap: onTap,
      semanticLabel: '${c.event.title}, ${label.value} ${label.unit}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              EmojiBadge(c.event.emoji, color),
              const SizedBox(width: UiSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      dateText(c),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: UiSpace.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(label.value, style: context.text.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
                  if (label.unit.isNotEmpty)
                    Text(label.unit, style: context.text.bodySmall?.copyWith(color: colors.textMuted)),
                ],
              ),
            ],
          ),
          if (!c.isPast) ...[
            const SizedBox(height: UiSpace.md),
            ColorBar(c.progress, color),
          ],
        ],
      ),
    );
  }
}
