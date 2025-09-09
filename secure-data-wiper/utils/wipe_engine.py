"""
Secure Wipe Engine
Implements DoD 5220.22-M and other secure data wiping standards
"""

import os
import random
import hashlib
import time
import json
from datetime import datetime
from pathlib import Path
import threading

class WipePattern:
    """Define various wipe patterns for secure erasure"""
    
    # DoD 5220.22-M standard (3-pass)
    DOD_522022M = [
        b'\x00' * 512,  # Pass 1: All zeros
        b'\xFF' * 512,  # Pass 2: All ones
        None            # Pass 3: Random data
    ]
    
    # DoD 5220.22-M ECE (7-pass)
    DOD_522022M_ECE = [
        b'\x00' * 512,  # Pass 1: All zeros
        b'\xFF' * 512,  # Pass 2: All ones
        None,           # Pass 3: Random data
        b'\xF6' * 512,  # Pass 4: Specific pattern
        b'\x00' * 512,  # Pass 5: All zeros
        b'\xFF' * 512,  # Pass 6: All ones
        None            # Pass 7: Random data
    ]
    
    # Gutmann method (simplified - normally 35 passes)
    GUTMANN_SIMPLIFIED = [
        None,           # Pass 1-4: Random data
        None,
        None,
        None,
        b'\x55' * 512,  # Pass 5: 01010101
        b'\xAA' * 512,  # Pass 6: 10101010
        b'\x92\x49\x24' * 170 + b'\x92\x49',  # Pass 7: Pattern
        b'\x49\x24\x92' * 170 + b'\x49\x24',  # Pass 8: Pattern
        b'\x24\x92\x49' * 170 + b'\x24\x92',  # Pass 9: Pattern
        b'\x00' * 512,  # Pass 10: All zeros
        b'\x11' * 512,  # Pass 11: Pattern
        b'\x22' * 512,  # Pass 12: Pattern
        b'\x33' * 512,  # Pass 13: Pattern
        b'\x44' * 512,  # Pass 14: Pattern
        b'\x55' * 512,  # Pass 15: Pattern
        b'\x66' * 512,  # Pass 16: Pattern
        b'\x77' * 512,  # Pass 17: Pattern
        b'\x88' * 512,  # Pass 18: Pattern
        b'\x99' * 512,  # Pass 19: Pattern
        b'\xAA' * 512,  # Pass 20: Pattern
        b'\xBB' * 512,  # Pass 21: Pattern
        b'\xCC' * 512,  # Pass 22: Pattern
        b'\xDD' * 512,  # Pass 23: Pattern
        b'\xEE' * 512,  # Pass 24: Pattern
        b'\xFF' * 512,  # Pass 25: All ones
        None,           # Pass 26-35: Random data
        None,
        None,
        None,
        None,
        None,
        None,
        None,
        None,
        None
    ]
    
    # Simple single pass with random data
    SINGLE_RANDOM = [None]
    
    # Simple 3-pass with random data
    TRIPLE_RANDOM = [None, None, None]

class SecureWipeEngine:
    def __init__(self, logger=None):
        self.logger = logger
        self.stop_flag = threading.Event()
        self.progress = 0
        self.current_status = "Idle"
        self.wipe_stats = {}
        
    def log(self, message, level="INFO"):
        """Log message with timestamp"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_message = f"[{timestamp}] [{level}] {message}"
        print(log_message)
        
        if self.logger:
            self.logger.log(message, level)
    
    def generate_random_data(self, size=512):
        """Generate cryptographically secure random data"""
        return os.urandom(size)
    
    def wipe_file(self, file_path, pattern=WipePattern.DOD_522022M, verify=True):
        """Securely wipe a single file"""
        try:
            if not os.path.exists(file_path):
                raise FileNotFoundError(f"File not found: {file_path}")
            
            file_size = os.path.getsize(file_path)
            self.log(f"Starting wipe of file: {file_path} (Size: {file_size} bytes)")
            
            # Open file in binary write mode
            with open(file_path, "r+b") as f:
                for pass_num, pattern_data in enumerate(pattern, 1):
                    if self.stop_flag.is_set():
                        self.log("Wipe operation cancelled by user", "WARNING")
                        return False
                    
                    self.current_status = f"Pass {pass_num}/{len(pattern)}"
                    self.log(f"Executing pass {pass_num} of {len(pattern)}")
                    
                    f.seek(0)
                    bytes_written = 0
                    
                    while bytes_written < file_size:
                        if self.stop_flag.is_set():
                            return False
                        
                        # Determine chunk to write
                        chunk_size = min(4096, file_size - bytes_written)
                        
                        if pattern_data is None:
                            # Random data
                            data = self.generate_random_data(chunk_size)
                        else:
                            # Pattern data
                            data = pattern_data[:chunk_size]
                        
                        f.write(data)
                        bytes_written += chunk_size
                        
                        # Update progress
                        total_passes = len(pattern)
                        pass_progress = bytes_written / file_size
                        self.progress = ((pass_num - 1) + pass_progress) / total_passes * 100
                    
                    f.flush()
                    os.fsync(f.fileno())
            
            # Verify wipe if requested
            if verify:
                if self.verify_wipe(file_path):
                    self.log(f"Wipe verification successful for {file_path}")
                else:
                    self.log(f"Wipe verification failed for {file_path}", "WARNING")
            
            # Rename file with random name before deletion
            random_name = self.generate_random_filename(file_path)
            os.rename(file_path, random_name)
            
            # Delete the file
            os.remove(random_name)
            
            self.log(f"File successfully wiped and deleted: {file_path}")
            return True
            
        except Exception as e:
            self.log(f"Error wiping file {file_path}: {str(e)}", "ERROR")
            return False
    
    def wipe_directory(self, dir_path, pattern=WipePattern.DOD_522022M, recursive=True):
        """Securely wipe all files in a directory"""
        try:
            if not os.path.exists(dir_path):
                raise FileNotFoundError(f"Directory not found: {dir_path}")
            
            self.log(f"Starting directory wipe: {dir_path}")
            
            files_wiped = 0
            files_failed = 0
            
            # Get all files in directory
            if recursive:
                files = list(Path(dir_path).rglob('*'))
            else:
                files = list(Path(dir_path).glob('*'))
            
            # Filter only files (not directories)
            files = [f for f in files if f.is_file()]
            total_files = len(files)
            
            for idx, file_path in enumerate(files):
                if self.stop_flag.is_set():
                    self.log("Directory wipe cancelled by user", "WARNING")
                    break
                
                self.current_status = f"Wiping file {idx + 1}/{total_files}"
                
                if self.wipe_file(str(file_path), pattern, verify=False):
                    files_wiped += 1
                else:
                    files_failed += 1
            
            self.log(f"Directory wipe completed. Files wiped: {files_wiped}, Failed: {files_failed}")
            
            return files_wiped, files_failed
            
        except Exception as e:
            self.log(f"Error wiping directory {dir_path}: {str(e)}", "ERROR")
            return 0, 0
    
    def wipe_free_space(self, drive_path, pattern=WipePattern.SINGLE_RANDOM):
        """Wipe free space on a drive"""
        try:
            self.log(f"Starting free space wipe on drive: {drive_path}")
            
            # Create temporary file to fill free space
            temp_file = os.path.join(drive_path, f"WIPE_TEMP_{int(time.time())}.tmp")
            
            with open(temp_file, "wb") as f:
                chunk_size = 1024 * 1024  # 1MB chunks
                written = 0
                
                try:
                    while True:
                        if self.stop_flag.is_set():
                            break
                        
                        # Write random data
                        data = self.generate_random_data(chunk_size)
                        f.write(data)
                        written += chunk_size
                        
                        self.current_status = f"Wiping free space: {written / (1024**3):.2f} GB"
                        
                except IOError:
                    # Disk full - this is expected
                    self.log(f"Free space filled: {written / (1024**3):.2f} GB written")
                
                f.flush()
                os.fsync(f.fileno())
            
            # Remove temporary file
            os.remove(temp_file)
            
            self.log("Free space wipe completed")
            return True
            
        except Exception as e:
            self.log(f"Error wiping free space: {str(e)}", "ERROR")
            # Try to clean up temp file if it exists
            if 'temp_file' in locals() and os.path.exists(temp_file):
                try:
                    os.remove(temp_file)
                except:
                    pass
            return False
    
    def verify_wipe(self, file_path):
        """Verify that a file has been properly wiped"""
        try:
            # For MVP, basic verification by checking if file contains only zeros or random patterns
            # In production, this would be more sophisticated
            with open(file_path, "rb") as f:
                # Read first and last portions of file
                f.seek(0)
                start_data = f.read(1024)
                
                f.seek(-1024, 2)  # Seek to last 1KB
                end_data = f.read(1024)
                
                # Check if data appears random or zeroed
                # Simple entropy check
                entropy_start = len(set(start_data)) / len(start_data) if start_data else 0
                entropy_end = len(set(end_data)) / len(end_data) if end_data else 0
                
                # If entropy is very low (all same bytes) or very high (random), consider it wiped
                if entropy_start < 0.1 or entropy_start > 0.9:
                    if entropy_end < 0.1 or entropy_end > 0.9:
                        return True
            
            return False
            
        except Exception as e:
            self.log(f"Error verifying wipe: {str(e)}", "ERROR")
            return False
    
    def generate_random_filename(self, original_path):
        """Generate a random filename for secure deletion"""
        directory = os.path.dirname(original_path)
        random_name = hashlib.sha256(os.urandom(32)).hexdigest()[:16]
        return os.path.join(directory, random_name)
    
    def calculate_wipe_time(self, size_bytes, pattern):
        """Estimate time required for wipe operation"""
        # Rough estimation: 50 MB/s write speed
        write_speed = 50 * 1024 * 1024  # 50 MB/s
        passes = len(pattern)
        total_bytes = size_bytes * passes
        estimated_seconds = total_bytes / write_speed
        
        return estimated_seconds
    
    def stop_wipe(self):
        """Stop ongoing wipe operation"""
        self.stop_flag.set()
        self.log("Stop signal sent to wipe engine")
    
    def reset(self):
        """Reset wipe engine state"""
        self.stop_flag.clear()
        self.progress = 0
        self.current_status = "Idle"
        self.wipe_stats = {}

class WipeMethod:
    """Enumeration of available wipe methods"""
    DOD_3PASS = "DoD 5220.22-M (3-pass)"
    DOD_7PASS = "DoD 5220.22-M ECE (7-pass)"
    GUTMANN = "Gutmann (35-pass)"
    RANDOM_1PASS = "Random (1-pass)"
    RANDOM_3PASS = "Random (3-pass)"
    
    @staticmethod
    def get_pattern(method):
        """Get wipe pattern for given method"""
        patterns = {
            WipeMethod.DOD_3PASS: WipePattern.DOD_522022M,
            WipeMethod.DOD_7PASS: WipePattern.DOD_522022M_ECE,
            WipeMethod.GUTMANN: WipePattern.GUTMANN_SIMPLIFIED,
            WipeMethod.RANDOM_1PASS: WipePattern.SINGLE_RANDOM,
            WipeMethod.RANDOM_3PASS: WipePattern.TRIPLE_RANDOM
        }
        return patterns.get(method, WipePattern.DOD_522022M)

if __name__ == "__main__":
    # Test the wipe engine
    engine = SecureWipeEngine()
    
    # Create a test file
    test_file = "test_wipe.txt"
    with open(test_file, "w") as f:
        f.write("This is sensitive data that needs to be securely wiped!" * 100)
    
    print(f"Created test file: {test_file}")
    print(f"File size: {os.path.getsize(test_file)} bytes")
    
    # Wipe the file
    success = engine.wipe_file(test_file, WipePattern.DOD_522022M)
    
    if success:
        print("File successfully wiped!")
    else:
        print("File wipe failed!")
