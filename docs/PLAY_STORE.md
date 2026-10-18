# Putting TimeFlow on Google Play

Everything that can be prepared without a Play Console account is done: the
app is signed, CI builds the bundle, the listing text, graphics and
screenshots are in `docs/store/`, and the answers to Play's questionnaires
are below. What's left needs Ian's Google account, in this order.

**The long pole is step 6.** A personal developer account must run a closed
test with **at least 12 testers for 14 days in a row** before it can publish
to production. Start it as soon as the internal test works.

## What's ready

| Item | Where |
|---|---|
| Signed bundle (AAB) and APK for each release | GitHub release assets, e.g. `timeflow-v1.1.0.aab` |
| Package name | `com.rinserepeatlabs.timeflow` |
| Target SDK 36, 16 KB page-size ready, no INTERNET permission | checked on the v1.1.0 APK |
| Listing text (name, short and full description) | [store/listing.md](store/listing.md) |
| App icon 512×512 | `docs/store/icon-512.png` |
| Feature graphic 1024×500 | `docs/store/feature-graphic.png` |
| Phone screenshots, 6 × 1080×1920 | `docs/store/screenshots/` (regenerate with `scripts/generate_play_screenshots.sh`) |
| "What's new" text | `distribution/whatsnew/whatsnew-en-US` (CI sends it with each upload) |
| Privacy policy | https://imcmurray.github.io/TimeFlow/privacy.html |
| Upload key | `~/.config/timeflow-signing/` (see [RELEASING.md](RELEASING.md); **back it up**) |

## 1. Decide the account type

- **Personal** (US$25, government ID): fastest to open. Shows *Ian McMurray*
  as the developer. Needs the 12-tester, 14-day closed test (step 6) before
  production, and a verified Android phone in the Play Console app.
- **Organization** (US$25): shows *Rinse Repeat Labs*. Needs the business to
  be a registered legal entity with a **D-U-N-S number** (free from Dun &
  Bradstreet, can take a couple of weeks) and a business website. **No
  closed-test requirement.**

If Rinse Repeat Labs is registered and has (or can get) a D-U-N-S number,
the organization account saves the 14-day test and matches the iOS publisher
plan. Otherwise go personal now; an app can be transferred to an
organization account later.

## 2. Create the developer account

1. https://play.google.com/console/signup, pick the account type, pay the fee.
2. Complete identity verification (and, for organizations, the D-U-N-S
   details). Verification can take a few days.
3. **Contact email:** Play shows it publicly on the listing. Use
   **RinseRepeatLabs@gmail.com**, which is already public on the Rinse
   Repeat Labs site and the support page (not a personal or work inbox).

## 3. Create the app

*Home → Create app*: name **TimeFlow: Calm Daily Planner**, default language
**English (United States)**, **App**, **Free**. Accept the declarations.

## 4. Set up the app (Dashboard → "Set up your app")

| Task | Answer |
|---|---|
| Privacy policy | `https://imcmurray.github.io/TimeFlow/privacy.html` |
| App access | All functionality is available without special access |
| Ads | No, the app doesn't contain ads |
| Content rating | Start questionnaire → category **Utility, Productivity, Communication, or Other** → answer **No** to every question (no violence, sexual content, language, drugs, gambling, user-to-user interaction, location sharing, purchases). Expected: Everyone / PEGI 3 |
| Target audience | **18 and over** (keeps the Families policy out of scope; 13+ is also fine) |
| News app | No |
| Government app | No |
| Financial features | My app doesn't provide any financial features |
| Health apps | No health features (the *Health* category is just a label people pick) |
| Advertising ID | No, the app doesn't use advertising ID |
| Data safety | See below |

**Data safety form:**
1. *Does your app collect or share any of the required user data types?*
   **No.** Tasks, notes, photos and categories stay on the device and the app
   has no internet permission. Share links are sent by the user through other
   apps; TimeFlow doesn't transmit them.
2. That's the whole form when the answer is No. Submit.

**Exact alarms:** TimeFlow requests `SCHEDULE_EXACT_ALARM` (not
`USE_EXACT_ALARM`) for reminders the user sets. If Play asks, reminders are
the core feature and they still work, possibly late, if the permission is
denied.

## 5. Store listing and the first internal release

*Grow users → Store presence → Main store listing*: paste the name, short and
full description from [store/listing.md](store/listing.md), website
**https://rinserepeatlabs.com/portfolio/timeflow/** (as on the App Store), upload the
icon, the feature graphic and the six phone screenshots. Category
**Productivity**, tags *Planner*, *Calendar*. Tablet screenshots are
optional.

*Test and release → Testing → Internal testing → Create new release*:
1. Accept **Play App Signing** (Google manages the app signing key; ours is
   the upload key).
2. Upload `timeflow-v1.1.0.aab` from
   https://github.com/imcmurray/TimeFlow/releases/tag/v1.1.0. The first
   bundle has to be uploaded by hand.
3. Release notes: paste `distribution/whatsnew/whatsnew-en-US`.
4. *Testers* tab: create an email list with your own Google account (and up
   to 100 others), save, roll out. Open the opt-in link on your phone and
   install from Play to check it works.

## 6. Closed test: 12 testers for 14 days (personal accounts)

1. Create a Google Group, e.g. **timeflow-testers@googlegroups.com**, set to
   anyone-can-join (or invite-only). The tester kit has a header image:
   `marketing/testers/timeflow-testers-header-1200x630.png`.
2. *Testing → Closed testing → Create track* (or use *Alpha*), add the group
   as testers, and promote the internal release to it.
3. Send testers the group link and the track's opt-in link. They must **opt
   in and install from Play**, and stay opted in. The 14 days count only
   while at least 12 testers are opted in.
4. After 14 days: *Dashboard → Apply for production*. Play asks what you
   tested and what changed; the changelog and the issues closed during the
   test are the answer. Review typically takes up to a week.

Invitation you can send:

> I'm about to put TimeFlow, my calm daily planner, on Google Play and need
> testers for two weeks. Join the group (link), then tap the testing link
> (link) on your Android phone and install TimeFlow from Play. Please keep it
> installed for 14 days and tell me anything that wobbles. You get a "TimeFlow
> Tester" badge for your trouble.

## 7. Automate uploads and promotion (do this; nothing else here works without it)

This is the one step only Ian can do, and until it is done every Play action
is a click in the Console that no session can make or audit. The v1.1.3
release logged `Upload to Google Play: skipped` for exactly this reason: the
secret has never existed, so Play has had nothing new since v1.1.0 (217).

1. Google Cloud console: create a project (or reuse one), enable the **Google
   Play Android Developer API**, create a **service account**, and create a
   JSON key for it.
2. Play Console → *Users and permissions → Invite new users*: the service
   account's email, app access to TimeFlow, permissions **Release to testing
   tracks** *and* **Release to production** — the Linux session maintains Play
   end to end, including the production rollout. It can take a day to start
   working.
3. GitHub → repository *Settings → Secrets and variables → Actions*:
   - Secret `PLAY_SERVICE_ACCOUNT_JSON`: the whole JSON key. Keep it here and
     not on any machine: then every promotion is a workflow run with a log,
     and deleting this one secret takes the ability away again.
   - Variable `PLAY_TRACK` (optional, default `internal`): e.g. `alpha` to
     send tagged releases straight to the closed test.
   - Variable `PLAY_RELEASE_STATUS` (default `draft`): leave unset until Play
     has reviewed the first release, then set it to `completed` so uploads go
     out without a manual click. Play refuses anything but `draft` for an app
     that hasn't been reviewed yet.

From then on, pushing a `vX.Y.Z` tag uploads the bundle with the "What's new"
text, and tracks are moved with the *Play release* workflow (Actions → *Play
release*) or `scripts/play_release.py`:

| Command | What it does |
|---|---|
| `show` | what build is on each track, and how much of the audience has it |
| `promote --from internal --to alpha` | moves a build between tracks |
| `promote --from alpha --to production` | to production, at a tenth of users |
| `rollout --fraction 0.5` / `--fraction 1` | widens a staged rollout |
| `halt` | stops a rollout reaching anyone new |

`--dry-run` prints the requests without credentials and without sending them,
which is how to read a command before it reaches real users. A build only ever
sits on one track: giving its version code to another moves it.

## Who maintains what

| | |
|---|---|
| TestFlight, App Store Connect, the iOS build | the Mac mini session |
| Google Play, the Android build, the tester-round APK and portal | the Linux PC session |
| Anything needing a phone in hand, Google/Apple sign-in, or identity | Ian |

The Linux PC has no Android device (`adb devices` is empty, by design — it is
a desktop), so it can prove a build compiles and check what is inside the
artifact the way CI does, but not that it runs. A build going to production
should have been on a phone first: Ian's, or a round's testers'.

## Each later release

Update `distribution/whatsnew/whatsnew-en-US` (500 characters max) in the
release PR, merge, tag. If screens changed, run
`scripts/generate_play_screenshots.sh` and upload the new screenshots to the
listing.
