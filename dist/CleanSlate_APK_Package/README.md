# CleanSlate - Secure Data Wiping Mobile App

A comprehensive mobile application designed to safely and permanently wipe sensitive data from mobile devices using military-grade security algorithms.

## 🔒 Security Features

- **Multiple Wiping Standards**: DoD 5220.22-M, NIST 800-88, Gutmann Method (35-pass), Random Overwrite, Zero Fill
- **Device Scanning**: Automatic detection of external storage devices and SD cards
- **File Selection**: Browse and select specific files/folders to wipe or preserve
- **Authentication**: Secure PIN-based access with biometric support
- **Comprehensive Warnings**: Multi-stage disclaimer system with user acknowledgment
- **Progress Tracking**: Real-time progress monitoring during wiping operations
- **Verification**: Post-wipe verification to ensure complete data destruction

## 📱 App Flow

1. **Authentication**: Set up and enter secure PIN
2. **Device Selection**: Choose between external storage scanning or internal/SD card browsing
3. **File Selection**: Browse directories and select files/folders for wiping
4. **Method Selection**: Choose wiping algorithm (DoD, NIST, Gutmann, etc.)
5. **Warning System**: Comprehensive disclaimer with multiple warnings to acknowledge
6. **"ALL DATA CLEAR"**: Confirmation button to start the irreversible wiping process
7. **Progress Monitoring**: Real-time progress with pass tracking and file status
8. **Completion Report**: Detailed results with verification status

## 🏗️ Project Structure

```
data-wiping-mobile-app/
├── src/
│   ├── App.tsx                     # Main app component with navigation
│   ├── components/
│   │   └── WarningDisclaimer.tsx   # Comprehensive warning system
│   ├── context/
│   │   └── AuthContext.tsx         # Authentication state management
│   ├── screens/
│   │   ├── AuthScreen.tsx          # PIN setup and login
│   │   ├── HomeScreen.tsx          # Main navigation screen
│   │   ├── DeviceScanScreen.tsx    # External device scanning
│   │   ├── FileSelectionScreen.tsx # File browser and selection
│   │   └── WipingScreen.tsx        # Wiping progress and completion
│   └── services/
│       ├── DeviceScanService.ts    # Storage device detection
│       ├── FileBrowserService.ts   # File system browsing
│       └── DataWipingService.ts    # Secure wiping algorithms
├── android/                       # Android build configuration
├── docs/                          # API and security documentation
├── package.json                   # Dependencies and scripts
├── build-apk.bat                  # APK build script
└── WARP.md                       # Development guidelines
```

## 🔧 Building the APK

### Prerequisites

Before building the APK, ensure you have the following installed:

1. **Node.js** (v16 or higher) - [Download](https://nodejs.org/)
2. **Android Studio** - [Download](https://developer.android.com/studio)
3. **Java JDK** (v11 or higher) - [Download](https://openjdk.java.net/)
4. **Android SDK** with Build Tools (API level 33)

### Environment Setup

1. **Set Android Home Environment Variable**:
   ```cmd
   set ANDROID_HOME=C:\Users\%USERNAME%\AppData\Local\Android\Sdk
   ```

2. **Add Android SDK to PATH**:
   ```cmd
   set PATH=%PATH%;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\tools
   ```

### Build Process

#### Option 1: Automated Build Script

Run the automated build script:
```cmd
build-apk.bat
```

This script will:
- Check for required dependencies
- Install React Native CLI if needed
- Install npm dependencies
- Set up Android build environment
- Generate the APK

#### Option 2: Manual Build

1. **Install Dependencies**:
   ```cmd
   npm install
   ```

2. **Install React Native CLI**:
   ```cmd
   npm install -g @react-native-community/cli
   ```

3. **Build APK**:
   ```cmd
   cd android
   gradlew assembleRelease
   ```

### APK Location

After successful build, the APK will be located at:
```
android/app/build/outputs/apk/release/app-release-1.0.0.apk
```

## 📲 Installation

1. **Enable Unknown Sources**: 
   - Go to Settings > Security > Unknown Sources
   - Enable "Allow installation of apps from unknown sources"

2. **Install APK**:
   - Transfer the APK to your Android device
   - Tap the APK file to install
   - Grant required permissions when prompted

## ⚠️ Security Warnings

**CRITICAL WARNING**: This application performs irreversible data destruction. Please read carefully:

- **Data Loss**: All wiped data will be permanently deleted and cannot be recovered
- **No Recovery**: Military-grade algorithms make data recovery impossible
- **System Impact**: Wiping system files may render your device unusable
- **Legal Responsibility**: Ensure compliance with data protection laws
- **Backup First**: Always backup important data before using this application

## 🛡️ Permissions Required

The app requires the following Android permissions:

- `READ_EXTERNAL_STORAGE`: To scan and list files
- `WRITE_EXTERNAL_STORAGE`: To perform wiping operations
- `MANAGE_EXTERNAL_STORAGE`: For comprehensive storage access
- `USE_BIOMETRIC`: For secure authentication
- `WAKE_LOCK`: To prevent device sleep during wiping

## 🧪 Testing

Run the test suite:
```cmd
npm test
```

Run with coverage:
```cmd
npm test -- --coverage
```

## 🔍 Wiping Methods

### DoD 5220.22-M (Default)
- **Passes**: 3
- **Pattern**: 0x00, 0xFF, Random
- **Standard**: US Department of Defense

### NIST 800-88
- **Passes**: 1
- **Pattern**: Cryptographic random
- **Standard**: National Institute of Standards and Technology

### Gutmann Method
- **Passes**: 35
- **Pattern**: Specific patterns designed for maximum security
- **Standard**: Peter Gutmann's algorithm

### Random Overwrite
- **Passes**: 7
- **Pattern**: Cryptographically secure random data
- **Standard**: Custom implementation

### Zero Fill
- **Passes**: 1
- **Pattern**: All zeros (0x00)
- **Standard**: Basic overwrite

## 🤝 Contributing

This is a security-focused application. All contributions must:

1. Follow secure coding practices
2. Include comprehensive tests
3. Maintain security documentation
4. Pass security code review

## 📜 License

This project is licensed under the ISC License.

## ⚡ Performance Notes

- **Storage Speed**: Wiping speed depends on storage device performance
- **Method Impact**: Gutmann method (35 passes) takes significantly longer than single-pass methods
- **File Size**: Large files and directories will take proportionally longer
- **Background Processing**: App prevents device sleep during wiping operations

## 🔗 Related Documentation

- [API Documentation](docs/API.md) - Detailed API specifications
- [Security Guidelines](docs/SECURITY.md) - Security requirements and compliance
- [WARP.md](WARP.md) - Development guidelines for WARP integration

## 📞 Support

For technical support or security concerns:
- Review the documentation in the `docs/` directory
- Check the security guidelines before reporting issues
- Ensure you understand the irreversible nature of data wiping operations

---

**Remember**: Data wiped with CleanSlate cannot be recovered. Always backup important data before using this application.
