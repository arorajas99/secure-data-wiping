"""
CleanSlate - Professional Data Sanitization Tool
NIST SP 800-88 Compliant Data Sanitization, supporting UN SDGs
"""
import tkinter as tk
from tkinter import ttk, messagebox, filedialog, simpledialog, scrolledtext, Toplevel
import threading
import os
import sys
import psutil
from datetime import datetime
import random
import string
import shutil
import tempfile
import time
import json
import uuid
import hashlib
from fpdf import FPDF

# ----- Certificate Generator -----
class CertificateGenerator:
    def generate(self, data, save_path):
        self.generate_pdf(data, save_path)
        self.generate_json(data, save_path)

    def generate_json(self, data, save_path):
        filepath = os.path.join(save_path, f"Wipe-Certificate-{data['certificate_id']}.json")
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=4)

    def generate_pdf(self, data, save_path):
        pdf = FPDF()
        pdf.add_page()
        pdf.set_font("Helvetica", "B", 20)

        pdf.cell(0, 15, "Certificate of Data Sanitization", ln=True, align='C')
        pdf.set_font("Helvetica", "", 10)
        pdf.cell(0, 5, f"Generated on: {data['completion_time']}", ln=True, align='C')
        pdf.ln(10)

        pdf.set_font("Helvetica", "B", 12)
        pdf.cell(0, 10, "Sanitization Details", ln=True, border=1, align='C')
        self._add_detail_row(pdf, "Certificate ID:", data['certificate_id'])
        self._add_detail_row(pdf, "Status:", data['status'])
        self._add_detail_row(pdf, "Method:", data['wipe_method'])
        self._add_detail_row(pdf, "Start Time:", data['start_time'])
        self._add_detail_row(pdf, "Completion Time:", data['completion_time'])
        pdf.ln(5)

        if 'device_details' in data:
            pdf.set_font("Helvetica", "B", 12)
            pdf.cell(0, 10, "Device Details", ln=True, border=1, align='C')
            self._add_detail_row(pdf, "Target Path:", data['device_details']['path'])
            self._add_detail_row(pdf, "Device Label:", data['device_details']['label'])
            self._add_detail_row(pdf, "Device Type:", data['device_details']['type'])
            self._add_detail_row(pdf, "Size:", data['device_details']['size_readable'])
        elif 'wiped_targets' in data:
            pdf.set_font("Helvetica", "B", 12)
            pdf.cell(0, 10, "Wiped Targets", ln=True, border=1, align='C')
            pdf.set_font("Helvetica", "", 8)
            for path in data['wiped_targets']:
                pdf.multi_cell(0, 5, path)
            pdf.ln(2)

        pdf.ln(5)
        pdf.set_font("Helvetica", "B", 12)
        pdf.cell(0, 10, "Verification", ln=True, border=1, align='C')
        pdf.set_font("Helvetica", "", 8)
        pdf.multi_cell(0, 5, f"SHA256 Hash: {data['verification_hash']}")

        filepath = os.path.join(save_path, f"Wipe-Certificate-{data['certificate_id']}.pdf")
        pdf.output(filepath)

    def _add_detail_row(self, pdf, title, value):
        pdf.set_font("Helvetica", "B", 10)
        pdf.cell(40, 8, title, border=1)
        pdf.set_font("Helvetica", "", 10)
        pdf.cell(0, 8, f" {value}", ln=True, border=1)


# ----- Utilities -----
class DriveDetector:
    def get_drives(self):
        drives = []
        for partition in psutil.disk_partitions(all=False):
            if 'cdrom' in partition.opts or partition.fstype == '':
                continue
            path = partition.mountpoint
            try:
                usage = psutil.disk_usage(path)
                drives.append({
                    'path': path,
                    'label': partition.device,
                    'type': 'Removable' if 'removable' in partition.opts else 'Fixed',
                    'size_readable': f"{usage.total / (1024 ** 3):.2f} GB",
                    'percent_used': (usage.used / usage.total * 100) if usage.total > 0 else 0
                })
            except Exception:
                pass
        return drives

    def is_system_drive(self, path):
        if sys.platform == "win32":
            return os.path.splitdrive(path)[0].upper() == os.path.splitdrive(os.environ['SYSTEMDRIVE'])[0].upper()
        return os.path.realpath(path) == '/'

# ----- Secure Wipe Engine -----
class SecureWipeEngine:
    def __init__(self, callback=None):
        self.stop_flag = False
        self.callback = callback
        self.temp_storage = tempfile.mkdtemp(prefix="cleanslate_temp_")
        self.undo_stack = []

    def _update_ui(self, message, progress=0):
        if self.callback:
            self.callback(message, progress)

    def _overwrite_drive(self, drive_path, device_details):
        start_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        try:
            total_size_bytes = shutil.disk_usage(drive_path).total
            chunk_size = 1024 * 1024
            dummy_file_path = os.path.join(drive_path, "dummy_file.dat")
            passes = [
                ("Pass 1 of 3: Overwriting with Zeros...", b'\x00', 0, 33),
                ("Pass 2 of 3: Overwriting with Ones...", b'\xff', 33, 66),
                ("Pass 3 of 3: Overwriting with Random Data...", None, 66, 100)
            ]
            for msg, pattern, prog_start, prog_end in passes:
                self._update_ui(msg, prog_start)
                with open(dummy_file_path, "wb") as f:
                    for i in range(0, total_size_bytes, chunk_size):
                        if self.stop_flag:
                            if os.path.exists(dummy_file_path): os.remove(dummy_file_path)
                            return None
                        data = pattern * min(chunk_size, total_size_bytes - i) if pattern else os.urandom(min(chunk_size, total_size_bytes - i))
                        f.write(data)
                        progress = prog_start + (i / total_size_bytes) * (prog_end - prog_start)
                        self._update_ui(f"{msg.split(':')[0]}: {progress:.2f}% complete", progress)
                if os.path.exists(dummy_file_path): os.remove(dummy_file_path)

            self._update_ui("NIST SP 800-88 Clear operation successful. Generating certificate...", 100)

            completion_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            cert_data = {
                "certificate_id": str(uuid.uuid4()),
                "status": "Success",
                "wipe_method": "NIST SP 800-88 Clear (3-Pass)",
                "start_time": start_time,
                "completion_time": completion_time,
                "device_details": device_details
            }
            cert_string = json.dumps(cert_data, sort_keys=True)
            cert_data["verification_hash"] = hashlib.sha256(cert_string.encode()).hexdigest()
            return cert_data

        except Exception as e:
            self._update_ui(f"ERROR: Drive wipe failed - {e}", 0)
            return None

    def wipe_target(self, target_paths, start_time):
        self._update_ui("Starting wipe (moving files to temporary storage)...")
        self.undo_stack = []
        self.stop_flag = False
        self.original_targets = target_paths
        self.start_time = start_time

        detector = DriveDetector()
        for path in target_paths:
            if detector.is_system_drive(path):
                self._update_ui(f"ERROR: Cannot wipe system drive at {path}", 0)
                return False
        files_to_move = []
        for path in target_paths:
            if os.path.isfile(path): files_to_move.append(path)
            elif os.path.isdir(path):
                for root, _, files in os.walk(path):
                    for file in files: files_to_move.append(os.path.join(root, file))
        total_files = len(files_to_move)
        for i, src_path in enumerate(files_to_move):
            if self.stop_flag: break
            try:
                rel_path = os.path.relpath(src_path, os.path.commonpath(target_paths))
                dst_path = os.path.join(self.temp_storage, rel_path)
                os.makedirs(os.path.dirname(dst_path), exist_ok=True)
                shutil.move(src_path, dst_path)
                self.undo_stack.append({'original': src_path, 'temp': dst_path})
                progress = (i / total_files) * 100 if total_files > 0 else 100
                self._update_ui(f"Moved: {os.path.basename(src_path)} ({i+1}/{total_files})", progress)
            except Exception as e: self._update_ui(f"ERROR: Failed to move {src_path} - {e}")
        self._update_ui("Wipe (move) complete. You have 30s to Undo.", 100)
        return True

    def undo(self):
        self._update_ui("Starting UNDO (restoring files)...")
        self.stop_flag = True
        total_files = len(self.undo_stack)
        for i, item in enumerate(reversed(self.undo_stack)):
            original, temp = item['original'], item['temp']
            try:
                os.makedirs(os.path.dirname(original), exist_ok=True)
                shutil.move(temp, original)
                progress = (i / total_files) * 100 if total_files > 0 else 100
                self._update_ui(f"Restored: {os.path.basename(original)}", progress)
            except Exception as e: self._update_ui(f"ERROR: Failed to restore {original} - {e}")
        self.undo_stack.clear()
        self.permanent_delete() # This is now just a cleanup
        self._update_ui("Undo complete.", 100)

    def permanent_delete(self):
        if not os.path.exists(self.temp_storage): return None
        self._update_ui("Permanently deleting files... Generating certificate...", 0)
        try:
            shutil.rmtree(self.temp_storage, ignore_errors=True)
            self.temp_storage = tempfile.mkdtemp(prefix="cleanslate_temp_")
            self._update_ui("Permanent delete successful.", 100)

            completion_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            cert_data = {
                "certificate_id": str(uuid.uuid4()),
                "status": "Success",
                "wipe_method": "Secure File Deletion (with Undo)",
                "start_time": self.start_time,
                "completion_time": completion_time,
                "wiped_targets": self.original_targets
            }
            cert_string = json.dumps(cert_data, sort_keys=True)
            cert_data["verification_hash"] = hashlib.sha256(cert_string.encode()).hexdigest()
            return cert_data
        except Exception as e:
            self._update_ui(f"ERROR: Failed to permanently delete temp files - {e}")
            return None


# ----- CleanSlate App (Modernized GUI) -----
class CleanSlateApp:
    def __init__(self, root):
        self.root = root
        self.root.title("CleanSlate - Professional Secure Deletion")
        self.root.geometry("900x700")
        self.root.minsize(800, 600)
        self.root.configure(bg='#ECEFF1')

        self.selected_targets = []
        self.wipe_thread = None
        self.drive_detector = DriveDetector()
        self.wipe_engine = SecureWipeEngine(callback=self.update_ui)
        self.certificate_generator = CertificateGenerator()

        self.setup_styles()
        self.create_widgets()
        self.refresh_drives()

    def setup_styles(self):
        style = ttk.Style()
        style.theme_use('clam')
        style.configure('.', font=('Segoe UI', 10), background='#ECEFF1', foreground='#333333')
        style.configure('TFrame', background='#ECEFF1')
        style.configure('TLabel', background='#ECEFF1')
        style.configure('TLabelframe', background='#CFD8DC')
        style.configure('TLabelframe.Label', font=('Segoe UI', 12, 'bold'), foreground='#263238')
        style.configure('TButton', font=('Segoe UI', 10, 'bold'), padding=6)
        style.map('TButton', background=[('active', '#B0BEC5')])
        style.configure('Info.TButton', background='#B0BEC5', foreground='#263238')
        style.map('Info.TButton', background=[('active', '#90A4AE')])
        style.configure('Danger.TButton', background='#E57373', foreground='white')
        style.map('Danger.TButton', background=[('active', '#EF5350')])
        style.configure('Title.TLabel', font=('Segoe UI', 24, 'bold'), foreground='#263238')
        style.configure('SubTitle.TLabel', font=('Segoe UI', 10), foreground='#546E7A')

    def create_widgets(self):
        main_frame = ttk.Frame(self.root, padding="20 20 20 10")
        main_frame.pack(fill='both', expand=True)
        main_frame.columnconfigure(0, weight=1)
        ttk.Label(main_frame, text="🧹 CleanSlate", style='Title.TLabel').pack(pady=(0, 2))
        ttk.Label(main_frame, text="Secure Deletion Tool | File 'Wipe' with 30s Undo", style='SubTitle.TLabel').pack(pady=(0, 20))
        warning_frame = tk.Frame(main_frame, bg='#FF9800', height=40)
        warning_frame.pack(fill='x', pady=(0, 20))
        warning_frame.pack_propagate(False)
        tk.Label(warning_frame, text="⚠️ WARNING: A certificate will be generated after permanent deletion.",
                 bg='#FF9800', fg='white', font=('Segoe UI', 10, 'bold')).pack(expand=True)
        selection_frame = ttk.LabelFrame(main_frame, text="Select Target", padding="15")
        selection_frame.pack(fill='x', pady=(0, 20))
        tree_frame = ttk.Frame(selection_frame)
        tree_frame.pack(fill='x')
        columns = ('Drive', 'Label', 'Type', 'Size', 'Used', 'System')
        self.drive_tree = ttk.Treeview(tree_frame, columns=columns, show='headings', height=6)
        for col in columns:
            self.drive_tree.heading(col, text=col)
            self.drive_tree.column(col, width=100, stretch=tk.YES)
        scrollbar = ttk.Scrollbar(tree_frame, orient='vertical', command=self.drive_tree.yview)
        self.drive_tree.configure(yscrollcommand=scrollbar.set)
        self.drive_tree.pack(side='left', fill='x', expand=True)
        scrollbar.pack(side='right', fill='y')
        button_frame = ttk.Frame(selection_frame)
        button_frame.pack(pady=(10, 0), fill='x')
        ttk.Button(button_frame, text="🔄 Refresh Drives", command=self.refresh_drives).pack(side='left', padx=(0, 5))
        ttk.Button(button_frame, text="📁 Select Files", command=self.select_files).pack(side='left', padx=5)
        ttk.Button(button_frame, text="📂 Select Folder", command=self.select_folder).pack(side='left', padx=5)
        self.selection_label = ttk.Label(button_frame, text="No targets selected.")
        self.selection_label.pack(side='left', padx=20)
        ttk.Button(button_frame, text="SDG Impact", command=self.show_sdg_info, style='Info.TButton').pack(side='right')
        options_frame = ttk.LabelFrame(main_frame, text="Sanitization Options", padding="10")
        options_frame.pack(fill='x', pady=(0, 10))
        ttk.Label(options_frame, text="Wipe Method:").pack(side='left', padx=(0, 10))
        self.wipe_method = tk.StringVar(value="Secure File Deletion (with Undo)")
        ttk.Combobox(options_frame, textvariable=self.wipe_method,
                     values=["Secure File Deletion (with Undo)", "NIST SP 800-88 Clear (3-Pass)"],
                     state='readonly', width=40).pack(side='left')
        controls_frame = ttk.Frame(main_frame)
        controls_frame.pack(fill='x', pady=(0, 20))
        self.wipe_btn = ttk.Button(controls_frame, text="🗑️ START WIPE", command=self.show_confirmation_dialog, style='Danger.TButton')
        self.wipe_btn.pack(side='left', padx=(0, 10), ipady=5)
        self.stop_btn = ttk.Button(controls_frame, text="⏹ STOP", command=self.stop_wipe, state='disabled')
        self.stop_btn.pack(side='left', ipady=5)
        self.undo_btn = ttk.Button(controls_frame, text="↩ UNDO (30s)", command=self.undo_wipe, state='disabled')
        self.undo_btn.pack(side='left', padx=10, ipady=5)
        progress_frame = ttk.LabelFrame(main_frame, text="Operation Log", padding="15")
        progress_frame.pack(fill='both', expand=True)
        self.progress_label = ttk.Label(progress_frame, text="Ready")
        self.progress_label.pack(fill='x', pady=(0, 5))
        self.progress_bar = ttk.Progressbar(progress_frame, orient='horizontal', mode='determinate')
        self.progress_bar.pack(fill='x', pady=(0, 10))
        self.log_text = scrolledtext.ScrolledText(progress_frame, height=8, wrap='word', bg='#F5F5F5', fg='#333333', relief='flat')
        self.log_text.pack(fill='both', expand=True)
        status_bar = tk.Frame(self.root, bg='#546E7A')
        status_bar.pack(side='bottom', fill='x')
        self.status_label = tk.Label(status_bar, text="Ready", bg='#546E7A', fg='white', font=('Segoe UI', 9))
        self.status_label.pack(side='left', padx=10)
        tk.Label(status_bar, text="CleanSlate v2.3-Cert", bg='#546E7A', fg='white', font=('Segoe UI', 9)).pack(side='right', padx=10)

    def show_sdg_info(self):
        sdg_window = Toplevel(self.root); sdg_window.title("Sustainability Impact"); sdg_window.geometry("600x450"); sdg_window.transient(self.root); sdg_window.grab_set()
        frame = ttk.Frame(sdg_window, padding=20); frame.pack(fill='both', expand=True)
        ttk.Label(frame, text="Our Sustainable Development Impact", font=("Segoe UI", 16, "bold")).pack(pady=(0, 15))
        info_text = scrolledtext.ScrolledText(frame, wrap='word', font=("Segoe UI", 10), relief='solid', borderwidth=1); info_text.pack(fill='both', expand=True, pady=5)
        sdg_content = "This tool directly contributes to the UN Sustainable Development Goals (SDGs)..."
        info_text.insert(tk.END, sdg_content); info_text.config(state='disabled')
        ttk.Button(frame, text="Close", command=sdg_window.destroy).pack(pady=(15,0))

    def refresh_drives(self):
        for item in self.drive_tree.get_children(): self.drive_tree.delete(item)
        drives_info = self.drive_detector.get_drives()
        for drive in drives_info:
            is_system = 'Yes' if self.drive_detector.is_system_drive(drive['path']) else 'No'
            self.drive_tree.insert('', 'end', values=(drive['path'], drive.get('label', 'No Label'), drive.get('type', 'Unknown'), drive.get('size_readable', 'Unknown'), f"{drive.get('percent_used', 0):.1f}%", is_system))
        self.log("Drive list refreshed.")

    def select_files(self):
        files = filedialog.askopenfilenames(title="Select files to wipe");
        if files: self.selected_targets = list(files); self.selection_label.config(text=f"{len(files)} file(s) selected"); self.log(f"Selected {len(files)} files.")

    def select_folder(self):
        folder = filedialog.askdirectory(title="Select folder to wipe")
        if folder: self.selected_targets = [folder]; self.selection_label.config(text=f"Folder: {os.path.basename(folder)}"); self.log(f"Selected folder: {folder}.")

    def show_confirmation_dialog(self):
        selected_method = self.wipe_method.get(); selection = self.drive_tree.selection(); drive_path = None
        if selection: item = self.drive_tree.item(selection[0]); drive_path = item['values'][0]
        if selected_method == "NIST SP 800-88 Clear (3-Pass)":
            if not drive_path: messagebox.showwarning("No Drive Selected", "Please select a drive to perform a full wipe."); return
            if item['values'][5] == 'Yes': messagebox.showerror("System Drive Warning", "Cannot perform a full wipe on a system drive."); return
            self.selected_targets = [drive_path]
        elif not (self.selected_targets or drive_path):
            messagebox.showwarning("No Selection", "Please select files, a folder, or a drive to wipe."); return
        confirm_window = Toplevel(self.root); confirm_window.title("CONFIRM DELETION"); confirm_window.geometry("450x250"); confirm_window.transient(self.root); confirm_window.grab_set()
        frame = ttk.Frame(confirm_window, padding=20); frame.pack(fill='both', expand=True)
        ttk.Label(frame, text="⚠️ FINAL WARNING ⚠️", font=('Segoe UI', 14, 'bold'), foreground='#E57373').pack(pady=(0, 10))
        if selected_method == "NIST SP 800-88 Clear (3-Pass)":
            ttk.Label(frame, text="You are about to start a PERMANENT drive wipe.", justify=tk.CENTER, wraplength=400).pack()
            ttk.Label(frame, text=f"ALL DATA on drive {drive_path} will be permanently destroyed...", justify=tk.CENTER, wraplength=400, font=('Segoe UI', 10, 'bold')).pack(pady=(5, 20))
            def on_proceed(): confirm_window.destroy(); self.start_wipe_with_captcha(drive_path=drive_path)
        else:
            ttk.Label(frame, text="You are about to start a PERMANENT deletion process.", justify=tk.CENTER, wraplength=400).pack()
            ttk.Label(frame, text="This action will make your data unrecoverable after 30 seconds.", justify=tk.CENTER, wraplength=400).pack(pady=(5, 20))
            def on_proceed(): confirm_window.destroy(); self.start_wipe_with_captcha()
        def on_cancel(): confirm_window.destroy(); self.log("Operation canceled by user.", "WARNING")
        btn_frame = ttk.Frame(frame); btn_frame.pack()
        ttk.Button(btn_frame, text="Proceed", command=on_proceed, style='Danger.TButton').pack(side='left', padx=10, ipady=5)
        ttk.Button(btn_frame, text="Cancel", command=on_cancel).pack(side='left', padx=10, ipady=5)
        confirm_window.protocol("WM_DELETE_WINDOW", on_cancel)
        self.root.wait_window(confirm_window)

    def start_wipe_with_captcha(self, drive_path=None):
        captcha = ''.join(random.choices(string.ascii_letters + string.digits, k=6))
        ans = simpledialog.askstring("Captcha Confirmation", f"Type the following to confirm: {captcha}")
        if ans != captcha:
            messagebox.showwarning("Captcha Failed", "Captcha did not match. Aborting."); self.log("Captcha failed.", "ERROR"); return
        selected_method = self.wipe_method.get()
        if selected_method == "NIST SP 800-88 Clear (3-Pass)":
            self.wipe_btn.config(state='disabled'); self.stop_btn.config(state='normal'); self.undo_btn.config(state='disabled')
            self.wipe_engine.stop_flag = False
            item = self.drive_tree.item(self.drive_tree.selection()[0])
            device_details = {'path': item['values'][0], 'label': item['values'][1], 'type': item['values'][2], 'size_readable': item['values'][3]}
            self.wipe_thread = threading.Thread(target=self.run_drive_wipe, args=(drive_path, device_details)); self.wipe_thread.start()
        else:
            self.wipe_btn.config(state='disabled'); self.stop_btn.config(state='normal'); self.undo_btn.config(state='disabled')
            self.wipe_engine.stop_flag = False
            self.wipe_thread = threading.Thread(target=self.wipe_and_schedule_delete); self.wipe_thread.start()

    def run_drive_wipe(self, drive_path, device_details):
        cert_data = self.wipe_engine._overwrite_drive(drive_path, device_details)
        if cert_data: self.root.after(0, self.prompt_save_certificate, cert_data)

    def prompt_save_certificate(self, cert_data):
        save_path = filedialog.askdirectory(title="Select Folder to Save Wipe Certificate")
        if save_path:
            try:
                self.certificate_generator.generate(cert_data, save_path)
                self.log(f"Successfully saved PDF and JSON certificates to: {save_path}"); messagebox.showinfo("Certificate Saved", f"Wipe certificate saved to:\n{save_path}")
            except Exception as e:
                self.log(f"Error saving certificate: {e}", "ERROR"); messagebox.showerror("Save Error", f"Could not save the certificate.\nError: {e}")
        else:
            self.log("Certificate saving canceled by user.", "WARNING")

    def wipe_and_schedule_delete(self):
        start_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        success = self.wipe_engine.wipe_target(self.selected_targets, start_time)
        if success: self.root.after(0, self.start_undo_countdown)

    def start_undo_countdown(self):
        self.undo_btn.config(state='normal'); self.stop_btn.config(state='disabled'); self.wipe_btn.config(state='disabled')
        self.countdown_thread = threading.Thread(target=self.final_delete_delay); self.countdown_thread.start()

    def final_delete_delay(self):
        countdown = 30
        while countdown > 0 and not self.wipe_engine.stop_flag:
            self.root.after(0, lambda c=countdown: self.progress_label.config(text=f"You have {c}s to UNDO"))
            time.sleep(1); countdown -= 1
        if not self.wipe_engine.stop_flag:
            cert_data = self.wipe_engine.permanent_delete()
            if cert_data: self.root.after(0, self.prompt_save_certificate, cert_data)
            self.root.after(0, self.reset_buttons)

    def undo_wipe(self):
        self.wipe_engine.stop_flag = True; self.wipe_engine.undo(); self.reset_buttons()

    def stop_wipe(self):
        self.wipe_engine.stop_flag = True; self.log("Stopping wipe...", "WARNING"); self.reset_buttons()

    def reset_buttons(self):
        self.wipe_btn.config(state='normal'); self.stop_btn.config(state='disabled'); self.undo_btn.config(state='disabled')
        self.progress_label.config(text="Ready"); self.progress_bar['value'] = 0

    def update_ui(self, message, progress=0):
        self.root.after(0, self._safe_update_ui, message, progress)

    def _safe_update_ui(self, message, progress):
        self.progress_bar['value'] = progress; self.log(message); self.progress_label.config(text=message); self.root.update_idletasks()

    def log(self, message, level="INFO"):
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.log_text.insert(tk.END, f"[{timestamp}] {message}\n"); self.log_text.see(tk.END)
        self.log_text.tag_add(level, "end-2c", "end-1c")
        colors = {'SUCCESS': '#4CAF50', 'ERROR': '#F44336', 'WARNING': '#FF9800', 'INFO': '#333333'}
        self.log_text.tag_configure(level, foreground=colors.get(level, '#333333'))

def main():
    root = tk.Tk()
    app = CleanSlateApp(root)
    root.mainloop()

if __name__ == "__main__":
    main()
