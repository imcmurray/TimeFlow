# TimeFlow Project Instructions

TimeFlow is a Flutter daily-schedule app: tasks flow down a vertical timeline
past a fixed NOW line as real time passes. Released as v1.0.0 for Android
(signed APK; Play Store pending) and the web (PWA on GitHub Pages). iPhone/iPad
are in progress (see `docs/IOS.md`); desktop builds are experimental.

## Working across machines (read first)

More than one Claude Code session works on this repo: one on Ian's Linux PC
(everything except Apple builds) and one on a Mac mini (iPhone/iPad, Xcode,
App Store Connect). They can't message each other; **GitHub is the shared
channel.**

At the start of every session:
1. `git fetch --prune && git checkout main && git pull`
2. Read `docs/CHANGELOG.md` → *Unreleased* for what changed since you last
   worked here.
3. `gh issue list --label mac` (on the Mac) or `gh issue list` (elsewhere) for
   work waiting for you. Issues are how instructions are handed over.

While working:
- **Never push to `main`.** Branch from an up-to-date `main`, open a PR, let CI
  (analyze, tests, web, Android, iOS) pass, then merge. CI is what keeps the
  other machine's work from breaking.
- Add a line to `docs/CHANGELOG.md` → *Unreleased* in the same PR, saying what
  changed for users or for the other machine.
- Reference the issue (`Fixes #12`) so it closes when the PR merges; comment on
  the issue if you're blocked or need Ian.
- Before branching again after a while, pull `main` first. The other machine
  has probably merged something.

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after editing drift tables
flutter analyze                                            # must be clean (CI gate)
TZ=America/Denver flutter test                             # CI runs the DST tests in this zone
dart format lib test                                       # CI checks formatting
flutter run -d linux                                       # quickest local run
flutter build web --release --no-web-resources-cdn --base-href=/TimeFlow/
```

## Layout

- `lib/domain/` — entities and pure logic (wall-clock time, recurrence rules,
  reminder planning, share-link codec)
- `lib/data/` — drift database (schema 4), repository, migrations, backups
- `lib/services/` — task operations, notifications/reminders, sun times, holidays
- `lib/core/plugins/`, `lib/plugins/` — opt-in plugin marketplace (ServerFlow, QuoteFlow)
- `lib/presentation/` — timeline, screens, widgets, Riverpod providers
- `docs/` — `RELEASING.md`, `IOS.md`, `CHANGELOG.md`, store listings, `VISION.md`

## Conventions

- Task times are wall-clock times; convert to pixels only through
  `TimelineGeometry`. Recurring tasks are a stored rule plus date-keyed
  overrides, never pre-generated rows.
- Schema changes: bump `schemaVersion`, add the migration step, dump a snapshot
  into `drift_schemas/` and regenerate `test/drift/generated/`.
- Plugins store data through `PluginStorage`, not new tables.
