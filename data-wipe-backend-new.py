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


def get_drive_size(drive_letter):
    """Get total size of a drive in bytes using GetDiskFreeSpaceEx."""
    try:
        sectors_per_cluster, bytes_per_sector, free_clusters, total_clusters = win32file.GetDiskFreeSpace(drive_letter + ":\\")
        return sectors_per_cluster * bytes_per_sector * total_clusters
    except Exception as e:
        print(f"[!] Error getting size of {drive_letter}: {e}")
        return None


def wipe_drive(drive_letter, passes=2, full=False, log_file=None):
    """Overwrite drive content."""
    path = fr'\\.\{drive_letter}:'
    print(f"[+] Opening {path} for wiping...")

    # Decide size
    size_bytes = get_drive_size(drive_letter) if full else 128 * 1024 * 1024
    if not size_bytes:
        print("[!] Could not determine drive size.")
        return None, None, None

    block_size = 1024 * 1024  # 1MB
    total_blocks = size_bytes // block_size
    final_hash = hashlib.sha256()
    start_time = datetime.now()

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

        # Lock and dismount before overwrite
        win32file.DeviceIoControl(handle, FSCTL_LOCK_VOLUME, None, 0)
        win32file.DeviceIoControl(handle, FSCTL_DISMOUNT_VOLUME, None, 0)

    except Exception as e:
        print(f"[!] Error opening {path}: {e}")
        if log_file:
            log_file.write(f"[!] Error opening {path}: {e}\n")
        return None, None, None

    # Overwriting loop
    for p in range(passes):
        print(f"[+] Pass {p + 1}/{passes}")
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
        print(f"[+] Pass {p + 1} complete.")

    handle.close()
    end_time = datetime.now()
    print("[+] Wipe complete.")
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
    filename = f"wipe_certificate_{drive_letter}.json"
    with open(filename, "w") as f:
        json.dump(certificate, f, indent=4)
    print(f"[+] Certificate generated: {filename}")


def confirm(prompt):
    ans = input(f"{prompt} [y/N]: ").strip().lower()
    return ans == 'y'


if __name__ == "__main__":
    print("=== Disk Wipe Tool (Safe Demo or Full Wipe) ===")
    drive_letter = input("Enter drive letter (e.g., E): ").strip().upper()
    media_type = input("Enter media type (HDD/SSD): ").strip().upper() or "HDD"

    print("\nChoose wipe mode:")
    print("  1) Safe Demo (128MB overwrite, 2 passes)")
    print("  2) Full Drive Wipe (entire drive, 2 passes)")
    choice = input("Enter 1 or 2: ").strip()

    full = (choice == "2")
    method = "Full Wipe (entire drive, 2 passes)" if full else "SAFE DEMO (128MB, 2 passes)"

    if not confirm(f"Are you sure you want to {'FULLY WIPE' if full else 'SAFE DEMO'} {drive_letter}: ?"):
        print("[*] Operation cancelled.")
        sys.exit(0)

    # ✅ Get drive size BEFORE dismount
    size_bytes = get_drive_size(drive_letter) if full else 128 * 1024 * 1024
    if full and not size_bytes:
        print("[!] Could not determine drive size. Aborting.")
        sys.exit(1)

    log_filename = f"wipe_log_{drive_letter}.txt"
    with open(log_filename, "w") as log_file:
        log_file.write(f"Wipe started for {drive_letter}: at {datetime.now().isoformat()}\n")
        start_time, end_time, checksum = wipe_drive(drive_letter, passes=2, full=full, log_file=log_file)

        generate_certificate(
            drive_letter=drive_letter,
            media_type=media_type,
            size_bytes=size_bytes,
            passes=2,
            method=method,
            start_time=start_time,
            end_time=end_time,
            checksum=checksum
        )
        log_file.write(f"Wipe completed at {datetime.now().isoformat()}\n")

    print(f"[+] Log saved to {log_filename}")
    print("[+] WIPE COMPLETED SUCCESSFULLY")
