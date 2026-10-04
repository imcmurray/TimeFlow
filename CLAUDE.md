# TimeFlow Project Instructions

TimeFlow is a Flutter daily-schedule app: tasks flow down a vertical timeline
past a fixed NOW line as real time passes. Launch targets are Android (Play
Store) and the web (PWA on GitHub Pages); desktop builds are secondary.

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after editing drift tables
flutter analyze                                            # must be clean (CI gate)
flutter test                                               # unit + widget tests (CI gate)
flutter run -d linux                                       # quickest local run
flutter build web --release --base-href=/TimeFlow/
```

## Layout

- `lib/domain/` — entities and pure logic
- `lib/data/` — drift database and repositories
- `lib/services/` — notifications, recurrence, sun times, holidays
- `lib/presentation/` — screens, widgets, Riverpod providers
- `docs/VISION.md` — long-term product vision; `docs/product-spec.xml` — the original spec

## Conventions

- The plugin system (ServerFlow, marketplace) lives on `feature/plugins-serverflow`
  and is intentionally out of 1.0.
