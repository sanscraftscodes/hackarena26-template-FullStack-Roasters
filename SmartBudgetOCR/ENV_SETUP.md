# Environment Setup Guide

## Overview
This project uses a `.env` file to manage sensitive credentials and configuration. The `.env` file is **NOT** committed to git for security reasons.

## Setup Instructions

### 1. Create `.env` File
- Copy `.env.example` to `.env`:
  ```bash
  cp .env.example .env
  ```

### 2. Fill in Your Credentials
Edit the `.env` file and replace all placeholder values with your actual credentials:

#### Firebase Configuration
- Get your Firebase credentials from:
  1. Go to [Firebase Console](https://console.firebase.google.com/)
  2. Select your project
  3. Go to Project Settings
  4. Copy the web configuration values into the corresponding `.env` variables

#### Android Configuration
- `ANDROID_SDK_PATH`: Path to your Android SDK installation
- `FLUTTER_SDK_PATH`: Path to your Flutter SDK installation
- Check your `android/local.properties` file for these paths

#### Gemini API Key
- Get your API key from [Google AI Studio](https://aistudio.google.com/apikey)

#### Backend API
- Set `BACKEND_API_URL` to your backend server URL

### 3. Firebase Configuration Files
The following files contain sensitive information and should NOT be committed:
- `android/app/src/google-services.json` - Android Firebase config
- `ios/GoogleService-Info.plist` - iOS Firebase config
- `android/local.properties` - Local Android configuration

These files are ignored by `.gitignore` but needed locally. Obtain these from your Firebase Console or project team.

### 4. Running the App
Once `.env` is configured with your credentials, the app will use these values.

## Important Security Notes
- ⚠️ **NEVER** commit `.env` file to git
- ⚠️ **NEVER** share your `.env` file or credentials
- ⚠️ Always use `.env.example` as a template for new developers
- ⚠️ If credentials are compromised, regenerate them immediately

## Gitignore Rules
The following are already in `.gitignore`:
```
.env
.env.local
.env.*.local
SmartBudgetOCR/.env
SmartBudgetOCR/google-services.json
SmartBudgetOCR/android/app/src/google-services.json
SmartBudgetOCR/ios/GoogleService-Info.plist
SmartBudgetOCR/android/local.properties
```
