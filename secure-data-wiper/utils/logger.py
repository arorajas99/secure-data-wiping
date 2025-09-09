"""
Logger module for Secure Data Wiper
"""

import os
from datetime import datetime
from pathlib import Path

class SecureWipeLogger:
    def __init__(self, log_dir="logs"):
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(exist_ok=True)
        self.log_file = self.log_dir / f"wiper_{datetime.now().strftime('%Y%m%d')}.log"
        
        # Create log file if not exists
        if not self.log_file.exists():
            with open(self.log_file, 'w') as f:
                f.write(f"Secure Data Wiper Log - {datetime.now().isoformat()}\n")
                f.write("="*80 + "\n")
    
    def log(self, message, level="INFO"):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] [{level}] {message}\n"
        
        # Write to file
        with open(self.log_file, 'a') as f:
            f.write(log_entry)
        
        return log_entry

