# Changelog

Every PR adds a line under **Unreleased**. Sessions on other machines read
this first to catch up (see "Working across machines" in `CLAUDE.md`). When a
version is tagged, *Unreleased* becomes that version's notes.

## Unreleased

### App
- **A reminder's buttons say what they do: Completed · Snooze 5 min · Snooze
  10 min · Dismiss.** *Done* meant "complete the task", and a tester and Ian
  both read it as "stop reminding me" — so the two meanings are now two buttons,
  and **Dismiss** clears the in-app red alert as well as the notification.
  Android gets Completed · Snooze 10 min · Dismiss, because Android shows at
  most three. *Delete* is deliberately not among them: from a lock screen it is
  one mis-tap from losing a task, with no undo. A reminder already delivered by
  1.1.3 (242) still works — its `done` button still completes (TimeFlow#68).
- **Beta builds record how far a background reminder action got**, in
  Settings → About → *Last reminder action*. **Completed** from the lock screen
  did not complete the task on a release build on a real iPhone, while passing
  on every simulator, where builds are debug — and a tester's phone can't be
  plugged in. The breadcrumb is written with `dart:io` alone, so it can still
  record the case where plugins in the background isolate are the problem; the
  handler also now calls `DartPluginRegistrant.ensureInitialized()`, whose
  absence is one documented way for that handler to do nothing (TimeFlow#68).
- **A task completed from the lock screen now shows as completed when you open
  TimeFlow.** The breadcrumb on a real iPhone (1.1.3 (250)) showed **Completed**
  had in fact been written. But iOS starts the app in the background to handle
  the button, the background handler writes through its own database
  connection, and drift only refreshes its task lists for writes made through
  the app's. Opening TimeFlow resumed that process still showing the task red
  and alerting until a restart. Coming back to the foreground now re-reads tasks
  as well as snoozes. 1.1.3 (242)'s *Done* most likely had the same cause
  (TimeFlow#68).
- **…and the save itself no longer fails when the app is starting up at the
  same moment.** On a second try the breadcrumb read `failed:
  SqliteException(5) … database is locked … COMMIT TRANSACTION`: the app's main
  isolate, started by iOS for the same launch, was reading tasks, and under
  SQLite's default rollback journal a reader blocks a writer's commit, so the
  background handler's save was lost. The database now runs in WAL mode, where
  a reader and a writer can work at once (TimeFlow#68).
- **The task editor's Category and Repeat values are no longer drawn grey.** Both
  fields are a tappable box rather than a real input, and a bare label inside one
  inherits the app's secondary grey, so a chosen category read as an empty
  placeholder. They now match the Reminder field next to them. Category was the
  reported half (TimeFlow#43); Repeat had the same defect and nobody had filed it.
- **That warning now knows which build is in front.** It fired on any
  difference and always said "update", so a tester who updated promptly — while
  the round's build row was still being caught up by hand — was told to update
  again, to a build behind the one they had. It now says *"You're ahead of this
  round"* and *nothing to do* in that case, and admits it can't tell when the
  build numbers aren't comparable (TimeFlow#68).
- **Settings warns when a round has moved past the build you're running.** A
  round's build moves in place rather than a new round opening — *First Look -
  Apple* went 1.1.0 (222) to 1.1.3 (242) — so a tester could be working a list of
  steps written for a build they don't have, with nothing to tell them apart.
  Settings now names the round and both builds ("It's on 1.1.3 (242) now; this is
  1.1.0 (227)") before they tap anything. It warns and never blocks: a finding on
  the older build still counts, and the notice says to report it and say which
  build it was (TimeFlow#61).
- The Tasks badge now counts **this app's** rounds only. A tester in rounds for
  two apps saw one number in Settings and a different one on the page the button
  opened; the summary is asked `?app=TimeFlow` and Settings names the round the
  count belongs to ("5 tasks left in First look - Android and web") or says how
  many rounds it spans (TimeFlow#61).
- **Disconnect** says what it actually does: it tells the portal to drop the
  device, then forgets the code. It always did both — only the wording suggested
  otherwise.
- The beta code example in the connect dialog is four groups, like a real code.
- Settings has a divider between **Beta testing** and **Plugins**, like every
  other section, and a store build drops the divider with the section.

## 1.1.3 — 2026-10-16

### App
- A **store build no longer contains beta tester mode at all** — not the Settings
  section, not the device token, not `testers.rinserepeatlabs.com`. `betaModeOffered`
  is now a compile-time constant and every reference sits behind it, so the compiler
  removes the feature instead of hiding it. 1.1.2's store APK carried the portal's
  hostname (unreachable, but there); 1.1.3's does not, and the release workflow now
  reads the artifact's strings and fails if it ever does again.

### Build
- The Linux desktop build installs `libsecret-1-dev` and `libjsoncpp-dev`, which
  `flutter_secure_storage_linux` needs to configure. v1.1.2's experimental Linux
  zip is missing because of this; nothing on a pull request builds Linux desktop,
  so only the tag found out.

## 1.1.2 — 2026-10-16

### App
- **Beta tester mode** (TimeFlow#54): **Settings → Beta testing** takes the one-time
  `RRL-…` code from a round's announcement email and connects this device to the
  tester portal. The Tasks button then carries a badge with how many required
  steps are left, and tapping either beta button lands in the portal already
  signed in — the app asks for a 30-second, single-use handoff on the tap, so the
  token itself never travels in a URL. Signing in to the portal by email keeps
  working, and **Disconnect** (or Revoke, in the portal) ends it from either side.
  The app talks to `/api/device/*` on the portal — Bearer only, never a cookie.
  New dependencies: `http`, `flutter_secure_storage` (Keychain `…ThisDeviceOnly`,
  not synchronizable; Android's secure-storage file is excluded from Auto Backup
  and device transfer, because its key never leaves the Keystore).
- The two beta buttons now appear when the build has `TIMEFLOW_BETA=1` **or** a
  code has been pasted, so the **web app** can be a tester build at runtime. iOS
  and Android store builds show no Beta testing section at all.
- Release builds now declare `android.permission.INTERNET`: beta tester mode is
  the only thing that uses the network, and a beta APK is the same build type as
  a store APK, so the permission can't be declared for one and not the other.
  Your tasks, your schedule and your backups still never leave the device.

## 1.1.1 — 2026-10-16

### App
- **Beta feedback button**: beta builds (`TIMEFLOW_BETA=1`, see
  `docs/RELEASING.md` → *Beta builds*) show a Feedback button beside
  Settings that opens the tester portal's report form for the tester's
  current TimeFlow round, pre-filled with version, build, commit, platform,
  OS and device (new dependency: `device_info_plus`). Store and web builds
  don't show it. Releases now also attach `timeflow-vX.Y.Z-beta.apk`.
  **Mac:** TestFlight builds for tester rounds need the flag; see the issue.
- **Beta tasks button**: beta builds show a second button beside Feedback
  that opens the tester portal at the round's tasks, walked one step to a
  screen. Same build context in the URL fragment, same `TIMEFLOW_BETA=1`
  gate, no new dependency. A badge counting the steps a tester has left
  needs the app to be connected to the portal and comes later (phase 2 of
  the issue); the page itself says "2 of 6" once they're signed in.
- The task editor no longer cuts off the start and end times on narrow
  phones (360 dp wide); the date gives way instead.

### Android / Google Play
- Play-ready: `docs/PLAY_STORE.md` walks through the console setup with every
  questionnaire answer. Phone screenshots regenerated at 1080×1920 (the old
  1082×2402 ones are over Play's 2:1 limit) with a new Categories shot, by
  `scripts/generate_play_screenshots.sh`. Releases attach the AAB for the
  first manual upload; CI uploads use `PLAY_TRACK` / `PLAY_RELEASE_STATUS`
  (default internal / draft, which a not-yet-reviewed app requires) and send
  `distribution/whatsnew/whatsnew-en-US`.

### iPhone and iPad
- `docs/IOS.md` explains how TestFlight builds for tester rounds are made
  (`TIMEFLOW_BETA=1`, kept apart from store builds) and the Mac's key-free
  upload. The first one, 1.1.0 (222), is in TestFlight. (#46)

## 1.1.0 — 2026-10-07

### App
- **Your own categories** (fixes #24): Settings → Categories lists every
  category with how many past, upcoming and repeating events use it. Add,
  edit (name, colour, icon), reorder and remove them; long-press a category
  (there, or in the task editor's picker) to rename it. Changing one that
  events use asks whether to **update all events** or **save as a new
  category**; removing one asks where its events go. Categories live in a
  new `categories` table (**database schema 5**, built-ins seeded with their
  old ids so existing tasks keep theirs), travel in backups, and travel in
  share links in a way older versions still open (custom ones show as None
  there).
- The midnight divider no longer draws through task cards that span
  midnight. (fixes #35)
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
- Done and Snooze on a reminder now take effect while TimeFlow is closed.
  The notification plugin let iOS suspend the app before the background
  handler had saved anything, so the task was only marked done once the app
  was next opened. `AppDelegate` now holds a short background task for
  action buttons. iOS-only; Android was unaffected. (#32)
- Still to do: real-device check that reminders arrive with the app closed
  and that Done/Snooze work from the lock screen; first TestFlight build.

### Web and docs
- Support page (`web/support.html`); privacy policy covers iOS and names the
  publisher. (#26)
- Marketing/press kit and beta-tester kit. (#28, #29) Both were deleted by
  mistake in #30's squash and are restored, now with vector SVGs of every
  tester design, new "TimeFlow Tester" / "TimeFlow Beta Tester" badges, and
  Ian's one-colour white/black logo SVGs.
- Tester kit: the SVGs in `marketing/testers/svg/` are now the source and are
  never overwritten (hand edits are kept); `scripts/render_tester_pngs.sh`
  redraws the PNGs from them. (fixes #39)
- Marketing kit generator ported from Swift/AppKit to
  `scripts/generate_marketing_assets.sh` (Docker + Inkscape), so it runs on
  Linux too: **the Mac no longer needs to run it.** One-colour files now use
  the outline marks; high-res print zip on *press-kit-1* refreshed. (fixes #39)
- Working agreement for multiple machines in `CLAUDE.md`; this changelog.
- `main` is now protected for everyone (no direct pushes; PRs merge only
  after analyze/test, web, Android and iOS checks pass). See `CLAUDE.md`.

## 1.0.0 — 2026-10-04

First release: the flowing timeline with a fixed NOW line, repeating tasks
with this/future/all edits, real reminder notifications (Android), photos,
share-by-link with a read-only web view, backups, accurate sunrise/sunset,
holiday calendars, an offline web app, and accessibility work. Android APK
and experimental desktop builds on GitHub Releases.
