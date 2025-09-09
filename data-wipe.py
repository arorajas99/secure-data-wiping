import os
import ctypes
import subprocess

# Windows API constants
GENERIC_READ  = 0x80000000
GENERIC_WRITE = 0x40000000
FILE_SHARE_READ = 0x1
FILE_SHARE_WRITE = 0x2
OPEN_EXISTING = 3

IOCTL_DISK_GET_DRIVE_GEOMETRY_EX = 0x700A0

def get_drive_size(drive_number=1):
    """Return size of PhysicalDriveN in bytes."""
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
    if handle == -1:
        raise OSError("Could not open drive")

    buf = ctypes.create_string_buffer(1024)
    bytes_returned = ctypes.c_ulong()
    res = ctypes.windll.kernel32.DeviceIoControl(
        handle,
        IOCTL_DISK_GET_DRIVE_GEOMETRY_EX,
        None,
        0,
        buf,
        len(buf),
        ctypes.byref(bytes_returned),
        None
    )
    ctypes.windll.kernel32.CloseHandle(handle)

    if res == 0:
        raise OSError("DeviceIoControl failed")

    # offset 24–32 is DiskSize
    size = ctypes.c_longlong.from_buffer_copy(buf[24:32]).value
    return size

def wipe_drive(drive_number=1, passes=1):
    """
    Securely wipe an entire Windows physical drive using Win32 API.
    """
    path = f"\\\\.\\PhysicalDrive{drive_number}"
    size = get_drive_size(drive_number)
    block_size = 1024 * 1024  # 1MB

    print(f"[+] Target: {path}, Size: {size/(1024*1024):.2f} MB")

    # Open raw disk handle for read/write
    handle = ctypes.windll.kernel32.CreateFileW(
        path,
        GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        None,
        OPEN_EXISTING,
        0,
        None
    )
    if handle == -1:
        raise OSError("Failed to open drive (Admin required)")

    # Python file object wrapper
    import msvcrt
    fd = msvcrt.open_osfhandle(handle, os.O_RDWR)

    with os.fdopen(fd, "wb", buffering=0) as raw:
        for p in range(passes):
            print(f"[+] Pass {p+1}/{passes}...")
            written = 0
            while written < size:
                raw.write(os.urandom(block_size))
                written += block_size
                if written % (100*1024*1024) == 0:  # every 100MB
                    print(f"    {written/(1024*1024):.0f} MB written...")

    print("[+] Wipe complete.")

    # Step 2: recreate partition + format
    print("[+] Formatting wiped disk as NTFS...")
    diskpart_script = f"""
    select disk {drive_number}
    create partition primary
    format fs=ntfs quick label=WIPED
    assign letter=E
    exit
    """
    process = subprocess.run(
        ["diskpart"],
        input=diskpart_script,
        text=True,
        capture_output=True
    )
    if process.returncode == 0:
        print("[+] Disk formatted successfully (NTFS, E:, label=WIPED).")
    else:
        print("[!] Diskpart failed:\n", process.stderr)


# ⚠️ Example usage:
# This will WIPE Disk 1 (external drive)
wipe_drive(1, passes=1)
