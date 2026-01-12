# Apple App Store Deployment Guide

This guide walks through setting up iOS platform support and automated deployment to Apple App Store via GitHub Actions.

---

## Part 1: Manual Setup (One-Time)

### Step 1: Enroll in Apple Developer Program
- Go to https://developer.apple.com/programs/
- Pay $99/year membership fee
- Complete identity verification (may take 24-48 hours)
- Requires Apple ID

### Step 2: Add iOS Platform to Project
```bash
flutter create --platforms=ios .
```

### Step 3: Configure Bundle Identifier
Edit `ios/Runner.xcodeproj/project.pbxproj` or use Xcode:
- Bundle Identifier: `com.rinserepeatlabs.timeflow`
- Display Name: `TimeFlow`
- Version: `1.0.0`
- Build: `1`

### Step 4: Create App in App Store Connect
1. Go to https://appstoreconnect.apple.com
2. My Apps → + → New App
3. Select iOS platform
4. Enter app name: **TimeFlow**
5. Select bundle ID: `com.rinserepeatlabs.timeflow`
6. SKU: `timeflow-ios`

---

## Part 2: App Store Listing Content

**App Name:** TimeFlow

**Subtitle (max 30 chars):**
```
Time flows like a river
```

**Promotional Text (max 170 chars):**
```
Experience your schedule as a gentle flowing river. Tasks flow past the NOW line as real minutes pass. No rigid boxes, just natural flow.
```

**Description:**
```
TimeFlow reimagines daily scheduling as a gentle, flowing river of time.

Unlike traditional calendar apps that chop your day into rigid boxes, TimeFlow presents your schedule as a continuous stream where tasks naturally flow past the NOW line as real minutes pass.

KEY FEATURES:

• River of Time View - Watch your day flow smoothly past the present moment
• Fluid Task Cards - Tasks float naturally in the timeline, not trapped in boxes
• NOW Line - A fixed reference point showing the current moment
• Gentle Reminders - Optional notifications that feel like friendly nudges
• Dark & Light Themes - Easy on your eyes, day or night
• 24-Hour Time Support - For those who prefer it
• Task Merging - Overlapping tasks intelligently combine into a single view
• Export & Import - Back up your data anytime

WHY TIMEFLOW?

Traditional scheduling apps create anxiety by showing time as something to be conquered and controlled. TimeFlow takes a different approach - time flows whether we stress about it or not, so why not embrace the flow?

Perfect for:
• People who feel overwhelmed by rigid calendar grids
• Those seeking a calmer approach to time management
• Anyone who wants to visualize their day differently
• Users who appreciate thoughtful, minimal design

PRIVACY FIRST:
• All data stored locally on your device
• No accounts required
• No analytics or tracking
• No ads, ever

TimeFlow is open source. Visit our GitHub for more information.
```

**Keywords (100 chars max, comma-separated):**
```
calendar,schedule,time,planner,tasks,productivity,todo,minimal,flow,timeline
```

**Support URL:** `https://github.com/imcmurray/TimeFlow`
**Privacy Policy URL:** (needs to be hosted publicly)

---

## Part 3: Certificates & Provisioning

### Option A: Manual Setup in Xcode
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Signing & Capabilities
3. Enable "Automatically manage signing"
4. Select your team
5. Xcode creates certificates and provisioning profiles automatically

### Option B: CI/CD Setup with Match (Fastlane)
Match syncs certificates across machines using a private git repo.

#### Step 1: Install Fastlane
```bash
# On macOS
brew install fastlane
```

#### Step 2: Initialize Fastlane
```bash
cd ios
fastlane init
```

#### Step 3: Set Up Match
```bash
fastlane match init
# Select git storage
# Enter private repo URL for certificates
```

#### Step 4: Generate Certificates
```bash
fastlane match appstore  # For App Store distribution
fastlane match development  # For development
```

---

## Part 4: GitHub Actions CI/CD

### Required Secrets

| Secret Name | Value |
|-------------|-------|
| `APPLE_TEAM_ID` | Your Apple Developer Team ID |
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID from App Store Connect |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer ID from App Store Connect |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64-encoded .p8 API key file |
| `MATCH_GIT_URL` | Private repo URL for certificates |
| `MATCH_PASSWORD` | Password to decrypt certificates |
| `MATCH_GIT_BASIC_AUTH` | Base64 of `username:token` for git access |

### Create App Store Connect API Key
1. App Store Connect → Users and Access → Keys
2. Generate API Key with "App Manager" role
3. Download the .p8 file (can only download once!)
4. Note the Key ID and Issuer ID

### GitHub Actions Workflow

Add to `.github/workflows/release.yml`:

```yaml
  build-ios:
    runs-on: macos-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Install Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Install Fastlane
        run: |
          cd ios
          gem install fastlane

      - name: Generate build info
        run: |
          chmod +x ./scripts/generate_build_info.sh
          ./scripts/generate_build_info.sh

      - name: Setup SSH for Match
        uses: webfactory/ssh-agent@v0.8.0
        with:
          ssh-private-key: ${{ secrets.MATCH_DEPLOY_KEY }}

      - name: Sync certificates with Match
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
        run: |
          cd ios
          fastlane match appstore --readonly

      - name: Build iOS
        run: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

      - name: Upload to App Store Connect
        env:
          APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
          APP_STORE_CONNECT_API_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_API_ISSUER_ID }}
          APP_STORE_CONNECT_API_KEY_BASE64: ${{ secrets.APP_STORE_CONNECT_API_KEY_BASE64 }}
        run: |
          cd ios
          echo "$APP_STORE_CONNECT_API_KEY_BASE64" | base64 -d > AuthKey.p8
          fastlane deliver --ipa ../build/ios/ipa/TimeFlow.ipa --skip_screenshots --skip_metadata

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: timeflow-ios
          path: build/ios/ipa/TimeFlow.ipa
```

### Create `ios/ExportOptions.plist`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```

### Create `ios/fastlane/Fastfile`
```ruby
default_platform(:ios)

platform :ios do
  desc "Push a new release build to TestFlight"
  lane :release do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
    upload_to_testflight(
      api_key_path: "fastlane/api_key.json"
    )
  end
end
```

---

## Part 5: App Store Assets

### Screenshots Required
| Device | Dimensions | Required |
|--------|------------|----------|
| iPhone 6.7" (14 Pro Max) | 1290x2796 | Yes |
| iPhone 6.5" (11 Pro Max) | 1242x2688 | Yes |
| iPhone 5.5" (8 Plus) | 1242x2208 | Yes |
| iPad Pro 12.9" | 2048x2732 | If supporting iPad |

### App Icon
- 1024x1024 PNG (no alpha, no rounded corners)
- Apple applies the rounded corners automatically

### App Preview Video (Optional)
- 15-30 seconds
- Specific dimensions per device

---

## Part 6: App Review Guidelines

### Common Rejection Reasons to Avoid
1. **Crashes or bugs** - Test thoroughly
2. **Incomplete information** - Fill all metadata
3. **Placeholder content** - Remove all test data
4. **Privacy policy** - Must have hosted URL
5. **Login required** - Provide demo account if needed (N/A for TimeFlow)

### Required Privacy Declarations
- Data collection: None
- Data sharing: None
- Tracking: None

---

## Part 7: Release Tracks

| Track | Purpose |
|-------|---------|
| TestFlight Internal | Up to 100 internal testers (immediate) |
| TestFlight External | Up to 10,000 beta testers (requires review) |
| App Store | Public release (requires review) |

**Review times:** Usually 24-48 hours, can be faster

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `ios/` folder | Generate via `flutter create` |
| `ios/Runner.xcodeproj` | Configure bundle ID, team, signing |
| `ios/ExportOptions.plist` | Create for CI/CD builds |
| `ios/fastlane/Fastfile` | Create for automation |
| `.github/workflows/release.yml` | Add iOS build job |
| GitHub Secrets | Add Apple credentials |

---

## Verification Steps

1. `flutter create --platforms=ios .` succeeds
2. Open in Xcode, configure signing
3. `flutter build ios --debug` succeeds locally
4. Push tag to trigger workflow
5. Check TestFlight for uploaded build
6. Submit for App Store review

---

## Cost Summary

| Item | Cost |
|------|------|
| Apple Developer Program | $99/year |
| Mac for development | Required (or use CI/CD only) |
| GitHub Actions | Free for public repos |

---

## Key Differences from Google Play

| Aspect | Google Play | Apple App Store |
|--------|-------------|-----------------|
| Cost | $25 one-time | $99/year |
| Review time | Hours | 24-48 hours |
| Build format | AAB | IPA |
| Signing | Keystore | Certificates + Provisioning |
| CI/CD complexity | Simple | Requires Match/Fastlane |
| Screenshots | More flexible | Strict dimensions |

---

## Quick Reference: CI/CD Flow

```
Push tag v1.0.0
    ↓
GitHub Actions triggered (macos-latest runner)
    ↓
Fastlane Match syncs certificates
    ↓
Build IPA
    ↓
Upload to TestFlight
    ↓
Manual promotion: TestFlight → App Store
```
