# CleanSlate - Professional Data Sanitization
### NIST SP 800-88 Rev. 1 Compliant Data Sanitization Tool

## 🧹 Overview

**CleanSlate** is a professional-grade data sanitization tool that provides secure, irreversible data wiping for IT asset recycling and data protection. This tool ensures complete data destruction using industry-standard wiping methods, making data recovery impossible.

### Key Features
- ✅ **Multiple Wiping Standards**: DoD 5220.22-M, Gutmann, and custom patterns
- ✅ **Cross-Platform Support**: Windows, Linux (coming soon), Android (planned)
- ✅ **Tamper-Proof Certificates**: Digitally signed PDF and JSON certificates
- ✅ **One-Click Interface**: Simple, intuitive GUI suitable for general public
- ✅ **Verification System**: Built-in verification of wipe completion
- ✅ **NIST SP 800-88 Compliant**: Follows international data sanitization standards

## ⚠️ CRITICAL WARNING

**DATA WIPING IS IRREVERSIBLE!**

This tool permanently destroys data. Once wiped, data CANNOT be recovered by any means. 

- **ALWAYS** ensure you have backups of important data
- **NEVER** wipe system drives while the OS is running
- **VERIFY** the correct drive/files are selected before wiping
- **USE** at your own risk - the developers are not responsible for data loss

## 📋 Requirements

### System Requirements
- **OS**: Windows 10/11 (64-bit)
- **RAM**: Minimum 4GB
- **Storage**: 100MB for application
- **Python**: 3.8 or higher (if running from source)

### Python Dependencies (for development)
```bash
pip install psutil
pip install reportlab  # Optional, for PDF generation
```

## 🚀 Installation

### Option 1: Using Pre-built Executable (Recommended)
1. Download the latest release from the releases page
2. Extract the ZIP file to your desired location
3. Run `SecureDataWiper.exe` as Administrator

### Option 2: Running from Source
1. Clone the repository:
```bash
git clone https://github.com/JNARDDC/secure-data-wiper.git
cd secure-data-wiper
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run the application:
```bash
python main.py
```

## 📖 Usage Guide

### Basic Usage

1. **Launch the Application**
   - Run as Administrator for full functionality
   - The main window will display available drives

2. **Select Target**
   - Choose a drive from the list, OR
   - Click "Select Files" to choose specific files, OR
   - Click "Select Folder" to choose a directory

3. **Configure Wipe Options**
   - **Wipe Method**: Select from available standards
     - DoD 5220.22-M (3-pass) - Recommended for most users
     - DoD 5220.22-M ECE (7-pass) - Enhanced security
     - Gutmann (35-pass) - Maximum security (slower)
     - Random (1-pass) - Quick wipe
     - Random (3-pass) - Balanced speed/security
   
   - **Additional Options**:
     - ✅ Verify after wipe - Confirms data is unrecoverable
     - ✅ Wipe free space - Also wipes deleted file remnants
     - ✅ Generate certificate - Creates proof of sanitization

4. **Start Wipe Process**
   - Click "START WIPE" button
   - Confirm the warning dialogs
   - Monitor progress in the progress bar and log window

5. **Certificate Generation**
   - After successful wipe, certificates are auto-generated
   - Find them in the `certificates` folder
   - Both JSON (machine-readable) and PDF/TXT (human-readable) formats

### Advanced Features

#### Certificate Verification
Certificates can be verified using the JSON file:
```python
from utils.certificate_generator import CertificateGenerator
generator = CertificateGenerator()
result = generator.verify_certificate("path/to/certificate.json")
print(result)  # Shows if certificate is valid and authentic
```

#### Command Line Usage (Future Feature)
```bash
python wiper.py --drive D:\ --method dod3 --verify --certificate
```

## 🔧 Technical Details

### Wiping Algorithms

#### DoD 5220.22-M (3-pass)
1. Pass 1: Overwrite with zeros (0x00)
2. Pass 2: Overwrite with ones (0xFF)
3. Pass 3: Overwrite with random data

#### DoD 5220.22-M ECE (7-pass)
Extended version with additional passes for enhanced security

#### Gutmann Method (35-pass)
Most thorough method, using specific patterns to account for different encoding schemes

### Security Features

1. **Multi-pass Overwriting**: Multiple passes ensure data remnants are eliminated
2. **Random Data Generation**: Cryptographically secure random number generation
3. **File System Metadata Cleaning**: Removes file names and attributes
4. **Free Space Wiping**: Eliminates traces of previously deleted files
5. **Verification Process**: Confirms successful data destruction

### Certificate Structure

Certificates include:
- Unique Certificate ID
- Timestamp and duration
- Wipe method and passes completed
- Target information (path, size, filesystem)
- Verification hash
- Digital signature (SHA-512)

## 🏗️ Architecture

```
secure-data-wiper/
├── main.py                 # Main GUI application
├── utils/
│   ├── drive_detector.py   # Drive detection module
│   ├── wipe_engine.py      # Core wiping algorithms
│   ├── certificate_generator.py  # Certificate generation
│   └── logger.py           # Logging functionality
├── certificates/           # Generated certificates
├── logs/                   # Application logs
└── README.md              # This file
```

## 🛠️ Development

### Building from Source

1. Install PyInstaller:
```bash
pip install pyinstaller
```

2. Build executable:
```bash
pyinstaller --onefile --windowed --icon=icon.ico main.py
```

### Running Tests
```bash
python -m pytest tests/
```

## 📊 Performance

| Drive Size | DoD 3-pass | DoD 7-pass | Gutmann 35-pass |
|------------|------------|------------|-----------------|
| 100 GB     | ~1 hour    | ~2.5 hours | ~12 hours      |
| 500 GB     | ~5 hours   | ~12 hours  | ~60 hours      |
| 1 TB       | ~10 hours  | ~24 hours  | ~120 hours     |

*Note: Times are estimates and depend on drive speed and system performance*

## 🔒 Compliance

This tool is designed to meet or exceed the following standards:
- **NIST SP 800-88 Rev. 1** - Guidelines for Media Sanitization
- **DoD 5220.22-M** - Department of Defense Standard
- **ISO/IEC 27040:2015** - Information technology security techniques

## 🐛 Known Issues

1. Windows Defender may flag the executable as suspicious (false positive)
2. Some SSDs may not be fully wiped due to wear leveling
3. System drives cannot be wiped while OS is running
4. Network drives are not supported

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

## 🆘 Support

For issues, questions, or suggestions:
- Create an issue on GitHub
- Contact JNARDDC support
- Email: support@jnarddc.gov.in (example)

## ⚖️ Disclaimer

This software is provided "as is" without warranty of any kind. The developers and JNARDDC are not responsible for any data loss resulting from the use of this tool. Users are solely responsible for ensuring they have appropriate backups before using this software.

## 🙏 Acknowledgments

- **Ministry of Mines, Government of India**
- **Jawaharlal Nehru Aluminium Research Development and Design Centre**
- **NIST** for SP 800-88 guidelines
- Open source community for supporting libraries

---

**Version**: 1.01  
**Last Updated**: December 2024  
**CleanSlate** - Professional Data Sanitization Solution
