# ServerFlow Feature Specification

## Overview

ServerFlow is a plugin for cron_timeflow that visualizes cron jobs and scheduled tasks on an interactive timeline. Users upload CSV files describing their scheduled jobs; ServerFlow parses, maps, and renders them as timeline events — with grouping, coloring, and filtering capabilities.

**Constraint:** ServerFlow is display-only. It never writes back to the CSV source or modify any external schedule.

## Goals

- Import cron/scheduled-task data from CSV files
- Map CSV rows to TimeFlow timeline events
- Expand cron schedule expressions into future occurrences
- Provide host/category grouping and impact-based coloring
- Offer a filter modal for narrowing visible jobs
- Support both Unix cron and Windows Task Scheduler formats

## CSV Column Definitions

### Mandatory Columns

| Column       | Type     | Description                          | Example                    |
|-------------|----------|--------------------------------------|----------------------------|
| `host`      | `String` | Hostname where the job runs          | `web-prod-01`             |
| `command`   | `String` | Command or script path               | `/usr/bin/backup.sh`      |
| `start_time`| `String` | ISO 8601 timestamp of first/next run | `2025-01-15T02:30:00Z`   |
| `user`      | `String` | User account that owns the job       | `root`                    |

### Optional Columns

| Column     | Type      | Default           | Description                                      | Example                 |
|-----------|-----------|-------------------|--------------------------------------------------|-------------------------|
| `category`| `String`  | `"uncategorized"` | Logical grouping label                           | `backup`               |
| `duration`| `int`     | `0`               | Expected duration in seconds                     | `3600`                 |
| `schedule`| `String`  | `null`            | Cron expression or `"once"`                      | `0 2 * * *`            |
| `os`      | `String`  | `"linux"`         | Operating system (`linux`, `windows`, `macos`)   | `windows`              |
| `end_time`| `String`  | `null`            | ISO 8601 end timestamp (overrides duration)      | `2025-01-15T03:30:00Z` |

### Parsing Rules

- The parser auto-detects delimiters: comma, semicolon, or tab
- Column headers are case-insensitive and trimmed of whitespace
- Missing mandatory columns cause a `CsvValidationException` with column name and row number
- Empty optional fields fall back to their defaults
- `end_time` takes precedence over `duration` when both are present
- Rows with unparseable `start_time` are collected into an error list (non-fatal)

## Features

### 1. CSV Upload

- File picker (desktop) or drag-and-drop (web) for `.csv` files
- Preview table showing first 10 rows before import
- Validation summary: row count, error count, column mapping
- Platform-conditional: `file_picker` on mobile/desktop, HTML5 drag-and-drop on web

### 2. Event Mapping

- Each valid CSV row becomes a `TimelineEvent`
- `host` maps to event group/lane
- `command` maps to event title
- `start_time` / `end_time` or `start_time` + `duration` define the event span
- `user` and `category` become event metadata for filtering

### 3. Cron Expansion

- When `schedule` contains a cron expression, expand it into N future occurrences (default N=50, configurable)
- Each expanded occurrence becomes its own `TimelineEvent` linked to the parent row
- `"once"` schedule means no expansion — single event only
- Uses `cron_expression_parser` package for expression parsing

### 4. Timeline Enhancements

- **HH:MM axis labels** — time-of-day labels on the horizontal axis
- **Pinch-to-zoom** — zoom into hour/minute granularity
- **Tappable event dots** — tap to show job detail popup (host, command, user, schedule, next run)

### 5. Grouping and Coloring

- Group events by `host` (default), `category`, or `user` — selectable via dropdown
- Color scheme based on `category` with auto-assigned palette
- Optional manual color overrides per category in settings
- Visual density indicator: brighter color = more overlapping jobs in time window

### 6. Impact Filter Modal

- Bottom-sheet modal with filter controls:
  - Host multi-select chips
  - Category multi-select chips
  - Time range slider (start/end)
  - User search/filter
- Live preview: timeline updates as filters change
- "Reset" button to clear all filters
- Filter state persisted in Riverpod provider (not to disk)

## Windows Scheduled Task Support

- `os: "windows"` rows may use Task Scheduler XML trigger syntax in `schedule`
- The parser normalizes Windows triggers to an internal representation
- Display labels show the original format alongside the normalized schedule

## Development Guidelines

- All ServerFlow code lives under `lib/plugins/server_flow/`
- Follow the plugin contract defined in CLAUDE.md
- CSV parsing has the highest test priority — aim for full coverage of edge cases
- Use Riverpod `StateNotifier` for filter state, `FutureProvider` for CSV parsing
- Drift tables for persisting imported job data locally

## Roadmap (Task Mapping)

| Phase      | Task | Description                        |
|-----------|------|------------------------------------|
| Foundation | 4    | CSV parser + ServerFlow data layer    |
| Features   | 5    | Timeline enhancements (HH:MM, zoom, dots) |
| Features   | 6    | Grouping and coloring system       |
| Features   | 7    | Impact filter modal                |
| Polish     | 8    | Integration testing                |
| Polish     | 9    | Platform packaging + docs          |
