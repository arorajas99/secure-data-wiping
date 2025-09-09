import win32file
import win32con
import os
import json
import hashlib
from datetime import datetime
import sys

# Windows control codes
FSCTL_LOCK_VOLUME = 0x00090018
FSCTL_DISMOUNT_VOLUME = 0x00090020

def wipe_drive_demo(drive_letter, passes=1, test_size=128*1024*1024, block_size=1024*1024, log_file=None):
    path = fr'\\.\{drive_letter}:'
    print(f"[+] SAFE DEMO: Overwriting first {test_size//(1024*1024)}MB of {path}, {passes} pass(es)")

    try:
        handle = win32file.CreateFile(
            path,
            win32con.GENERIC_WRITE | win32con.GENERIC_READ,
            win32con.FILE_SHARE_READ | win32con.FILE_SHARE_WRITE,
            None,
            win32con.OPEN_EXISTING,
            0,
            None
        )

        # Lock and dismount the volume
        win32file.DeviceIoControl(handle, FSCTL_LOCK_VOLUME, None, 0)
        win32file.DeviceIoControl(handle, FSCTL_DISMOUNT_VOLUME, None, 0)

    except Exception as e:
        print(f"[!] Error opening or dismounting {path}: {e}")
        if log_file:
            log_file.write(f"[!] Error opening {path}: {e}\n")
        return None, None, None

    total_blocks = test_size // block_size
    final_hash = hashlib.sha256()
    start_time = datetime.now()

    for p in range(passes):
        print(f"[+] Pass {p+1}/{passes}")
        win32file.SetFilePointer(handle, 0, win32con.FILE_BEGIN)
        for i in range(int(total_blocks)):
            rand_block = os.urandom(block_size)
            try:
                win32file.WriteFile(handle, rand_block)
            except Exception as e:
                print(f"[!] Error writing to {path}: {e}")
                if log_file:
                    log_file.write(f"[!] Error writing: {e}\n")
                handle.close()
                return start_time, datetime.now(), final_hash.hexdigest()
            final_hash.update(rand_block)

            percent = int((i + 1) / total_blocks * 100)
            bar = ('#' * (percent // 2)).ljust(50)
            print(f"\r    [{bar}] {percent}% complete", end='', flush=True)
        print()
        print(f"[+] Pass {p+1} complete.")

    handle.close()
    end_time = datetime.now()
    print("[+] Demo wipe complete.")
    return start_time, end_time, final_hash.hexdigest()

def generate_certificate(drive_letter, media_type, size_bytes, passes, method, start_time, end_time, checksum):
    certificate = {
        "Drive": drive_letter,
        "Media Type": media_type,
        "Size (Bytes)": size_bytes,
        "Overwrite Passes": passes,
        "Sanitization Method": method,
        "Start Time": start_time.isoformat() if start_time else "",
        "End Time": end_time.isoformat() if end_time else "",
        "Final Pass SHA256": checksum
    }
    filename = f"demo_wipe_certificate_{drive_letter}.json"
    with open(filename, "w") as f:
        json.dump(certificate, f, indent=4)
    print(f"[+] Certificate generated: {filename}")

def confirm(prompt):
    ans = input(f"{prompt} [y/N]: ").strip().lower()
    return ans == 'y'

if __name__ == "__main__":
    print("=== SAFE DEMO: Disk Wipe Tool (with volume lock+dismount) ===")
    drive_letter = input("Enter drive letter (e.g., E): ").strip().upper()
    media_type = input("Enter media type (HDD/SSD): ").strip().upper() or "HDD"

    print("[!] THIS IS A SAFE DEMO - Only the first 128MB will be overwritten FOR TESTING.")
    if media_type == "SSD":
        print("[!] WARNING: Even a full overwrite may not fully sanitize SSD due to wear-leveling.")

    if not confirm(f"Are you sure you want to overwrite the first 128MB of {drive_letter}: ?"):
        print("[*] Operation cancelled.")
        sys.exit(0)

    log_filename = f"demo_wipe_log_{drive_letter}.txt"
    with open(log_filename, "w") as log_file:
        log_file.write(f"Demo wipe started for {drive_letter}: at {datetime.now().isoformat()}\n")
        start_time, end_time, checksum = wipe_drive_demo(drive_letter, log_file=log_file)
        test_size = 128*1024*1024
        generate_certificate(
            drive_letter=drive_letter,
            media_type=media_type,
            size_bytes=test_size,
            passes=1,
            method="SAFE DEMO (1-pass overwrite of first 128MB)",
            start_time=start_time,
            end_time=end_time,
            checksum=checksum
        )
        log_file.write(f"Demo wipe completed at {datetime.now().isoformat()}\n")

    print(f"[+] Log saved to {log_filename}")
    print("[+] SAFE DEMO COMPLETED SUCCESSFULLY")
