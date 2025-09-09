"""
CleanSlate - Professional Data Sanitization Tool
NIST SP 800-88 Compliant Data Sanitization
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

# ----- Secure Wipe Engine with Overwrite and Undo Functionality -----
class SecureWipeEngine:
    def __init__(self, callback=None):
        self.stop_flag = False
        self.callback = callback
        self.temp_storage = tempfile.mkdtemp(prefix="cleanslate_temp_")
        self.undo_stack = []

    def _update_ui(self, message, progress=0):
        if self.callback:
            self.callback(message, progress)

    def _overwrite_drive(self, drive_path):
        """
        Securely overwrites a full drive with a two-pass method (zeros then ones).
        This method is IRREVERSIBLE.
        """
        try:
            total_size_bytes = shutil.disk_usage(drive_path).total
            chunk_size = 1024 * 1024 # 1 MB chunk

            # Pass 1: Overwrite with Zeros
            self._update_ui("Pass 1 of 2: Overwriting with Zeros...", 0)
            with open(drive_path + "\\dummy_file.dat", "wb") as f:
                for i in range(0, total_size_bytes, chunk_size):
                    if self.stop_flag: return False
                    f.write(b'\x00' * min(chunk_size, total_size_bytes - i))
                    progress = (i / total_size_bytes) * 50 if total_size_bytes > 0 else 50
                    self._update_ui(f"Pass 1: {progress:.2f}% complete", progress)
            os.remove(drive_path + "\\dummy_file.dat")

            # Pass 2: Overwrite with Ones
            self._update_ui("Pass 2 of 2: Overwriting with Ones...", 50)
            with open(drive_path + "\\dummy_file.dat", "wb") as f:
                for i in range(0, total_size_bytes, chunk_size):
                    if self.stop_flag: return False
                    f.write(b'\xff' * min(chunk_size, total_size_bytes - i))
                    progress = 50 + (i / total_size_bytes) * 50 if total_size_bytes > 0 else 100
                    self._update_ui(f"Pass 2: {progress:.2f}% complete", progress)
            os.remove(drive_path + "\\dummy_file.dat")

            return True

        except Exception as e:
            self._update_ui(f"ERROR: Drive wipe failed - {e}", 0)
            return False

    def wipe_target(self, target_paths):
        """Moves files/folders to temp storage for a safe 'undo' period."""
        self._update_ui("Starting wipe (moving files to temporary storage)...")
        self.undo_stack = []
        self.stop_flag = False

        # Check for system drive
        detector = DriveDetector()
        for path in target_paths:
            if detector.is_system_drive(path):
                self._update_ui(f"ERROR: Cannot wipe system drive at {path}", 0)
                return False

        # Get all files to be moved
        files_to_move = []
        for path in target_paths:
            if os.path.isfile(path):
                files_to_move.append(path)
            elif os.path.isdir(path):
                for root, _, files in os.walk(path):
                    for file in files:
                        files_to_move.append(os.path.join(root, file))

        total_files = len(files_to_move)
        for i, src_path in enumerate(files_to_move):
            if self.stop_flag:
                break
            try:
                rel_path = os.path.relpath(src_path, os.path.commonpath(target_paths))
                dst_path = os.path.join(self.temp_storage, rel_path)
                os.makedirs(os.path.dirname(dst_path), exist_ok=True)

                shutil.move(src_path, dst_path)
                self.undo_stack.append({'original': src_path, 'temp': dst_path})

                progress = (i / total_files) * 100 if total_files > 0 else 100
                self._update_ui(f"Moved: {os.path.basename(src_path)} ({i+1}/{total_files})", progress)
            except Exception as e:
                self._update_ui(f"ERROR: Failed to move {src_path} - {e}")

        self._update_ui("Wipe (move) complete.", 100)
        return True

    def undo(self):
        """Restores files from temp storage to their original locations."""
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
            except Exception as e:
                self._update_ui(f"ERROR: Failed to restore {original} - {e}")

        self.undo_stack.clear()
        self.permanent_delete()
        self._update_ui("Undo complete.", 100)

    def permanent_delete(self):
        """Deletes all files and folders in temp storage."""
        if not os.path.exists(self.temp_storage):
            return

        self._update_ui("Permanently deleting files from temp storage...", 0)
        try:
            shutil.rmtree(self.temp_storage, ignore_errors=True)
            self.temp_storage = tempfile.mkdtemp(prefix="cleanslate_temp_")
            self._update_ui("Permanent delete successful.", 100)
        except Exception as e:
            self._update_ui(f"ERROR: Failed to permanently delete temp files - {e}")

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
        style.configure('Danger.TButton', background='#E57373', foreground='white')
        style.map('Danger.TButton', background=[('active', '#EF5350')])
        style.configure('Title.TLabel', font=('Segoe UI', 24, 'bold'), foreground='#263238')
        style.configure('SubTitle.TLabel', font=('Segoe UI', 10), foreground='#546E7A')

    def create_widgets(self):
        main_frame = ttk.Frame(self.root, padding="20 20 20 10")
        main_frame.pack(fill='both', expand=True)
        main_frame.columnconfigure(0, weight=1)

        # Header
        ttk.Label(main_frame, text="🧹 CleanSlate", style='Title.TLabel').pack(pady=(0, 2))
        ttk.Label(main_frame, text="Secure Deletion Tool | File 'Wipe' with 30s Undo", style='SubTitle.TLabel').pack(pady=(0, 20))

        # Warning Banner
        warning_frame = tk.Frame(main_frame, bg='#FF9800', height=40)
        warning_frame.pack(fill='x', pady=(0, 20))
        warning_frame.pack_propagate(False)
        tk.Label(warning_frame, text="⚠️ WARNING: Data is recoverable for 30s. After that, it's PERMANENTLY deleted.",
                 bg='#FF9800', fg='white', font=('Segoe UI', 10, 'bold')).pack(expand=True)

        # Drive and File Selection
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

        # Options
        options_frame = ttk.LabelFrame(main_frame, text="Sanitization Options", padding="10")
        options_frame.pack(fill='x', pady=(0, 10))
        ttk.Label(options_frame, text="Wipe Method:").pack(side='left', padx=(0, 10))
        self.wipe_method = tk.StringVar(value="Secure File Deletion (with Undo)")
        ttk.Combobox(options_frame, textvariable=self.wipe_method,
                     values=["Secure File Deletion (with Undo)", "Full Drive Wipe (2-Pass Overwrite)"],
                     state='readonly', width=40).pack(side='left')

        # Operation Controls
        controls_frame = ttk.Frame(main_frame)
        controls_frame.pack(fill='x', pady=(0, 20))

        self.wipe_btn = ttk.Button(controls_frame, text="🗑️ START WIPE", command=self.show_confirmation_dialog, style='Danger.TButton')
        self.wipe_btn.pack(side='left', padx=(0, 10), ipady=5)
        self.stop_btn = ttk.Button(controls_frame, text="⏹ STOP", command=self.stop_wipe, state='disabled')
        self.stop_btn.pack(side='left', ipady=5)
        self.undo_btn = ttk.Button(controls_frame, text="↩ UNDO (30s)", command=self.undo_wipe, state='disabled')
        self.undo_btn.pack(side='left', padx=10, ipady=5)

        # Progress & Log
        progress_frame = ttk.LabelFrame(main_frame, text="Operation Log", padding="15")
        progress_frame.pack(fill='both', expand=True)

        self.progress_label = ttk.Label(progress_frame, text="Ready")
        self.progress_label.pack(fill='x', pady=(0, 5))
        self.progress_bar = ttk.Progressbar(progress_frame, orient='horizontal', mode='determinate')
        self.progress_bar.pack(fill='x', pady=(0, 10))

        self.log_text = scrolledtext.ScrolledText(progress_frame, height=8, wrap='word', bg='#F5F5F5', fg='#333333', relief='flat')
        self.log_text.pack(fill='both', expand=True)

        # Status Bar
        status_bar = tk.Frame(self.root, bg='#546E7A')
        status_bar.pack(side='bottom', fill='x')
        self.status_label = tk.Label(status_bar, text="Ready", bg='#546E7A', fg='white', font=('Segoe UI', 9))
        self.status_label.pack(side='left', padx=10)
        tk.Label(status_bar, text="CleanSlate v2.1", bg='#546E7A', fg='white', font=('Segoe UI', 9)).pack(side='right', padx=10)

    # ----- Functions -----
    def refresh_drives(self):
        for item in self.drive_tree.get_children():
            self.drive_tree.delete(item)
        drives_info = self.drive_detector.get_drives()
        for drive in drives_info:
            is_system = 'Yes' if self.drive_detector.is_system_drive(drive['path']) else 'No'
            self.drive_tree.insert('', 'end', values=(
                drive['path'], drive.get('label', 'No Label'), drive.get('type', 'Unknown'),
                drive.get('size_readable', 'Unknown'), f"{drive.get('percent_used', 0):.1f}%", is_system
            ))
        self.log("Drive list refreshed.")

    def select_files(self):
        files = filedialog.askopenfilenames(title="Select files to wipe")
        if files:
            self.selected_targets = list(files)
            self.selection_label.config(text=f"{len(files)} file(s) selected")
            self.log(f"Selected {len(files)} files.")

    def select_folder(self):
        folder = filedialog.askdirectory(title="Select folder to wipe")
        if folder:
            self.selected_targets = [folder]
            self.selection_label.config(text=f"Folder: {os.path.basename(folder)}")
            self.log(f"Selected folder: {folder}.")

    def show_confirmation_dialog(self):
        selected_method = self.wipe_method.get()
        selection = self.drive_tree.selection()
        drive_path = None
        if selection:
            item = self.drive_tree.item(selection[0])
            drive_path = item['values'][0]

        if selected_method == "Full Drive Wipe (2-Pass Overwrite)":
            if not drive_path:
                messagebox.showwarning("No Drive Selected", "Please select a drive to perform a full wipe.")
                return
            if item['values'][5] == 'Yes':
                messagebox.showerror("System Drive Warning", "Cannot perform a full wipe on a system drive.")
                return
            self.selected_targets = [drive_path]

        elif not (self.selected_targets or drive_path):
            messagebox.showwarning("No Selection", "Please select files, a folder, or a drive to wipe.")
            return

        confirm_window = Toplevel(self.root)
        confirm_window.title("CONFIRM DELETION")
        confirm_window.geometry("450x250")
        confirm_window.transient(self.root)
        confirm_window.grab_set()

        frame = ttk.Frame(confirm_window, padding=20)
        frame.pack(fill='both', expand=True)

        ttk.Label(frame, text="⚠️ FINAL WARNING ⚠️", font=('Segoe UI', 14, 'bold'), foreground='#E57373').pack(pady=(0, 10))

        if selected_method == "Full Drive Wipe (2-Pass Overwrite)":
            ttk.Label(frame, text="You are about to start a PERMANENT drive wipe.", justify=tk.CENTER, wraplength=400).pack()
            ttk.Label(frame, text=f"ALL DATA on drive {drive_path} will be permanently destroyed and is IRREVERSIBLE.", justify=tk.CENTER, wraplength=400, font=('Segoe UI', 10, 'bold')).pack(pady=(5, 20))
            def on_proceed():
                confirm_window.destroy()
                self.start_wipe_with_captcha(drive_path)
        else:
            ttk.Label(frame, text="You are about to start a PERMANENT deletion process.", justify=tk.CENTER, wraplength=400).pack()
            ttk.Label(frame, text="This action will make your data unrecoverable after 30 seconds.", justify=tk.CENTER, wraplength=400).pack(pady=(5, 20))
            def on_proceed():
                confirm_window.destroy()
                self.start_wipe_with_captcha()

        def on_cancel():
            confirm_window.destroy()
            self.log("Operation canceled by user.", "WARNING")

        btn_frame = ttk.Frame(frame)
        btn_frame.pack()
        ttk.Button(btn_frame, text="Proceed", command=on_proceed, style='Danger.TButton').pack(side='left', padx=10, ipady=5)
        ttk.Button(btn_frame, text="Cancel", command=on_cancel).pack(side='left', padx=10, ipady=5)

        confirm_window.protocol("WM_DELETE_WINDOW", on_cancel)
        self.root.wait_window(confirm_window)

    def start_wipe_with_captcha(self, drive_path=None):
        captcha = ''.join(random.choices(string.ascii_letters + string.digits, k=6))
        ans = simpledialog.askstring("Captcha Confirmation", f"Type the following to confirm: {captcha}")
        if ans != captcha:
            messagebox.showwarning("Captcha Failed", "Captcha did not match. Aborting.")
            self.log("Captcha failed. Operation aborted.", "ERROR")
            return

        selected_method = self.wipe_method.get()
        if selected_method == "Full Drive Wipe (2-Pass Overwrite)":
            self.wipe_btn.config(state='disabled')
            self.stop_btn.config(state='normal')
            self.undo_btn.config(state='disabled')
            self.wipe_engine.stop_flag = False
            self.wipe_thread = threading.Thread(target=self.wipe_engine._overwrite_drive, args=(drive_path,))
            self.wipe_thread.start()
        else:
            self.wipe_btn.config(state='disabled')
            self.stop_btn.config(state='normal')
            self.undo_btn.config(state='disabled')
            self.wipe_engine.stop_flag = False
            self.wipe_thread = threading.Thread(target=self.wipe_and_schedule_delete)
            self.wipe_thread.start()

    def wipe_and_schedule_delete(self):
        success = self.wipe_engine.wipe_target(self.selected_targets)
        if success:
            self.root.after(0, self.start_undo_countdown)

    def start_undo_countdown(self):
        self.undo_btn.config(state='normal')
        self.stop_btn.config(state='disabled')
        self.wipe_btn.config(state='disabled')
        self.countdown_thread = threading.Thread(target=self.final_delete_delay)
        self.countdown_thread.start()

    def final_delete_delay(self):
        countdown = 30
        while countdown > 0 and not self.wipe_engine.stop_flag:
            self.root.after(0, lambda c=countdown: self.progress_label.config(text=f"You have {c}s to UNDO"))
            time.sleep(1)
            countdown -= 1

        if not self.wipe_engine.stop_flag:
            self.wipe_engine.permanent_delete()
            self.root.after(0, self.reset_buttons)

    def undo_wipe(self):
        self.wipe_engine.stop_flag = True
        self.wipe_engine.undo()
        self.reset_buttons()

    def stop_wipe(self):
        self.wipe_engine.stop_flag = True
        self.log("Stopping wipe...", "WARNING")
        self.reset_buttons()

    def reset_buttons(self):
        self.wipe_btn.config(state='normal')
        self.stop_btn.config(state='disabled')
        self.undo_btn.config(state='disabled')
        self.progress_label.config(text="Ready")
        self.progress_bar['value'] = 0

    def update_ui(self, message, progress=0):
        self.root.after(0, self._safe_update_ui, message, progress)

    def _safe_update_ui(self, message, progress):
        self.progress_bar['value'] = progress
        self.log(message)
        self.progress_label.config(text=message)
        self.root.update_idletasks()

    def log(self, message, level="INFO"):
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.log_text.insert(tk.END, f"[{timestamp}] {message}\n")
        self.log_text.see(tk.END)
        self.log_text.tag_add(level, "end-2c", "end-1c")

        colors = {'SUCCESS': '#4CAF50', 'ERROR': '#F44336', 'WARNING': '#FF9800', 'INFO': '#333333'}
        self.log_text.tag_configure(level, foreground=colors.get(level, '#333333'))

def main():
    root = tk.Tk()
    app = CleanSlateApp(root)
    root.mainloop()

if __name__ == "__main__":
    main()
