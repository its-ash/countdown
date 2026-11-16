import 'dart:async';

import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../core/event_store.dart';
import 'detail_screen.dart';
import 'edit_screen.dart';
import 'settings_screen.dart';
import 'widgets/event_card.dart';

/// The list of countdowns, soonest first, with Settings in the app bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});

  final EventStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppLifecycleListener _lifecycle;
  Timer? _tick;

  EventStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    store.load();
    // Numbers change at midnight and as hours pass: redraw each minute and on resume.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
    _lifecycle = AppLifecycleListener(onResume: () => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _add() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EditScreen(store: store)));

  void _open(String id) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DetailScreen(store: store, id: id)));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final items = store.countdowns;
        return UiScaffold(
          appBar: UiAppBar(
            title: 'Countdown',
            actions: [
              UiIconButton(
                Icons.settings_rounded,
                tooltip: 'Settings',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => SettingsScreen(store: store)),
                ),
              ),
            ],
          ),
          fab: UiFab(Icons.add_rounded, label: 'Add', tooltip: 'Add event', onPressed: _add),
          body: !store.ready
              ? const Center(child: UiSpinner(size: 28))
              : items.isEmpty
              ? UiEmptyState(
                  icon: Icons.hourglass_empty_rounded,
                  title: 'No countdowns yet',
                  message: 'Add a birthday, a trip or any day you are waiting for.',
                  action: UiButton('Add event', icon: Icons.add_rounded, onPressed: _add),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: UiSpace.md),
                  itemBuilder: (_, i) => EventCard(countdown: items[i], onTap: () => _open(items[i].event.id)),
                ),
        );
      },
    );
  }
}
