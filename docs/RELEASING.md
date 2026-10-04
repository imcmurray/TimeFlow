# Releasing TimeFlow

## What's automated

| Trigger | What happens |
|---|---|
| Pull request | Analyze, format check, generated-code check, tests (under `TZ=America/Denver`), web build, debug-signed Android build |
| Push to `main` | All of the above, then the web app deploys to GitHub Pages and a **release-signed** app bundle + APK are built (CI artifacts) |
| Tag `vX.Y.Z` | GitHub release with the signed APK and experimental desktop zips; the bundle goes to Play's **internal** track if `PLAY_SERVICE_ACCOUNT_JSON` is set |

Build numbers are the commit count on `main` (`scripts/build_flags.sh`), so
every build's Android version code is higher than the last.

## Cutting a release

1. Bump `version:` in `pubspec.yaml` (e.g. `1.0.1+1`; the `+n` part is
   ignored, CI supplies the build number).
2. Commit, merge to `main`, wait for CI to go green.
3. `git tag v1.0.1 && git push origin v1.0.1`.
4. Promote the build in Play Console (internal → closed → production).

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

## First Play Store submission (one-time, needs the Play Console account)

1. **Create the app** in Play Console: name *TimeFlow*, default language
   English (US), App, Free. Package name `com.rinserepeatlabs.timeflow`.
   - A *personal* developer account created after Nov 2023 must run a
     **closed test with at least 12 testers for 14 days** before production
     access. An *organization* account (e.g. RinseRepeatLabs, with a D-U-N-S
     number) is exempt. Start the closed test as early as possible.
2. **Play App Signing:** accept Google-managed signing; upload the first
   bundle from a CI artifact (`timeflow-android` → `app-release.aab`).
3. **Automate uploads:** in Google Cloud, create a service account, grant it
   access in Play Console (*Users and permissions* → *Invite* → release
   permissions for this app), download its JSON key and add it as the
   `PLAY_SERVICE_ACCOUNT_JSON` repository secret. From then on, tags upload
   to the internal track automatically.
4. **Store listing:** text in [store/listing.md](store/listing.md);
   screenshots and the feature graphic are in [store/](store/).
5. **App content** answers are below.

### App content answers

- **Privacy policy URL:** https://imcmurray.github.io/TimeFlow/privacy.html
- **Ads:** No ads.
- **App access:** All functionality is available without special access.
- **Content rating (IARC):** Utility/productivity; no violence, sexual
  content, profanity, drugs, gambling, user interaction or sharing of
  location. Expected rating: Everyone / PEGI 3.
- **Target audience:** 18+ (not designed for children; avoids the Families
  policy requirements). 13+ is also defensible.
- **Data safety:**
  - Does the app collect or share user data? **No.** Tasks, notes and photos
    are stored only on the device and never transmitted. Share links are
    created and sent by the user through other apps, and their contents
    aren't transmitted by TimeFlow.
  - Is data encrypted in transit? Not applicable (nothing is transmitted).
  - Can users request deletion? Data is deleted by uninstalling, or with
    *Settings → Delete all tasks*.
- **Exact alarms declaration:** TimeFlow uses `SCHEDULE_EXACT_ALARM` (not
  `USE_EXACT_ALARM`) for user-set task reminders; it works without the
  permission, with possibly late reminders, and asks the user to allow it in
  settings.
- **Photo and video permissions:** none requested; photos come from the
  system photo picker or camera intent.

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
