# Web & Desktop Deployment Guide

Complete guide for deploying the Workout Wizard app to web and desktop platforms (Windows, macOS, Linux).

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Web Deployment](#web-deployment)
3. [Windows Desktop](#windows-desktop)
4. [macOS Desktop](#macos-desktop)
5. [Linux Desktop](#linux-desktop)
6. [Model Setup](#model-setup)
7. [Configuration](#configuration)
8. [Testing](#testing)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software
- **Flutter SDK**: 3.0.0 or higher
- **Dart SDK**: Included with Flutter
- **Git**: For version control

### Platform-Specific Requirements

**Web:**
- Chrome 90+ (for development and testing)
- Web server (for production deployment)

**Windows:**
- Windows 10 or later
- Visual Studio 2019 or later (with "Desktop development with C++" workload)
- CMake 3.15 or higher

**macOS:**
- macOS 10.14 or later
- Xcode 12 or later
- CocoaPods 1.10.0 or higher

**Linux:**
- Ubuntu 18.04 or later (or equivalent)
- Clang or GCC
- GTK+ 3.0 development libraries
- pkg-config

### Install Platform Support

```bash
# Enable web support
flutter config --enable-web

# Enable Windows desktop support (Windows only)
flutter config --enable-windows-desktop

# Enable macOS desktop support (macOS only)
flutter config --enable-macos-desktop

# Enable Linux desktop support (Linux only)
flutter config --enable-linux-desktop

# Verify enabled platforms
flutter devices
```

---

## Web Deployment

### 1. Setup MoveNet Model for Web

The web version uses TensorFlow Lite for pose detection. You need to download the MoveNet model:

```bash
# Create models directory
mkdir -p fitness_frontend/assets/models

# Download MoveNet Lightning model (recommended for web)
cd fitness_frontend/assets/models
curl -L -o movenet_lightning.tflite \
  https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/lightning/tflite/float16/4.tflite

# Optional: Download Thunder model (more accurate but slower)
curl -L -o movenet_thunder.tflite \
  https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/thunder/tflite/float16/4.tflite
```

### 2. Update pubspec.yaml

Ensure the model is included in assets:

```yaml
flutter:
  assets:
    - assets/data/programs_database.json
    - assets/data/exercise_form_rules.json
    - assets/models/movenet_lightning.tflite
    - assets/models/movenet_thunder.tflite
```

### 3. Build for Web

```bash
cd fitness_frontend

# Development build (with debugging)
flutter build web --web-renderer html

# Production build (optimized)
flutter build web --release --web-renderer html

# Build with specific base href (for subdirectory hosting)
flutter build web --release --base-href /workout-wizard/
```

**Build Output:** `fitness_frontend/build/web/`

### 4. Web Renderers

Flutter supports two web renderers:

**HTML Renderer (Recommended):**
```bash
flutter build web --web-renderer html
```
- Better compatibility
- Smaller download size
- Works on all browsers
- Recommended for this app

**CanvasKit Renderer:**
```bash
flutter build web --web-renderer canvaskit
```
- Better performance
- Larger download size (~2MB additional)
- May have compatibility issues

**Auto (Default):**
```bash
flutter build web --web-renderer auto
```
- Uses HTML on mobile browsers
- Uses CanvasKit on desktop browsers

### 5. Local Testing

```bash
# Run development server
cd fitness_frontend
flutter run -d chrome

# Or use Python HTTP server
cd fitness_frontend/build/web
python3 -m http.server 8000

# Access at http://localhost:8000
```

### 6. Production Deployment Options

#### Option A: Firebase Hosting

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize Firebase
cd fitness_frontend
firebase login
firebase init hosting

# Select build/web as public directory
# Configure as single-page app: Yes
# Set up automatic builds: Optional

# Deploy
firebase deploy --only hosting

# Your app is live at: https://your-project.web.app
```

#### Option B: Netlify

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
cd fitness_frontend/build/web
netlify deploy --prod

# Follow prompts to link/create site
```

#### Option C: GitHub Pages

```bash
# Build with correct base href
flutter build web --release --base-href /workout-wizard/

# Copy to GitHub Pages directory
cp -r build/web/* ../docs/

# Commit and push
git add ../docs
git commit -m "Deploy web app"
git push

# Enable GitHub Pages in repository settings
# Set source to /docs folder
```

#### Option D: Traditional Web Server (Apache/Nginx)

**Nginx Configuration:**
```nginx
server {
    listen 80;
    server_name workout-wizard.example.com;
    root /var/www/workout-wizard;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Enable gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

**Apache Configuration (.htaccess):**
```apache
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /
    RewriteRule ^index\.html$ - [L]
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /index.html [L]
</IfModule>

# Enable compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript
</IfModule>

# Cache static assets
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType image/jpg "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
</IfModule>
```

### 7. Web Permissions

The web app requires camera permission. Ensure:
1. **HTTPS Required:** Camera API only works on HTTPS (except localhost)
2. **Permissions Policy:** Modern browsers require explicit permission
3. **User Gesture:** Camera access must be triggered by user interaction

Add to `web/index.html`:
```html
<meta http-equiv="Permissions-Policy" content="camera=()">
```

---

## Windows Desktop

### 1. Prerequisites

```powershell
# Install Visual Studio 2019 or later
# Ensure "Desktop development with C++" workload is installed

# Verify installation
flutter doctor -v
```

### 2. Build for Windows

```bash
cd fitness_frontend

# Development build
flutter build windows

# Release build
flutter build windows --release

# Build output: build/windows/runner/Release/
```

### 3. Application Structure

```
build/windows/runner/Release/
├── fitness_frontend.exe          # Main executable
├── flutter_windows.dll           # Flutter engine
├── data/                         # App data
│   ├── icudtl.dat
│   └── flutter_assets/           # Your assets
└── [other DLLs]                  # Dependencies
```

### 4. Creating Installer (NSIS)

Install [NSIS](https://nsis.sourceforge.io/):

Create `installer.nsi`:
```nsis
!define APP_NAME "Workout Wizard"
!define APP_VERSION "1.0.0"
!define APP_PUBLISHER "Your Company"
!define APP_EXECUTABLE "fitness_frontend.exe"

OutFile "WorkoutWizard_Setup.exe"
InstallDir "$PROGRAMFILES64\${APP_NAME}"

Section "Install"
    SetOutPath "$INSTDIR"
    File /r "build\windows\runner\Release\*.*"

    CreateShortcut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXECUTABLE}"
    CreateDirectory "$SMPROGRAMS\${APP_NAME}"
    CreateShortcut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXECUTABLE}"
SectionEnd

Section "Uninstall"
    Delete "$DESKTOP\${APP_NAME}.lnk"
    Delete "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk"
    RMDir "$SMPROGRAMS\${APP_NAME}"
    RMDir /r "$INSTDIR"
SectionEnd
```

Build installer:
```bash
makensis installer.nsi
```

### 5. MSIX Package (Windows Store)

```bash
# Install dependencies
flutter pub add --dev msix

# Configure in pubspec.yaml
msix_config:
  display_name: Workout Wizard
  publisher_display_name: Your Company
  identity_name: com.yourcompany.workoutwizard
  logo_path: assets/icon.png
  capabilities: webcam

# Build MSIX package
flutter pub run msix:create

# Output: build/windows/runner/Release/fitness_frontend.msix
```

---

## macOS Desktop

### 1. Prerequisites

```bash
# Install Xcode from App Store

# Install CocoaPods
sudo gem install cocoapods

# Verify
flutter doctor -v
```

### 2. Configure Entitlements

Edit `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.security.device.camera</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

### 3. Update Info.plist

Edit `macos/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access for exercise form analysis</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app uses audio feedback for workout guidance</string>
```

### 4. Build for macOS

```bash
cd fitness_frontend

# Development build
flutter build macos

# Release build
flutter build macos --release

# Output: build/macos/Build/Products/Release/fitness_frontend.app
```

### 5. Code Signing (Required for Distribution)

```bash
# List available signing identities
security find-identity -v -p codesigning

# Sign the app
codesign --force --deep --sign "Developer ID Application: Your Name" \
    build/macos/Build/Products/Release/fitness_frontend.app

# Verify signature
codesign -vvv --deep --strict build/macos/Build/Products/Release/fitness_frontend.app
```

### 6. Creating DMG Installer

```bash
# Install create-dmg
brew install create-dmg

# Create DMG
create-dmg \
    --volname "Workout Wizard" \
    --window-pos 200 120 \
    --window-size 800 400 \
    --icon-size 100 \
    --icon "fitness_frontend.app" 200 190 \
    --hide-extension "fitness_frontend.app" \
    --app-drop-link 600 185 \
    "WorkoutWizard.dmg" \
    "build/macos/Build/Products/Release/fitness_frontend.app"
```

### 7. Notarization (Required for macOS 10.15+)

```bash
# Create app-specific password at appleid.apple.com

# Notarize
xcrun altool --notarize-app \
    --primary-bundle-id "com.yourcompany.workoutwizard" \
    --username "your-email@example.com" \
    --password "@keychain:AC_PASSWORD" \
    --file WorkoutWizard.dmg

# Check status (use RequestUUID from previous command)
xcrun altool --notarization-info <RequestUUID> \
    --username "your-email@example.com" \
    --password "@keychain:AC_PASSWORD"

# Staple notarization
xcrun stapler staple WorkoutWizard.dmg
```

---

## Linux Desktop

### 1. Prerequisites (Ubuntu/Debian)

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev

# Verify
flutter doctor -v
```

### 2. Build for Linux

```bash
cd fitness_frontend

# Development build
flutter build linux

# Release build
flutter build linux --release

# Output: build/linux/x64/release/bundle/
```

### 3. Application Structure

```
build/linux/x64/release/bundle/
├── fitness_frontend              # Executable
├── lib/                          # Shared libraries
└── data/                         # App data
    └── flutter_assets/           # Your assets
```

### 4. Creating .deb Package

Create `debian/control`:
```
Package: workout-wizard
Version: 1.0.0
Architecture: amd64
Maintainer: Your Name <your.email@example.com>
Description: AI-powered workout form correction
 Workout Wizard uses computer vision to analyze and correct
 your exercise form in real-time.
Depends: libgtk-3-0, libgstreamer1.0-0
```

Create package:
```bash
# Create directory structure
mkdir -p workout-wizard_1.0.0_amd64/DEBIAN
mkdir -p workout-wizard_1.0.0_amd64/usr/local/bin
mkdir -p workout-wizard_1.0.0_amd64/usr/share/applications

# Copy files
cp debian/control workout-wizard_1.0.0_amd64/DEBIAN/
cp -r build/linux/x64/release/bundle/* workout-wizard_1.0.0_amd64/usr/local/bin/

# Create desktop entry
cat > workout-wizard_1.0.0_amd64/usr/share/applications/workout-wizard.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Workout Wizard
Comment=AI-powered workout form correction
Exec=/usr/local/bin/fitness_frontend
Icon=workout-wizard
Categories=Health;Sports;
EOF

# Build package
dpkg-deb --build workout-wizard_1.0.0_amd64

# Output: workout-wizard_1.0.0_amd64.deb
```

### 5. Creating AppImage

```bash
# Install appimagetool
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage

# Create AppDir structure
mkdir -p WorkoutWizard.AppDir/usr/bin
mkdir -p WorkoutWizard.AppDir/usr/lib

# Copy application
cp -r build/linux/x64/release/bundle/* WorkoutWizard.AppDir/usr/bin/

# Create AppRun script
cat > WorkoutWizard.AppDir/AppRun <<'EOF'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin/:${HERE}/usr/sbin/:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib/:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/fitness_frontend" "$@"
EOF
chmod +x WorkoutWizard.AppDir/AppRun

# Create desktop file
cat > WorkoutWizard.AppDir/workout-wizard.desktop <<EOF
[Desktop Entry]
Name=Workout Wizard
Exec=fitness_frontend
Icon=workout-wizard
Type=Application
Categories=Health;Sports;
EOF

# Build AppImage
./appimagetool-x86_64.AppImage WorkoutWizard.AppDir WorkoutWizard-x86_64.AppImage
```

---

## Model Setup

### Download Pre-trained Models

The app requires TensorFlow Lite models for pose detection on non-mobile platforms:

```bash
cd fitness_frontend/assets/models

# MoveNet Lightning (Fast, 192x192, ~6 MB)
wget https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/lightning/tflite/float16/4.tflite \
    -O movenet_lightning.tflite

# MoveNet Thunder (Accurate, 256x256, ~12 MB)
wget https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/thunder/tflite/float16/4.tflite \
    -O movenet_thunder.tflite
```

### Model Comparison

| Model | Size | Input | FPS (Desktop) | FPS (Web) | Accuracy |
|-------|------|-------|---------------|-----------|----------|
| Lightning | 6 MB | 192x192 | 24-30 | 12-15 | Good |
| Thunder | 12 MB | 256x256 | 15-20 | 8-12 | Excellent |

**Recommendation:** Use Lightning for production, Thunder for high-accuracy scenarios.

---

## Configuration

### Environment Variables

Create `.env` file (if using environment-based config):

```bash
# API Configuration
API_BASE_URL=https://api.workoutwizard.com
API_TIMEOUT=30000

# Feature Flags
ENABLE_ANALYTICS=true
ENABLE_AUDIO_FEEDBACK=true
ENABLE_VIDEO_RECORDING=true

# Performance
DEFAULT_FRAME_SKIP=2
DEFAULT_RESOLUTION=medium
```

### Platform-Specific Settings

Edit platform configuration files:

**Web** (`web/index.html`):
```html
<script>
  window.flutterConfiguration = {
    canvasKitBaseUrl: "/canvaskit/"
  };
</script>
```

**Windows** (`windows/runner/main.cpp`):
```cpp
// Disable console window in release mode
#ifdef NDEBUG
  FreeConsole();
#endif
```

**macOS** (`macos/Runner/MainFlutterWindow.swift`):
```swift
// Set minimum window size
self.setContentSize(NSSize(width: 1280, height: 720))
self.setContentMinSize(NSSize(width: 800, height: 600))
```

---

## Testing

### Cross-Platform Testing Checklist

- [ ] Camera access works on all platforms
- [ ] Pose detection runs smoothly (≥15 FPS)
- [ ] Audio feedback plays correctly
- [ ] Video recording works (mobile/desktop)
- [ ] Data persistence works
- [ ] Export/share functionality works
- [ ] UI scales properly on different screen sizes
- [ ] Keyboard shortcuts work (desktop)
- [ ] All 30 exercises are recognized
- [ ] Fuzzy name matching works
- [ ] Performance is acceptable on target devices

### Automated Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Performance tests
flutter run --profile -d <device> --trace-startup
```

### Browser Testing (Web)

Test on multiple browsers:
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

### Desktop Testing

Test on different OS versions:
- Windows 10, 11
- macOS 10.14+
- Ubuntu 18.04, 20.04, 22.04

---

## Troubleshooting

### Common Issues

#### Web: Camera not working
**Symptoms:** Camera permission denied or not available
**Solutions:**
1. Ensure site is served over HTTPS
2. Check browser permissions
3. Test on localhost first
4. Clear browser cache
5. Try different browser

#### Web: Slow performance
**Symptoms:** Low FPS, stuttering
**Solutions:**
1. Use HTML renderer instead of CanvasKit
2. Reduce camera resolution
3. Increase frame skip count
4. Check browser console for errors
5. Test on desktop browser

#### Windows: Missing DLLs
**Symptoms:** App won't start, DLL errors
**Solutions:**
1. Ensure all DLLs are in same directory as .exe
2. Install Visual C++ Redistributable
3. Rebuild with `flutter build windows --release`

#### macOS: App won't open
**Symptoms:** "App is damaged" or security warning
**Solutions:**
1. Right-click → Open (first time)
2. System Preferences → Security → Allow
3. Code sign the app properly
4. Notarize the app for distribution

#### Linux: GTK errors
**Symptoms:** Crash on startup, missing libraries
**Solutions:**
1. Install GTK3: `sudo apt-get install libgtk-3-0`
2. Install GStreamer: `sudo apt-get install libgstreamer1.0-0`
3. Check `ldd` output for missing dependencies

#### All Platforms: Model not loading
**Symptoms:** Pose detection fails
**Solutions:**
1. Verify model files in assets/models/
2. Check pubspec.yaml includes models
3. Run `flutter clean && flutter build`
4. Verify model file integrity

### Debug Mode

Enable debug logging:

```dart
// In main.dart
void main() {
  if (kDebugMode) {
    print('Platform: ${PlatformPerformanceConfig.getOptimizedConfig().platformName}');
    print('Performance: ${PlatformPerformanceConfig.getOptimizedConfig()}');
  }
  runApp(const FitnessRecommenderApp());
}
```

---

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Performance benchmarks met
- [ ] Models downloaded and included
- [ ] Assets properly configured
- [ ] Environment variables set
- [ ] Version numbers updated
- [ ] Changelog updated

### Web Deployment
- [ ] Build with `--release` flag
- [ ] Test on multiple browsers
- [ ] Configure HTTPS
- [ ] Set up CDN (optional)
- [ ] Configure caching headers
- [ ] Test camera permissions
- [ ] Monitor analytics

### Desktop Deployment
- [ ] Code signing configured
- [ ] Installer/package created
- [ ] Icon and assets included
- [ ] Version info updated
- [ ] License file included
- [ ] Uninstaller works
- [ ] Desktop shortcuts created

---

## Support & Resources

### Documentation
- [Flutter Web Deployment](https://flutter.dev/docs/deployment/web)
- [Flutter Desktop Support](https://flutter.dev/desktop)
- [TensorFlow Lite](https://www.tensorflow.org/lite)
- [MoveNet Model](https://tfhub.dev/google/movenet/singlepose/lightning/4)

### Community
- GitHub Issues: Report bugs and feature requests
- Discord/Slack: Community support
- Stack Overflow: Technical questions

### Professional Support
For enterprise deployment assistance, contact: support@workoutwizard.com

---

**Last Updated:** 2025-12-16
**Version:** 1.0.0
**Maintainer:** Workout Wizard Team
