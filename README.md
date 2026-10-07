# Silenz — Automatic Silent Mode App

Silenz is a Flutter application that helps users manage their phone's sound mode through recurring schedules and location zones. Set up quiet periods for classes, meetings, study sessions, or other activities, and choose Silent, Vibrate, or Do Not Disturb for each rule.

Built as a hackathon project, the app combines a Flutter interface with native Android sound controls, background checking, local storage, and an external account API.

## Features

### Time-Based Schedules

- Create, edit, delete, enable, and disable schedules.
- Choose a schedule name, icon, start time, end time, and days of the week.
- Select **Silent**, **Vibrate**, or **DND** mode.
- Check enabled schedules periodically and apply their configured mode.
- Switch to Normal mode when no applicable time schedule is active.

### Location Zones

- View an OpenStreetMap-based map and use the device's current location.
- Search for places through Nominatim.
- Define zones with coordinates, a radius, a name, and a sound mode.
- Enable or disable saved zones.
- Apply a zone's configured mode when the device is detected inside it.
- Store zone definitions locally for native Android checking.

### Accounts and Guest Mode

- Use guest mode with schedules saved on the device.
- Register with email/password and verify an email OTP through the external API.
- Sign in, resend OTPs, and use the password-recovery flow.
- Store session information with Flutter Secure Storage.
- Load and manage account schedules through the API.
- Attempt to merge guest schedules into the account after signing in.
- View and update profile details and avatar information.

### Dashboard and Statistics

- View schedule information and enabled-schedule counts.
- Access statistics charts and summaries.
- Calculate guest statistics from configured schedules.
- Request account statistics from external API endpoints.
- Use the app's light and dark theme infrastructure.

### Android Integration

- Flutter-to-Kotlin communication through a method channel.
- Native ringer and Do Not Disturb controls.
- Foreground service and periodic alarm-based checks.
- Boot receiver intended to restart background processing after reboot.
- Links to Do Not Disturb and battery settings.

## Tech Stack

| Technology | Purpose |
| --- | --- |
| Flutter and Dart | App interface and application logic |
| Kotlin | Native Android sound control and background components |
| Provider | App and user state management |
| Flutter Secure Storage | Session information and guest schedule storage |
| Shared Preferences | Settings, native-readable schedules, and location zones |
| HTTP and Dio | External API and place-search requests |
| Flutter Map and LatLong2 | Map display and coordinates |
| Geolocator | Device location and distance checks |
| FL Chart | Statistics visualizations |
| Image Picker | Profile image selection |
| Google Fonts | Typography |

## Architecture

The Flutter UI uses providers to manage schedules and user state. Guest schedules are stored locally; signed-in schedules are requested from an external REST API. Schedule data is also written to Shared Preferences for Android background components to read.

`RingerService` communicates with `MainActivity` using the method channel `com.autosilence.app/ringer`. Native components apply sound modes and perform periodic checks. Location zones are stored separately on the device.

The backend source and database configuration are **not included** in this repository. Client code expects a MongoDB-style `_id` field in schedule responses, but the server implementation cannot be verified from this repository alone.

## Getting Started

### Requirements

- Flutter SDK with a Dart version satisfying `^3.7.2`.
- Android Studio and Android SDK 36, matching the current build configuration.
- JDK 17, matching the Android Java/Kotlin target.
- An Android device or emulator; a physical device is preferable for checking sound modes and location behavior.
- Internet access for account features, map tiles, and place search.

The native sound-control implementation is Android-specific. An iOS project is present, but equivalent iOS ringer-control code is not included.

### 1. Clone and Install Dependencies

```bash
git clone https://github.com/AhmedMemon7x/Silenz-App-Hackathon-Project.git
cd Silenz-App-Hackathon-Project
flutter pub get
```

If you rename the repository, update the clone URL and directory name accordingly.

### 2. Configure the API

The client currently contains hard-coded Railway API URLs. To use your own compatible backend, update the base URL consistently in:

- `lib/services/auth_service.dart`
- `lib/services/schedule_service.dart`
- `lib/providers/user_provider.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/stats_screen.dart`

Most paths currently use `https://autosilence-backend-production.up.railway.app/api`. The statistics screen uses a differently spelled hostname, which should be corrected to your intended API URL.

The repository does not provide a `.env` configuration flow. Guest mode can be used without an account backend; account functions require a compatible, reachable server.

### 3. Run on Android

```bash
flutter doctor
flutter devices
flutter run
```

For a particular device:

```bash
flutter run -d DEVICE_ID
```

### 4. Configure Device Access

- Grant **Do Not Disturb access** through the app's permission flow.
- Enable location services and grant location access for location zones.
- Review background location, notification, and battery settings when testing background behavior.
- Check exact-alarm access if required by the device's Android settings.

Declaring permissions in the manifest does not grant them automatically. Background behavior depends on Android restrictions, granted access, and the device manufacturer's power management.

### Build an APK

```bash
flutter build apk --release
```

Expected output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

The current release build configuration uses debug signing. Configure your own release signing before distributing a production build.

## User Flow

1. Open Silenz and complete the permission setup.
2. Continue as a guest or sign in to an account.
3. Create a recurring schedule and choose its sound mode.
4. Optionally add a location zone from the map.
5. Enable the desired rules.
6. Review schedules, profile details, and statistics from the app.

## Project Organization

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | App startup, providers, theme selection, and routing |
| `lib/screens/` | Dashboard, schedules, maps, authentication, profile, statistics, and settings |
| `lib/providers/` | App and user state |
| `lib/services/` | Authentication, schedule persistence, schedule checking, and ringer bridge |
| `lib/models/` | Schedule model and JSON conversion |
| `lib/widgets/` | Shared navigation components |
| `lib/app_theme.dart` | Theme and color definitions |
| `android/` | Kotlin integration, manifest, receivers, service, and build configuration |
| `ios/` | Flutter iOS project |
| `assets/` | App icon assets |
| `test/` | Existing widget test |

## Current Implementation Notes

- Background location checking uses last-known device locations, which can be stale. The code does not guarantee immediate zone-entry detection.
- Time checks, foreground location checks, and native checks can apply different modes. A unified priority policy is needed for overlapping schedules and zones.
- Native zone checks take precedence over time schedules within `SilenceService`, while the foreground location screen restores Normal mode outside zones.
- Normal mode does not consistently restore previously saved volume levels across native paths.
- Guest-to-account sync currently clears local guest storage on some request failures. Preserve local data until synchronization is confirmed before relying on this flow.
- Google sign-in code is commented out and is not an active feature.
- Guest statistics estimate configured schedule hours rather than measuring actual silence usage.
- The settings screen contains a theme toggle marked as UI-only, separate from the provider's theme state.
- The existing widget test still expects a counter demonstration and needs replacement with tests for the actual app.

## Development Checks

```bash
flutter analyze
flutter test
```

These commands are provided for local validation. Android builds, device permissions, backend availability, and tests were not verified during this README preparation.

## Author

**Ahmed Memon** — [GitHub](https://github.com/AhmedMemon7x)

Developed as a hackathon project to make phone sound management more convenient.
