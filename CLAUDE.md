# cron_timeflow — Development Guide

## 1. Project Overview

**cron_timeflow** is a Flutter application forked from [TimeFlow](https://github.com/imcmurray/TimeFlow/) that adds a ServerFlow plugin for visualizing cron jobs and scheduled tasks from CSV uploads on an interactive timeline.

- **Platforms:** Android, iOS, Web, macOS, Windows, Linux
- **State management:** Riverpod
- **Local DB:** Drift (SQLite), with web fallback
- **Key additions:** Plugin system, CSV parser, cron expansion, grouping/filtering UI

## 2. Initialization (Gated)

> **STOP — Agents MUST NOT start feature work until initialization is complete.**

Initialization steps (run once on an empty repo):

1. `git clone https://github.com/imcmurray/TimeFlow/ .`
2. Rename package: replace `timeflow` → `cron_timeflow` in `pubspec.yaml`, all Dart imports, Android/iOS/web configs
3. Add dependencies to `pubspec.yaml`:
   ```yaml
   dependencies:
     csv: ^6.0.0
     cron_expression_parser: ^1.0.0
   ```
4. `flutter pub get`
5. `flutter analyze` — fix any issues from rename
6. `flutter test` — confirm upstream tests pass
7. Commit to `main`: `"chore: fork TimeFlow as cron_timeflow, add csv+cron_expression_parser deps"`

**Gate check:** `main` branch exists with a clean build before ANY feature branch is created.

## 3. Architecture

```
lib/
├── core/
│   └── plugins/
│       ├── plugin_interface.dart      # TimeFlowPlugin abstract class
│       └── plugin_registry.dart       # PluginRegistry singleton
├── plugins/
│   └── server_flow/
│       ├── server_flow_plugin.dart        # Plugin entry point
│       ├── data/
│       │   ├── csv_parser.dart
│       │   ├── cron_job_model.dart
│       │   └── cron_job_drift_dao.dart
│       ├── domain/
│       │   ├── cron_expansion_service.dart
│       │   └── csv_validation.dart
│       └── presentation/
│           ├── csv_upload_screen.dart
│           ├── filter_modal.dart
│           └── widgets/
├── data/          # ← upstream TimeFlow
├── domain/        # ← upstream TimeFlow
├── presentation/  # ← upstream TimeFlow
└── services/      # ← upstream TimeFlow
```

### Layer Rules

- `presentation/` → `domain/` → `data/` (never reverse)
- `plugins/server_flow/` depends on `core/plugins/` only — never on upstream `data/` directly
- Upstream code communicates with plugins through `PluginRegistry`

## 4. Plugin System Contract

```dart
abstract class TimeFlowPlugin {
  String get id;
  String get name;
  List<DataSourceDescriptor> get dataSources;
  List<UIExtensionDescriptor> get uiExtensions;
  TimelineEvent Function(dynamic raw) get eventMapper;
  List<Override> get providerOverrides;
  Future<void> initialize();
  Future<void> dispose();
}
```

```dart
class PluginRegistry {
  void register(TimeFlowPlugin plugin);
  void unregister(String pluginId);
  List<TimeFlowPlugin> get plugins;
  TimeFlowPlugin? getById(String id);
}
```

### Registration (main.dart)

```dart
void main() async {
  final registry = PluginRegistry();
  final serverFlow = ServerFlowPlugin();
  registry.register(serverFlow);
  await serverFlow.initialize();

  runApp(ProviderScope(
    overrides: [
      ...serverFlow.providerOverrides,
    ],
    child: const CronTimeflowApp(),
  ));
}
```

## 5. CSV Spec (Summary)

**Mandatory columns:** `host`, `command`, `start_time`, `user`
**Optional columns:** `category`, `duration`, `schedule`, `os`, `end_time`

Key rules:
- Auto-detect delimiter (comma, semicolon, tab)
- Case-insensitive headers
- Missing mandatory columns → `CsvValidationException`
- `end_time` overrides `duration` when both present
- Unparseable rows collected as non-fatal errors

Full column definitions, examples, and parsing rules → [FEATURE_SPEC.md](./FEATURE_SPEC.md)

## 6. Commands

```bash
# Dependencies
flutter pub get

# Code generation (Drift, freezed, etc.)
dart run build_runner build --delete-conflicting-outputs

# Analysis
flutter analyze

# Tests
flutter test                          # all tests
flutter test test/plugins/server_flow/   # ServerFlow only

# Formatting
dart format lib/ test/

# Build
flutter build apk        # Android
flutter build web         # Web
flutter build macos       # macOS
```

### Pre-Commit Checklist

1. `dart format lib/ test/` — no formatting changes
2. `flutter analyze` — zero issues
3. `flutter test` — all pass
4. No uncommitted generated files (run `build_runner` if schema changed)

## 7. Worktree Workflow

### Branch Structure

| Branch                        | Scope                                    | Tasks |
|------------------------------|------------------------------------------|-------|
| `feature/plugin-core`        | Plugin system + registry                 | 2–3   |
| `feature/csv-upload`         | CSV parser + ServerFlow data layer          | 4     |
| `feature/timeline-enhancements` | HH:MM labels, zoom, tappable dots     | 5     |
| `feature/impact-filter`      | Grouping, coloring, filter modal         | 6–7   |

### Merge Order

```
feature/plugin-core → main    (FIRST — others depend on this)
feature/csv-upload → main     (second — needs plugin interfaces)
feature/timeline-enhancements → main
feature/impact-filter → main  (last — needs csv-upload models)
```

### Conflict Prevention

- **`pubspec.yaml`** — only `feature/plugin-core` modifies it
- **`lib/core/plugins/`** — only `feature/plugin-core` creates/edits these files
- **`lib/plugins/server_flow/data/`** — only `feature/csv-upload`
- **`lib/plugins/server_flow/presentation/`** — shared by `timeline-enhancements` and `impact-filter`, but they touch different files

### Agent Protocol

1. Create worktree: `git worktree add ../<branch-name> -b <branch-name>`
2. Work inside the worktree directory
3. Run `flutter analyze` + `flutter test` before every commit
4. **Do NOT merge to main** — human handles all merges
5. Push feature branch when ready: `git push -u origin <branch-name>`

## 8. Development Tasks

### Phase 1 — Foundation

| # | Task                         | Branch               | Deps |
|---|------------------------------|----------------------|------|
| 1 | Initialize repo (clone, rename, deps) | `main`       | —    |
| 2 | Create plugin interfaces     | `feature/plugin-core`| 1    |
| 3 | Implement PluginRegistry + wire into main.dart | `feature/plugin-core` | 2 |

### Phase 2 — Parallel Features (after plugin-core merges)

| # | Task                         | Branch                        | Deps |
|---|------------------------------|-------------------------------|------|
| 4 | CSV parser + ServerFlow data layer | `feature/csv-upload`       | 3    |
| 5 | Timeline enhancements        | `feature/timeline-enhancements` | 3 |
| 6 | Grouping + coloring system   | `feature/impact-filter`       | 4    |
| 7 | Impact filter modal          | `feature/impact-filter`       | 6    |

### Phase 3 — Polish

| # | Task                         | Branch  | Deps  |
|---|------------------------------|---------|-------|
| 8 | Integration testing          | `main`  | 4–7   |
| 9 | Platform packaging + docs    | `main`  | 8     |

## 9. Testing Strategy

```
test/
├── core/
│   └── plugins/
│       ├── plugin_registry_test.dart
│       └── mock_plugin.dart
├── plugins/
│   └── server_flow/
│       ├── data/
│       │   ├── csv_parser_test.dart        # ← highest priority
│       │   └── cron_job_model_test.dart
│       ├── domain/
│       │   ├── cron_expansion_test.dart
│       │   └── csv_validation_test.dart
│       └── presentation/
│           ├── csv_upload_screen_test.dart
│           └── filter_modal_test.dart
└── test_helpers/
    ├── sample_csvs.dart          # Valid/invalid CSV fixtures
    └── mock_providers.dart       # Riverpod test overrides
```

### Priorities

1. **CSV parser** — edge cases: missing columns, mixed delimiters, encoding, large files
2. **Cron expansion** — verify against known cron expressions
3. **Plugin registry** — register/unregister/lookup lifecycle
4. **Filter state** — Riverpod provider interactions
5. **Widget tests** — upload flow, filter modal

## 10. Code Conventions

- **Files:** `snake_case.dart`
- **Classes:** `PascalCase`
- **Imports:** absolute `package:cron_timeflow/` — never relative
- **Riverpod:** `StateNotifier` for mutable state, `FutureProvider` for async, `Provider` for computed
- **Drift:** numbered migrations (`v1`, `v2`, …), never alter existing migration files
- **Platform conditionals:** use conditional imports (`_web.dart` / `_native.dart`) — never `dart:io` on web
- **Plugin isolation:** ServerFlow code imports from `core/plugins/` only, never from upstream `data/`/`domain/`

## 11. Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Drift/freezed files out of date | Run `dart run build_runner build --delete-conflicting-outputs` |
| Web build fails with `dart:io` | Use conditional imports — see upstream pattern in `services/` |
| Tests import `timeflow` instead of `cron_timeflow` | Search-and-replace after rename; `flutter analyze` catches this |
| Worktree conflicts on `pubspec.lock` | Only `plugin-core` modifies `pubspec.yaml`; other branches `flutter pub get` from the lock in main |
| Schema race between branches | Each branch uses its own Drift migration number; coordinate at merge time |
| Generated files committed | Add `*.g.dart`, `*.freezed.dart` to `.gitignore` if not already present |
