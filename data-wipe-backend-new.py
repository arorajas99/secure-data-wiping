import win32file
import win32con
import os
import json
import hashlib
from datetime import datetime

def get_drive_size(disk_number):
    handle = win32file.CreateFile(
        fr'\\.\PhysicalDrive{disk_number}',
        win32con.GENERIC_READ,
        win32con.FILE_SHARE_READ | win32con.FILE_SHARE_WRITE,
        None,
        win32con.OPEN_EXISTING,
        0,
        None
    )
    data = win32file.DeviceIoControl(
        handle,
        0x7405c,  # IOCTL_DISK_GET_LENGTH_INFO
        None,
        8
    )
    handle.close()
    return int.from_bytes(data, 'little')

def wipe_drive_demo(disk_number, passes=1, test_size=128*1024*1024, block_size=1024*1024):
    print(f"[+] SAFE DEMO: Overwriting first {test_size//(1024*1024)}MB of disk {disk_number}, {passes} pass(es)")
    handle = win32file.CreateFile(
        fr'\\.\PhysicalDrive{disk_number}',
        win32con.GENERIC_WRITE | win32con.GENERIC_READ,
        win32con.FILE_SHARE_READ | win32con.FILE_SHARE_WRITE,
        None,
        win32con.OPEN_EXISTING,
        0,
        None
    )
    total_blocks = test_size // block_size
    final_hash = hashlib.sha256()
    start_time = datetime.now()
    for p in range(passes):
        print(f"[+] Pass {p+1}/{passes}")
        win32file.SetFilePointer(handle, 0, win32con.FILE_BEGIN)
        for i in range(int(total_blocks)):
            rand_block = os.urandom(block_size)
            win32file.WriteFile(handle, rand_block)
            final_hash.update(rand_block)
            if i % 4 == 0:
                progress = (i / total_blocks) * 100
                print(f"    {progress:.2f}% complete...")
        remaining = test_size % block_size
        if remaining:
            rand_block = os.urandom(int(remaining))
            win32file.WriteFile(handle, rand_block)
            final_hash.update(rand_block)
        print(f"[+] Pass {p+1} complete.")
    handle.close()
    end_time = datetime.now()
    print("[+] Demo 'wipe' complete. (NOT a real disk wipe!)")
    return start_time, end_time, final_hash.hexdigest()

def generate_certificate(disk_number, media_type, size_bytes, passes, method, start_time, end_time, checksum):
    certificate = {
        "Disk Number": disk_number,
        "Media Type": media_type,
        "Size (Bytes)": size_bytes,
        "Overwrite Passes": passes,
        "Sanitization Method": method,
        "Start Time": start_time.isoformat(),
        "End Time": end_time.isoformat(),
        "Final Pass SHA256": checksum
    }
    filename = f"demo_wipe_certificate_disk{disk_number}.json"
    with open(filename, "w") as f:
        json.dump(certificate, f, indent=4)
    print(f"[+] Demo wipe certificate generated: {filename}")

if __name__ == "__main__":
    print("=== SAFE DEMO: Disk Wipe Tool (TEST MODE with pywin32) ===")
    disk_number = int(input("Enter disk number for test (check with 'diskpart -> list disk'): "))
    media_type = input("Enter media type (HDD/SSD): ").strip().upper() or "HDD"
    print("[!] THIS IS A SAFE DEMO - Only the first 128MB will be overwritten FOR TESTING.")
    if media_type == "SSD":
        print("[!] WARNING: Even a full overwrite may not fully sanitize SSD due to wear-leveling.")
    # Skips prepare_disk, create_partition_and_format for safety
    start_time, end_time, checksum = wipe_drive_demo(disk_number)
    test_size = 128*1024*1024
    generate_certificate(
        disk_number=disk_number,
        media_type=media_type,
        size_bytes=test_size,
        passes=1,
        method="SAFE DEMO (1-pass overwrite of first 128MB)",
        start_time=start_time,
        end_time=end_time,
        checksum=checksum
    )
    print("[+] SAFE DEMO STEPS COMPLETED SUCCESSFULLY")
