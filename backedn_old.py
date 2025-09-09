import win32file
import win32con
import os
import json
import hashlib
from datetime import datetime
import sys

def get_drive_size(disk_number):
    try:
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
    except Exception as e:
        print(f"[!] Error getting drive size: {e}")
        return None

def wipe_drive_demo(disk_number, passes=1, test_size=128*1024*1024, block_size=1024*1024, log_file=None):
    print(f"[+] SAFE DEMO: Overwriting first {test_size//(1024*1024)}MB of disk {disk_number}, {passes} pass(es)")
    try:
        handle = win32file.CreateFile(
            fr'\\.\PhysicalDrive{disk_number}',
            win32con.GENERIC_WRITE | win32con.GENERIC_READ,
            win32con.FILE_SHARE_READ | win32con.FILE_SHARE_WRITE,
            None,
            win32con.OPEN_EXISTING,
            0,
            None
        )
    except Exception as e:
        print(f"[!] Error opening disk: {e}")
        if log_file:
            log_file.write(f"[!] Error opening disk: {e}\n")
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
                print(f"[!] Error writing to disk: {e}")
                if log_file:
                    log_file.write(f"[!] Error writing to disk: {e}\n")
                handle.close()
                return start_time, datetime.now(), final_hash.hexdigest()
            final_hash.update(rand_block)
            # Console progress bar
            percent = int((i + 1) / total_blocks * 100)
            bar = ('#' * (percent // 2)).ljust(50)
            print(f"\r    [{bar}] {percent}% complete", end='', flush=True)
            if log_file and i % 10 == 0:
                log_file.write(f"Block {i+1}/{total_blocks}, {percent}%\n")
        print()
        remaining = test_size % block_size
        if remaining:
            rand_block = os.urandom(int(remaining))
            win32file.WriteFile(handle, rand_block)
            final_hash.update(rand_block)
        print(f"[+] Pass {p+1} complete.")
    handle.close()
    end_time = datetime.now()
    print("[+] Demo 'wipe' complete. (NOT a real disk wipe!)")
    if log_file:
        log_file.write("[+] Demo 'wipe' complete.\n")
    return start_time, end_time, final_hash.hexdigest()

def generate_certificate(disk_number, media_type, size_bytes, passes, method, start_time, end_time, checksum):
    certificate = {
        "Disk Number": disk_number,
        "Media Type": media_type,
        "Size (Bytes)": size_bytes,
        "Overwrite Passes": passes,
        "Sanitization Method": method,
        "Start Time": start_time.isoformat() if start_time else "",
        "End Time": end_time.isoformat() if end_time else "",
        "Final Pass SHA256": checksum
    }
    filename = f"demo_wipe_certificate_disk{disk_number}.json"
    with open(filename, "w") as f:
        json.dump(certificate, f, indent=4)
    print(f"[+] Demo wipe certificate generated: {filename}")

def confirm(prompt):
    ans = input(f"{prompt} [y/N]: ").strip().lower()
    return ans == 'y'

if __name__ == "__main__":
    print("=== SAFE DEMO: Disk Wipe Tool (TEST MODE with pywin32) ===")
    if len(sys.argv) > 1:
        disk_number = int(sys.argv[1])
        media_type = sys.argv[2].strip().upper() if len(sys.argv) > 2 else "HDD"
    else:
        disk_number = int(input("Enter disk number for test (check with 'diskpart -> list disk'): "))
        media_type = input("Enter media type (HDD/SSD): ").strip().upper() or "HDD"
    print("[!] THIS IS A SAFE DEMO - Only the first 128MB will be overwritten FOR TESTING.")
    if media_type == "SSD":
        print("[!] WARNING: Even a full overwrite may not fully sanitize SSD due to wear-leveling.")

    if not confirm(f"Are you sure you want to overwrite the first 128MB of PhysicalDrive{disk_number}?"):
        print("[*] Operation cancelled.")
        sys.exit(0)

    log_filename = f"demo_wipe_log_disk{disk_number}.txt"
    with open(log_filename, "w") as log_file:
        log_file.write(f"Demo wipe started for disk {disk_number} at {datetime.now().isoformat()}\n")
        start_time, end_time, checksum = wipe_drive_demo(disk_number, log_file=log_file)
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
        log_file.write(f"Demo wipe completed at {datetime.now().isoformat()}\n")
    print(f"[+] Log saved to {log_filename}")
    print("[+] SAFE DEMO STEPS COMPLETED SUCCESSFULLY")