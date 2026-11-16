# Countdown

Count down to birthdays, trips and big days. Days left on your home screen.

**[Website](https://countdown.itsash.in)** · **[Download APK](https://github.com/its-ash/countdown/releases/latest/download/countdown.apk)** · Get it in **[Ash Store](https://store.itsash.in)**

## Features

- **Events**: title, date, optional time, emoji, accent color, a note, and **repeat every year**
  for birthdays and anniversaries (Feb 29 falls on Feb 28 in common years).
- **Home list**: soonest first, with the days or hours left in big numbers and a progress bar
  from the day you added the event to its date. Past dates show **days since**.
- **Detail page**: a live days / hours / minutes / seconds clock.
- **Notifications**: on the day (at the event time, or 09:00 for all-day events) and, if you
  like, N days before at 09:00. They work with the app closed and after a reboot.
- **Widgets**: a small one for a single event (you pick it when you add the widget) and a 4x2
  list of your next events. Both refresh at midnight and whenever you change an event.
- Light and dark theme. **Private**: no account, everything stays on your phone. The only
  network call is the update check in Settings.

## Install

- **Ash Store**: install [Ash Store](https://store.itsash.in) once, then install and update Countdown from it.
- **APK**: download the [latest APK](https://github.com/its-ash/countdown/releases/latest/download/countdown.apk) on your phone and open it. Allow your browser to install unknown apps if Android asks.

Requires Android 8.0 (API 26) or later. Allow notifications when Android asks. Add the
widgets from your home screen's widget list.

## Develop

Needs Flutter ≥ 3.44 and the shared theme package at `../theme`.

```bash
make run     # run on a connected device
make test    # flutter analyze + flutter test
make build   # release APK
make deploy  # bump version, build, tag, push, GitHub release (see store.mk)
```

## Release

`make deploy` follows the Ash Store kit (`store.mk`, `store.json`): it bumps the
version in `pubspec.yaml`, builds, commits, tags `vX.Y.Z`, pushes, and publishes
a GitHub release with `countdown.apk`. Ash Store and the website pick up the new
version from that release.

## Project layout

```
lib/
├── main.dart
├── core/
│   ├── event.dart            # CountdownEvent + JSON
│   ├── countdown_math.dart   # days left, yearly repeat, progress, alerts (pure)
│   ├── format.dart           # big number labels, date text
│   ├── platform.dart         # MethodChannel to MainActivity.kt
│   └── event_store.dart      # UI state, saves natively on every change
└── screens/
    ├── home_screen.dart      # list, add button, Settings icon
    ├── detail_screen.dart    # live clock
    ├── edit_screen.dart      # add / edit form
    ├── settings_screen.dart
    └── widgets/event_card.dart
android/app/src/main/kotlin/com/itsash/countdown/
├── Events.kt                 # event model, Calc (same rules as the Dart math), prefs
├── Sync.kt                   # refresh widgets, midnight alarm, notifications
├── Receivers.kt              # alarm and boot / clock-change receivers
├── Widgets.kt                # SmallWidget and ListWidget
├── SmallConfigActivity.kt    # pick the event of a small widget
└── MainActivity.kt           # channel handlers, permissions
```

See `CLAUDE.md` for details.

## License

No license file is included yet.

Built by [itsash.in](https://itsash.in).
