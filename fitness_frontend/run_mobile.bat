@echo off
REM Quick launcher for Flutter mobile app

echo ========================================
echo   Workout Wizard - Mobile Launcher
echo ========================================
echo.

:menu
echo Choose platform:
echo.
echo [1] Android Emulator
echo [2] iOS Simulator (Mac only)
echo [3] Web Browser
echo [4] Physical Device (Auto-detect)
echo [5] List Connected Devices
echo [6] Build APK (Release)
echo [7] Exit
echo.

set /p choice="Enter choice (1-7): "

if "%choice%"=="1" goto android
if "%choice%"=="2" goto ios
if "%choice%"=="3" goto web
if "%choice%"=="4" goto device
if "%choice%"=="5" goto list
if "%choice%"=="6" goto build
if "%choice%"=="7" goto end

echo Invalid choice!
goto menu

:android
echo.
echo ========================================
echo  Running on Android Emulator...
echo ========================================
echo.
echo IMPORTANT: Make sure:
echo  1. Backend is running (python run_backend.py)
echo  2. Android emulator is started
echo  3. API URL is: http://10.0.2.2:8000
echo.
pause
flutter run -d android
goto menu

:ios
echo.
echo ========================================
echo  Running on iOS Simulator...
echo ========================================
echo.
echo IMPORTANT: Make sure:
echo  1. Backend is running (python run_backend.py)
echo  2. iOS simulator is started
echo  3. API URL is: http://localhost:8000
echo  4. You're on a Mac!
echo.
pause
flutter run -d ios
goto menu

:web
echo.
echo ========================================
echo  Running on Web Browser...
echo ========================================
echo.
echo IMPORTANT: Make sure:
echo  1. Backend is running (python run_backend.py)
echo  2. API URL is: http://localhost:8000
echo.
pause
flutter run -d chrome
goto menu

:device
echo.
echo ========================================
echo  Running on Connected Device...
echo ========================================
echo.
echo IMPORTANT: Make sure:
echo  1. Backend is running (python run_backend.py)
echo  2. Device is connected (USB debugging enabled)
echo  3. API URL matches your platform
echo.
pause
flutter run
goto menu

:list
echo.
echo ========================================
echo  Connected Devices:
echo ========================================
echo.
flutter devices
echo.
pause
goto menu

:build
echo.
echo ========================================
echo  Building Android APK (Release)...
echo ========================================
echo.
echo This will create a release APK...
echo Location: build/app/outputs/flutter-apk/app-release.apk
echo.
pause
flutter build apk --release
echo.
echo Build complete!
echo APK location: build\app\outputs\flutter-apk\app-release.apk
echo.
pause
goto menu

:end
echo.
echo Goodbye!
exit

