@echo off
echo ============================================
echo CleanSlate - Secure Data Wiping App
echo Building APK...
echo ============================================

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

REM Check if React Native CLI is installed
where react-native >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Installing React Native CLI...
    npm install -g @react-native-community/cli
)

REM Install dependencies
echo Installing dependencies...
npm install

REM Check if Android SDK is configured
if not defined ANDROID_HOME (
    echo WARNING: ANDROID_HOME is not set
    echo Please install Android Studio and set ANDROID_HOME environment variable
    echo Example: set ANDROID_HOME=C:\Users\%USERNAME%\AppData\Local\Android\Sdk
)

REM Create android directory structure if it doesn't exist
if not exist "android\gradle" mkdir android\gradle
if not exist "android\gradle\wrapper" mkdir android\gradle\wrapper

REM Generate Gradle Wrapper if not exists
if not exist "android\gradlew.bat" (
    echo Generating Gradle Wrapper...
    cd android
    gradle wrapper --gradle-version=7.5.1
    cd ..
)

REM Build the APK
echo Building release APK...
cd android
if exist "gradlew.bat" (
    gradlew.bat assembleRelease
) else (
    echo ERROR: Gradle wrapper not found
    echo Please ensure Android development environment is properly set up
    pause
    exit /b 1
)
cd ..

REM Check if APK was built successfully
if exist "android\app\build\outputs\apk\release\*.apk" (
    echo ============================================
    echo BUILD SUCCESSFUL!
    echo ============================================
    echo APK Location: android\app\build\outputs\apk\release\
    dir android\app\build\outputs\apk\release\*.apk
    echo.
    echo The CleanSlate APK has been built successfully!
    echo You can now install it on your Android device.
    echo.
    echo SECURITY WARNING:
    echo This app performs secure data wiping operations.
    echo Only install on devices where you intend to permanently delete data.
    echo Data wiped with this application CANNOT be recovered.
    echo.
) else (
    echo ============================================
    echo BUILD FAILED!
    echo ============================================
    echo Please check the error messages above.
    echo Make sure you have:
    echo 1. Android Studio installed
    echo 2. ANDROID_HOME environment variable set
    echo 3. Android SDK Build Tools installed
    echo 4. Java JDK installed
    echo.
)

pause
