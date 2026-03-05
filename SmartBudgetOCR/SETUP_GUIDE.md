# SnapBudget OCR - Setup Guide

## Overview
This guide helps you complete the configuration of SnapBudget OCR for Web and Android platforms.

## Critical: Google Sign-In Web Configuration

### Issue
The web app requires a Google OAuth 2.0 Client ID to enable Google Sign-In authentication. Without this, the web app will fail to initialize.

### Solution: Get Your Web Client ID

Follow these steps to obtain your Web Client ID from Google Cloud Console:

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com
   - Select your project: **smartocr-5610d**

2. **Navigate to Credentials**
   - Left sidebar → APIs & Services → Credentials
   - Look for OAuth 2.0 Client IDs section

3. **Create or Find Web Client ID**
   - If you have an existing web client, copy its Client ID
   - If not, create one:
     - Click "Create Credentials" → OAuth Client ID
     - Choose "Web application"
     - Name: "SnapBudget Web"
     - Authorized JavaScript Origins: Add your domains:
       - `http://localhost:7777` (for local development)
       - `http://127.0.0.1:7777`
     - Authorized Redirect URIs: Add:
       - `http://localhost:7777/`
       - `http://127.0.0.1:7777/`
     - Click Create

4. **Format Your Client ID**
   - Google Cloud gives you a full Client ID like: `XXXXXXXXX-YYYYYYYYYYYY.apps.googleusercontent.com`
   - This is what you need (including the .apps.googleusercontent.com part)

5. **Update web/index.html**
   - Open `SmartBudgetOCR/web/index.html`
   - Find this line: `<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">`
   - Replace `YOUR_WEB_CLIENT_ID.apps.googleusercontent.com` with your actual Client ID
   - Example: `<meta name="google-signin-client_id" content="123456789-abcdefghijk.apps.googleusercontent.com">`

6. **Save and Test**
   - Save the file
   - Run: `flutter pub get`
   - Run: `flutter run -d chrome` (or your target device)

## Platform-Specific Configuration

### Android
✅ **Already Configured**
- Google Services JSON: `android/app/google-services.json`
- Android Client ID: `641729749448-9fvubbop3gvuisapp9ooh1452kg17ptj.apps.googleusercontent.com`
- Package Name: `com.snapbudget.snapbudget_ocr`

**To test Android:**
```bash
flutter run -d android
```

### iOS
✅ **Already Configured**
- GoogleService-Info.plist: `ios/GoogleService-Info.plist`
- iOS Client ID: `641729749448-3q9h0m20s8optth1iti3rujfomtlstn2.apps.googleusercontent.com`
- Bundle ID: `com.snapbudget.snapbudgetOcr`

**To test iOS:**
```bash
flutter run -d ios
```

### Web
⚠️ **Requires Manual Configuration**
- Follow steps 1-6 above to configure Google Sign-In Client ID

**To test Web:**
```bash
flutter run -d chrome
# or
flutter run -d firefox
# or
flutter web
```

## Common Issues & Solutions

### "ClientID not set" Error
**Problem:** You see this error when running on web.
```
appClientId != null
"ClientID not set. Either set it on a <meta name=\"google-signin-client_id\"
content=\"CLIENT_ID\" /> tag, or pass clientId when initializing GoogleSignIn"
```

**Solution:** 
- Make sure you followed steps 1-6 above
- Verify the Client ID in `web/index.html` is correct
- Hard refresh your browser (Ctrl+Shift+R) or clear cache
- Make sure the Client ID includes `.apps.googleusercontent.com`

### "Redirect URI Mismatch" Error
**Problem:** Google Sign-In fails with redirect mismatch error.

**Solution:**
- In Google Cloud Console → Credentials → Your Web Client
- Edit the client
- Add your exact domain to "Authorized JavaScript Origins"
- Example for localhost: `http://localhost:7777`

### Firebase Not Initialized
**Problem:** Firebase initialization fails.

**Solution:**
- The app now handles this gracefully and continues
- Check that `firebase_options.dart` has the correct project ID: `smartocr-5610d`
- Verify internet connection is working

## Development Tools

### Running on Different Platforms
```bash
# Web (Chrome)
flutter run -d chrome

# Web (Firefox)
flutter run -d firefox

# Android Emulator
flutter run -d emulator

# iOS Simulator
flutter run -d ios-simulator

# Windows Desktop
flutter run -d windows
```

### Viewing Debug Output
```bash
# Enhanced logging
flutter run --verbose
```

### Building for Production
```bash
# Web
flutter build web

# Android
flutter build apk

# iOS
flutter build ios
```

## Offline Functionality

✅ **The app supports offline-first architecture:**
- Expenses are saved locally using SQLite
- Syncing occurs automatically when connectivity returns
- Works perfectly without initial Google Sign-In on some platforms

## Next Steps

1. ✅ Complete the Google Sign-In setup above
2. Run `flutter pub get` to ensure all dependencies are installed
3. Test on each platform:
   - `flutter run -d chrome` (Web)
   - `flutter run -d android` (Android)
   - `flutter run -d ios` (iOS)
4. Check the app runs and you can navigate through screens
5. Test Google Sign-In on web after setting up the Client ID

## Support

If you encounter any issues:
1. Check that all steps in this guide are completed
2. Run `flutter doctor` to verify your Flutter setup
3. Check `flutter run --verbose` output for detailed error messages
4. Verify internet connectivity and Google Cloud Console access

---

**Last Updated:** March 5, 2026
**Project:** SnapBudget OCR
**Firebase Project ID:** smartocr-5610d
