# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a **Secure Data Wiper** tool - a NIST SP 800-88 Rev. 1 compliant data sanitization application designed for IT asset recycling. It's a professional-grade tool with irreversible data destruction capabilities, developed for JNARDDC under the Ministry of Mines, Government of India.

## Development Commands

### Build & Run

```bash
# Install dependencies
pip install -r requirements.txt

# Run the application from source
python main.py

# Build Windows executable
pyinstaller --onefile --windowed --name="SecureDataWiper" --add-data="utils;utils" --hidden-import=psutil --hidden-import=tkinter main.py

# Quick build using batch script (Windows)
build.bat
```

### Testing

```bash
# Run all tests (when test suite is added)
python -m pytest tests/

# Run with coverage (future implementation)
python -m pytest --cov=utils tests/
```

## Architecture Overview

### Core Components

The application follows a modular architecture with clear separation of concerns:

1. **main.py** - GUI application entry point using tkinter
   - Implements `SecureDataWiperGUI` class with complete UI workflow
   - Handles user interactions and threading for non-blocking operations
   - Manages warning dialogs and confirmation prompts for safety

2. **utils/wipe_engine.py** - Core wiping algorithms
   - `SecureWipeEngine`: Main engine implementing multiple wipe standards
   - `WipePattern`: Defines DoD 5220.22-M, Gutmann, and random patterns
   - Implements file/directory/drive wiping with progress tracking
   - Handles verification after wipe completion
   - Thread-safe with cancellation support via `stop_flag`

3. **utils/drive_detector.py** - Drive detection and information
   - `DriveDetector`: Uses win32api for detailed Windows drive information
   - `SimpleDriveDetector`: Fallback implementation without pywin32
   - Retrieves physical disk info via WMI
   - Identifies system drives to prevent accidental OS wipe

4. **utils/certificate_generator.py** - Certificate generation system
   - Generates tamper-proof PDF and JSON certificates
   - Implements SHA-512 digital signatures
   - Creates verification hashes for authenticity checking
   - Falls back to text certificates if ReportLab unavailable

5. **utils/logger.py** - Logging functionality
   - Centralized logging with timestamp and severity levels
   - Maintains operation logs in the `logs/` directory

### Data Flow

1. User selects target (drive/files/folder) via GUI
2. Drive detector validates selection and checks for system drives
3. Wipe engine performs multi-pass overwriting based on selected method
4. Progress updates flow back to GUI via threading callbacks
5. Certificate generator creates signed proof of sanitization
6. All operations logged for audit trail

### Security Implementation

- **Multi-pass overwriting**: DoD 3-pass, 7-pass, and Gutmann 35-pass methods
- **Verification process**: Reads back data to confirm successful wipe
- **File metadata cleaning**: Renames files before deletion
- **Free space wiping**: Optional clearing of unallocated space
- **Cryptographically secure random data**: Uses `os.urandom()` for pattern generation

## Critical Safety Considerations

⚠️ **This tool performs IRREVERSIBLE data destruction** ⚠️

When modifying wipe-related code:
- Always maintain multiple confirmation dialogs before wipe operations
- Never allow system drive wiping while OS is running
- Preserve the `stop_flag` mechanism for operation cancellation
- Keep detailed logging of all destructive operations
- Ensure certificate generation captures complete wipe details

## Windows-Specific Implementation

The codebase currently targets Windows with:
- `pywin32` for drive enumeration and volume information
- WMI queries for physical disk details
- Windows-specific path handling (drive letters)
- Administrator privileges required for full functionality

Future Linux/Android support placeholders exist but are not implemented.

## Dependencies Management

Core dependencies:
- `psutil` - System and process utilities (required)
- `reportlab` - PDF certificate generation (optional, has text fallback)
- `pywin32` - Windows API access (optional, has SimpleDriveDetector fallback)
- `pyinstaller` - Executable building (development only)

## Certificate System

Certificates include:
- Unique ID format: `JNARDDC-YYYYMMDD-XXXXXXXX`
- Wipe method, duration, and pass count
- Target information (path, size, filesystem)
- SHA-512 digital signature
- Verification hash for authenticity checking

Certificates are stored in `certificates/` directory in both JSON (machine-readable) and PDF/TXT (human-readable) formats.

## GUI State Management

The tkinter GUI manages:
- Drive list refresh with usage statistics
- Method selection (DoD, Gutmann, Random)
- Progress tracking with real-time updates
- Log display in scrollable text widget
- Status bar for current operation info

Threading is used to prevent UI freezing during long wipe operations.

## Error Handling Patterns

The codebase uses try-except blocks extensively with:
- Graceful fallbacks (e.g., SimpleDriveDetector when pywin32 unavailable)
- Detailed error logging to both console and log files
- User-friendly error messages in GUI message boxes
- Operation rollback on critical failures

## Performance Characteristics

Wipe speeds depend on drive type and selected method:
- DoD 3-pass: ~100 GB/hour
- DoD 7-pass: ~40 GB/hour  
- Gutmann 35-pass: ~8 GB/hour
- Buffer size: 4096 bytes for file operations
- Progress updates throttled to prevent GUI lag
