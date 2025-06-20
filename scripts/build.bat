@echo off
echo ====================================
echo        Moni App Build Script
echo ====================================

set ENV=%1
if "%ENV%"=="" set ENV=development

echo Building for environment: %ENV%

:: Clean previous builds
echo Cleaning previous builds...
flutter clean
flutter pub get

:: Build based on environment
if "%ENV%"=="production" (
    echo Building PRODUCTION release...
    flutter build apk --dart-define=ENV=production --obfuscate --split-debug-info=debug-info/ --release
    echo Production APK built successfully!
    echo Location: build\app\outputs\flutter-apk\app-release.apk
) else if "%ENV%"=="staging" (
    echo Building STAGING release...
    flutter build apk --dart-define=ENV=staging --obfuscate --split-debug-info=debug-info/ --release
    echo Staging APK built successfully!
    echo Location: build\app\outputs\flutter-apk\app-release.apk
) else (
    echo Building DEVELOPMENT debug...
    flutter build apk --dart-define=ENV=development --debug
    echo Development APK built successfully!
    echo Location: build\app\outputs\flutter-apk\app-debug.apk
)

echo ====================================
echo         Build Complete!
echo ====================================
pause 