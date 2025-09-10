  import tkinter as tk
from tkinter import ttk, messagebox
import time
from fpdf import FPDF
from datetime import datetime

# ---------------- PDF Certificate Function ----------------
def generate_certificate(drive, method):
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", "B", 16)
    pdf.cell(0, 10, "Certificate of Secure Wipe", ln=True, align="C")
    
    pdf.ln(10)
    pdf.set_font("Arial", "", 12)
    pdf.cell(0, 10, f"Drive Wiped: {drive}", ln=True)
    pdf.cell(0, 10, f"Wiping Method: {method}", ln=True)
    pdf.cell(0, 10, f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", ln=True)
    
    pdf.ln(10)
    pdf.cell(0, 10, "This certificate confirms that the selected drive was securely wiped.", ln=True)

    filename = f"SecureWipe_{drive.replace(' ', '_')}.pdf"
    pdf.output(filename)
    messagebox.showinfo("Certificate Generated", f"Certificate saved as:\n{filename}")

# ---------------- Start Wipe Function ----------------
def start_wipe():
    progress["value"] = 0
    root.update_idletasks()

    chosen_drive = selected_drive.get()
    chosen_method = selected_method.get()

    # Simulate wiping in steps
    for i in range(5):
        time.sleep(1)  # wait 1 sec
        progress["value"] += 20
        root.update_idletasks()

    # Show success popup
    messagebox.showinfo("Done", 
        f"Wiping Completed Successfully ✅\n\n"
        f"Drive: {chosen_drive}\n"
        f"Method: {chosen_method}"
    )

    # Generate PDF certificate
    generate_certificate(chosen_drive, chosen_method)

# ---------------- Main Window ----------------
root = tk.Tk()
root.title("Secure Wipe Tool - Simulation")

# Drive options
drives = ["USB Drive (8GB)", "Hard Disk (500GB)", "SSD (1TB)"]
selected_drive = tk.StringVar(root)
selected_drive.set(drives[0])

drive_label = tk.Label(root, text="Select Drive:", font=("Arial", 10))
drive_label.pack()
drive_dropdown = tk.OptionMenu(root, selected_drive, *drives)
drive_dropdown.pack(pady=5)

# Method options
methods = ["Quick Wipe", "DoD 5220.22-M", "NIST 800-88"]
selected_method = tk.StringVar(root)
selected_method.set(methods[0])

method_label = tk.Label(root, text="Select Wiping Method:", font=("Arial", 10))
method_label.pack()
method_dropdown = tk.OptionMenu(root, selected_method, *methods)
method_dropdown.pack(pady=5)

# Progress bar
progress = ttk.Progressbar(root, length=250, mode="determinate")
progress.pack(pady=20)

# Start button
start_btn = tk.Button(root, text="Start Wipe", command=start_wipe)
start_btn.pack(pady=10)

# Run app
root.mainloop()

