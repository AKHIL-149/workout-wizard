#!/bin/bash
# Quick launcher for Flutter mobile app

clear
echo "========================================"
echo "  Workout Wizard - Mobile Launcher"
echo "========================================"
echo ""

while true; do
    echo "Choose platform:"
    echo ""
    echo "[1] Android Emulator"
    echo "[2] iOS Simulator (Mac only)"
    echo "[3] Web Browser"
    echo "[4] Physical Device (Auto-detect)"
    echo "[5] List Connected Devices"
    echo "[6] Build APK (Android Release)"
    echo "[7] Build iOS (Release)"
    echo "[8] Exit"
    echo ""
    
    read -p "Enter choice (1-8): " choice
    
    case $choice in
        1)
            echo ""
            echo "========================================"
            echo " Running on Android Emulator..."
            echo "========================================"
            echo ""
            echo "IMPORTANT: Make sure:"
            echo " 1. Backend is running (python run_backend.py)"
            echo " 2. Android emulator is started"
            echo " 3. API URL is: http://10.0.2.2:8000"
            echo ""
            read -p "Press Enter to continue..."
            flutter run -d android
            ;;
        2)
            echo ""
            echo "========================================"
            echo " Running on iOS Simulator..."
            echo "========================================"
            echo ""
            echo "IMPORTANT: Make sure:"
            echo " 1. Backend is running (python run_backend.py)"
            echo " 2. iOS simulator is started"
            echo " 3. API URL is: http://localhost:8000"
            echo ""
            read -p "Press Enter to continue..."
            flutter run -d ios
            ;;
        3)
            echo ""
            echo "========================================"
            echo " Running on Web Browser..."
            echo "========================================"
            echo ""
            echo "IMPORTANT: Make sure:"
            echo " 1. Backend is running (python run_backend.py)"
            echo " 2. API URL is: http://localhost:8000"
            echo ""
            read -p "Press Enter to continue..."
            flutter run -d chrome
            ;;
        4)
            echo ""
            echo "========================================"
            echo " Running on Connected Device..."
            echo "========================================"
            echo ""
            echo "IMPORTANT: Make sure:"
            echo " 1. Backend is running (python run_backend.py)"
            echo " 2. Device is connected (USB debugging enabled)"
            echo " 3. API URL matches your platform"
            echo ""
            read -p "Press Enter to continue..."
            flutter run
            ;;
        5)
            echo ""
            echo "========================================"
            echo " Connected Devices:"
            echo "========================================"
            echo ""
            flutter devices
            echo ""
            read -p "Press Enter to continue..."
            ;;
        6)
            echo ""
            echo "========================================"
            echo " Building Android APK (Release)..."
            echo "========================================"
            echo ""
            echo "This will create a release APK..."
            echo "Location: build/app/outputs/flutter-apk/app-release.apk"
            echo ""
            read -p "Press Enter to continue..."
            flutter build apk --release
            echo ""
            echo "Build complete!"
            echo "APK location: build/app/outputs/flutter-apk/app-release.apk"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        7)
            echo ""
            echo "========================================"
            echo " Building iOS (Release)..."
            echo "========================================"
            echo ""
            echo "This will create a release iOS build..."
            echo "Use Xcode to archive and distribute."
            echo ""
            read -p "Press Enter to continue..."
            flutter build ios --release
            echo ""
            echo "Build complete!"
            echo "Use Xcode to archive: ios/Runner.xcworkspace"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        8)
            echo ""
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice!"
            ;;
    esac
    
    clear
    echo "========================================"
    echo "  Workout Wizard - Mobile Launcher"
    echo "========================================"
    echo ""
done

