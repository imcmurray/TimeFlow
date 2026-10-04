<p align="center">
  <img src="assets/images/timeflow-logo.png" alt="" width="112" height="112">
</p>

<h1 align="center">TimeFlow</h1>

<p align="center"><em>Your day as a gentle river, not a pressure cooker.</em></p>

<p align="center">
  <a href="https://imcmurray.github.io/TimeFlow/">Open the web app</a> ·
  <a href="https://github.com/imcmurray/TimeFlow/releases">Download for Android</a> ·
  <a href="https://imcmurray.github.io/TimeFlow/privacy.html">Privacy</a>
</p>

TimeFlow shows your schedule as a vertical river. A NOW line stays put on the
screen while your tasks drift toward it and flow past as real minutes go by,
so you always see what's happening now, what's coming, and what's behind you.

## What it does

- **A living timeline.** The view follows the present on its own; scroll away
  to look ahead or back, tap *Jump to now* to return. Days run together with
  sunrise and sunset marked, and pinch (or Ctrl+scroll) zooms.
- **Tasks that fit real life.** Times, notes, a photo, a category, an
  "important" flag. Long-press empty space to create a task right there, or
  long-press a task to drag it somewhere else. Swipe right when it's done,
  left to delete (with undo).
- **Repeats done properly.** Daily, weekdays, weekly on chosen days, every N
  weeks, monthly, yearly, with an optional end date. Change or delete just one
  occurrence, that one and the rest, or the whole series.
- **Gentle reminders.** Real notifications on Android, delivered even when the
  app is closed, with *Done* and *Snooze* buttons. The desktop and web
  versions remind you while they're open.
- **Hand over your day.** Share a day or a week with a pet sitter, caregiver or
  family member as a link. They open it in any browser and see the same live,
  read-only river, with nothing to install and no account. The schedule
  travels inside the link and is never uploaded.
- **Private by design.** Everything stays on your device. No accounts, no
  servers, no analytics, no ads. Back up and restore with a file whenever you
  like.

## Platforms

| Platform | Status |
|---|---|
| Android | Main release; Play Store submission in progress, signed APKs on [Releases](https://github.com/imcmurray/TimeFlow/releases) |
| Web (installable app, works offline) | [imcmurray.github.io/TimeFlow](https://imcmurray.github.io/TimeFlow/) |
| Linux, Windows, macOS | Experimental builds attached to releases (unsigned) |
| iOS | Not yet |

## Development

TimeFlow is a Flutter app (Dart 3.9+, Flutter 3.44). State is Riverpod, storage
is SQLite through [drift](https://drift.simonbinder.eu/) on every platform
(WebAssembly + IndexedDB on the web).

```bash
flutter pub get
flutter run -d linux            # or chrome, or an Android device
flutter analyze                 # CI requires zero issues
TZ=America/Denver flutter test  # the DST tests need a zone with DST
```

After changing a drift table: `dart run build_runner build`, bump
`schemaVersion`, write the migration, and dump a schema snapshot with
`dart run drift_dev make-migrations` so the migration tests cover it.

### Layout

```
lib/
  domain/        entities (Task, RecurrenceRule), wall-clock time, series
                 expansion, reminder planning, share-link codec
  data/          drift database, repository, migrations, backup format
  services/      task operations (edit scopes), notifications, sun times,
                 holidays
  presentation/  timeline (geometry, layout, layers), screens, providers
test/            unit, migration (drift schema snapshots) and widget tests
docs/            vision, original spec, release and store notes
```

### Releases

Every push to `main` runs analyze and tests, then deploys the web app to
GitHub Pages and builds a signed Android bundle. Tagging `vX.Y.Z` (matching
the version in `pubspec.yaml`) publishes a GitHub release with the APK and
desktop builds, and uploads the bundle to Play's internal track once the
`PLAY_SERVICE_ACCOUNT_JSON` secret is set. See
[docs/RELEASING.md](docs/RELEASING.md).

## License

Copyright © 2026 Ian McMurray. See [LICENSE](LICENSE).
