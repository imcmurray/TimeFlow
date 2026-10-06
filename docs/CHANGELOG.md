# Changelog

Every PR adds a line under **Unreleased**. Sessions on other machines read
this first to catch up (see "Working across machines" in `CLAUDE.md`). When a
version is tagged, *Unreleased* becomes that version's notes.

## Unreleased

### App
- Plugin marketplace is back, opt-in: Settings → Plugins. **ServerFlow**
  shows cron jobs imported from CSV on the timeline (schedules in local time
  by default, filter by host/category/user, alerts when a job reaches NOW);
  **QuoteFlow** adds quotes through the day. Plugin data is stored in the new
  `plugin_data` table (**database schema 4**) and included in backups. (#30)
- Desktop: scrolling with a mouse wheel, trackpad or scrollbar no longer
  snaps back to NOW. (#30)
- Linux/Windows: the database moved from `~/Documents` to the app's support
  folder (moved automatically on first launch). (#30)
- The "Deleted … Undo" snackbar times out instead of staying forever. (#26, fixes #23)

### iPhone and iPad
- iOS project, signing (team 3UU2DT4DNW), privacy manifest, branded launch
  screen, App Store listing (as *TimeFlow Planner*) and screenshots. CI builds
  iOS unsigned on every PR. (#22, #26)
- Still to do: real-device check that reminders arrive with the app closed
  and that Done/Snooze work from the lock screen; first TestFlight build.

### Web and docs
- Support page (`web/support.html`); privacy policy covers iOS and names the
  publisher. (#26)
- Marketing/press kit and beta-tester kit. (#28, #29)
- Working agreement for multiple machines in `CLAUDE.md`; this changelog.
- `main` is now protected for everyone (no direct pushes; PRs merge only
  after analyze/test, web, Android and iOS checks pass). See `CLAUDE.md`.

## 1.0.0 — 2026-10-04

First release: the flowing timeline with a fixed NOW line, repeating tasks
with this/future/all edits, real reminder notifications (Android), photos,
share-by-link with a read-only web view, backups, accurate sunrise/sunset,
holiday calendars, an offline web app, and accessibility work. Android APK
and experimental desktop builds on GitHub Releases.
