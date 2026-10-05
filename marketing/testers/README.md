# TimeFlow tester kit

Badges, stickers and banners for the **timeflow-testers** group: the people
trying TimeFlow builds before everyone else. Same Nunito type and river
blues as the rest of the kit, with a little more mischief.

Regenerate (Docker needed; renders with Chromium):

```bash
SINCE_VERSION=1.0.0 SINCE_BUILD=183 ./scripts/generate_tester_assets.sh
```

`SINCE_VERSION` and `SINCE_BUILD` set the "Since vX (N)" text: the first
build a tester received. The defaults are **v1.0.0 (183)**, the first
TestFlight build. Make a set for a later cohort by changing them. The
designs live in `scripts/tester-assets/generate.mjs`.

Every file has a transparent background and comes at 1× plus 2× (and 4× for
the stickers), so pick the pixel size you need.

| File | Use it for |
|---|---|
| `seal-since-*` | Round "TimeFlow Tester · Since v1.0.0 (183)" seal: profile pictures, stickers, the group's avatar |
| `caution-beta-tester-banner-*` | Hazard-tape "CAUTION: BETA TESTER" banner: email signatures, chat headers, laptop stickers |
| `caution-beta-tester-square-*` | Square caution badge with the "since" build: avatars, stickers |
| `pill-since-*` / `pill-since-dark-*` | Small "TESTER since v1.0.0 (183)" pill in the app's NOW-line style, for light or dark backgrounds |
| `saw-it-before-now-*` | "I saw it before NOW" sticker |
| `beta-expect-ripples-*` | "BETA · expect ripples" sticker |
| `founding-tester-*` | Medal for the first cohort |
| `bug-hunter-*` | For testers whose reports led to a fix |
| `timeflow-testers-header-*` | Header image for the group page or invitation email (1200×630 social size) |
| `role-icon-tester-*` | Small square icon for a chat role (Discord, Slack) or an emoji |

For printed stickers, the 4× files are 2400 px across: about 8 in at
300 DPI, plenty for a 3–4 in sticker.
