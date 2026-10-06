<h1 align="center">Alcademy – Academic Platform for IGIT</h1>

A Flutter app for academic resources, college notices, and student utilities.

## Features

- Notes, syllabus, previous-year questions, and academic resources served through GitHub.
- College notices, results, academic calendar, holidays, and amenities.
- SGPA calculator and expense tracker.
- Local profile with a name and branch stored on the device.
- Private files and notes protected with device authentication.
- AI assistant with a user-provided Gemini API key.
- Firebase push notifications and notification history.

The app uses Firebase for notifications and GitHub for content and settings.
No backend account or environment file is required to start the app.

## Run on an Android phone

Use JDK 21 for Android builds. Configure Flutter with:

```bash
flutter config --jdk-dir=/path/to/jdk-21
```

On this Linux machine, the JDK is `/usr/lib/jvm/java-21-openjdk`.
Restart your IDE after changing Flutter's JDK setting.

Enable USB debugging on your phone, connect it with a data cable, and accept the
debugging authorization prompt. From the project directory, run:

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
```

Use the phone's ID from `flutter devices`. Android Firebase configuration is
included in `android/app/google-services.json` and `lib/firebase_options.dart`.
Online content and notifications require an internet connection. Set your Gemini
API key through the profile's API Key page to use the AI assistant.

## Validate

```bash
flutter analyze
flutter test
flutter build apk --debug
```
