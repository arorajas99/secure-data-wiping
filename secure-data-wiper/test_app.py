#!/usr/bin/env python
"""
Test script for CleanSlate application
"""

import os
import sys

# Test imports
print("Testing imports...")
try:
    from utils.drive_detector import SimpleDriveDetector
    print("✓ Drive detector imported")
except ImportError as e:
    print(f"✗ Drive detector import failed: {e}")

try:
    from utils.wipe_engine import SecureWipeEngine, WipePattern
    print("✓ Wipe engine imported")
except ImportError as e:
    print(f"✗ Wipe engine import failed: {e}")

try:
    from utils.certificate_generator import CertificateGenerator
    print("✓ Certificate generator imported")
except ImportError as e:
    print(f"✗ Certificate generator import failed: {e}")

# Test basic functionality
print("\nTesting basic functionality...")

# Test drive detection
try:
    detector = SimpleDriveDetector()
    drives = detector.get_drives_windows()
    print(f"✓ Found {len(drives)} drives")
    for drive in drives:
        print(f"  - {drive['path']} ({drive['size_readable']})")
except Exception as e:
    print(f"✗ Drive detection failed: {e}")

# Test file creation and wiping
print("\nTesting file wipe...")
test_file = "test_cleanslate.txt"
try:
    # Create test file
    with open(test_file, "w") as f:
        f.write("Test data for CleanSlate wipe test" * 100)
    print(f"✓ Created test file: {test_file}")
    
    # Test wipe
    engine = SecureWipeEngine()
    result = engine.wipe_file(test_file, WipePattern.SINGLE_RANDOM, verify=False)
    
    if result:
        print("✓ File successfully wiped")
    else:
        print("✗ File wipe failed")
        
    # Check if file was deleted
    if not os.path.exists(test_file):
        print("✓ File was deleted after wipe")
    else:
        print("✗ File still exists after wipe")
        
except Exception as e:
    print(f"✗ Wipe test failed: {e}")
    # Clean up if needed
    if os.path.exists(test_file):
        os.remove(test_file)

# Test certificate generation
print("\nTesting certificate generation...")
try:
    gen = CertificateGenerator()
    wipe_data = {
        "wipe_method": "Test Method",
        "target_type": "File",
        "target_path": "test.txt",
        "start_time": "2024-01-01T00:00:00",
        "end_time": "2024-01-01T00:01:00",
        "bytes_wiped": 1024,
        "passes_completed": 1,
        "verification_status": "Verified",
        "duration": 60
    }
    result = gen.generate_certificate(wipe_data)
    if result:
        print(f"✓ Certificate generated: {result['certificate_id']}")
    else:
        print("✗ Certificate generation failed")
except Exception as e:
    print(f"✗ Certificate test failed: {e}")

print("\n" + "="*50)
print("Test complete! You can now run the main application:")
print("python main.py")
print("="*50)
