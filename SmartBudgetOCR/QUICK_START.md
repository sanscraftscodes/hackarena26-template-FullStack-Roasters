# Quick Start - SnapBudget OCR

## ⚡ Get Running in 5 Minutes

### Step 1: Get Web Client ID (5 min)
This is the only blocking issue. The app has been fixed and is ready to run!

1. Go to: https://console.cloud.google.com
2. Select project: **smartocr-5610d**
3. Left menu → **APIs & Services** → **Credentials**
4. Find or create "OAuth 2.0 Client ID" (Web application)
5. Copy your Client ID (looks like: `123456-abc.apps.googleusercontent.com`)

### Step 2: Configure Web (2 min)
1. Open: `SmartBudgetOCR/web/index.html`
2. Find: `content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"`
3. Replace with your actual Client ID from Step 1
4. Save file

### Step 3: Get Dependencies (2 min)
```bash
cd SmartBudgetOCR
flutter pub get
```

### Step 4: Run (Pick Your Target)

**Web (Chrome)**
```bash
flutter run -d chrome
```

**Android Emulator**
```bash
flutter run -d emulator
```

**iOS Simulator**
```bash
flutter run -d ios
```

**Windows Desktop**
```bash
flutter run -d windows
```

---

## What Was Fixed? ✅

| Issue | Status | Fix |
|-------|--------|-----|
| Google Sign-In Web error | ✅ FIXED | Added platform-aware initialization and meta tag |
| Service initialization errors | ✅ FIXED | Changed to lazy loading with error handling |
| Firebase initialization crash | ✅ FIXED | Added try-catch with graceful fallback |
| Android config | ✅ READY | google-services.json in place |
| iOS config | ✅ READY | GoogleService-Info.plist in place |

---

## Documentation Files

- **SETUP_GUIDE.md** - Detailed setup with troubleshooting
- **FIXES_APPLIED.md** - Technical details of all changes
- **This file** - Quick start guide

---

## Common Issues?

❌ **"ClientID not set" error**
→ You forgot step 2! Replace `YOUR_WEB_CLIENT_ID` in `web/index.html`

❌ **"Redirect URI Mismatch"**
→ In Google Cloud Console, add `http://localhost:7777` to Authorized JavaScript Origins

❌ **Can't find my Client ID**
→ Check SETUP_GUIDE.md Step 1-5 for detailed instructions

---

## Need Help?

1. Run with verbose logging: `flutter run --verbose`
2. Check device logs: Device console or `adb logcat` (Android)
3. See **SETUP_GUIDE.md** for full troubleshooting

---

**Ready? Start with Step 1 above! 🚀**
