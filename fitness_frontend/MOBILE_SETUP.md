# Mobile Setup Guide - Workout Wizard

## Overview

Your Fitness Recommendation app is now **mobile-ready**! The same Flutter codebase runs on:
- ✅ Web (Chrome, Edge, Safari)
- ✅ Android (Phone, Tablet, Emulator)
- ✅ iOS (iPhone, iPad, Simulator)

---

## Quick Start

### Prerequisites
- Flutter SDK installed
- Backend running at `http://localhost:8000`
- For Android: Android Studio with emulator
- For iOS: Xcode (Mac only)

### Run on Android
```bash
cd fitness_frontend

# Run on Android emulator (must be started first)
flutter run -d android

# OR build APK for physical device
flutter build apk --release
```

### Run on iOS (Mac only)
```bash
cd fitness_frontend

# Run on iOS simulator
flutter run -d ios

# OR build for physical device
flutter build ios --release
```

### Run on Web
```bash
cd fitness_frontend
flutter run -d chrome
```

---

## Detailed Setup

### 1. Backend Configuration

The app needs to connect to your backend API. Update `lib/services/api_service.dart`:

#### For Android Emulator:
```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```
**Why?** `10.0.2.2` is the emulator's special alias for your computer's localhost.

#### For iOS Simulator:
```dart
static const String baseUrl = 'http://localhost:8000';
```

#### For Physical Device (Same WiFi Network):
```dart
static const String baseUrl = 'http://192.168.1.XXX:8000';
```
**Replace XXX** with your computer's local IP address.

**Find your IP:**
- Windows: `ipconfig` (look for IPv4 Address)
- Mac/Linux: `ifconfig` or `ip addr show`

#### For Production:
```dart
static const String baseUrl = 'https://your-api.onrender.com';
```

---

## Android Setup

### 1. Install Android Studio
Download from: https://developer.android.com/studio

### 2. Setup Android Emulator
```bash
# List available emulators
flutter emulators

# Create new emulator (if none exist)
# Open Android Studio > Tools > Device Manager > Create Device

# Start emulator
flutter emulators --launch <emulator_name>
```

### 3. Enable Developer Mode on Physical Device
1. Go to Settings > About Phone
2. Tap "Build Number" 7 times
3. Enable USB Debugging in Developer Options
4. Connect device via USB

### 4. Run App
```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run on any connected Android device
flutter run -d android
```

### 5. Build APK for Distribution
```bash
# Build release APK
flutter build apk --release

# APK location: build/app/outputs/flutter-apk/app-release.apk

# Install on connected device
flutter install
```

### 6. Build App Bundle (for Play Store)
```bash
flutter build appbundle --release

# Bundle location: build/app/outputs/bundle/release/app-release.aab
```

---

## iOS Setup (Mac Only)

### 1. Install Xcode
Download from App Store or: https://developer.apple.com/xcode/

### 2. Install Xcode Command Line Tools
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### 3. Open iOS Simulator
```bash
# List available simulators
flutter emulators

# Launch simulator
open -a Simulator

# OR
flutter emulators --launch apple_ios_simulator
```

### 4. Run App on Simulator
```bash
flutter run -d ios
```

### 5. Run on Physical Device
1. Connect iPhone/iPad via USB
2. Trust computer on device
3. In Xcode: Set Development Team (requires Apple ID)
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner project
   - Signing & Capabilities > Team > Add your Apple ID

```bash
flutter run -d ios
```

### 6. Build for TestFlight/App Store
```bash
flutter build ios --release

# Then in Xcode:
# Product > Archive > Distribute App
```

---

## Testing on Different Platforms

### Check Connected Devices
```bash
flutter devices
```

Output example:
```
3 connected devices:

sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64    • Android 13 (API 33) (emulator)
iPhone 14 Pro (mobile)       • 12345678-ABCD  • ios           • com.apple.CoreSimulator.SimRuntime.iOS-16-0 (simulator)
Chrome (web)                 • chrome         • web-javascript • Google Chrome 120.0.6099.129
```

### Run on Specific Device
```bash
# Android emulator
flutter run -d emulator-5554

# iOS simulator
flutter run -d 12345678-ABCD

# Web
flutter run -d chrome
```

### Hot Reload
While app is running:
- Press `r` - Hot reload (fast)
- Press `R` - Hot restart (slow, full restart)
- Press `q` - Quit

---

## Network Configuration

### Backend Must Be Running
```bash
# In backend directory
python run_backend.py
```

### Test Backend Connection
```bash
# From your computer
curl http://localhost:8000/health

# From Android emulator
# Use adb to access emulator shell
adb shell
curl http://10.0.2.2:8000/health

# From iOS simulator
curl http://localhost:8000/health
```

### Allow Backend on Firewall
**Windows:**
```powershell
# Allow Python through firewall
netsh advfirewall firewall add rule name="Python Backend" dir=in action=allow program="C:\Python312\python.exe" enable=yes
```

**Mac:**
```bash
# System Preferences > Security & Privacy > Firewall > Firewall Options
# Add Python to allowed apps
```

---

## Troubleshooting

### Issue 1: Cannot Connect to Backend

**Android Emulator:**
- ✅ Use `http://10.0.2.2:8000` not `localhost`
- ✅ Backend must be running
- ✅ Check firewall allows connections

**iOS Simulator:**
- ✅ Use `http://localhost:8000`
- ✅ Backend must be running

**Physical Device:**
- ✅ Use your computer's IP: `http://192.168.1.XXX:8000`
- ✅ Device and computer must be on same WiFi
- ✅ Firewall must allow incoming connections

### Issue 2: Build Failed

**Android:**
```bash
# Clean build
flutter clean
flutter pub get
flutter build apk --release
```

**iOS:**
```bash
# Clean build
cd ios
pod install
cd ..
flutter clean
flutter pub get
flutter build ios --release
```

### Issue 3: Permission Denied (iOS)

**Solution:**
- Open `ios/Runner.xcworkspace` in Xcode
- Select Runner target
- Signing & Capabilities
- Add your Apple Developer Team

### Issue 4: Network Permission Error (Android)

**Solution:**
- Already added in `android/app/src/main/AndroidManifest.xml`
- If missing, add:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### Issue 5: HTTP Not Allowed (iOS)

**Solution:**
- Already configured in `ios/Runner/Info.plist`
- `NSAppTransportSecurity` allows HTTP for development

---

## Building for Production

### Android Play Store

1. **Create Signing Key:**
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. **Configure Signing:**
Create `android/key.properties`:
```properties
storePassword=your-password
keyPassword=your-password
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

3. **Build App Bundle:**
```bash
flutter build appbundle --release
```

4. **Upload to Play Console:**
Upload `build/app/outputs/bundle/release/app-release.aab`

### iOS App Store

1. **Create App ID:**
- Apple Developer Portal > Certificates, IDs & Profiles

2. **Configure in Xcode:**
- Open `ios/Runner.xcworkspace`
- Set Bundle ID, Team, Version

3. **Archive:**
```bash
flutter build ios --release
```

4. **Distribute:**
- Open Xcode
- Product > Archive
- Distribute App > App Store Connect

---

## Performance Tips

### Optimize Build Size

**Android:**
```bash
# Split APKs by architecture
flutter build apk --split-per-abi --release
```

**iOS:**
```bash
# Already optimized by default
flutter build ios --release
```

### Enable Proguard (Android)
In `android/app/build.gradle`:
```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

---

## App Features

### ✅ Cross-Platform
- Same codebase for Web, Android, iOS
- Native performance on all platforms

### ✅ Responsive Design
- Adapts to phone, tablet, desktop
- Portrait and landscape support

### ✅ Material Design 3
- Modern UI following Google's guidelines
- Smooth animations and transitions

### ✅ API Integration
- Real-time recommendations from backend
- Error handling and loading states

---

## Development Workflow

### 1. Start Backend
```bash
cd c:\fitness_rms
python run_backend.py
```

### 2. Update API URL (if needed)
Edit `lib/services/api_service.dart` based on target platform

### 3. Run App
```bash
cd fitness_frontend

# Choose platform:
flutter run -d android    # Android
flutter run -d ios        # iOS
flutter run -d chrome     # Web
```

### 4. Make Changes
- Edit Dart files
- Press `r` for hot reload
- See changes instantly

### 5. Test on All Platforms
```bash
# Test each platform
flutter run -d android
flutter run -d ios
flutter run -d chrome

# Run tests
flutter test
```

---

## File Structure

```
fitness_frontend/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/
│   │   ├── user_profile.dart       # Data models
│   │   └── recommendation.dart
│   ├── screens/
│   │   ├── home_screen.dart        # Home page
│   │   ├── recommendation_form_screen.dart
│   │   └── results_screen.dart
│   └── services/
│       └── api_service.dart         # Backend API calls
├── android/                          # Android-specific files
│   └── app/src/main/AndroidManifest.xml
├── ios/                              # iOS-specific files
│   └── Runner/Info.plist
├── web/                              # Web-specific files
├── pubspec.yaml                      # Dependencies
└── MOBILE_SETUP.md                   # This file
```

---

## Quick Reference

### Commands
```bash
# Check Flutter setup
flutter doctor

# List devices
flutter devices

# Run app
flutter run -d <platform>

# Build for release
flutter build <platform> --release

# Clean project
flutter clean

# Get dependencies
flutter pub get

# Run tests
flutter test

# Analyze code
flutter analyze
```

### API URLs
- **Android Emulator:** `http://10.0.2.2:8000`
- **iOS Simulator:** `http://localhost:8000`
- **Physical Device:** `http://192.168.1.XXX:8000`
- **Production:** `https://your-api.com`

### Platforms
- `android` - Android devices/emulators
- `ios` - iOS devices/simulators (Mac only)
- `chrome` - Chrome browser
- `edge` - Edge browser
- `web-server` - Web server

---

## Support

### Documentation
- Flutter: https://docs.flutter.dev
- Android: https://developer.android.com
- iOS: https://developer.apple.com

### Common Issues
1. Backend not reachable → Check API URL and firewall
2. Build fails → Run `flutter clean` and rebuild
3. Signing issues → Configure in Xcode (iOS) or Android Studio

---

## Status

✅ **Mobile Ready!**

The app is fully configured for:
- ✅ Android phones and tablets
- ✅ iOS iPhones and iPads  
- ✅ Web browsers
- ✅ Development and production builds

**Next Steps:**
1. Start backend
2. Update API URL in code
3. Run on your preferred platform
4. Build and distribute!

---

**Happy coding! 🚀📱**

