import tkinter as tk
from tkinter import ttk, messagebox, simpledialog
import threading
from fpdf import FPDF
from datetime import datetime
from backend import wipe_drive_demo  # <-- your backend demo function

# ---------------- PDF Certificate Function ----------------
def generate_pdf_certificate(drive, method, start_time, end_time, checksum):
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", "B", 16)
    pdf.cell(0, 10, "CleanSlate - Certificate of Secure Wipe", ln=True, align="C")
    
    pdf.ln(10)
    pdf.set_font("Arial", "", 12)
    pdf.cell(0, 10, f"Drive Wiped: {drive}", ln=True)
    pdf.cell(0, 10, f"Wiping Method: {method}", ln=True)
    pdf.cell(0, 10, f"Start Time: {start_time}", ln=True)
    pdf.cell(0, 10, f"End Time: {end_time}", ln=True)
    pdf.cell(0, 10, f"Final SHA256 (first 128MB): {checksum}", ln=True)
    
    pdf.ln(10)
    pdf.cell(0, 10, "This certificate confirms that the selected drive was securely wiped.", ln=True)

    filename = f"CleanSlate_Wipe_{drive}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    pdf.output(filename)
    messagebox.showinfo("Certificate Generated", f"Certificate saved as:\n{filename}")

# ---------------- Wipe Thread ----------------
def perform_wipe(drive_letter, media_type):
    start_btn.config(state="disabled")
    progress["value"] = 0

    def progress_callback(percent):
        progress["value"] = percent
        root.update_idletasks()

    try:
        start_time, end_time, checksum = wipe_drive_demo(
            drive_letter,
            passes=1,
            log_file=None
        )
        progress["value"] = 100
        messagebox.showinfo("Wipe Completed",
                            f"Drive {drive_letter}: wiped successfully.\nMethod: SAFE DEMO")
        generate_pdf_certificate(drive_letter, "SAFE DEMO", start_time, end_time, checksum)
    except Exception as e:
        messagebox.showerror("Error", f"An error occurred:\n{str(e)}")
    finally:
        start_btn.config(state="normal")
        progress["value"] = 0

def start_wipe():
    drive_letter = int(selected_drive.get().replace("Disk ", ""))
    media_type = simpledialog.askstring("Media Type", "Enter media type (HDD/SSD):", initialvalue="HDD")
    if not media_type:
        media_type = "HDD"

    confirm = messagebox.askyesno("Confirm Wipe",
                                  f"Are you sure you want to wipe Disk {drive_letter} ({media_type})?\n"
                                  f"This will overwrite the first 128MB (SAFE DEMO).")
    if confirm:
        threading.Thread(target=perform_wipe, args=(drive_letter, media_type), daemon=True).start()

# ---------------- Main Window ----------------
root = tk.Tk()
root.title("CleanSlate - Secure Wipe Tool")
root.geometry("450x320")
root.resizable(False, False)

# ---------- Header ----------
header = tk.Label(root, text="CleanSlate", font=("Arial", 20, "bold"))
header.pack(pady=10)

# ---------- Main Frame ----------
main_frame = ttk.Frame(root, padding=20)
main_frame.pack(fill="both", expand=True)

# Drive options (Disk numbers)
drives = ["Disk 0", "Disk 1", "Disk 2"]
selected_drive = tk.StringVar()
selected_drive.set(drives[0])

drive_label = ttk.Label(main_frame, text="Select Drive:", font=("Arial", 12))
drive_label.grid(row=0, column=0, sticky="w", pady=5)
drive_dropdown = ttk.OptionMenu(main_frame, selected_drive, *drives)
drive_dropdown.grid(row=0, column=1, pady=5)

# Progress bar
progress = ttk.Progressbar(main_frame, length=300, mode="determinate")
progress.grid(row=1, column=0, columnspan=2, pady=20)

# Start button
start_btn = ttk.Button(main_frame, text="Start SAFE Demo Wipe", command=start_wipe)
start_btn.grid(row=2, column=0, columnspan=2, pady=10)

root.mainloop()
