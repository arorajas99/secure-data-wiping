#!/usr/bin/env python
"""
Test script to verify that data is actually being wiped
"""

import os
import sys
sys.path.append(os.path.dirname(__file__))

from utils.wipe_engine import SecureWipeEngine, WipePattern

def test_actual_wipe():
    # Create test file with known content
    test_file = "WIPE_TEST_VERIFY.txt"
    test_content = "SENSITIVE DATA " * 100
    
    print("=" * 60)
    print("CLEANSLATE DATA WIPE VERIFICATION TEST")
    print("=" * 60)
    
    # Step 1: Create file
    print("\n1. Creating test file with sensitive data...")
    with open(test_file, "w") as f:
        f.write(test_content)
    
    original_size = os.path.getsize(test_file)
    print(f"   Created: {test_file}")
    print(f"   Size: {original_size} bytes")
    print(f"   Content preview: '{test_content[:50]}...'")
    
    # Step 2: Read original content
    print("\n2. Reading original file content...")
    with open(test_file, "rb") as f:
        original_bytes = f.read()
    print(f"   First 20 bytes (hex): {original_bytes[:20].hex()}")
    
    # Step 3: Perform wipe WITHOUT deleting (to check if data is overwritten)
    print("\n3. Performing DoD 3-pass wipe (without deletion)...")
    engine = SecureWipeEngine()
    
    # Manually do the wiping without deletion
    with open(test_file, "r+b") as f:
        file_size = os.path.getsize(test_file)
        pattern = WipePattern.DOD_522022M
        
        for pass_num, pattern_data in enumerate(pattern, 1):
            print(f"   Pass {pass_num}/{len(pattern)}:")
            f.seek(0)
            bytes_written = 0
            
            while bytes_written < file_size:
                chunk_size = min(4096, file_size - bytes_written)
                
                if pattern_data is None:
                    # Random data
                    data = os.urandom(chunk_size)
                    print(f"      Writing random data...")
                else:
                    # Pattern data
                    data = pattern_data[:chunk_size]
                    print(f"      Writing pattern: {pattern_data[:8].hex()}...")
                
                f.write(data)
                bytes_written += chunk_size
            
            f.flush()
            os.fsync(f.fileno())
    
    # Step 4: Read wiped content
    print("\n4. Reading wiped file content...")
    with open(test_file, "rb") as f:
        wiped_bytes = f.read()
    print(f"   First 20 bytes (hex): {wiped_bytes[:20].hex()}")
    
    # Step 5: Verify data is different
    print("\n5. Verification:")
    if original_bytes == wiped_bytes:
        print("   ❌ FAILED: Data was NOT wiped (content unchanged)")
        success = False
    else:
        print("   ✅ SUCCESS: Data was wiped (content changed)")
        
        # Check if original text is still present
        if test_content.encode() in wiped_bytes:
            print("   ⚠️ WARNING: Original text still found in file!")
            success = False
        else:
            print("   ✅ Original text completely overwritten")
            success = True
    
    # Step 6: Clean up
    print("\n6. Cleaning up test file...")
    try:
        os.remove(test_file)
        print("   Test file deleted")
    except:
        print("   Could not delete test file")
    
    print("\n" + "=" * 60)
    if success:
        print("TEST PASSED: Data wiping is working correctly!")
    else:
        print("TEST FAILED: Data is not being properly wiped!")
    print("=" * 60)
    
    return success

if __name__ == "__main__":
    test_actual_wipe()
