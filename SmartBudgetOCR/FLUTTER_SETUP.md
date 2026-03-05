# SnapBudget Flutter Setup

## Prerequisites
- Flutter SDK
- Firebase project
- Backend running (see backend README)

## 1. Firebase Configuration
Do NOT hardcode Firebase config. Use `firebase_options.dart`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `lib/firebase_options.dart` with your project config.

## 2. Backend URL
TODO: Replace BASE_URL via build:

```bash
flutter run --dart-define=BASE_URL=https://your-api.example.com
```

Or set default in `lib/core/config/app_config.dart` for development.

## 3. Run
```bash
flutter pub get
flutter run
```

Targets: Android, iOS, Web (configure Firebase for each platform in Firebase Console).
