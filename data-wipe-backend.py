import os
import ctypes
import subprocess
import time
import json
import hashlib
from datetime import datetime

# Windows API constants
GENERIC_READ = 0x80000000
GENERIC_WRITE = 0x40000000
FILE_SHARE_READ = 1
FILE_SHARE_WRITE = 2
OPEN_EXISTING = 3

def run_diskpart(script: str):
    result = subprocess.run(
        ["diskpart"],
        input=script,
        text=True,
        capture_output=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"Diskpart failed:\n{result.stderr}")
    return result.stdout

def prepare_disk(drive_number):
    script = f"""
    select disk {drive_number}
    clean
    exit
    """
    print(f"[+] Cleaning disk {drive_number}...")
    run_diskpart(script)
    print(f"[+] Disk {drive_number} cleaned.")

def create_partition_and_format(drive_number, fs="NTFS", label="WIPED_DRIVE"):
    script = f"""
    select disk {drive_number}
    create partition primary
    format fs={fs} label={label} quick
    assign
    exit
    """
    print(f"[+] Creating new partition and formatting as {fs}...")
    run_diskpart(script)
    print(f"[+] Disk {drive_number} partitioned and formatted.")

def get_drive_size(drive_number):
    path = f"\\\\.\\PhysicalDrive{drive_number}"
    handle = ctypes.windll.kernel32.CreateFileW(
        path,
        GENERIC_READ,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        None,
        OPEN_EXISTING,
        0,
        None
    )

    if handle == -1 or handle == 0:
        err = ctypes.windll.kernel32.GetLastError()
        raise OSError(f"Could not open drive {path}, WinError={err}")

    class GET_LENGTH(ctypes.Structure):
        _fields_ = [("Length", ctypes.c_ulonglong)]

    size_struct = GET_LENGTH()
    returned = ctypes.c_ulong(0)
    IOCTL_DISK_GET_LENGTH_INFO = 0x7405c

    success = ctypes.windll.kernel32.DeviceIoControl(
        handle,
        IOCTL_DISK_GET_LENGTH_INFO,
        None,
        0,
        ctypes.byref(size_struct),
        ctypes.sizeof(size_struct),
        ctypes.byref(returned),
        None
    )
    ctypes.windll.kernel32.CloseHandle(handle)

    if not success:
        raise OSError("Could not get drive size")
    return size_struct.Length

def wipe_drive(drive_number, passes=2, block_size=32*1024*1024):
    path = f"\\\\.\\PhysicalDrive{drive_number}"
    size = get_drive_size(drive_number)
    print(f"[+] Drive {drive_number} size: {size / (1024*1024*1024):.2f} GB")

    handle = os.open(path, os.O_RDWR | os.O_BINARY)
    total_blocks = size // block_size
    final_hash = hashlib.sha256()

    start_time = datetime.now()
    for p in range(passes):
        print(f"[+] Pass {p+1}/{passes}")
        os.lseek(handle, 0, os.SEEK_SET)

        for i in range(int(total_blocks)):
            data = os.urandom(block_size)
            os.write(handle, data)
            if p == passes - 1:
                final_hash.update(data)
            if i % 50 == 0:
                progress = (i / total_blocks) * 100
                print(f"    {progress:.2f}% complete...")

        remaining = size % block_size
        if remaining:
            data = os.urandom(int(remaining))
            os.write(handle, data)
            if p == passes - 1:
                final_hash.update(data)

        os.fsync(handle)
        elapsed = datetime.now() - start_time
        print(f"[+] Pass {p+1} complete. Elapsed: {elapsed}")

    os.close(handle)
    end_time = datetime.now()
    print("[+] Wipe complete.")

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

    filename = f"wipe_certificate_disk{disk_number}.json"
    with open(filename, "w") as f:
        json.dump(certificate, f, indent=4)

    print(f"[+] Wipe certificate generated: {filename}")

if __name__ == "__main__":
    print("=== Secure Disk Wipe Tool (NIST SP 800-88) ===")
    disk_number = int(input("Enter disk number to wipe (check with 'diskpart -> list disk'): "))
    fs = input("Enter file system for new partition (NTFS/FAT32, default NTFS): ") or "NTFS"
    media_type = input("Enter media type (HDD/SSD): ").strip().upper() or "HDD"

    if media_type == "SSD":
        print("[!] Warning: Overwriting SSD may not erase all hidden cells due to wear-leveling.")
        print("    Consider using manufacturer secure erase or encryption reset for full sanitization.")

    prepare_disk(disk_number)
    start_time, end_time, checksum = wipe_drive(disk_number)  # 2 passes default
    create_partition_and_format(disk_number, fs=fs)
    size_bytes = get_drive_size(disk_number)

    generate_certificate(
        disk_number=disk_number,
        media_type=media_type,
        size_bytes=size_bytes,
        passes=2,
        method="Clear (2-pass random overwrite, NIST SP 800-88)",
        start_time=start_time,
        end_time=end_time,
        checksum=checksum
    )

    print("[+] All steps completed successfully!")
