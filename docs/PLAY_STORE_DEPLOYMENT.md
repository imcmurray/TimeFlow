# Google Play Store CI/CD Deployment Guide

This guide walks through setting up automated deployment to Google Play Store via GitHub Actions.

---

## Part 1: Manual Setup (One-Time)

### Step 1: Create Google Play Developer Account
- Go to https://play.google.com/console
- Pay $25 one-time registration fee
- Complete identity verification (may take 24-48 hours)

### Step 2: Create App in Play Console
1. Click "Create app"
2. Enter app name: **TimeFlow**
3. Select: App (not game)
4. Select: Free
5. Accept declarations

### Step 3: Complete Store Listing

**App Name:** TimeFlow

**Short Description (max 80 chars):**
```
Transform your day into a flowing river of time, not a pressure cooker.
```

**Full Description (max 4000 chars):**
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

Experience time as a gentle flowing river, not a pressure cooker.
```

### Step 4: Create Service Account for API Access
1. Go to Google Cloud Console: https://console.cloud.google.com
2. Create new project or select existing
3. Enable "Google Play Android Developer API"
4. Go to IAM & Admin → Service Accounts
5. Create service account:
   - Name: `github-play-deploy`
   - Grant role: None (we'll set permissions in Play Console)
6. Create JSON key and download it
7. In Play Console → Users & Permissions → Invite user
8. Add service account email with "Release manager" permission

### Step 5: Generate Upload Keystore
```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

> **IMPORTANT:** Store this keystore and passwords securely. Losing it means you can never update the app.

---

## Part 2: GitHub Repository Setup

### Step 6: Add GitHub Secrets
Go to Repository → Settings → Secrets and variables → Actions

Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `KEYSTORE_BASE64` | Base64-encoded keystore file: `base64 -w 0 upload-keystore.jks` |
| `KEYSTORE_PASSWORD` | Your keystore password |
| `KEY_ALIAS` | `upload` |
| `KEY_PASSWORD` | Your key password |
| `PLAY_SERVICE_ACCOUNT_JSON` | Contents of service account JSON file |

---

## Part 3: Code Changes

### File 1: `android/app/build.gradle.kts`
Replace the entire file with:

```kotlin
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.rinserepeatlabs.timeflow"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.rinserepeatlabs.timeflow"
        minSdk = 21
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
```

### File 2: `android/app/proguard-rules.pro` (Create new)
```proguard
# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
```

### File 3: `.github/workflows/release.yml`
Add the Android build job after the existing desktop jobs:

```yaml
  build-android:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Generate build info
        run: |
          chmod +x ./scripts/generate_build_info.sh
          ./scripts/generate_build_info.sh

      - name: Decode keystore
        env:
          KEYSTORE_BASE64: ${{ secrets.KEYSTORE_BASE64 }}
        run: echo "$KEYSTORE_BASE64" | base64 -d > android/upload-keystore.jks

      - name: Create key.properties
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
        run: |
          cat > android/key.properties << EOF
          storePassword=$KEYSTORE_PASSWORD
          keyPassword=$KEY_PASSWORD
          keyAlias=$KEY_ALIAS
          storeFile=upload-keystore.jks
          EOF

      - name: Build App Bundle
        run: flutter build appbundle --release

      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}
          packageName: com.rinserepeatlabs.timeflow
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal
          status: completed

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: timeflow-android
          path: build/app/outputs/bundle/release/app-release.aab
```

---

## Part 4: Play Store Assets Needed

### Screenshots Required
| Type | Dimensions | Quantity |
|------|------------|----------|
| Phone | 1080x1920 (or 16:9) | 2-8 |
| 7" Tablet | 1080x1920 | Optional |
| 10" Tablet | 1920x1200 | Optional |

### Graphics
| Asset | Dimensions | Format |
|-------|------------|--------|
| App Icon | 512x512 | PNG (no alpha) |
| Feature Graphic | 1024x500 | PNG or JPG |

### Content Rating
Complete the questionnaire in Play Console (violence, drugs, etc. - select "None" for all)

### Privacy Policy
Host at a public URL. Options:
- Create GitHub Pages privacy policy page
- Use a free hosted policy generator

---

## Part 5: Release Tracks

| Track | Purpose |
|-------|---------|
| Internal | Testing with up to 100 testers (immediate) |
| Closed | Beta testing with selected users |
| Open | Public beta testing |
| Production | Public release |

**Recommended:** Start with Internal → Closed → Production

---

## Verification Steps

1. Push a tag `v1.0.0` to trigger the workflow
2. Check GitHub Actions for successful build
3. Verify app bundle uploaded to Play Console internal track
4. Install internal test version on Android device
5. Promote to production when ready

---

## Security Checklist

- [ ] Keystore file backed up securely (NOT in git)
- [ ] Keystore passwords stored securely
- [ ] Service account JSON kept private
- [ ] GitHub secrets configured correctly
- [ ] `key.properties` in `.gitignore` ✓
- [ ] `*.jks` in `.gitignore` ✓

---

## Quick Reference: CI/CD Flow

```
Push tag v1.0.0
    ↓
GitHub Actions triggered
    ↓
Build App Bundle (AAB)
    ↓
Upload to Play Store (internal track)
    ↓
Manual promotion: Internal → Closed → Production
```
