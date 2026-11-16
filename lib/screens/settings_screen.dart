import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../core/event_store.dart';

/// Notifications, then Appearance, Updates and Developer.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store});

  final EventStore store;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AppLifecycleListener _lifecycle;
  bool _granted = true;

  @override
  void initState() {
    super.initState();
    _check();
    // Back from the system notification settings.
    _lifecycle = AppLifecycleListener(onResume: _check);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final g = await widget.store.notificationsGranted();
    if (mounted) setState(() => _granted = g);
  }

  @override
  Widget build(BuildContext context) {
    return UiScaffold(
      appBar: const UiAppBar(title: 'Settings'),
      scrollable: true,
      body: UiColumn(
        gap: UiSpace.lg,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiSection(
            title: 'Notifications',
            child: UiListTile(
              _granted ? 'Notifications are on' : 'Notifications are off',
              subtitle: _granted
                  ? 'Reminders arrive on the day, and before it if you set that.'
                  : 'Allow them to get reminders for your events.',
              icon: _granted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
              iconStatus: _granted ? UiStatus.success : UiStatus.warning,
              chevron: !_granted,
              onTap: _granted ? null : () async {
                await widget.store.requestNotifications();
                _check();
              },
            ),
          ),
          UiSection(
            title: 'Widgets',
            child: const UiListTile(
              'Add a widget',
              subtitle: 'Touch and hold your home screen, tap Widgets, then pick Countdown. '
                  'The small one shows one event, the large one your next four.',
              icon: Icons.widgets_rounded,
            ),
          ),
          const UiAppearanceSection(),
          const UiUpdateSection(storeId: 'countdown'),
          const UiDeveloperSection(),
        ],
      ),
    );
  }
}
