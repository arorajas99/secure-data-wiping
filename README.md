# 🧹 CleanSlate – Professional Data Sanitization Tool

CleanSlate is a professional secure data deletion and sanitization tool designed to permanently remove sensitive files or wipe storage drives.

The tool follows the **NIST SP 800-88 data sanitization standard** and generates **verifiable certificates of data destruction** for compliance, auditing, and documentation purposes.

CleanSlate also supports sustainability initiatives by enabling safe device reuse and reducing electronic waste.

---

# Features

## 🔐 Secure File Deletion
- Permanently deletes selected files or folders
- Temporary **30-second undo window**
- Prevents recovery using standard recovery tools

## 💾 NIST SP 800-88 Drive Wiping
Implements a **3-pass overwrite method**:
1. Zero overwrite
2. Ones overwrite
3. Random data overwrite

Ensures sensitive data cannot be reconstructed.

## 📄 Certificate of Data Sanitization
After a wipe operation, CleanSlate generates:

- **PDF Certificate**
- **JSON Certificate**

Certificates include:
- Unique certificate ID
- Wipe method used
- Start and completion timestamps
- Device details
- SHA-256 verification hash

This makes the tool useful for **IT Asset Disposition (ITAD)** and **data compliance documentation**.

## 🖥 Modern GUI
Built with **Tkinter** featuring:

- Drive detection
- File and folder selection
- Progress tracking
- Operation logs
- Safety confirmations
- Captcha verification before wipe

## ⚠ Safety Mechanisms
To prevent accidental data loss:

- System drive protection
- Confirmation dialog
- Captcha verification
- 30-second undo option for file deletion

---

# How It Works

## File Deletion Workflow
1. Selected files are moved to secure temporary storage.
2. A **30-second undo window** is provided.
3. If not restored, files are permanently deleted.
4. A **wipe certificate** is generated.

## Drive Wipe Workflow
1. User selects a drive.
2. System drive protection prevents OS deletion.
3. Drive free space is overwritten using the **3-pass NIST method**.
4. A **data sanitization certificate** is generated.

---

# Installation

Clone the repository:

git clone https://github.com/arorajas99/secure-data-wiping.git  
cd secure-data-wiping

Install dependencies:

pip install psutil fpdf

---

# Usage

Run the application:

python cleanslate.py

Steps:

1. Launch CleanSlate
2. Select files, folder, or drive
3. Choose sanitization method
4. Confirm wipe using captcha
5. Wait for completion
6. Save generated wipe certificate

---

# Project Structure

secure-data-wiping/

│  
├── cleanslate.py       # Main application  
├── README.md  
└── requirements.txt  

---

# Compliance

CleanSlate follows the **NIST SP 800-88 Clear data sanitization standard**, commonly used in:

- Government organizations
- Corporate IT departments
- Data centers
- Hardware recycling companies

---

# Sustainability Impact (UN SDGs)

CleanSlate contributes to several **UN Sustainable Development Goals**:

### Goal 12 – Responsible Consumption and Production
Secure data wiping allows devices to be **reused, resold, or refurbished** instead of discarded.

### Goal 16 – Peace, Justice, and Strong Institutions
Protects personal and organizational data from unauthorized access.

### Goal 9 – Industry, Innovation, and Infrastructure
Supports secure IT infrastructure and safe hardware lifecycle management.

---

# Dependencies

- Python 3.x
- tkinter
- psutil
- fpdf

---

# Disclaimer

⚠ **Warning:**  
Data wiped using this software **cannot be recovered**.

Always verify the selected targets before performing a wipe operation.

The authors are not responsible for accidental data loss caused by misuse.



