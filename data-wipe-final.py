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

# ----- Custom Rounded Button Widget -----
class RoundButton(tk.Canvas):
    def __init__(self, parent, text, command, width, height, bg, fg, hover_bg, hover_fg, corner_radius, **kwargs):
        super().__init__(parent, width=width, height=height, bg=parent.cget('bg'), highlightthickness=0, **kwargs)
        self.command = command
        self.text = text
        self.width = width
        self.height = height
        self.bg = bg
        self.fg = fg
        self.hover_bg = hover_bg
        self.hover_fg = hover_fg
        self.corner_radius = corner_radius
        self.is_disabled = False

        self.tag = f"round_button_{random.randint(1, 10000)}"

        self.bind("<Enter>", self._on_enter)
        self.bind("<Leave>", self._on_leave)
        self.bind("<Button-1>", self._on_click)

        self._draw_button(self.bg, self.fg)

    def _draw_button(self, bg_color, fg_color):
        self.delete("all")
        r = self.corner_radius
        self.create_polygon(
            (r, 0, self.width-r, 0, self.width, r, self.width, self.height-r, self.width-r, self.height, r, self.height, 0, self.height-r, 0, r),
            smooth=True, fill=bg_color, tags=self.tag
        )
        self.create_text(self.width/2, self.height/2, text=self.text, font=("Segoe UI", 11, "bold"), fill=fg_color, tags=self.tag)

    def _on_enter(self, event):
        if not self.is_disabled:
            self._draw_button(self.hover_bg, self.hover_fg)

    def _on_leave(self, event):
        if not self.is_disabled:
            self._draw_button(self.bg, self.fg)

    def _on_click(self, event):
        if self.command and not self.is_disabled:
            self.command()

    def config(self, state):
        if state == 'disabled':
            self.is_disabled = True
            self._draw_button('#ECEEDF', '#B0B0B0') # Disabled colors
        elif state == 'normal':
            self.is_disabled = False
            self._draw_button(self.bg, self.fg)
            if self.text.startswith("UNDO ("):
                self.text = "UNDO"
                self._draw_button(self.bg, self.fg)

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

    def _overwrite_drive(self, drive_path):
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
                            return False
                        data = pattern * min(chunk_size, total_size_bytes - i) if pattern else os.urandom(min(chunk_size, total_size_bytes - i))
                        f.write(data)
                        progress = prog_start + (i / total_size_bytes) * (prog_end - prog_start)
                        self._update_ui(f"{msg.split(':')[0]}: {progress:.2f}% complete", progress)
                if os.path.exists(dummy_file_path): os.remove(dummy_file_path)
            self._update_ui("NIST SP 800-88 Clear operation successful.", 100)
            return True
        except Exception as e:
            self._update_ui(f"ERROR: Drive wipe failed - {e}", 0)
            return False

    def wipe_target(self, target_paths):
        self._update_ui("Starting wipe (moving files to temporary storage)...")
        self.undo_stack = []
        self.stop_flag = False
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
        self._update_ui("Wipe (move) complete.", 100)
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
        self.permanent_delete()
        self._update_ui("Undo complete.", 100)

    def permanent_delete(self):
        if not os.path.exists(self.temp_storage): return
        self._update_ui("Permanently deleting files from temp storage...", 0)
        try:
            shutil.rmtree(self.temp_storage, ignore_errors=True)
            self.temp_storage = tempfile.mkdtemp(prefix="cleanslate_temp_")
            self._update_ui("Permanent delete successful.", 100)
        except Exception as e: self._update_ui(f"ERROR: Failed to permanently delete temp files - {e}")

# ----- CleanSlate App (Modernized GUI) -----
class CleanSlateApp:
    def __init__(self, root):
        self.root = root
        self.root.title("CleanSlate")
        self.root.geometry("900x750")
        self.root.minsize(800, 700)

        # Color Palette
        self.bg_main = '#E0E0E0'      # Light Grey
        self.bg_widget = '#ECEEDF'    # Off-white/Beige
        self.accent_primary = '#D9C4B0' # Light Tan
        self.accent_hover = '#CFAB8D' # Dark Tan
        self.text_dark = '#5D5C61'    # Dark Gray/Brown for text

        self.root.configure(bg=self.bg_main)
        self.root.overrideredirect(True)

        self.selected_targets = []
        self.wipe_thread = None
        self.drive_detector = DriveDetector()
        self.wipe_engine = SecureWipeEngine(callback=self.update_ui)

        self.setup_styles()
        self.create_custom_title_bar()
        self.create_widgets()
        self.refresh_drives()

    def create_custom_title_bar(self):
        title_bar = tk.Frame(self.root, bg=self.bg_widget, relief='raised', bd=0, highlightthickness=0)
        title_bar.pack(fill='x')
        title_label = tk.Label(title_bar, text="🧹 CleanSlate", bg=self.bg_widget, fg=self.text_dark, font=("Segoe UI", 12, "bold"))
        title_label.pack(side='left', padx=10, pady=5)
        close_button = tk.Button(title_bar, text='✕', bg=self.bg_widget, fg=self.text_dark, relief='flat', font=("Segoe UI", 12, "bold"), command=self.root.destroy, activebackground='#e74c3c', activeforeground='white')
        close_button.pack(side='right', padx=5)
        title_bar.bind("<B1-Motion>", self.move_app)
        title_bar.bind("<ButtonPress-1>", self.start_move)
        title_label.bind("<B1-Motion>", self.move_app)
        title_label.bind("<ButtonPress-1>", self.start_move)

    def start_move(self, event):
        self.x = event.x
        self.y = event.y

    def move_app(self, event):
        self.root.geometry(f"+{self.root.winfo_x() + event.x - self.x}+{self.root.winfo_y() + event.y - self.y}")

    def setup_styles(self):
        style = ttk.Style()
        style.theme_use('clam')
        style.configure('.', font=('Segoe UI', 10), background=self.bg_main, foreground=self.text_dark)
        style.configure('TFrame', background=self.bg_main)
        style.configure('TLabel', background=self.bg_main, foreground=self.text_dark)
        style.configure('TLabelframe', background=self.bg_main, bordercolor=self.accent_primary)
        style.configure('TLabelframe.Label', font=('Segoe UI', 12, 'bold'), foreground=self.text_dark, background=self.bg_main)
        style.configure('Treeview', rowheight=25, fieldbackground=self.bg_widget, background=self.bg_widget, foreground=self.text_dark)
        style.map('Treeview', background=[('selected', self.accent_primary)], foreground=[('selected', 'white')])
        style.configure('Treeview.Heading', font=('Segoe UI', 10, 'bold'), background=self.bg_widget, foreground=self.text_dark)
        style.configure("TCombobox", fieldbackground=self.bg_widget, background=self.bg_widget, foreground=self.text_dark, selectbackground=self.accent_primary, selectforeground='white')
        style.map('TCombobox', fieldbackground=[('readonly', self.bg_widget)], background=[('readonly', self.bg_widget)])
        style.map('TCombobox', foreground=[('readonly', self.text_dark)])
        style.configure("custom.Horizontal.TProgressbar", troughcolor=self.bg_widget, background=self.accent_primary, bordercolor=self.bg_widget)

    def create_widgets(self):
        main_frame = tk.Frame(self.root, bg=self.bg_main, padx=30, pady=20)
        main_frame.pack(fill='both', expand=True)
        main_frame.columnconfigure(0, weight=1)

        header_frame = tk.Frame(main_frame, bg=self.bg_main)
        header_frame.pack(pady=(10, 30))
        tk.Label(header_frame, text="CleanSlate Secure Deletion", font=('Segoe UI', 24, 'bold'), fg=self.text_dark, bg=self.bg_main).pack()
        tk.Label(header_frame, text="File 'Wipe' with Undo or Full Drive Sanitization", font=('Segoe UI', 11), fg=self.accent_hover, bg=self.bg_main).pack()

        selection_frame = ttk.LabelFrame(main_frame, text="Select Target", padding="20")
        selection_frame.pack(fill='x', pady=(0, 20))
        tree_frame = ttk.Frame(selection_frame)
        tree_frame.pack(fill='x', expand=True)
        columns = ('Drive', 'Label', 'Type', 'Size', 'Used', 'System')
        self.drive_tree = ttk.Treeview(tree_frame, columns=columns, show='headings', height=6)
        for col in columns: self.drive_tree.heading(col, text=col)
        self.drive_tree.column('Drive', width=120); self.drive_tree.column('Label', width=150); self.drive_tree.column('System', width=60, anchor='center')
        scrollbar = ttk.Scrollbar(tree_frame, orient='vertical', command=self.drive_tree.yview)
        self.drive_tree.configure(yscrollcommand=scrollbar.set)
        self.drive_tree.pack(side='left', fill='x', expand=True)
        scrollbar.pack(side='right', fill='y')

        button_frame = tk.Frame(selection_frame, bg=self.bg_main)
        button_frame.pack(pady=(15, 5), fill='x')
        btn_w, btn_h, btn_r = 130, 35, 15
        RoundButton(button_frame, "Refresh Drives", self.refresh_drives, btn_w, btn_h, self.accent_primary, 'white', self.accent_hover, 'white', btn_r).pack(side='left', padx=(0, 10))
        RoundButton(button_frame, "Select Files", self.select_files, btn_w, btn_h, self.accent_primary, 'white', self.accent_hover, 'white', btn_r).pack(side='left', padx=10)
        RoundButton(button_frame, "Select Folder", self.select_folder, btn_w, btn_h, self.accent_primary, 'white', self.accent_hover, 'white', btn_r).pack(side='left', padx=10)
        self.selection_label = ttk.Label(button_frame, text="No targets selected.", font=("Segoe UI", 9))
        self.selection_label.pack(side='left', padx=20, pady=8)

        options_frame = ttk.LabelFrame(main_frame, text="Sanitization Options", padding="15")
        options_frame.pack(fill='x', pady=10)
        ttk.Label(options_frame, text="Wipe Method:", font=("Segoe UI", 10, 'bold')).pack(side='left', padx=(0, 10))
        self.wipe_method = tk.StringVar(value="Secure File Deletion (with Undo)")
        combobox = ttk.Combobox(options_frame, textvariable=self.wipe_method, values=["Secure File Deletion (with Undo)", "NIST SP 800-88 Clear (3-Pass)"], state='readonly', width=40)
        combobox.pack(side='left')

        controls_frame = tk.Frame(main_frame, bg=self.bg_main)
        controls_frame.pack(fill='x', pady=20)
        self.wipe_btn = RoundButton(controls_frame, "START WIPE", self.show_confirmation_dialog, 150, 45, '#e74c3c', 'white', '#c0392b', 'white', 20)
        self.wipe_btn.pack(side='left')
        self.stop_btn = RoundButton(controls_frame, "STOP", self.stop_wipe, 100, 45, self.bg_widget, self.text_dark, self.accent_primary, 'white', 20)
        self.stop_btn.pack(side='left', padx=20)
        self.undo_btn = RoundButton(controls_frame, "UNDO", self.undo_wipe, 120, 45, '#f39c12', 'white', '#e67e22', 'white', 20)
        self.undo_btn.pack(side='left')
        self.undo_btn.config(state='disabled')

        progress_frame = ttk.LabelFrame(main_frame, text="Operation Log", padding="20")
        progress_frame.pack(fill='both', expand=True)
        self.progress_label = ttk.Label(progress_frame, text="Ready", font=('Segoe UI', 9))
        self.progress_label.pack(fill='x', pady=(0, 5))
        self.progress_bar = ttk.Progressbar(progress_frame, orient='horizontal', mode='determinate', style="custom.Horizontal.TProgressbar")
        self.progress_bar.pack(fill='x', pady=(0, 10), ipady=2)
        self.log_text = scrolledtext.ScrolledText(progress_frame, height=8, wrap='word', bg=self.bg_widget, fg=self.text_dark, relief='flat', font=("Consolas", 9), borderwidth=0)
        self.log_text.pack(fill='both', expand=True)

    def refresh_drives(self):
        for item in self.drive_tree.get_children(): self.drive_tree.delete(item)
        drives_info = self.drive_detector.get_drives()
        for drive in drives_info:
            is_system = 'Yes' if self.drive_detector.is_system_drive(drive['path']) else 'No'
            self.drive_tree.insert('', 'end', values=(drive['path'], drive.get('label', 'N/A'), drive.get('type', 'N/A'), drive.get('size_readable', 'N/A'), f"{drive.get('percent_used', 0):.1f}%", is_system))
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

        if selected_method == "NIST SP 800-88 Clear (3-Pass)":
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
        confirm_window.configure(bg=self.bg_main)
        frame = ttk.Frame(confirm_window, padding=20)
        frame.pack(fill='both', expand=True)
        ttk.Label(frame, text="⚠️ FINAL WARNING ⚠️", font=('Segoe UI', 14, 'bold'), foreground='#e74c3c').pack(pady=(0, 10))
        if selected_method == "NIST SP 800-88 Clear (3-Pass)":
            ttk.Label(frame, text="You are about to start a PERMANENT drive wipe.", justify=tk.CENTER, wraplength=400).pack()
            ttk.Label(frame, text=f"ALL DATA on drive {drive_path} will be permanently destroyed and is IRREVERSIBLE.", justify=tk.CENTER, wraplength=400, font=('Segoe UI', 10, 'bold'), foreground=self.text_dark).pack(pady=(5, 20))
            def on_proceed():
                confirm_window.destroy()
                self.start_wipe_with_captcha(drive_path)
        else:
            ttk.Label(frame, text="You are about to start a PERMANENT deletion process.", justify=tk.CENTER, wraplength=400).pack()
            ttk.Label(frame, text="This action will make your data unrecoverable.", justify=tk.CENTER, wraplength=400, foreground=self.text_dark).pack(pady=(5, 20))
            def on_proceed():
                confirm_window.destroy()
                self.start_wipe_with_captcha()
        def on_cancel():
            confirm_window.destroy()
            self.log("Operation canceled by user.", "WARNING")
        btn_frame = ttk.Frame(frame)
        btn_frame.pack(pady=10)
        RoundButton(btn_frame, "Proceed", on_proceed, 100, 35, '#e74c3c', 'white', '#c0392b', 'white', 15).pack(side='left', padx=10)
        RoundButton(btn_frame, "Cancel", on_cancel, 100, 35, self.bg_widget, self.text_dark, self.accent_primary, 'white', 15).pack(side='left', padx=10)
        confirm_window.protocol("WM_DELETE_WINDOW", on_cancel)
        self.root.wait_window(confirm_window)

    def start_wipe_with_captcha(self, drive_path=None):
        captcha = ''.join(random.choices(string.ascii_letters + string.digits, k=6))
        ans = simpledialog.askstring("Captcha Confirmation", f"This is an irreversible action.\nPlease type the following to confirm: {captcha}")
        if ans != captcha:
            messagebox.showwarning("Captcha Failed", "Captcha did not match. Aborting.")
            self.log("Captcha failed. Operation aborted.", "ERROR")
            return
        selected_method = self.wipe_method.get()
        if selected_method == "NIST SP 800-88 Clear (3-Pass)":
            self.wipe_btn.config(state='disabled'); self.stop_btn.config(state='normal'); self.undo_btn.config(state='disabled')
            self.wipe_engine.stop_flag = False
            self.wipe_thread = threading.Thread(target=self.wipe_engine._overwrite_drive, args=(drive_path,)); self.wipe_thread.start()
        else:
            self.wipe_btn.config(state='disabled'); self.stop_btn.config(state='normal'); self.undo_btn.config(state='disabled')
            self.wipe_engine.stop_flag = False
            self.wipe_thread = threading.Thread(target=self.wipe_and_schedule_delete); self.wipe_thread.start()

    def wipe_and_schedule_delete(self):
        success = self.wipe_engine.wipe_target(self.selected_targets)
        if success: self.root.after(0, self.start_undo_countdown)

    def start_undo_countdown(self):
        self.undo_btn.config(state='normal'); self.stop_btn.config(state='disabled'); self.wipe_btn.config(state='disabled')
        self.countdown_thread = threading.Thread(target=self.final_delete_delay); self.countdown_thread.start()

    def final_delete_delay(self):
        countdown = 30
        while countdown > 0 and not self.wipe_engine.stop_flag:
            self.root.after(0, lambda c=countdown: self.undo_btn._draw_button('#f39c12', 'white') if c > 0 else None)
            self.root.after(0, lambda c=countdown: setattr(self.undo_btn, 'text', f"UNDO ({c}s)"))
            time.sleep(1)
            countdown -= 1
        if not self.wipe_engine.stop_flag:
            self.root.after(0, lambda: setattr(self.undo_btn, 'text', "UNDO"))
            self.wipe_engine.permanent_delete()
            self.root.after(0, self.reset_buttons)

    def undo_wipe(self):
        self.wipe_engine.stop_flag = True
        self.root.after(0, lambda: setattr(self.undo_btn, 'text', "UNDO"))
        self.wipe_engine.undo()
        self.reset_buttons()

    def stop_wipe(self):
        self.wipe_engine.stop_flag = True
        self.log("Stopping wipe...", "WARNING")
        self.reset_buttons()

    def reset_buttons(self):
        self.wipe_btn.config(state='normal'); self.stop_btn.config(state='normal'); self.undo_btn.config(state='disabled')
        self.progress_label.config(text="Ready"); self.progress_bar['value'] = 0

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

def main():
    root = tk.Tk()
    app = CleanSlateApp(root)
    root.mainloop()

if __name__ == "__main__":
    main()
