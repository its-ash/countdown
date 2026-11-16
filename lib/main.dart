import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import 'core/event_store.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CountdownApp(store: EventStore()));
}

class CountdownApp extends StatelessWidget {
  const CountdownApp({super.key, required this.store});

  final EventStore store;

  @override
  Widget build(BuildContext context) {
    return UiApp(
      title: 'Countdown',
      home: HomeScreen(store: store),
    );
  }
}
