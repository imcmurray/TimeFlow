# Releasing TimeFlow

## What's automated

| Trigger | What happens |
|---|---|
| Pull request | Analyze, format check, generated-code check, tests (under `TZ=America/Denver`), web build, debug-signed Android build |
| Push to `main` | All of the above, then the web app deploys to GitHub Pages and a **release-signed** app bundle + APK are built (CI artifacts) |
| Tag `vX.Y.Z` | GitHub release with the signed APK, a beta APK for tester rounds (`timeflow-vX.Y.Z-beta.apk`), the bundle (AAB) and experimental desktop zips; the bundle also goes to Google Play if `PLAY_SERVICE_ACCOUNT_JSON` is set (track/status from the `PLAY_TRACK`/`PLAY_RELEASE_STATUS` variables, default internal/draft) |

Build numbers are the commit count on `main` (`scripts/build_flags.sh`), so
every build's Android version code is higher than the last.

## Cutting a release

1. Bump `version:` in `pubspec.yaml` (e.g. `1.0.1+1`; the `+n` part is
   ignored, CI supplies the build number) and update
   `distribution/whatsnew/whatsnew-en-US` (Play's "What's new", 500 max).
2. Commit, merge to `main`, wait for CI to go green.
3. Once the PR shows **merged**, tag the merge commit:
   `git tag v1.0.1 && git push origin v1.0.1`. The release workflow refuses
   a tag that doesn't match `pubspec.yaml`.
4. Promote the build in Play Console (internal → closed → production).

## Beta builds (tester rounds)

A beta build is a release build with a **Feedback** button beside Settings.
It opens the tester portal (testers.rinserepeatlabs.com) at the report form
for the tester's current TimeFlow round, with the version, build, commit,
platform, OS and device filled in from the URL fragment. The tester signs in
there, and findings go through portal-sync and findings-bridge into GitLab
(`rrl-beta/timeflow-findings`) the same way as any other finding.

- Make one with `TIMEFLOW_BETA=1`:
  `flutter build apk --release $(TIMEFLOW_BETA=1 ./scripts/build_flags.sh)`.
  Without it (the default) there's no button, which is what Play production,
  the App Store and the public web app must get.
- Each tag's release has `timeflow-vX.Y.Z-beta.apk` for Android rounds.
- iPhone/iPad: TestFlight builds for a round are built with the flag on the
  Mac (see `IOS.md`). Don't promote a beta build to the App Store, and don't
  promote a beta bundle out of a Play testing track; upload a store build
  instead.
- The portal picks the round by the app name `TimeFlow`, so the app in the
  tester console must keep that name.

## Signing

- **Upload key:** `~/.config/timeflow-signing/upload-keystore.jks` with its
  passwords in `key.properties` next to it (`android/key.properties` is a
  symlink to it for local release builds). **Back up both to a password
  manager.** With Play App Signing an upload key can be reset through Play
  support, but it's a slow process.
- **CI** gets the same key from repository secrets: `ANDROID_KEYSTORE_BASE64`,
  `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
- Upload-key certificate SHA-256:
  `04:13:3A:F5:FF:54:F2:45:F5:DA:E7:98:A9:BA:87:36:6E:02:65:E6:BA:22:1A:4B:E7:E3:BD:98:98:6F:F5:80`

## Google Play

The step-by-step setup (account, app, questionnaire answers, store listing,
first upload, the closed test, automated uploads) is in
[PLAY_STORE.md](PLAY_STORE.md).

## Web app

Deploys from `main` to https://imcmurray.github.io/TimeFlow/. Built with
`--no-web-resources-cdn` so it works offline (service worker in
`web/sw.js`). After upgrading drift or sqlite3, run
`scripts/update_web_sqlite.sh` to refresh `web/sqlite3.wasm` and
`web/drift_worker.js`.

## Not done yet

- **Cloudflare Web Analytics** for `imcmurray.github.io` (shared by all Pages
  projects) needs a token with *Account Analytics: Write* to create the site.
  If it's added to `web/index.html`, add a sentence about cookieless page-view
  counts to `web/privacy.html` and the README's "no analytics" claim.
- **iOS**: the project is ready and builds unsigned in CI; signing,
  device testing and App Store Connect are in [IOS.md](IOS.md).
- **Desktop builds** are unsigned (macOS will warn; Windows SmartScreen will
  warn).
