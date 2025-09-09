# CleanSlate Changelog

## Version 1.01 (2025-09-09)
### Fixed
- Fixed file wiping issue on removable drives
- Improved logging to show full file paths and sizes
- Added file existence check before wiping
- Enhanced error reporting for failed wipe operations

### Changed
- Updated version number to 1.01 (first minor version)
- Added verification step to confirm files are deleted after wipe
- Improved wipe engine initialization to use actual engine

### Added
- Better diagnostic logging during wipe operations
- Warning when files still exist after wipe attempt
- Version number now displayed in status bar

## Version 1.0.0 (2025-09-09)
### Initial Release
- DoD 5220.22-M 3-pass and 7-pass wiping
- Gutmann 35-pass wiping method
- Random data wiping options
- Certificate generation (PDF and JSON)
- Drive detection and listing
- File and folder selection
- Progress tracking
- Operation logging
- NIST SP 800-88 compliance
