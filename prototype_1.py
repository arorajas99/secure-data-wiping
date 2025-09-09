import tkinter as tk
from tkinter import ttk, messagebox
import threading
import os
import ctypes
import subprocess
import time
import json
import hashlib
from datetime import datetime
from fpdf import FPDF

# ---------------- Backend Functions ----------------

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
    run_diskpart(script)

def create_partition_and_format(drive_number, fs="NTFS", label="WIPED_DRIVE"):
    script = f"""
select disk {drive_number}
create partition primary
format fs={fs} label={label} quick
assign
exit
"""
    run_diskpart(script)

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

def wipe_drive(drive_number, passes=2, block_size=32*1024*1024, progress_callback=None):
    path = f"\\\\.\\PhysicalDrive{drive_number}"
    size = get_drive_size(drive_number)
    handle = os.open(path, os.O_RDWR | os.O_BINARY)
    total_blocks = size // block_size
    final_hash = hashlib.sha256()
    start_time = datetime.now()

    for p in range(passes):
        os.lseek(handle, 0, os.SEEK_SET)
        for i in range(int(total_blocks)):
            data = os.urandom(block_size)
            os.write(handle, data)
            if p == passes - 1:
                final_hash.update(data)
            if progress_callback and i % 50 == 0:
                progress = int((i / total_blocks) * 100)
                progress_callback(progress)
        remaining = size % block_size
        if remaining:
            data = os.urandom(int(remaining))
            os.write(handle, data)
            if p == passes - 1:
                final_hash.update(data)
        os.fsync(handle)
    os.close(handle)
    if progress_callback:
        progress_callback(100)
    end_time = datetime.now()
    return start_time, end_time, final_hash.hexdigest()

def generate_certificate(disk_number, method, size_bytes, passes, start_time, end_time, checksum):
    certificate = {
        "Disk Number": disk_number,
        "Overwrite Passes": passes,
        "Sanitization Method": method,
        "Size (Bytes)": size_bytes,
        "Start Time": start_time.isoformat(),
        "End Time": end_time.isoformat(),
        "Final Pass SHA256": checksum
    }
    filename = f"wipe_certificate_disk{disk_number}.json"
    with open(filename, "w") as f:
        json.dump(certificate, f, indent=4)
    # Optional PDF certificate
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", "B", 16)
    pdf.cell(0, 10, "Certificate of Secure Wipe", ln=True, align="C")
    pdf.ln(10)
    pdf.set_font("Arial", "", 12)
    pdf.cell(0, 10, f"Disk Wiped: {disk_number}", ln=True)
    pdf.cell(0, 10, f"Wiping Method: {method}", ln=True)
    pdf.cell(0, 10, f"Size (Bytes): {size_bytes}", ln=True)
    pdf.cell(0, 10, f"Start Time: {start_time}", ln=True)
    pdf.cell(0, 10, f"End Time: {end_time}", ln=True)
    pdf.cell(0, 10, f"SHA256 Checksum: {checksum}", ln=True)
    pdf_filename = f"wipe_certificate_disk{disk_number}.pdf"
    pdf.output(pdf_filename)
    messagebox.showinfo("Certificate Generated", f"JSON saved as {filename}\nPDF saved as {pdf_filename}")

# ---------------- GUI ----------------

root = tk.Tk()
root.title("Secure Wipe Tool")
root.geometry("400x300")

# Detect disks (simple example)
disks = ["Disk 0", "Disk 1", "Disk 2"]  # Can be replaced with dynamic detection
selected_drive = tk.StringVar(root)
selected_drive.set(disks[0])

tk.Label(root, text="Select Disk Number:", font=("Arial", 10)).pack()
tk.OptionMenu(root, selected_drive, *disks).pack(pady=5)

methods = ["Quick Wipe", "Full Wipe (2-pass Random)"]
selected_method = tk.StringVar(root)
selected_method.set(methods[1])

tk.Label(root, text="Select Wipe Method:", font=("Arial", 10)).pack()
tk.OptionMenu(root, selected_method, *methods).pack(pady=5)

progress = ttk.Progressbar(root, length=300, mode="determinate")
progress.pack(pady=20)

def start_wipe_thread():
    threading.Thread(target=start_wipe, daemon=True).start()

def start_wipe():
    disk_number = int(selected_drive.get().split()[1])
    method = selected_method.get()
    passes = 1 if "Quick" in method else 2

    confirm = messagebox.askyesno(
        "Confirm Wipe",
        f"Are you sure you want to wipe Disk {disk_number}? This CANNOT be undone!"
    )
    if not confirm:
        return

    progress["value"] = 0
    root.update_idletasks()

    try:
        prepare_disk(disk_number)
        start_time, end_time, checksum = wipe_drive(disk_number, passes=passes, progress_callback=lambda p: progress.config(value=p))
        create_partition_and_format(disk_number)
        size_bytes = get_drive_size(disk_number)
        generate_certificate(disk_number, method, size_bytes, passes, start_time, end_time, checksum)
        messagebox.showinfo("Done", f"Wiping Completed Successfully ✅\nDisk {disk_number}")
    except Exception as e:
        messagebox.showerror("Error", f"Wipe failed!\n{str(e)}")

tk.Button(root, text="Start Wipe", command=start_wipe_thread).pack(pady=10)
root.mainloop()
