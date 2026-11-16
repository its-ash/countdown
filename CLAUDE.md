# Countdown (package: countdown / com.itsash.countdown)

Offline countdowns to events that matter, with home-screen widgets and notifications.
Flutter is the UI; native Kotlin owns the stored data and everything that runs with the
app closed (widgets, midnight refresh, notifications).

## Data contract (Kotlin and Dart)

- SharedPreferences file `countdown_prefs` (`CountdownPrefs` in `Events.kt`):
  - `events`: JSON list written by Dart (`CountdownEvent.toJson`): `id`, `title`, `date`
    (`yyyy-MM-dd`), `time` (minutes after midnight or null), `emoji`, `color` (index into
    `context.colors.chart`), `yearly`, `note`, `created` (epoch ms), `notify` (on the day),
    `before` (days before, 0 = off).
  - `alerts`: JSON list `[{at, title, body}]` planned by Dart (`buildAlerts`: yearly events are
    expanded 5 years ahead, capped at 300). Native only schedules and shows them.
  - Native-only: `lastFired` (watermark so nothing fires twice), `askedNotifications`,
    `w_<widgetId>` (event id of a small widget).
- Channel `com.itsash.countdown/control` (`MainActivity.kt`, `lib/core/platform.dart`): `load`,
  `save({events, alerts})` (stores, then `CountdownSync.refresh`), `notificationsGranted`,
  `requestNotifications`.

## Date rules (keep Dart and Kotlin in step)

`lib/core/countdown_math.dart` and `Calc` in `Events.kt`: calendar days between dates (never
Duration / 24h, so DST cannot shift a day); yearly counts to the next occurrence on or after
today, Feb 29 becomes Feb 28 in common years; a date is "today" all day and "past" from the next
midnight; a yearly event is never past. Progress runs from creation (yearly: previous occurrence).
Palette colors are stored as an index; `Calc.color` repeats the theme's `chart` colors for widgets.

## Native pieces

- `Sync.kt`: `CountdownSync.refresh` = redraw both widgets + `Alerts.process` (show what is due,
  arm one alarm for the next alert) + arm a midnight alarm. Alarms use `setAndAllowWhileIdle`
  (inexact, no exact-alarm permission). `AlarmReceiver` and `BootReceiver` (boot, update, time /
  time zone / date change) both just call `refresh`.
- `Widgets.kt`: `SmallWidget` (2x2, one event, `SmallConfigActivity` picks it; tapping an
  unconfigured one reopens the picker) and `ListWidget` (4x2, next four events). Light / dark via
  `res/values{,-night}/colors.xml`.
- Permissions: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `INTERNET` (update check only).

## Code layout

- `lib/core/`: `event.dart`, `countdown_math.dart` (pure, tested), `format.dart`, `platform.dart`,
  `event_store.dart`.
- `lib/screens/`: `home_screen.dart`, `detail_screen.dart` (1 s ticker), `edit_screen.dart`,
  `settings_screen.dart` (ends with `UiAppearanceSection`, `UiUpdateSection(storeId: 'countdown')`,
  `UiDeveloperSection`), `widgets/event_card.dart`.
- Tests: `test/countdown_math_test.dart` (days left, yearly, Feb 29, past, midnight, alerts, JSON),
  `test/widget_test.dart` (store with a fake platform, home screen).

## Commands

- `make run`, `make build`, `make test` (analyze + tests), `make clean`.
- Icon: `assets/icon/*.svg` → `*-1024.png`, then `dart run flutter_launcher_icons`.

## Conventions

- minSdk 26. UI only from `../theme` (read `../theme/COMPONENTS.md`). Local helpers: `ColorBar`
  (progress bar in the event color) and `EmojiBadge` in `event_card.dart`.
- Only network use: `UiUpdateSection` in Settings. No analytics.

## Release (Ash Store)

- `store.json` (id `countdown`, repo its-ash/countdown), `store.mk`, `index.html` + `CNAME`
  (`countdown.itsash.in`). See `../ash-store/store-kit/STORE.md`.
- `make deploy` = bump version → build → commit, tag `vX.Y.Z`, push → GitHub release with
  `countdown.apk` → topics, homepage, Pages. Never create releases, tags or asset names by hand.
- Do not edit `store.mk` here. Edit `../ash-store/store-kit/store.mk`, then run
  `make store-sync` at the workspace root.
