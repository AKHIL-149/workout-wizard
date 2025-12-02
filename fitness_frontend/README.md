# Workout Wizard - Flutter Frontend

A beautiful, cross-platform fitness recommendation app built with Flutter.

## 🚀 Platforms Supported

- ✅ **Web** - Chrome, Edge, Safari, Firefox
- ✅ **Android** - Phones, Tablets, Emulators (API 21+)
- ✅ **iOS** - iPhone, iPad, Simulators (iOS 12+)
- ✅ **Desktop** - Windows, macOS, Linux (coming soon)

## 📱 Quick Start

### Prerequisites
```bash
# Check Flutter is installed
flutter doctor

# Install dependencies
cd fitness_frontend
flutter pub get
```

### Run on Different Platforms

#### Web
```bash
flutter run -d chrome
```

#### Android
```bash
# Start Android emulator first, then:
flutter run -d android
```

#### iOS (Mac only)
```bash
# Start iOS simulator first, then:
flutter run -d ios
```

## 🔧 Configuration

### Backend API URL
Edit `lib/services/api_service.dart` and set the correct URL:

```dart
// For Android emulator
static const String baseUrl = 'http://10.0.2.2:8000';

// For iOS simulator
static const String baseUrl = 'http://localhost:8000';

// For physical device (same WiFi as backend)
static const String baseUrl = 'http://192.168.1.XXX:8000';

// For production
static const String baseUrl = 'https://your-api.com';
```

## 📚 Documentation

- **[MOBILE_SETUP.md](MOBILE_SETUP.md)** - Complete mobile setup guide
- **[Flutter Docs](https://docs.flutter.dev)** - Official Flutter documentation

## 🏗️ Building for Release

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS App
```bash
flutter build ios --release
# Then use Xcode to archive and distribute
```

### Web
```bash
flutter build web --release
# Output: build/web/
```

## 🎨 Features

- ✅ Material Design 3 UI
- ✅ Responsive layout (mobile, tablet, desktop)
- ✅ Dark mode ready
- ✅ Smooth animations
- ✅ Real-time API integration
- ✅ Form validation
- ✅ Error handling
- ✅ Loading states

## 🛠️ Development

### Hot Reload
While app is running:
- Press `r` - Hot reload
- Press `R` - Hot restart
- Press `q` - Quit

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format .

# Run tests
flutter test
```

## 📦 Dependencies

- `http` - API calls
- `google_fonts` - Typography
- `provider` - State management
- `flutter_bloc` - Advanced state management
- `shared_preferences` - Local storage
- `intl` - Internationalization

## 🔒 Permissions

### Android
- ✅ Internet access (already configured)

### iOS
- ✅ HTTP transport security (already configured)

## 📱 Screenshots

### Mobile
- Home screen with hero section
- Form with all inputs
- Results with recommendations
- Responsive design

### Tablet/Desktop
- Optimized layout for larger screens
- Multi-column views
- Enhanced navigation

## 🚨 Troubleshooting

### Cannot connect to backend
- Check API URL in `api_service.dart`
- Ensure backend is running
- Check firewall settings

### Build fails
```bash
flutter clean
flutter pub get
flutter run
```

### More Help
See [MOBILE_SETUP.md](MOBILE_SETUP.md) for detailed troubleshooting

## 📈 Next Steps

1. ✅ Configure API URL
2. ✅ Run on your preferred platform
3. ✅ Test all features
4. ✅ Build for release
5. ✅ Deploy to stores

## 🤝 Contributing

This is part of the Fitness Recommendation System project.

## 📄 License

MIT License

---

**Made with ❤️ using Flutter**
