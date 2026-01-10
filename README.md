# TimeFlow

> Experience time as a gentle flowing river, not a pressure cooker

TimeFlow is a revolutionary daily schedule app that transforms how you experience time. Instead of static grids or stressful lists, your day flows like a gentle river toward a fixed "NOW" line. As real minutes pass, tasks automatically scroll down, creating a calming, intuitive sense of progress.

## Key Features

- **Dynamic Real-Time Timeline** - Auto-scrolls to keep current time aligned with the prominent "NOW" line
- **Visual Time Zones** - Upcoming tasks above, current tasks at NOW, completed tasks below
- **Elegant Task Cards** - Flowing downward through time, positioned by start/end times
- **Rich Task Management** - Priority levels, reminders, notes, and attachments
- **One-Tap Sharing** - Easy schedule handoff to caregivers, sitters, or team members
- **Beautiful Animations** - Fluid, natural transitions that make time feel like water
- **Local Notifications** - Never miss an upcoming task
- **Offline-First** - Full functionality with local persistence

## Use Cases

- **Pet Owners**: Share your dog's daily routine with a pet sitter
- **Busy Professionals**: Feel calm progress instead of time pressure
- **Parents**: Manage family schedules visually
- **Caregivers**: Track medical routines and appointments
- **ADHD Support**: Visual representation of time passing

## Tech Stack

- **Framework**: Flutter (cross-platform mobile - iOS & Android)
- **Architecture**: Clean Architecture with Repository pattern
- **State Management**: Riverpod
- **Database**: SQLite via drift (offline-first storage)
- **Animations**: Flutter animation framework with custom ScrollController
- **Notifications**: flutter_local_notifications

## Getting Started

### Prerequisites

1. **Flutter SDK** (3.0+)
   - Install from: https://docs.flutter.dev/get-started/install

2. **Xcode** (for iOS development on macOS)
   - Install from Mac App Store

3. **Android Studio** (for Android development)
   - Install from: https://developer.android.com/studio

### Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd TaskRiver

# Run the setup script
./init.sh
```

The `init.sh` script will:
1. Verify Flutter installation
2. Run `flutter doctor` to check dependencies
3. Get Flutter packages
4. Launch an emulator/simulator if needed
5. Start the app with hot reload

### Manual Setup

```bash
# Check Flutter installation
flutter doctor

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run
```

## Project Structure

```
timeflow/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── core/                     # Core utilities and constants
│   │   ├── theme/                # App themes and styling
│   │   └── utils/                # Helper functions
│   ├── data/                     # Data layer
│   │   ├── models/               # Data models
│   │   ├── repositories/         # Repository implementations
│   │   └── datasources/          # Local database
│   ├── domain/                   # Business logic
│   │   ├── entities/             # Domain entities
│   │   └── usecases/             # Use cases
│   └── presentation/             # UI layer
│       ├── screens/              # App screens
│       ├── widgets/              # Reusable widgets
│       └── providers/            # State management
├── test/                         # Unit and widget tests
├── integration_test/             # Integration tests
├── assets/                       # Images, fonts, etc.
├── pubspec.yaml                  # Dependencies
└── init.sh                       # Development setup script
```

## UI Design

### Color Scheme

| Role | Light | Dark |
|------|-------|------|
| Primary | Soft blues (#E3F2FD, #42A5F5) | Muted blues |
| Secondary | Gentle greens (#E8F5E9, #66BB6A) | Muted greens |
| Accent | Warm coral (#FFCCBC, #FF7043) | Coral |
| Background | Off-white (#FAFAFA) | Dark gray |
| Text | Charcoal (#212121, #757575) | Light gray |

### Key UI Elements

- Full-screen vertical ScrollView as main canvas
- Thin timeline on left with subtle hour markers
- Bold horizontal NOW line at 70-80% down screen with soft glow
- Task cards with rounded corners, subtle shadows
- Card height proportional to task duration
- Floating Action Button for quick task addition

## Development Commands

While running `flutter run`:

| Key | Action |
|-----|--------|
| `r` | Hot reload (rebuild UI) |
| `R` | Hot restart (restart app) |
| `h` | Help / list commands |
| `d` | Detach (leave app running) |
| `q` | Quit |
| `o` | Open DevTools |
| `p` | Toggle debug paint |

## Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test

# Run with coverage
flutter test --coverage
```

## Building for Production

```bash
# Build for Android
flutter build apk --release
flutter build appbundle --release

# Build for iOS
flutter build ios --release
```

## Feature Progress

Features are tracked via a SQLite database (`features.db`). Use the feature management API to:
- Get next feature to implement
- Mark features as passing
- Track overall progress

## Contributing

1. Get the next feature from the feature list
2. Implement the feature following Clean Architecture
3. Write tests for the feature
4. Mark the feature as passing when complete

## License

This project is licensed under [CC BY-NC-SA 4.0](LICENSE) (Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International).

---

*TimeFlow - Because time should flow, not stress.*
