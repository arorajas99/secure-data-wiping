import tkinter as tk
from tkinter import ttk, messagebox
import threading
from fpdf import FPDF
from datetime import datetime
import win32file
import win32con
import win32api
import os
import hashlib

# ---------------- Backend Wiping Logic ----------------

# Windows control codes
FSCTL_LOCK_VOLUME = 0x00090018
FSCTL_DISMOUNT_VOLUME = 0x00090020

def get_available_drives():
    """Gets a list of available drive letters."""
    drives = win32api.GetLogicalDriveStrings()
    return [d.strip('\\') for d in drives.split('\0') if d]

def wipe_drive(drive_letter, passes, progress_callback, status_callback):
    """
    Performs a demo wipe on the first 128MB of the selected drive.
    Updates GUI via callbacks.
    """
    path = fr'\\.\{drive_letter}'
    test_size = 128 * 1024 * 1024  # 128MB for demo
    block_size = 1024 * 1024       # 1MB blocks

    status_callback(f"Starting wipe on {drive_letter}...")
    
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
        status_callback(f"Locking and dismounting {drive_letter}...")
        win32file.DeviceIoControl(handle, FSCTL_LOCK_VOLUME, None, 0)
        win32file.DeviceIoControl(handle, FSCTL_DISMOUNT_VOLUME, None, 0)
    except Exception as e:
        messagebox.showerror("Error", f"Could not open or lock drive {drive_letter}.\nRun as Administrator.\n\nError: {e}")
        return None, None, None

    total_blocks = test_size // block_size
    final_hash = hashlib.sha256()
    start_time = datetime.now()

    try:
        for p in range(passes):
            status_callback(f"Pass {p + 1}/{passes}...")
            win32file.SetFilePointer(handle, 0, win32con.FILE_BEGIN)
            for i in range(total_blocks):
                rand_block = os.urandom(block_size)
                win32file.WriteFile(handle, rand_block)
                final_hash.update(rand_block)
                
                # Calculate overall progress
                progress = int(((p * total_blocks + i + 1) / (passes * total_blocks)) * 100)
                progress_callback(progress)
        
        status_callback("Wipe completed. Finalizing...")
    except Exception as e:
        messagebox.showerror("Write Error", f"An error occurred while writing to {drive_letter}:\n{e}")
        return start_time, datetime.now(), final_hash.hexdigest()
    finally:
        handle.close()

    end_time = datetime.now()
    return start_time, end_time, final_hash.hexdigest()

# ---------------- GUI Functions ----------------

def generate_certificate(drive, method, start_time, end_time, checksum):
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", "B", 16)
    pdf.cell(0, 10, "Certificate of Secure Wipe", ln=True, align="C")
    
    pdf.ln(10)
    pdf.set_font("Arial", "", 12)
    pdf.cell(0, 8, f"Drive Wiped: {drive}", ln=True)
    pdf.cell(0, 8, f"Wiping Method: {method}", ln=True)
    pdf.cell(0, 8, f"Start Time: {start_time.strftime('%Y-%m-%d %H:%M:%S')}", ln=True)
    pdf.cell(0, 8, f"End Time: {end_time.strftime('%Y-%m-%d %H:%M:%S')}", ln=True)
    pdf.cell(0, 8, f"Final Pass SHA256: {checksum}", ln=True)
    
    pdf.ln(10)
    pdf.set_font("Arial", "I", 10)
    pdf.cell(0, 10, "This certificate confirms that the first 128MB of the selected drive were securely wiped.", ln=True)

    filename = f"CleanSlate_Wipe_{drive.replace(':', '')}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    pdf.output(filename)
    messagebox.showinfo("Certificate Generated", f"Certificate saved as:\n{filename}")

def update_progress(value):
    progress["value"] = value

def update_status(text):
    status_label.config(text=text)

def wipe_worker():
    drive = selected_drive.get()
    method = selected_method.get()
    
    # Map method to passes
    method_passes = {
        "Quick Wipe (1 Pass)": 1,
        "DoD 5220.22-M (3 Passes)": 3,
        "Gutmann (35 Passes)": 35
    }
    passes = method_passes.get(method, 1)

    start_time, end_time, checksum = wipe_drive(drive, passes, update_progress, update_status)

    # Re-enable GUI elements after wipe is done
    start_btn.config(state="normal")
    drive_dropdown.config(state="normal")
    method_dropdown.config(state="normal")

    if start_time and end_time and checksum:
        update_status(f"Wipe of {drive} completed successfully!")
        messagebox.showinfo("Done", f"Wiping Completed Successfully ✅\n\nDrive: {drive}\nMethod: {method}")
        generate_certificate(drive, method, start_time, end_time, checksum)
    else:
        update_status("Wipe failed. Check logs or permissions.")
        progress["value"] = 0

def start_wipe():
    drive = selected_drive.get()
    if not messagebox.askyesno("Confirm Wipe", 
        f"!! WARNING !!\n\nThis is a demo that will PERMANENTLY OVERWRITE the first 128MB of drive {drive}.\n\nAre you sure you want to continue?"):
        return

    start_btn.config(state="disabled")
    drive_dropdown.config(state="disabled")
    method_dropdown.config(state="disabled")
    progress["value"] = 0
    
    # Run the wipe function in a separate thread
    threading.Thread(target=wipe_worker, daemon=True).start()

# ---------------- Main Window Setup ----------------
root = tk.Tk()
root.title("CleanSlate - Secure Wipe Tool")
root.geometry("450x350")
root.resizable(False, False)

# ---------- Header ----------
header_frame = ttk.Frame(root, padding=(0, 10))
header_frame.pack(fill="x")
header = tk.Label(header_frame, text="CleanSlate", font=("Arial", 18, "bold"))
header.pack()
warning_label = tk.Label(header_frame, text="SAFE DEMO - Wipes first 128MB only", font=("Arial", 9, "italic"), fg="red")
warning_label.pack()

# ---------- Main Frame ----------
main_frame = ttk.Frame(root, padding=20)
main_frame.pack(fill="both", expand=True)
main_frame.columnconfigure(1, weight=1)

# Drive options
drives = get_available_drives()
selected_drive = tk.StringVar()

drive_label = ttk.Label(main_frame, text="Select Drive:", font=("Arial", 10))
drive_label.grid(row=0, column=0, sticky="w", pady=5, padx=5)
drive_dropdown = ttk.OptionMenu(main_frame, selected_drive, drives[0] if drives else "No drives found", *drives)
drive_dropdown.grid(row=0, column=1, sticky="ew", pady=5)
if not drives:
    drive_dropdown.config(state="disabled")

# Method options
methods = ["Quick Wipe (1 Pass)", "DoD 5220.22-M (3 Passes)", "Gutmann (35 Passes)"]
selected_method = tk.StringVar()
selected_method.set(methods[0])

method_label = ttk.Label(main_frame, text="Select Wiping Method:", font=("Arial", 10))
method_label.grid(row=1, column=0, sticky="w", pady=5, padx=5)
method_dropdown = ttk.OptionMenu(main_frame, selected_method, *methods)
method_dropdown.grid(row=1, column=1, sticky="ew", pady=5)

# Progress bar
progress = ttk.Progressbar(main_frame, length=250, mode="determinate")
progress.grid(row=2, column=0, columnspan=2, pady=20)

# Status Label
status_label = ttk.Label(main_frame, text="Ready to start.", font=("Arial", 9))
status_label.grid(row=3, column=0, columnspan=2)

# Start button
start_btn = ttk.Button(main_frame, text="Start Wipe", command=start_wipe)
start_btn.grid(row=4, column=0, columnspan=2, pady=10)
if not drives:
        start_btn.config(state="disabled")
root.mainloop()