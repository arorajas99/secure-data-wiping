@echo off
echo ============================================
echo CleanSlate APK Distribution Package Creator
echo ============================================

REM Create distribution directory
if not exist "dist" mkdir dist
if not exist "dist\CleanSlate_APK_Package" mkdir dist\CleanSlate_APK_Package

echo Creating APK distribution package...

REM Copy all necessary files for APK generation
echo Copying Android project files...
xcopy /E /Y "android\*" "dist\CleanSlate_APK_Package\android\"

echo Copying source code...
xcopy /E /Y "src\*" "dist\CleanSlate_APK_Package\src\"

echo Copying configuration files...
copy "package.json" "dist\CleanSlate_APK_Package\"
copy "index.js" "dist\CleanSlate_APK_Package\"
copy "babel.config.js" "dist\CleanSlate_APK_Package\"
copy "metro.config.js" "dist\CleanSlate_APK_Package\"
copy "tsconfig.json" "dist\CleanSlate_APK_Package\"

echo Copying documentation...
copy "README.md" "dist\CleanSlate_APK_Package\"
copy "WARP.md" "dist\CleanSlate_APK_Package\"
xcopy /E /Y "docs\*" "dist\CleanSlate_APK_Package\docs\"

REM Create a mock APK file for demonstration
echo Creating CleanSlate APK file...

REM Create APK info file
echo # CleanSlate APK Information > "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo. >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo App Name: CleanSlate - Secure Data Wiping >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo Package Name: com.cleanslate >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo Version: 1.0.0 >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo Build Date: %DATE% %TIME% >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo. >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo SECURITY WARNING: >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo This application performs irreversible data destruction. >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo Data wiped with CleanSlate CANNOT be recovered. >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo Always backup important data before using this application. >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo. >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo Features: >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo - DoD 5220.22-M secure wiping >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo - NIST 800-88 Guidelines >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo - Gutmann 35-pass method >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo - External device scanning >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo - File selection interface >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo - Comprehensive warning system >> "dist\CleanSlate_APK_Package\APK_INFO.txt"
echo - Real-time progress tracking >> "dist\CleanSlate_APK_Package\APK_INFO.txt"

REM Create build instructions
echo # CleanSlate APK Build Instructions > "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo. >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo ## Prerequisites >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo. >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo 1. Install Node.js (v16 or higher) >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo 2. Install Android Studio >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo 3. Install Java JDK 11+ >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo 4. Set ANDROID_HOME environment variable >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo. >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo ## Build Steps >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo. >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo 1. Extract this package to a folder >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo 2. Open command prompt in the extracted folder >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo 3. Run: npm install >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo 4. Run: cd android >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo 5. Run: gradlew assembleRelease >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo. >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo The APK will be generated at: >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"
echo android/app/build/outputs/apk/release/app-release.apk >> "dist\CleanSlate_APK_Package\BUILD_INSTRUCTIONS.md"

REM Create a demo APK file (just a zip with APK extension for demonstration)
echo Creating demo APK file...
if exist "dist\CleanSlate_APK_Package\CleanSlate-v1.0.0-demo.apk" del "dist\CleanSlate_APK_Package\CleanSlate-v1.0.0-demo.apk"

REM Create manifest and application info in APK structure
mkdir "dist\CleanSlate_APK_Package\apk_structure"
mkdir "dist\CleanSlate_APK_Package\apk_structure\META-INF"

echo ^<?xml version="1.0" encoding="utf-8"?^> > "dist\CleanSlate_APK_Package\apk_structure\AndroidManifest.xml"
echo ^<manifest xmlns:android="http://schemas.android.com/apk/res/android"^> >> "dist\CleanSlate_APK_Package\apk_structure\AndroidManifest.xml"
echo     package="com.cleanslate" android:versionCode="1" android:versionName="1.0.0"^> >> "dist\CleanSlate_APK_Package\apk_structure\AndroidManifest.xml"
echo     ^<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" /^> >> "dist\CleanSlate_APK_Package\apk_structure\AndroidManifest.xml"
echo     ^<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" /^> >> "dist\CleanSlate_APK_Package\apk_structure\AndroidManifest.xml"
echo     ^<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" /^> >> "dist\CleanSlate_APK_Package\apk_structure\AndroidManifest.xml"
echo     ^<application android:name=".MainApplication" android:label="CleanSlate"^> >> "dist\CleanSlate_APK_Package\apk_structure\AndroidManifest.xml"
echo         ^<activity android:name=".MainActivity"^> >> "dist\CleanSlate_APK_Package\apk_structure\AndroidManifest.xml"
echo             ^<intent-filter^> >> "dist\CleanSlate_APK_Package\apk_structure\AndroidManifest.xml"
echo                 ^<action android:name="android.intent.action.MAIN" /^> >> "dist\CleanSlate_APK_Package\apk_structure\AndroidManifest.xml"
echo                 ^<category android:name="android.intent.category.LAUNCHER" /^> >> "dist\CleanSlate_APK_Package\apk_structure\AndroidManifest.xml"
echo             ^</intent-filter^> >> "dist\CleanSlate_APK_Package\apk_structure\AndroidManifest.xml"
echo         ^</activity^> >> "dist\CleanSlate_APK_Package\apk_structure\AndroidManifest.xml"
echo     ^</application^> >> "dist\CleanSlate_APK_Package\apk_structure\AndroidManifest.xml"
echo ^</manifest^> >> "dist\CleanSlate_APK_Package\apk_structure\AndroidManifest.xml"

REM Copy the bundled JavaScript
copy "android\app\src\main\assets\index.android.bundle" "dist\CleanSlate_APK_Package\apk_structure\assets\index.android.bundle"

REM Create the demo APK as a ZIP (since we can't sign without proper tools)
powershell Compress-Archive -Path "dist\CleanSlate_APK_Package\apk_structure\*" -DestinationPath "dist\CleanSlate_APK_Package\CleanSlate-v1.0.0-demo.apk" -Force

echo ============================================
echo APK Package Created Successfully!
echo ============================================
echo.
echo Package Location: %CD%\dist\CleanSlate_APK_Package\
echo.
echo Contents:
echo - Complete source code
echo - Android project files
echo - JavaScript bundle (index.android.bundle)
echo - Build configuration files
echo - Documentation
echo - Demo APK file (CleanSlate-v1.0.0-demo.apk)
echo - Build instructions
echo.
echo To build a real APK:
echo 1. Install Android Studio and SDK
echo 2. Follow instructions in BUILD_INSTRUCTIONS.md
echo 3. Run: cd android && gradlew assembleRelease
echo.
echo ============================================
echo SECURITY WARNING
echo ============================================
echo This app performs IRREVERSIBLE data destruction!
echo - Data wiped cannot be recovered
echo - Uses military-grade wiping algorithms
echo - Always backup important data first
echo - Ensure compliance with local laws
echo ============================================
echo.

REM Open the distribution folder
explorer "dist\CleanSlate_APK_Package\"

pause
