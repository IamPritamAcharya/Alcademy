<h1 align="center">Alcademy – Academic Platform for IGIT</h1>

A Flutter app for academic resources, college notices, and student utilities.

## Features

- Notes, syllabus, previous-year questions, and academic resources served through GitHub.
- College notices, results, academic calendar, holidays, and amenities.
- SGPA calculator and expense tracker.
- Local profile with a name and branch stored on the device.
- Optional ERP automatic login, with credentials managed in Profile and kept in device-encrypted storage.
- Private files and notes protected with device authentication.
- Firebase push notifications and notification history.

The app uses Firebase for notifications and GitHub for content and settings.
No backend account or environment file is required to start the app.

## Run on an Android phone

Use Flutter 3.47 or newer and JDK 21 for Android builds. Configure Flutter with:

```bash
flutter config --jdk-dir=/path/to/jdk-21
```

On this Linux machine, the JDK is `/usr/lib/jvm/java-21-openjdk`.
Restart your IDE after changing Flutter's JDK setting.

Android uses AGP 9 with built-in Kotlin (runtime pinned to 2.3.20), Java 17
bytecode, Flutter's compile SDK
(API 36 in Flutter 3.47), and Flutter's NDK (28.2.13676358 in Flutter 3.47).
The first build may install missing Android SDK and NDK components.
Local Gradle compatibility patches for in-app WebView and Firebase are documented
in each package's `third_party/*/PATCHES.md`. The upstream implementations and
licenses are preserved.

Enable USB debugging on your phone, connect it with a data cable, and accept the
debugging authorization prompt. From the project directory, run:

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
```

Use the phone's ID from `flutter devices`. Android Firebase configuration is
included in `android/app/google-services.json` and `lib/firebase_options.dart`.
Online content and notifications require an internet connection.

## Project structure

`lib/main.dart` starts the app. `lib/app/` owns bootstrap, routing, and the theme.
`lib/core/` contains shared configuration, networking, and cache helpers.
All GitHub repositories, branches, and content paths are configured in
`lib/core/network/github_sources.dart`. GitHub listings and downloaded JSON,
Markdown, and text use `lib/core/network/github_content_client.dart` for requests,
timeouts, status checks, and optional refresh cache busting. Feature repositories
retain their parsing and cache policies. All remote content now lives in this
repository's `content/` directory. Folder listings use the configured content
branch explicitly. Startup migrates old cached GitHub URLs while preserving the
selected note year; requests also rebase legacy download links.
`lib/shared/theme/app_style.dart` owns the app palette; `lib/app/theme.dart`
styles Material controls with the same always-dark colors.
`lib/features/` groups each feature's screens (`presentation`), repositories
(`data`), and models. Reusable UI lives in `lib/shared/widgets/`.
Images, fonts, and bundled syllabus data live under `assets/`. JSON examples used
by tests live under `test/fixtures/`.

Repositories keep the existing device preference keys and private-file locations,
so this refactor does not require clearing app data. Cached app settings are loaded
before startup; remote settings refresh in the background and notify open screens.

## Validate

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Tests cover cached notes, document expiry, blog refresh, local expenses, notice
parsing, and private-note metadata preservation. Screenshot tests cover onboarding,
profile, notes selection, expenses, and notices using the neutral dark theme and bundled
fonts at 430 × 932 pixels. Run them with the same Flutter SDK used to generate the
screenshots; review visual differences before updating golden files. Device rendering and native integrations still need
verification on the phone.

ERP credentials are used only to submit the college ERP login form over HTTPS.
They are excluded from Android cloud backup and device transfer. Forgetting them
disables automatic login without ending an existing web session. After adding
the secure-storage plugin, stop the app and run it again; hot reload cannot load
the native plugin. The ERP JavaScript execution test runs when Node.js is available.
