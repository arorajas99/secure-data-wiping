@echo off
echo ============================================
echo CleanSlate - React Native Build Script
echo ============================================

REM Check if we're in the right directory
if not exist "package.json" (
    echo ERROR: package.json not found. Make sure you're in the project root directory.
    pause
    exit /b 1
)

REM Install dependencies
echo Installing npm dependencies...
call npm install
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to install npm dependencies
    pause
    exit /b 1
)

REM Check if React Native CLI is available
where npx >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Installing React Native CLI globally...
    call npm install -g @react-native-community/cli
)

echo ============================================
echo Setting up React Native project...
echo ============================================

REM Initialize React Native project if needed
if not exist "node_modules\react-native" (
    echo Installing React Native...
    call npm install react-native@0.72.6
)

REM Generate Android project structure using React Native CLI
echo Generating Android project...
call npx react-native init CleanSlateTemp --version 0.72.6
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Could not generate template project
)

REM Copy our source code over the generated template
echo Copying source code...
if exist "CleanSlateTemp\android" (
    echo Copying Android build files...
    xcopy /E /Y "CleanSlateTemp\android\*" "android\"
    rmdir /S /Q "CleanSlateTemp"
)

echo ============================================
echo Building APK with Metro bundler...
echo ============================================

REM Start Metro bundler in the background
start /B npx react-native start

REM Wait a moment for Metro to start
timeout /T 5 /NOBREAK >nul

REM Create a bundle
echo Creating JavaScript bundle...
call npx react-native bundle --platform android --dev false --entry-file index.js --bundle-output android/app/src/main/assets/index.android.bundle --assets-dest android/app/src/main/res/

echo ============================================
echo Creating Debug APK...
echo ============================================

REM Create a simple APK structure
if not exist "build\outputs\apk" mkdir build\outputs\apk

REM Copy all files to a build directory
echo Copying application files...
xcopy /E /Y "src\*" "build\app\src\"
xcopy /E /Y "android\*" "build\app\android\"

echo ============================================
echo APK Build Information
echo ============================================
echo.
echo Due to the complexity of Android build tools, a complete APK
echo cannot be generated without the full Android SDK and build tools.
echo.
echo To complete the APK build, you need:
echo 1. Android Studio with SDK installed
echo 2. Java JDK 11 or higher
echo 3. Android SDK Build Tools
echo 4. Gradle
echo.
echo Once these are installed, run:
echo   cd android
echo   .\gradlew assembleDebug
echo.
echo The generated APK will be at:
echo   android\app\build\outputs\apk\debug\app-debug.apk
echo.
echo ============================================
echo Build files prepared successfully!
echo ============================================
echo Application source code: %CD%\src\
echo Android configuration: %CD%\android\
echo Build output: %CD%\build\
echo.
echo Next steps:
echo 1. Install Android Studio
echo 2. Set ANDROID_HOME environment variable
echo 3. Run: cd android && .\gradlew assembleDebug
echo.

pause
