import tkinter as tk
from tkinter import ttk, messagebox, simpledialog
import subprocess
import os
import json
import signal
from datetime import datetime
import uuid

# --- PDF Generation Dependency ---
try:
    from reportlab.pdfgen import canvas
    from reportlab.lib.pagesizes import letter
    from reportlab.lib.units import inch
    REPORTLAB_AVAILABLE = True
except ImportError:
    REPORTLAB_AVAILABLE = False


class CleanSlateApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("CleanSlate Secure Wiper for Linux")
        self.geometry("800x650")
        self.minsize(700, 600)
        self.configure(bg="#2E2E2E")
        self.wipe_process = None
        self.current_wipe_info = {}
        self.was_cancelled = False

        # --- Style Configuration ---
        style = ttk.Style(self)
        style.theme_use("clam")
        
        # ... (Styling code is identical to previous version, redacted for brevity) ...
        bg_color = "#2E2E2E"; fg_color = "#E0E0E0"; entry_bg = "#3C3C3C"; entry_fg = "#FFFFFF"; button_bg = "#007BFF"; button_fg = "#FFFFFF"; button_active = "#0056b3"; quick_wipe_bg = "#17A2B8"; quick_wipe_active = "#117A8B"; danger_bg = "#DC3545"; danger_active = "#a02531"; cancel_bg = "#FFC107"; cancel_fg = "#1F1F1F"; cancel_active = "#d39e00"; tree_bg = "#333333"; tree_fg = "#E0E0E0"; tree_field_bg = "#3C3C3C"; separator_color = "#4A4A4A"
        style.configure(".", background=bg_color, foreground=fg_color, font=('Helvetica', 10)); style.configure("TLabel", background=bg_color, foreground=fg_color, padding=5); style.configure("TButton", background=button_bg, foreground=button_fg, padding=10, font=('Helvetica', 10, 'bold'), borderwidth=0); style.map("TButton", background=[('active', button_active)]); style.configure("QuickWipe.TButton", background=quick_wipe_bg, foreground=button_fg); style.map("QuickWipe.TButton", background=[('active', quick_wipe_active)]); style.configure("Danger.TButton", background=danger_bg, foreground=button_fg); style.map("Danger.TButton", background=[('active', danger_active)]); style.configure("Cancel.TButton", background=cancel_bg, foreground=cancel_fg); style.map("Cancel.TButton", background=[('active', cancel_active)]); style.configure("TEntry", fieldbackground=entry_bg, foreground=entry_fg, insertcolor=entry_fg); style.configure("Treeview", background=tree_bg, foreground=tree_fg, fieldbackground=tree_field_bg, rowheight=25); style.map("Treeview", background=[('selected', button_bg)]); style.configure("Treeview.Heading", background=bg_color, foreground=fg_color, font=('Helvetica', 11, 'bold')); style.configure("TLabelframe", background=bg_color, bordercolor=separator_color); style.configure("TLabelframe.Label", foreground=fg_color, background=bg_color); style.configure("TSeparator", background=separator_color)


        # --- Initial Check ---
        self.check_dependencies()
        self.check_root_privileges()

        # --- Main Layout ---
        main_frame = ttk.Frame(self, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)
        main_frame.columnconfigure(0, weight=1)
        main_frame.rowconfigure(0, weight=1)

        # ... (UI layout code is identical to previous version, redacted for brevity) ...
        drive_frame = ttk.LabelFrame(main_frame, text="Available Drives", padding="10"); drive_frame.grid(row=0, column=0, sticky="nsew", pady=(0, 10)); drive_frame.rowconfigure(0, weight=1); drive_frame.columnconfigure(0, weight=1); columns = ("device", "size", "type", "mountpoint"); self.drive_tree = ttk.Treeview(drive_frame, columns=columns, show="headings"); self.drive_tree.heading("device", text="Device"); self.drive_tree.heading("size", text="Size"); self.drive_tree.heading("type", text="Type"); self.drive_tree.heading("mountpoint", text="Mountpoint"); self.drive_tree.column("device", width=150, stretch=False); self.drive_tree.column("size", width=100, anchor="e", stretch=False); self.drive_tree.column("type", width=100, anchor="center", stretch=False); self.drive_tree.column("mountpoint", width=250); self.drive_tree.grid(row=0, column=0, sticky="nsew"); self.drive_tree.bind('<<TreeviewSelect>>', self.on_drive_select); scrollbar = ttk.Scrollbar(drive_frame, orient=tk.VERTICAL, command=self.drive_tree.yview); self.drive_tree.configure(yscroll=scrollbar.set); scrollbar.grid(row=0, column=1, sticky="ns"); controls_frame = ttk.Frame(main_frame); controls_frame.grid(row=1, column=0, sticky="ew"); controls_frame.columnconfigure(0, weight=1); target_frame = ttk.Frame(controls_frame); target_frame.grid(row=0, column=0, sticky="ew", pady=(0, 10)); target_frame.columnconfigure(1, weight=1); ttk.Label(target_frame, text="Target Device Path:").grid(row=0, column=0, sticky="w", padx=(0, 10)); self.target_drive_entry = ttk.Entry(target_frame); self.target_drive_entry.grid(row=0, column=1, sticky="ew"); self.refresh_button = ttk.Button(target_frame, text="Refresh Drive List", command=self.populate_drives); self.refresh_button.grid(row=0, column=2, sticky="e", padx=(10, 0)); actions_frame = ttk.LabelFrame(controls_frame, text="Wipe Actions", padding="10"); actions_frame.grid(row=1, column=0, sticky="ew", pady=10); actions_frame.columnconfigure((0, 1), weight=1); self.quick_wipe_btn = ttk.Button(actions_frame, text="Quick Wipe (Fast)", style="QuickWipe.TButton", command=lambda: self.initiate_wipe("quick")); self.quick_wipe_btn.grid(row=0, column=0, sticky="ew", padx=(0, 5)); ttk.Label(actions_frame, text="Destroys partition table. Fast but less secure.", font=('Helvetica', 8)).grid(row=1, column=0, sticky="ew", pady=(5,0), padx=(0,5)); self.secure_wipe_btn = ttk.Button(actions_frame, text="Secure Wipe (Slow)", style="Danger.TButton", command=lambda: self.initiate_wipe("secure")); self.secure_wipe_btn.grid(row=0, column=1, sticky="ew", padx=(5, 0)); ttk.Label(actions_frame, text="Overwrites all data. Very slow but highly secure.", font=('Helvetica', 8)).grid(row=1, column=1, sticky="ew", pady=(5,0), padx=(5,0)); cancel_frame = ttk.Frame(controls_frame); cancel_frame.grid(row=2, column=0, sticky="ew", pady=5); cancel_frame.columnconfigure(0, weight=1); self.cancel_button = ttk.Button(cancel_frame, text="Cancel Current Wipe", style="Cancel.TButton", command=self.cancel_wipe); self.cancel_button.grid(row=0, column=0, sticky="ew"); self.cancel_button.state(['disabled'])

        # Initial Population
        self.populate_drives()

    def check_dependencies(self):
        """Check if the required reportlab library for PDF generation is installed."""
        if not REPORTLAB_AVAILABLE:
            messagebox.showerror(
                "Dependency Missing",
                "The 'reportlab' library is required to generate PDF certificates.\n\nPlease install it by running:\n'sudo python3 -m pip install reportlab'"
            )
            self.destroy()
            exit()

    def toggle_buttons(self, is_wiping):
        """Enable/disable buttons based on wipe status."""
        state = 'disabled' if is_wiping else '!disabled'
        self.quick_wipe_btn.state([state])
        self.secure_wipe_btn.state([state])
        self.refresh_button.state([state])
        self.cancel_button.state(['!disabled' if is_wiping else 'disabled'])

    def check_root_privileges(self):
        if os.geteuid() != 0:
            messagebox.showerror("Root Privileges Required", "This application requires root privileges. Please run with 'sudo'.")
            self.destroy()
            exit()

    def populate_drives(self):
        # ... (This function is identical to the previous version) ...
        for i in self.drive_tree.get_children(): self.drive_tree.delete(i);
        try:
            result = subprocess.run(["lsblk", "-b", "-o", "NAME,SIZE,TYPE,MOUNTPOINT", "--json"], capture_output=True, text=True, check=True);
            for device in json.loads(result.stdout).get("blockdevices", []):
                if device.get("type") == "loop": continue;
                size_bytes = int(device.get('size', 0));
                if size_bytes > 1024**4: size_str = f"{size_bytes / 1024**4:.2f} TB"
                elif size_bytes > 1024**3: size_str = f"{size_bytes / 1024**3:.2f} GB"
                elif size_bytes > 1024**2: size_str = f"{size_bytes / 1024**2:.2f} MB"
                else: size_str = f"{size_bytes} B";
                self.drive_tree.insert("", tk.END, values=("/dev/" + device.get("name", "N/A"), size_str, device.get("type", "N/A"), device.get("mountpoint", "Not mounted") or "Not mounted"))
        except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError) as e:
            messagebox.showerror("Error", f"Failed to list drives: {e}")

    def on_drive_select(self, event):
        # ... (This function is identical to the previous version) ...
        selected_item = self.drive_tree.selection();
        if selected_item:
            device_info = self.drive_tree.item(selected_item[0])['values'];
            self.target_drive_entry.delete(0, tk.END);
            self.target_drive_entry.insert(0, device_info[0])

    def initiate_wipe(self, wipe_mode):
        # ... (This function is identical to the previous version until the end) ...
        target_device = self.target_drive_entry.get().strip();
        if not target_device or not target_device.startswith("/dev/"):
            messagebox.showwarning("No Target", "Please select or enter a valid target device (e.g., /dev/sdb)."); return
        try:
            result = subprocess.run(["lsblk", "-b", "--json", target_device], capture_output=True, text=True, check=True);
            device_info = json.loads(result.stdout).get("blockdevices", [{}])[0]; is_mounted = False
            if device_info.get("mountpoint"): is_mounted = True
            for child in device_info.get("children", []):
                if child.get("mountpoint"): is_mounted = True; break
            if is_mounted: messagebox.showerror("Safety Check Failed", f"'{target_device}' is mounted. Please unmount before wiping."); return
        except Exception:
            messagebox.showerror("Error", f"Could not verify status of '{target_device}'. Aborting."); return

        mode_text = "QUICK WIPE" if wipe_mode == "quick" else "SECURE WIPE";
        if not messagebox.askokcancel("ARE YOU SURE?", f"You are about to perform a {mode_text} on:\n\n{target_device}\n\nThis is IRREVERSIBLE and ALL DATA will be PERMANENTLY DESTROYED.", icon='warning'): return

        challenge = simpledialog.askstring("Final Confirmation", f"To proceed, type the full device path '{target_device}' below.", parent=self);
        if challenge != target_device: messagebox.showerror("Confirmation Failed", "The device path did not match. Wipe operation cancelled."); return

        self.current_wipe_info = {'device': target_device, 'mode': wipe_mode, 'start_time': datetime.now()}
        command = f"shred -vfn 1 -z {target_device}" if wipe_mode == "secure" else f"dd if=/dev/zero of={target_device} bs=4M count=25 status=progress"
        self.run_in_terminal(command, target_device)

    def run_in_terminal(self, command, device):
        try:
            terminal_command = f"gnome-terminal -- bash -c '{command}; echo $? > /tmp/cleanslate_exit_code'"
            self.wipe_process = subprocess.Popen(terminal_command, shell=True, preexec_fn=os.setsid)
            self.toggle_buttons(is_wiping=True)
            self.check_wipe_status()
            messagebox.showinfo("Process Started", f"Wipe process started for {device} in a new terminal window.\n\nDO NOT close this main application window.")
        except Exception as e:
            messagebox.showerror("Execution Error", f"Could not open a terminal. Please install 'gnome-terminal' or use a system with 'xterm'.\nError: {e}")

    def check_wipe_status(self):
        """Periodically check if the wipe process has finished."""
        if self.wipe_process and self.wipe_process.poll() is not None:
            # Process has finished
            end_time = datetime.now()
            exit_code = -1
            try:
                with open("/tmp/cleanslate_exit_code", "r") as f:
                    exit_code = int(f.read().strip())
                os.remove("/tmp/cleanslate_exit_code")
            except (IOError, ValueError):
                pass 

            if self.was_cancelled:
                messagebox.showwarning("Cancelled", "The wipe process was cancelled by the user.")
            elif exit_code == 0:
                self.current_wipe_info['end_time'] = end_time
                self.current_wipe_info['status'] = 'Completed Successfully'
                save_path = self.generate_certificate()
                messagebox.showinfo("Success!", f"Wipe completed successfully!\n\nA certificate of destruction has been saved in:\n{save_path}")
            else:
                messagebox.showerror("Wipe Failed", f"The wipe process failed with exit code {exit_code}.")
            
            self.wipe_process = None
            self.toggle_buttons(is_wiping=False)
            self.populate_drives()
            self.was_cancelled = False
            self.current_wipe_info = {}
        else:
            self.after(1000, self.check_wipe_status)

    def cancel_wipe(self):
        """Terminate the running wipe process."""
        if self.wipe_process and self.wipe_process.poll() is None:
            self.was_cancelled = True
            try:
                os.killpg(os.getpgid(self.wipe_process.pid), signal.SIGTERM)
            except Exception:
                pass # The process might have just finished
        else:
            messagebox.showinfo("No Process", "No wipe process is currently running.")

    def _get_save_directory(self):
        """Get the directory to save certificates, creating it if it doesn't exist."""
        try:
            # Get home directory of the user who invoked sudo
            sudo_user = os.environ.get('SUDO_USER')
            if sudo_user:
                home_dir = os.path.expanduser(f"~{sudo_user}")
            else:
                # Fallback for 'sudo su' or direct root login
                home_dir = os.path.expanduser("~")
        except Exception:
            home_dir = os.path.expanduser("~")

        save_dir = os.path.join(home_dir, "cleanslate_certificates")
        os.makedirs(save_dir, exist_ok=True)
        return save_dir

    def generate_certificate(self):
        """Generates JSON and PDF certificates for the completed wipe operation."""
        info = self.current_wipe_info
        save_dir = self._get_save_directory()
        timestamp_str = info['start_time'].strftime("%Y%m%d_%H%M%S")
        device_name = os.path.basename(info['device'])
        base_filename = f"cleanslate_cert_{device_name}_{timestamp_str}"
        
        cert_data = {
            "software": "CleanSlate Secure Wiper for Linux",
            "certificateId": str(uuid.uuid4()),
            "targetDevice": info['device'],
            "wipeMethod": f"{info['mode'].capitalize()} Wipe ({'shred' if info['mode'] == 'secure' else 'dd'})",
            "status": info['status'],
            "startTime": info['start_time'].isoformat(),
            "endTime": info['end_time'].isoformat(),
            "durationSeconds": (info['end_time'] - info['start_time']).total_seconds(),
        }

        # --- Save JSON Certificate ---
        json_path = os.path.join(save_dir, f"{base_filename}.json")
        with open(json_path, 'w') as f:
            json.dump(cert_data, f, indent=4)

        # --- Save PDF Certificate ---
        pdf_path = os.path.join(save_dir, f"{base_filename}.pdf")
        c = canvas.Canvas(pdf_path, pagesize=letter)
        width, height = letter

        # Title
        c.setFont("Helvetica-Bold", 24)
        c.drawCentredString(width / 2.0, height - inch, "Certificate of Data Destruction")
        
        # Header Line
        c.setStrokeColorRGB(0.1, 0.1, 0.1)
        c.line(inch, height - 1.25 * inch, width - inch, height - 1.25 * inch)
        
        # Body Text
        c.setFont("Helvetica", 12)
        text = c.beginText(inch, height - 2 * inch)
        text.setFont("Helvetica-Bold", 12)
        text.textLine("This document certifies that the data on the specified storage device was securely and")
        text.textLine("irreversibly destroyed in accordance with the details provided below.")
        text.moveCursor(0, 20)
        
        text.setFont("Helvetica-Bold", 14)
        text.textLine("Operation Details:")
        text.setFont("Helvetica", 12)
        text.moveCursor(0, 10)

        details = [
            ("Certificate ID:", cert_data["certificateId"]),
            ("Target Device:", cert_data["targetDevice"]),
            ("Wipe Method:", cert_data["wipeMethod"]),
            ("Status:", cert_data["status"]),
            ("Wipe Started:", info['start_time'].strftime("%Y-%m-%d %H:%M:%S %Z")),
            ("Wipe Completed:", info['end_time'].strftime("%Y-%m-%d %H:%M:%S %Z")),
        ]

        for label, value in details:
            text.setFont("Helvetica-Bold", 12)
            text.textOut(label.ljust(20))
            text.setFont("Helvetica", 12)
            text.textLine(f" {value}")
            text.moveCursor(0, 5)

        c.drawText(text)
        
        # Footer
        c.setFont("Helvetica-Oblique", 10)
        c.drawCentredString(width / 2.0, 0.75 * inch, f"Generated by {cert_data['software']}")

        c.save()
        
        return save_dir


if __name__ == "__main__":
    app = CleanSlateApp()
    app.mainloop()

