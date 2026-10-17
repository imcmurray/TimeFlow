# TimeFlow Project Instructions

TimeFlow is a Flutter daily-schedule app: tasks flow down a vertical timeline
past a fixed NOW line as real time passes. Released as v1.0.0 for Android
(signed APK; Play Store pending) and the web (PWA on GitHub Pages). iPhone/iPad
are in progress (see `docs/IOS.md`); desktop builds are experimental.

## Working across machines (read first)

More than one Claude session works on this repo: one on Ian's Linux PC
(everything except Apple builds) and one on a Mac mini (iPhone/iPad, Xcode,
App Store Connect). **GitHub issues are the shared channel and the durable
record** — a decision that isn't in an issue didn't happen, because the other
machine can only read what's written down.

At the start of every session:
1. `git fetch --prune && git checkout main && git pull`
2. Read `docs/CHANGELOG.md` → *Unreleased* for what changed since you last
   worked here.
3. `gh issue list --label mac` (on the Mac) or `gh issue list` (elsewhere) for
   work waiting for you. Issues are how instructions are handed over.

### The baton

**End every comment written for the other machine with a baton line**, on its
own, as the last line:

```
**Baton: mac** — <what you're waiting for, in a few words>
```

`mac`, `linux` or `ian`. It says who the issue is waiting on, so either session
can tell at a glance whether it is working or waiting without reading the whole
thread. Taking work means posting a comment that takes the baton; finishing
means handing it back. If you read an issue whose last baton is yours, that is
your queue — start there.

The one thing never to put in a GitHub comment is anything private to a tester:
a name, an email address, a beta code, a device row. This repo is public. Those
go through the private relay (`relay.py` in the tester-pool repo, a message
queue on Ian's LAN server) or they wait for Ian.

On the Mac that means the relay's MCP tools: `relay_mcp.py` exposes the queue
as `relay_inbox`, `relay_read`, `relay_send`, `relay_threads` and
`relay_thread`. Check the inbox when a session starts and answer on the same
thread; `docs/relay.md` in tester-pool has the rest, including the setup.

The Mac runs Claude Code in a tab of the Claude desktop app, so it also has a
shell: `python3 ~/Development/tester-pool/relay.py wait --timeout 1800` as a
background command exits the moment something arrives, and that wakes the
session. Arm it when a session starts and re-arm it when it expires. The MCP
tools never wake anything — they are for working the queue once awake.

While working:
- **Commit as `Ian McMurray <ian.mcmurray@gmail.com>`.** This is a personal,
  public repo: never commit with the court (`uscourts.gov`) address. Check with
  `git config user.email` in a fresh clone and set it per repo if needed.
- **Never push to `main`.** Branch from an up-to-date `main`, open a PR, let CI
  (analyze, tests, web, Android, iOS) pass, then merge. CI is what keeps the
  other machine's work from breaking.
- Add a line to `docs/CHANGELOG.md` → *Unreleased* in the same PR, saying what
  changed for users or for the other machine.
- Reference the issue (`Fixes #12`) so it closes when the PR merges; comment on
  the issue if you're blocked or need Ian.
- Before branching again after a while, pull `main` first. The other machine
  has probably merged something.

### `main` is protected (this applies to everyone, Ian included)

A repository ruleset ("Protect main") rejects direct pushes, force-pushes
and deletion of `main`, and only allows merging a PR once these CI checks
pass: **Analyze and test**, **Web build**, **Android build**, **iOS build
(unsigned)**. There's no admin bypass, so a push straight to `main` fails
with `GH013: Repository rule violations`. That's expected, not a problem
with your credentials.

The workflow:

```bash
git checkout main && git pull
git checkout -b short-topic-name          # one branch per change
# ...work, run analyze/tests/format locally, commit...
git push -u origin short-topic-name
gh pr create --fill                        # or a written title/body
gh pr checks --watch                       # wait for the four checks
gh pr merge --merge --delete-branch        # refuses until checks pass
git checkout main && git pull
```

If you committed on `main` by accident and the push was rejected, move the
commits to a branch instead of retrying:

```bash
git branch short-topic-name                # keep the commits
git reset --hard origin/main               # put local main back
git checkout short-topic-name && git push -u origin short-topic-name
gh pr create --fill
```

A failing check blocks the merge: fix it on the same branch and push again.
If a check fails for reasons outside your change (e.g. the macOS runner is
down), comment on the PR or issue for Ian instead of working around it.
Ian can switch the ruleset off temporarily in Settings → Rules in a real
emergency; sessions shouldn't.

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
