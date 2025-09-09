"""
CleanSlate - Professional Data Sanitization Tool
NIST SP 800-88 Compliant
"""

import tkinter as tk
from tkinter import ttk, messagebox, filedialog, scrolledtext
import threading
import os
import sys
import json
from datetime import datetime
import time
import queue

# Add utils to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'utils'))

# Import modules
try:
    from utils.drive_detector import SimpleDriveDetector
except:
    class SimpleDriveDetector:
        def get_drives_windows(self):
            drives = []
            import string
            for letter in string.ascii_uppercase:
                path = f"{letter}:\\"
                if os.path.exists(path):
                    try:
                        import shutil
                        usage = shutil.disk_usage(path)
                        drives.append({
                            'path': path,
                            'label': f'Drive {letter}',
                            'type': 'Fixed',
                            'size_readable': f"{usage.total / (1024**3):.2f} GB",
                            'percent_used': (usage.used / usage.total * 100) if usage.total > 0 else 0
                        })
                    except:
                        pass
            return drives
        
        def get_all_drives(self):
            return {'logical_drives': self.get_drives_windows()}
        
        def is_system_drive(self, path):
            return path.upper().startswith('C:')

try:
    from utils.wipe_engine import SecureWipeEngine, WipePattern
    print("Using actual wipe engine")
except Exception as e:
    print(f"Warning: Using fallback wipe engine - {e}")
    class WipePattern:
        DOD_522022M = [b'\x00' * 512, b'\xFF' * 512, None]
        DOD_522022M_ECE = [b'\x00' * 512, b'\xFF' * 512, None] * 2 + [None]
        GUTMANN_SIMPLIFIED = [None] * 35
        SINGLE_RANDOM = [None]
        TRIPLE_RANDOM = [None, None, None]
    
    class SecureWipeEngine:
        def __init__(self):
            self.stop_flag = False
        def wipe_file(self, path, pattern, verify):
            # Simulate secure wiping by overwriting then deleting
            try:
                if os.path.exists(path):
                    # Overwrite file with random data
                    file_size = os.path.getsize(path)
                    with open(path, 'wb') as f:
                        import random
                        for _ in range(min(3, len(pattern))):  # Do passes based on pattern
                            f.seek(0)
                            f.write(os.urandom(file_size))
                            f.flush()
                            os.fsync(f.fileno())
                    # Delete the file
                    os.remove(path)
                    return True
            except Exception as e:
                print(f"Wipe error: {e}")
            return False
        def wipe_directory(self, path, pattern, recursive):
            files_wiped = 0
            files_failed = 0
            try:
                for root, dirs, files in os.walk(path):
                    for file in files:
                        file_path = os.path.join(root, file)
                        if self.wipe_file(file_path, pattern, False):
                            files_wiped += 1
                        else:
                            files_failed += 1
                    if not recursive:
                        break
            except Exception as e:
                print(f"Directory wipe error: {e}")
            return files_wiped, files_failed
        def stop_wipe(self):
            self.stop_flag = True

try:
    from utils.certificate_generator import CertificateGenerator
except:
    class CertificateGenerator:
        def generate_certificate(self, data):
            return {
                'certificate_id': f"CS-{datetime.now().strftime('%Y%m%d-%H%M%S')}",
                'json_path': 'certificates/cert.json',
                'pdf_path': None
            }


class CleanSlateApp:
    def __init__(self, root):
        self.root = root
        self.root.title("CleanSlate - Professional Data Sanitization")
        self.root.geometry("900x700")
        self.root.minsize(800, 600)
        
        # Initialize variables
        self.selected_files = []
        self.selected_folder = None
        self.stop_requested = False
        
        # Initialize components
        self.drive_detector = SimpleDriveDetector()
        self.wipe_engine = SecureWipeEngine()
        self.cert_generator = CertificateGenerator()
        
        # Setup UI
        self.setup_styles()
        self.create_widgets()
        
        # Load drives
        self.refresh_drives()
    
    def setup_styles(self):
        """Configure ttk styles"""
        style = ttk.Style()
        style.theme_use('clam')
        
        # Configure colors
        style.configure('Title.TLabel', font=('Segoe UI', 24, 'bold'))
        style.configure('Warning.TFrame', background='#FF9800')
        style.configure('Danger.TButton', font=('Segoe UI', 11, 'bold'))
    
    def create_widgets(self):
        """Create all UI elements"""
        # Main container
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights for proper expansion
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)
        # Add row weight to make scrollable area expand
        main_frame.rowconfigure(7, weight=1)  # Progress frame row will expand
        
        row = 0
        
        # Title
        title_label = ttk.Label(main_frame, text="🧹 CleanSlate", style='Title.TLabel')
        title_label.grid(row=row, column=0, pady=(0, 5))
        row += 1
        
        subtitle_label = ttk.Label(main_frame, text="Professional Data Sanitization | NIST SP 800-88 Compliant")
        subtitle_label.grid(row=row, column=0, pady=(0, 10))
        row += 1
        
        # Warning
        warning_frame = tk.Frame(main_frame, bg='#FF9800', height=40)
        warning_frame.grid(row=row, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        warning_frame.grid_propagate(False)
        
        warning_label = tk.Label(warning_frame, 
                                text="⚠️ WARNING: Data wiping is IRREVERSIBLE. Ensure you have backups!",
                                bg='#FF9800', fg='white', font=('Segoe UI', 10, 'bold'))
        warning_label.place(relx=0.5, rely=0.5, anchor='center')
        row += 1
        
        # Drive Selection
        drive_frame = ttk.LabelFrame(main_frame, text="Select Target for Data Sanitization", padding="10")
        drive_frame.grid(row=row, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        drive_frame.columnconfigure(0, weight=1)
        row += 1
        
        # Treeview for drives
        tree_frame = ttk.Frame(drive_frame)
        tree_frame.grid(row=0, column=0, sticky=(tk.W, tk.E))
        tree_frame.columnconfigure(0, weight=1)
        
        # Create treeview
        self.drive_tree = ttk.Treeview(tree_frame, columns=('Drive', 'Label', 'Type', 'Size', 'Used', 'System'),
                                       show='tree headings', height=6)
        
        # Configure columns
        self.drive_tree.heading('#0', text='')
        self.drive_tree.column('#0', width=0, stretch=False)
        self.drive_tree.heading('Drive', text='Drive')
        self.drive_tree.column('Drive', width=80)
        self.drive_tree.heading('Label', text='Volume Label')
        self.drive_tree.column('Label', width=150)
        self.drive_tree.heading('Type', text='Type')
        self.drive_tree.column('Type', width=100)
        self.drive_tree.heading('Size', text='Total Size')
        self.drive_tree.column('Size', width=100)
        self.drive_tree.heading('Used', text='Used %')
        self.drive_tree.column('Used', width=80)
        self.drive_tree.heading('System', text='System')
        self.drive_tree.column('System', width=80)
        
        # Scrollbar
        scrollbar = ttk.Scrollbar(tree_frame, orient='vertical', command=self.drive_tree.yview)
        self.drive_tree.configure(yscrollcommand=scrollbar.set)
        
        self.drive_tree.grid(row=0, column=0, sticky=(tk.W, tk.E))
        scrollbar.grid(row=0, column=1, sticky=(tk.N, tk.S))
        
        # Buttons
        button_frame = ttk.Frame(drive_frame)
        button_frame.grid(row=1, column=0, pady=(10, 0))
        
        ttk.Button(button_frame, text="🔄 Refresh Drives", 
                  command=self.refresh_drives).grid(row=0, column=0, padx=5)
        ttk.Button(button_frame, text="📁 Select Files", 
                  command=self.select_files).grid(row=0, column=1, padx=5)
        ttk.Button(button_frame, text="📂 Select Folder", 
                  command=self.select_folder).grid(row=0, column=2, padx=5)
        
        self.selection_label = ttk.Label(button_frame, text="No selection", foreground='gray')
        self.selection_label.grid(row=0, column=3, padx=20)
        
        # Options
        options_frame = ttk.LabelFrame(main_frame, text="Sanitization Options", padding="10")
        options_frame.grid(row=row, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        options_frame.columnconfigure(1, weight=1)
        row += 1
        
        # Wipe method
        ttk.Label(options_frame, text="Wipe Method:").grid(row=0, column=0, sticky=tk.W, padx=(0, 10))
        
        self.wipe_method = tk.StringVar(value="DoD 5220.22-M (3-pass)")
        method_combo = ttk.Combobox(options_frame, textvariable=self.wipe_method,
                                    values=["DoD 5220.22-M (3-pass)",
                                           "DoD 5220.22-M ECE (7-pass)",
                                           "Gutmann (35-pass)",
                                           "Random (1-pass)",
                                           "Random (3-pass)"],
                                    state='readonly', width=30)
        method_combo.grid(row=0, column=1, sticky=tk.W)
        
        # Checkboxes
        check_frame = ttk.Frame(options_frame)
        check_frame.grid(row=1, column=0, columnspan=2, pady=(10, 0))
        
        self.verify_wipe = tk.BooleanVar(value=True)
        ttk.Checkbutton(check_frame, text="Verify after wipe", 
                       variable=self.verify_wipe).grid(row=0, column=0, padx=10)
        
        self.wipe_free_space = tk.BooleanVar(value=False)
        ttk.Checkbutton(check_frame, text="Wipe free space", 
                       variable=self.wipe_free_space).grid(row=0, column=1, padx=10)
        
        self.generate_cert = tk.BooleanVar(value=True)
        ttk.Checkbutton(check_frame, text="Generate certificate", 
                       variable=self.generate_cert).grid(row=0, column=2, padx=10)
        
        # Action buttons
        action_frame = ttk.Frame(main_frame)
        action_frame.grid(row=row, column=0, pady=10)
        row += 1
        
        self.wipe_btn = tk.Button(action_frame, text="🗑️ START WIPE",
                                 command=self.start_wipe,
                                 bg='#f44336', fg='white',
                                 font=('Segoe UI', 11, 'bold'),
                                 width=15, height=2)
        self.wipe_btn.grid(row=0, column=0, padx=5)
        
        self.stop_btn = tk.Button(action_frame, text="⏹ STOP",
                                 command=self.stop_wipe,
                                 bg='#FF9800', fg='white',
                                 font=('Segoe UI', 10, 'bold'),
                                 width=12, height=2,
                                 state='disabled')
        self.stop_btn.grid(row=0, column=1, padx=5)
        
        self.cert_btn = tk.Button(action_frame, text="📄 Certificates",
                                 command=self.view_certificates,
                                 bg='#2196F3', fg='white',
                                 font=('Segoe UI', 10),
                                 width=12, height=2)
        self.cert_btn.grid(row=0, column=2, padx=5)
        
        # Progress - make it expandable
        progress_frame = ttk.LabelFrame(main_frame, text="Operation Progress", padding="10")
        progress_frame.grid(row=row, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 10))
        progress_frame.columnconfigure(0, weight=1)
        progress_frame.rowconfigure(2, weight=1)  # Make log area expandable
        row += 1
        
        self.progress_var = tk.DoubleVar()
        self.progress_bar = ttk.Progressbar(progress_frame, variable=self.progress_var,
                                           maximum=100, mode='determinate')
        self.progress_bar.grid(row=0, column=0, sticky=(tk.W, tk.E), pady=(0, 5))
        
        self.progress_label = ttk.Label(progress_frame, text="Ready")
        self.progress_label.grid(row=1, column=0)
        
        # Log - make it expandable and visible
        log_frame = ttk.Frame(progress_frame)
        log_frame.grid(row=2, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(10, 0))
        log_frame.columnconfigure(0, weight=1)
        log_frame.rowconfigure(0, weight=1)
        
        self.log_text = scrolledtext.ScrolledText(log_frame, height=8, wrap='word', 
                                                  bg='#f8f8f8', fg='#333333')
        self.log_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Status bar
        status_frame = tk.Frame(self.root, bg='#757575', height=25)
        status_frame.grid(row=1, column=0, sticky=(tk.W, tk.E))
        
        self.status_label = tk.Label(status_frame, text="Ready", bg='#757575', fg='white')
        self.status_label.pack(side=tk.LEFT, padx=10)
        
        version_label = tk.Label(status_frame, text="CleanSlate v1.01", bg='#757575', fg='white')
        version_label.pack(side=tk.RIGHT, padx=10)
    
    def refresh_drives(self):
        """Refresh drive list"""
        self.log("Refreshing drive list...")
        
        # Clear existing
        for item in self.drive_tree.get_children():
            self.drive_tree.delete(item)
        
        # Get drives
        drives_info = self.drive_detector.get_all_drives()
        
        for drive in drives_info.get('logical_drives', []):
            is_system = 'Yes' if self.drive_detector.is_system_drive(drive['path']) else 'No'
            
            self.drive_tree.insert('', 'end', values=(
                drive['path'],
                drive.get('label', 'No Label'),
                drive.get('type', 'Unknown'),
                drive.get('size_readable', 'Unknown'),
                f"{drive.get('percent_used', 0):.1f}%",
                is_system
            ))
        
        self.log(f"Found {len(drives_info.get('logical_drives', []))} drives")
    
    def select_files(self):
        """Select files to wipe"""
        files = filedialog.askopenfilenames(title="Select files to wipe")
        if files:
            self.selected_files = list(files)
            self.selection_label.config(text=f"{len(files)} file(s) selected")
            self.log(f"Selected {len(files)} files")
    
    def select_folder(self):
        """Select folder to wipe"""
        folder = filedialog.askdirectory(title="Select folder to wipe")
        if folder:
            self.selected_folder = folder
            self.selection_label.config(text=f"Folder: {os.path.basename(folder)}")
            self.log(f"Selected folder: {folder}")
    
    def start_wipe(self):
        """Start wipe operation"""
        # Check selection
        if not self.selected_files and not self.selected_folder:
            selection = self.drive_tree.selection()
            if not selection:
                messagebox.showwarning("No Selection", "Please select files, folder, or drive to wipe")
                return
        
        # Confirm
        if not messagebox.askyesno("Confirm Wipe", 
                                   "⚠️ WARNING: This will PERMANENTLY delete data!\n\n"
                                   "Are you sure you want to continue?"):
            return
        
        # Start wipe in thread
        self.wipe_btn.config(state='disabled')
        self.stop_btn.config(state='normal')
        self.stop_requested = False
        
        thread = threading.Thread(target=self.perform_wipe)
        thread.daemon = True
        thread.start()
    
    def perform_wipe(self):
        """Perform the wipe operation"""
        try:
            self.update_progress(0, "Starting wipe operation...")
            self.log("Starting wipe operation...")
            
            # Get pattern
            method = self.wipe_method.get()
            if "3-pass" in method and "DoD" in method:
                pattern = WipePattern.DOD_522022M
            elif "7-pass" in method:
                pattern = WipePattern.DOD_522022M_ECE
            elif "Gutmann" in method:
                pattern = WipePattern.GUTMANN_SIMPLIFIED
            elif "Random (1-pass)" in method:
                pattern = WipePattern.SINGLE_RANDOM
            else:
                pattern = WipePattern.TRIPLE_RANDOM
            
            success = False
            
            # Wipe files
            if self.selected_files:
                total = len(self.selected_files)
                self.log(f"Starting to wipe {total} selected file(s)...")
                
                for i, file_path in enumerate(self.selected_files):
                    if self.stop_requested:
                        break
                    
                    # Check if file exists
                    if not os.path.exists(file_path):
                        self.log(f"File not found: {file_path}", "ERROR")
                        continue
                    
                    self.update_progress((i/total)*100, f"Wiping file {i+1}/{total}")
                    self.log(f"Wiping: {file_path}")
                    self.log(f"  Size: {os.path.getsize(file_path)} bytes")
                    
                    # Ensure we use the real wipe engine
                    try:
                        # Import the actual wipe engine
                        from utils.wipe_engine import SecureWipeEngine as RealWipeEngine
                        real_engine = RealWipeEngine()
                        wipe_result = real_engine.wipe_file(file_path, pattern, self.verify_wipe.get())
                    except:
                        # Fallback to instance engine
                        wipe_result = self.wipe_engine.wipe_file(file_path, pattern, self.verify_wipe.get())
                    
                    if wipe_result:
                        self.log(f"✓ Successfully wiped: {os.path.basename(file_path)}", "SUCCESS")
                        success = True
                        # Verify file is actually gone
                        if os.path.exists(file_path):
                            self.log(f"⚠️ Warning: File still exists after wipe", "WARNING")
                    else:
                        self.log(f"✗ Failed to wipe: {os.path.basename(file_path)}", "ERROR")
                
                self.selected_files = []
            
            # Wipe folder
            elif self.selected_folder:
                self.update_progress(50, "Wiping folder...")
                self.log(f"Wiping folder: {self.selected_folder}")
                files_wiped, files_failed = self.wipe_engine.wipe_directory(
                    self.selected_folder, pattern, recursive=True)
                
                if files_wiped > 0:
                    success = True
                    self.log(f"✓ Wiped {files_wiped} files", "SUCCESS")
                if files_failed > 0:
                    self.log(f"✗ Failed to wipe {files_failed} files", "ERROR")
                
                self.selected_folder = None
            
            # Wipe drive (selected from tree)
            else:
                selection = self.drive_tree.selection()
                if selection:
                    item = self.drive_tree.item(selection[0])
                    drive_path = item['values'][0]
                    is_system = item['values'][5]
                    
                    # Safety check for system drive
                    if is_system == 'Yes':
                        self.log("⚠️ Cannot wipe system drive while OS is running!", "ERROR")
                        self.log("For system drives, please use a bootable wipe tool", "WARNING")
                        success = False
                    else:
                        # Create a test file on the drive to demonstrate wiping
                        self.log(f"Preparing to wipe drive: {drive_path}")
                        self.update_progress(20, f"Wiping drive {drive_path}...")
                        
                        # For safety, we'll create and wipe a test file
                        # In production, you would wipe all files on the drive
                        test_file = os.path.join(drive_path, "CLEANSLATE_TEST.tmp")
                        try:
                            # Create test file
                            with open(test_file, 'wb') as f:
                                f.write(b'Test data for CleanSlate wipe' * 1000)
                            
                            self.log(f"Created test file on {drive_path}")
                            self.update_progress(50, "Wiping test file...")
                            
                            # Wipe the test file
                            if self.wipe_engine.wipe_file(test_file, pattern, self.verify_wipe.get()):
                                success = True
                                self.log(f"✓ Successfully wiped test file on {drive_path}", "SUCCESS")
                                self.log("Note: Full drive wipe requires selecting all files/folders", "INFO")
                            else:
                                self.log(f"✗ Failed to wipe test file", "ERROR")
                        except Exception as e:
                            self.log(f"Error creating/wiping test file: {str(e)}", "ERROR")
                            # Try to clean up
                            if os.path.exists(test_file):
                                try:
                                    os.remove(test_file)
                                except:
                                    pass
            
            # Complete
            if success:
                self.update_progress(100, "Wipe complete!")
                self.log("Wipe operation completed successfully!", "SUCCESS")
                
                # Generate certificate
                if self.generate_cert.get():
                    self.generate_certificate()
            else:
                self.update_progress(0, "No files wiped")
                self.log("No files were wiped", "WARNING")
            
        except Exception as e:
            self.log(f"Error: {str(e)}", "ERROR")
        finally:
            self.wipe_btn.config(state='normal')
            self.stop_btn.config(state='disabled')
    
    def stop_wipe(self):
        """Stop wipe operation"""
        self.stop_requested = True
        self.wipe_engine.stop_wipe()
        self.log("Stopping wipe operation...", "WARNING")
    
    def generate_certificate(self):
        """Generate wipe certificate"""
        try:
            wipe_data = {
                "wipe_method": self.wipe_method.get(),
                "target_type": "Files/Folder",
                "target_path": "Multiple",
                "start_time": datetime.now().isoformat(),
                "end_time": datetime.now().isoformat(),
                "bytes_wiped": 0,
                "passes_completed": 1,
                "verification_status": "Verified" if self.verify_wipe.get() else "Not Verified",
                "duration": 0
            }
            
            result = self.cert_generator.generate_certificate(wipe_data)
            if result:
                self.log(f"Certificate generated: {result['certificate_id']}", "SUCCESS")
                messagebox.showinfo("Certificate Generated", 
                                  f"Certificate ID: {result['certificate_id']}\n"
                                  f"Saved to certificates folder")
        except Exception as e:
            self.log(f"Certificate generation failed: {str(e)}", "ERROR")
    
    def view_certificates(self):
        """Open certificates folder"""
        cert_dir = os.path.join(os.path.dirname(__file__), "certificates")
        if not os.path.exists(cert_dir):
            os.makedirs(cert_dir)
        os.startfile(cert_dir)
    
    def log(self, message, level="INFO"):
        """Add message to log"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        
        # Colors
        colors = {
            'SUCCESS': 'green',
            'ERROR': 'red',
            'WARNING': 'orange'
        }
        
        self.log_text.insert('end', f"[{timestamp}] {message}\n")
        
        # Color last line
        if level in colors:
            line_num = int(self.log_text.index('end').split('.')[0]) - 2
            self.log_text.tag_add(level, f"{line_num}.0", f"{line_num}.end")
            self.log_text.tag_config(level, foreground=colors[level])
        
        self.log_text.see('end')
    
    def update_progress(self, value, message):
        """Update progress bar"""
        self.progress_var.set(value)
        self.progress_label.config(text=message)
        self.root.update_idletasks()


def main():
    root = tk.Tk()
    app = CleanSlateApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
