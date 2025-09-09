#!/usr/bin/env python
"""
Test file wiping on removable drive (v1.01)
"""

import os
import sys
sys.path.append(os.path.dirname(__file__))

print("CleanSlate v1.01 - Removable Drive Wipe Test")
print("=" * 60)

# Create test file on E: drive
test_file = r"E:\TEST_WIPE_v101.txt"
test_content = "SENSITIVE DATA TO BE WIPED - Version 1.01 Test\n" * 20

print(f"1. Creating test file: {test_file}")
try:
    with open(test_file, 'w') as f:
        f.write(test_content)
    print(f"   Created: {os.path.getsize(test_file)} bytes")
except Exception as e:
    print(f"   ERROR creating file: {e}")
    sys.exit(1)

# Import and test wipe engine
print("\n2. Importing wipe engine...")
try:
    from utils.wipe_engine import SecureWipeEngine, WipePattern
    print("   ✓ Wipe engine imported successfully")
except Exception as e:
    print(f"   ✗ Failed to import: {e}")
    sys.exit(1)

# Perform wipe
print("\n3. Performing DoD 3-pass wipe...")
engine = SecureWipeEngine()

# Check file before wipe
print(f"   File exists before wipe: {os.path.exists(test_file)}")

# Wipe the file
result = engine.wipe_file(test_file, WipePattern.DOD_522022M, verify=True)

# Check result
print("\n4. Results:")
print(f"   Wipe result: {'SUCCESS' if result else 'FAILED'}")
print(f"   File exists after wipe: {os.path.exists(test_file)}")

if result and not os.path.exists(test_file):
    print("\n✅ TEST PASSED: File was successfully wiped from removable drive!")
else:
    print("\n❌ TEST FAILED: File was not properly wiped!")
    
print("\n" + "=" * 60)
print("CleanSlate v1.01 - Test Complete")
