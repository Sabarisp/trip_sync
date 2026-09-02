# Setup Guide

This repo currently contains the app's Dart source (`lib/`) and a `macos/`
platform folder, but **not** `android/` or `ios/` — those get generated
locally, since they contain machine-specific build files that don't belong
in git. Follow these steps in order.

## 1. Get the Flutter SDK

Install Flutter 3.27+ / Dart 3.9+ if you don't already have it:
https://docs.flutter.dev/get-started/install

Verify:
```bash
flutter doctor
```

## 2. Generate the missing native platforms

From the project root:
```bash
flutter create --platforms=android,ios .
```
This is safe to run on an existing project — it only adds the missing
`android/` and `ios/` folders, it won't touch `lib/` or `pubspec.yaml`.

## 3. Install dependencies
```bash
flutter pub get
```

## 4. Set up Firebase

1. Create a project at https://console.firebase.google.com
2. Enable **Authentication → Email/Password**
3. Enable **Firestore Database** (start in production mode, then apply the
   rules below)
4. Enable **Cloud Messaging** if you want push notifications
5. Install the FlutterFire CLI and connect the app:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` and downloads
   `google-services.json` / `GoogleService-Info.plist` into the right native
   folders automatically. (These are gitignored on purpose — don't commit
   them.)
6. Update `lib/main.dart` to use the generated options:
   ```dart
   import 'firebase_options.dart';
   // ...
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```

## 5. Apply Firestore security rules

Deploy `firestore.rules` from this repo:
```bash
firebase deploy --only firestore:rules
```
(requires `firebase login` and `firebase init` with this project selected
first, if you haven't already)

## 6. Add location permissions

### Android — `android/app/src/main/AndroidManifest.xml`
Add inside `<manifest>`, above `<application>`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### iOS — `ios/Runner/Info.plist`
Add inside the outer `<dict>`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Trip Sync needs your location to share it with your travel group.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Trip Sync needs your location in the background to keep your group updated.</string>
```

## 7. Run it
```bash
flutter run
```

## 8. Ship it

- **Android**: `flutter build appbundle --release` → upload to Google Play
  Console (internal testing track first).
- **iOS**: `flutter build ipa --release` → upload via Xcode/Transporter to
  App Store Connect, start with TestFlight.
- **Web**: `flutter build web --release` → deploy the `build/web` folder to
  Firebase Hosting (`firebase deploy --only hosting`), Netlify, or Vercel.

Push notifications, background location, and app-store review all have
their own platform-specific gotchas — happy to walk through whichever one
you hit first once you're at that stage.
