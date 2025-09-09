# CleanSlate APK Build Instructions 
 
## Prerequisites 
 
1. Install Node.js (v16 or higher) 
2. Install Android Studio 
3. Install Java JDK 11+ 
4. Set ANDROID_HOME environment variable 
 
## Build Steps 
 
1. Extract this package to a folder 
2. Open command prompt in the extracted folder 
3. Run: npm install 
4. Run: cd android 
5. Run: gradlew assembleRelease 
 
The APK will be generated at: 
android/app/build/outputs/apk/release/app-release.apk 
