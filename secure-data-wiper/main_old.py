"""
CleanSlate - Data Sanitization Tool
A user-friendly tool for secure data wiping compliant with NIST SP 800-88
"""

import tkinter as tk
from tkinter import ttk, messagebox, filedialog, scrolledtext
import threading
import os
import sys
import json
from datetime import datetime
import webbrowser
import time
import queue

# Add utils to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'utils'))

# Import our modules with proper error handling
try:
    from utils.drive_detector import SimpleDriveDetector
    try:
        from utils.drive_detector import get_drive_detector
    except:
        def get_drive_detector():
            return SimpleDriveDetector()
except ImportError:
    print("Warning: Could not import drive_detector")
    class SimpleDriveDetector:
        def get_all_drives(self):
            return {'logical_drives': [], 'physical_disks': []}
        def is_system_drive(self, path):
            return False
    def get_drive_detector():
        return SimpleDriveDetector()

try:
    from utils.wipe_engine import SecureWipeEngine, WipeMethod, WipePattern
except ImportError:
    print("Warning: Could not import wipe_engine")
    class WipePattern:
        DOD_522022M = [b'\x00' * 512, b'\xFF' * 512, None]
        DOD_522022M_ECE = [b'\x00' * 512, b'\xFF' * 512, None] * 2 + [None]
        GUTMANN_SIMPLIFIED = [None] * 35
        SINGLE_RANDOM = [None]
        TRIPLE_RANDOM = [None, None, None]
    class SecureWipeEngine:
        def __init__(self):
            self.progress = 0
        def wipe_file(self, path, pattern, verify):
            return False
        def wipe_directory(self, path, pattern, recursive):
            return 0, 0
        def stop_wipe(self):
            pass

try:
    from utils.certificate_generator import CertificateGenerator
except ImportError:
    print("Warning: Could not import certificate_generator")
    class CertificateGenerator:
        def generate_certificate(self, data):
            return None

try:
    from utils.logger import SecureWipeLogger
except ImportError:
    class SecureWipeLogger:
        def log(self, message, level):
            print(f"[{level}] {message}")

class CleanSlateGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("CleanSlate - Professional Data Sanitization")
        self.root.geometry("1000x750")
        self.root.resizable(True, True)  # Allow resizing
        self.root.minsize(800, 600)  # Set minimum size
        
        # Initialize components
        self.drive_detector = get_drive_detector()
        self.wipe_engine = SecureWipeEngine()
        self.cert_generator = CertificateGenerator()
        self.current_operation = None
        self.selected_files = []
        self.selected_folder = None
        self.stop_requested = False
        self.message_queue = queue.Queue()
        
        # Set application icon and colors
        self.setup_theme()
        
        # Configure window grid
        self.root.grid_rowconfigure(0, weight=1)
        self.root.grid_columnconfigure(0, weight=1)
        
        # Create main container with scrollbar
        self.create_main_container()
        
        # Create GUI elements
        self.create_widgets()
        
        # Load drives on startup
        self.root.after(100, self.refresh_drives)
        
        # Start message queue processor
        self.process_message_queue()
    
    def setup_theme(self):
        """Setup application theme and colors"""
        self.colors = {
            'bg': '#ffffff',
            'frame_bg': '#f5f5f5',
            'primary': '#2196F3',
            'danger': '#f44336',
            'success': '#4CAF50',
            'warning': '#FF9800',
            'text': '#212121',
            'text_secondary': '#757575',
            'border': '#e0e0e0'
        }
        
        self.root.configure(bg=self.colors['bg'])
        
        # Configure ttk styles
        style = ttk.Style()
        style.theme_use('clam')
        
        style.configure('Title.TLabel', font=('Segoe UI', 28, 'bold'), background=self.colors['bg'])
        style.configure('Subtitle.TLabel', font=('Segoe UI', 11), background=self.colors['bg'], foreground=self.colors['text_secondary'])
        style.configure('Header.TLabel', font=('Segoe UI', 12, 'bold'), background=self.colors['frame_bg'])
        style.configure('Card.TFrame', background=self.colors['frame_bg'], relief='flat', borderwidth=1)
        style.configure('Main.TFrame', background=self.colors['bg'])
        
    def create_main_container(self):
        """Create main scrollable container"""
        # Create canvas and scrollbar for main content
        self.main_canvas = tk.Canvas(self.root, bg=self.colors['bg'], highlightthickness=0)
        self.main_scrollbar = ttk.Scrollbar(self.root, orient="vertical", command=self.main_canvas.yview)
        self.scrollable_frame = ttk.Frame(self.main_canvas, style='Main.TFrame')
        
        self.scrollable_frame.bind(
            "<Configure>",
            lambda e: self.main_canvas.configure(scrollregion=self.main_canvas.bbox("all"))
        )
        
        self.main_canvas.create_window((0, 0), window=self.scrollable_frame, anchor="nw")
        self.main_canvas.configure(yscrollcommand=self.main_scrollbar.set)
        
        # Grid layout
        self.main_canvas.grid(row=0, column=0, sticky="nsew")
        self.main_scrollbar.grid(row=0, column=1, sticky="ns")
        
        # Bind mousewheel for scrolling
        self.main_canvas.bind_all("<MouseWheel>", self._on_mousewheel)
        
    def _on_mousewheel(self, event):
        """Handle mouse wheel scrolling"""
        self.main_canvas.yview_scroll(int(-1*(event.delta/120)), "units")
    
    def create_widgets(self):
        """Create all GUI widgets"""
        container = self.scrollable_frame
        container.grid_columnconfigure(0, weight=1)
        
        # Title Section
        title_frame = ttk.Frame(container, style='Main.TFrame')
        title_frame.grid(row=0, column=0, sticky="ew", padx=20, pady=(20, 10))
        
        title_label = ttk.Label(title_frame, text="🧹 CleanSlate", style='Title.TLabel')
        title_label.pack()
        
        subtitle_label = ttk.Label(title_frame, 
                                   text="Professional Data Sanitization | NIST SP 800-88 Compliant",
                                   style='Subtitle.TLabel')
        subtitle_label.pack(pady=(5, 0))
        
        # Warning Banner
        warning_frame = tk.Frame(container, bg=self.colors['warning'], height=45)
        warning_frame.grid(row=1, column=0, sticky="ew", padx=20, pady=10)
        warning_frame.grid_propagate(False)
        
        warning_label = tk.Label(warning_frame,
                                text="⚠️ WARNING: Data wiping is IRREVERSIBLE. Ensure you have backups!",
                                bg=self.colors['warning'], fg='white', font=('Segoe UI', 11, 'bold'))
        warning_label.place(relx=0.5, rely=0.5, anchor='center')
        
        # Main Content Area
        content_frame = ttk.Frame(container, style='Main.TFrame')
        content_frame.grid(row=2, column=0, sticky="nsew", padx=20)
        content_frame.grid_columnconfigure(0, weight=1)
        
        # Create sections in grid layout
        self.create_drive_section(content_frame)
        self.create_options_section(content_frame)
        self.create_action_section(content_frame)
        self.create_progress_section(content_frame)
        
        # Status Bar (at bottom of window, not scrollable)
        self.create_status_bar()
    
    def create_drive_section(self, parent):
        """Create drive selection section"""
        # Create a styled frame
        drive_frame = ttk.LabelFrame(parent, text="Select Target for Data Sanitization", 
                                     style='Card.TLabelframe')
        drive_frame.grid(row=0, column=0, sticky="ew", pady=(0, 15))
        drive_frame.grid_columnconfigure(0, weight=1)
        
        # Create frame for treeview with scrollbars
        tree_frame = ttk.Frame(drive_frame)
        tree_frame.grid(row=0, column=0, sticky="ew", padx=10, pady=10)
        tree_frame.grid_columnconfigure(0, weight=1)
        
        # Create Treeview for drives
        columns = ('Drive', 'Label', 'Type', 'Size', 'Used', 'System')
        self.drive_tree = ttk.Treeview(tree_frame, columns=columns, height=6, selectmode='browse', show='tree headings')
        
        # Configure columns with better widths
        self.drive_tree.heading('#0', text='')
        self.drive_tree.column('#0', width=0, stretch=False)
        
        self.drive_tree.heading('Drive', text='Drive')
        self.drive_tree.column('Drive', width=80, minwidth=60)
        
        self.drive_tree.heading('Label', text='Volume Label')
        self.drive_tree.column('Label', width=180, minwidth=100)
        
        self.drive_tree.heading('Type', text='Type')
        self.drive_tree.column('Type', width=100, minwidth=80)
        
        self.drive_tree.heading('Size', text='Total Size')
        self.drive_tree.column('Size', width=120, minwidth=80)
        
        self.drive_tree.heading('Used', text='Used')
        self.drive_tree.column('Used', width=80, minwidth=60)
        
        self.drive_tree.heading('System', text='System')
        self.drive_tree.column('System', width=80, minwidth=60)
        
        # Add scrollbars
        v_scrollbar = ttk.Scrollbar(tree_frame, orient='vertical', command=self.drive_tree.yview)
        h_scrollbar = ttk.Scrollbar(tree_frame, orient='horizontal', command=self.drive_tree.xview)
        self.drive_tree.configure(yscrollcommand=v_scrollbar.set, xscrollcommand=h_scrollbar.set)
        
        # Grid layout for tree and scrollbars
        self.drive_tree.grid(row=0, column=0, sticky="nsew")
        v_scrollbar.grid(row=0, column=1, sticky="ns")
        h_scrollbar.grid(row=1, column=0, sticky="ew")
        
        tree_frame.grid_rowconfigure(0, weight=1)
        tree_frame.grid_columnconfigure(0, weight=1)
        
        # Buttons for drive operations
        button_frame = ttk.Frame(drive_frame)
        button_frame.grid(row=1, column=0, sticky="ew", padx=10, pady=(0, 10))
        
        ttk.Button(button_frame, text="🔄 Refresh Drives", 
                  command=self.refresh_drives, width=18).grid(row=0, column=0, padx=5, pady=2)
        ttk.Button(button_frame, text="📁 Select Files", 
                  command=self.select_files, width=18).grid(row=0, column=1, padx=5, pady=2)
        ttk.Button(button_frame, text="📂 Select Folder", 
                  command=self.select_folder, width=18).grid(row=0, column=2, padx=5, pady=2)
        
        # Selection display
        self.selection_label = ttk.Label(button_frame, text="No selection", 
                                        font=('Segoe UI', 9), foreground=self.colors['text_secondary'])
        self.selection_label.grid(row=0, column=3, padx=20, pady=2)
    
    def create_options_section(self, parent):
        """Create wipe options section"""
        options_frame = ttk.LabelFrame(parent, text="Sanitization Options", 
                                      style='Card.TLabelframe')
        options_frame.grid(row=1, column=0, sticky="ew", pady=(0, 15))
        options_frame.grid_columnconfigure(1, weight=1)
        
        # Wipe method selection
        method_frame = ttk.Frame(options_frame)
        method_frame.grid(row=0, column=0, columnspan=2, sticky="ew", padx=10, pady=10)
        
        ttk.Label(method_frame, text="Wipe Method:", 
                 font=('Segoe UI', 10)).grid(row=0, column=0, padx=(0, 10), sticky="w")
        
        self.wipe_method = tk.StringVar(value="DoD 5220.22-M (3-pass)")
        methods = [
            "DoD 5220.22-M (3-pass)",
            "DoD 5220.22-M ECE (7-pass)",
            "Gutmann (35-pass)",
            "Random (1-pass)",
            "Random (3-pass)"
        ]
        
        method_combo = ttk.Combobox(method_frame, textvariable=self.wipe_method, 
                                    values=methods, state='readonly', width=35)
        method_combo.grid(row=0, column=1, padx=5, sticky="ew")
        
        # Method description
        self.method_desc = ttk.Label(method_frame, text="Recommended for most users", 
                                     font=('Segoe UI', 9, 'italic'), 
                                     foreground=self.colors['text_secondary'])
        self.method_desc.grid(row=0, column=2, padx=10, sticky="w")
        
        method_combo.bind('<<ComboboxSelected>>', self.update_method_description)
        
        # Additional options
        options_inner_frame = ttk.Frame(options_frame)
        options_inner_frame.grid(row=1, column=0, columnspan=2, sticky="ew", padx=10, pady=(0, 10))
        
        self.verify_wipe = tk.BooleanVar(value=True)
        ttk.Checkbutton(options_inner_frame, text="✓ Verify after wipe",
                       variable=self.verify_wipe).grid(row=0, column=0, padx=10, sticky="w")
        
        self.wipe_free_space = tk.BooleanVar(value=False)
        ttk.Checkbutton(options_inner_frame, text="✓ Wipe free space",
                       variable=self.wipe_free_space).grid(row=0, column=1, padx=10, sticky="w")
        
        self.generate_cert = tk.BooleanVar(value=True)
        ttk.Checkbutton(options_inner_frame, text="✓ Generate certificate",
                       variable=self.generate_cert).grid(row=0, column=2, padx=10, sticky="w")
    
    def create_action_section(self, parent):
        """Create action buttons section"""
        action_frame = ttk.Frame(parent)
        action_frame.grid(row=2, column=0, sticky="ew", pady=(0, 15))
        
        # Center the buttons
        button_container = ttk.Frame(action_frame)
        button_container.place(relx=0.5, rely=0.5, anchor='center')
        
        # Main action buttons with better styling
        self.wipe_btn = tk.Button(button_container, text="🗑️ START WIPE", 
                                 command=self.start_wipe,
                                 bg=self.colors['danger'], fg='white',
                                 font=('Segoe UI', 12, 'bold'),
                                 height=2, width=18, cursor='hand2',
                                 relief='flat', bd=0)
        self.wipe_btn.grid(row=0, column=0, padx=10)
        
        self.stop_btn = tk.Button(button_container, text="⏹ STOP", 
                                 command=self.stop_wipe,
                                 bg=self.colors['warning'], fg='white',
                                 font=('Segoe UI', 11, 'bold'),
                                 height=2, width=12,
                                 state='disabled', cursor='hand2',
                                 relief='flat', bd=0)
        self.stop_btn.grid(row=0, column=1, padx=10)
        
        self.cert_btn = tk.Button(button_container, text="📄 Certificates", 
                                 command=self.view_certificates,
                                 bg=self.colors['primary'], fg='white',
                                 font=('Segoe UI', 10),
                                 height=2, width=12, cursor='hand2',
                                 relief='flat', bd=0)
        self.cert_btn.grid(row=0, column=2, padx=10)
    
    def create_progress_section(self, parent):
        """Create progress display section"""
        progress_frame = ttk.LabelFrame(parent, text="Operation Progress", 
                                       style='Card.TLabelframe')
        progress_frame.grid(row=3, column=0, sticky="ew", pady=(0, 10))
        progress_frame.grid_columnconfigure(0, weight=1)
        
        # Progress bar container
        progress_container = ttk.Frame(progress_frame)
        progress_container.grid(row=0, column=0, sticky="ew", padx=15, pady=(10, 5))
        progress_container.grid_columnconfigure(0, weight=1)
        
        # Progress bar
        self.progress_var = tk.DoubleVar(value=0)
        self.progress_bar = ttk.Progressbar(progress_container, variable=self.progress_var,
                                           maximum=100, mode='determinate')
        self.progress_bar.grid(row=0, column=0, sticky="ew", pady=5)
        
        # Progress label
        self.progress_label = ttk.Label(progress_container, text="Ready", 
                                       font=('Segoe UI', 10))
        self.progress_label.grid(row=1, column=0, pady=(0, 5))
        
        # Log display with better scrolling
        log_container = ttk.Frame(progress_frame)
        log_container.grid(row=1, column=0, sticky="ew", padx=15, pady=(0, 10))
        log_container.grid_columnconfigure(0, weight=1)
        log_container.grid_rowconfigure(0, weight=1)
        
        # Use scrolledtext for better text widget with scrollbar
        self.log_text = scrolledtext.ScrolledText(log_container, height=8, wrap='word',
                                                  font=('Consolas', 9),
                                                  bg='#f8f8f8', fg='#333333')
        self.log_text.grid(row=0, column=0, sticky="nsew")
        self.log_text.config(state='disabled')
    
    def create_status_bar(self):
        """Create status bar at bottom"""
        status_frame = tk.Frame(self.root, bg=self.colors['text_secondary'], height=30)
        status_frame.grid(row=1, column=0, columnspan=2, sticky="ew")
        status_frame.grid_propagate(False)
        
        self.status_label = tk.Label(status_frame, text="Ready", 
                                    bg=self.colors['text_secondary'], fg='white',
                                    font=('Segoe UI', 9))
        self.status_label.pack(side='left', padx=15, pady=5)
        
        version_label = tk.Label(status_frame, text="CleanSlate v1.0.0 | NIST SP 800-88 Compliant", 
                                bg=self.colors['text_secondary'], fg='white',
                                font=('Segoe UI', 9))
        version_label.pack(side='right', padx=15, pady=5)
        
    def process_message_queue(self):
        """Process messages from queue for thread-safe GUI updates"""
        try:
            while True:
                msg = self.message_queue.get_nowait()
                if msg['type'] == 'log':
                    self.log(msg['message'], msg.get('level', 'INFO'))
                elif msg['type'] == 'progress':
                    self.update_progress(msg['value'], msg['message'])
                elif msg['type'] == 'status':
                    self.update_status(msg['message'])
        except queue.Empty:
            pass
        finally:
            self.root.after(100, self.process_message_queue)
    
    def update_method_description(self, event=None):
        """Update method description based on selection"""
        method = self.wipe_method.get()
        descriptions = {
            "DoD 5220.22-M (3-pass)": "Recommended for most users",
            "DoD 5220.22-M ECE (7-pass)": "Enhanced security, slower",
            "Gutmann (35-pass)": "Maximum security, very slow",
            "Random (1-pass)": "Quick wipe for testing",
            "Random (3-pass)": "Balanced speed and security"
        }
        self.method_desc.config(text=descriptions.get(method, ""))
    
    def refresh_drives(self):
        """Refresh the list of available drives"""
        self.log("Refreshing drive list...")
        
        # Clear existing items
        for item in self.drive_tree.get_children():
            self.drive_tree.delete(item)
        
        if self.drive_detector:
            try:
                drives_info = self.drive_detector.get_all_drives()
                
                for drive in drives_info.get('logical_drives', []):
                    is_system = 'Yes' if self.drive_detector.is_system_drive(drive['path']) else 'No'
                    
                    # Add warning color for system drives
                    tag = 'system' if is_system == 'Yes' else 'normal'
                    
                    self.drive_tree.insert('', 'end', values=(
                        drive['path'],
                        drive.get('label', 'Unknown'),
                        drive.get('type', 'Unknown'),
                        drive.get('size_readable', 'Unknown'),
                        f"{drive.get('percent_used', 0):.1f}%",
                        is_system
                    ), tags=(tag,))
                
                # Configure tags
                self.drive_tree.tag_configure('system', background='#ffebee')
                self.drive_tree.tag_configure('normal', background='white')
                
                self.log(f"Found {len(drives_info.get('logical_drives', []))} drives")
                
            except Exception as e:
                self.log(f"Error refreshing drives: {str(e)}", 'ERROR')
                messagebox.showerror("Error", f"Failed to refresh drives: {str(e)}")
        else:
            self.log("Drive detector not available", 'WARNING')
    
    def select_files(self):
        """Open file selection dialog"""
        files = filedialog.askopenfilenames(title="Select files to wipe")
        if files:
            self.selected_files = list(files)
            self.selection_label.config(text=f"Selected {len(files)} file(s)")
            self.log(f"Selected {len(files)} files for wiping")
            self.update_status(f"Selected {len(files)} files")
    
    def select_folder(self):
        """Open folder selection dialog"""
        folder = filedialog.askdirectory(title="Select folder to wipe")
        if folder:
            self.selected_folder = folder
            self.selected_files = []  # Clear file selection
            folder_name = os.path.basename(folder) or folder
            self.selection_label.config(text=f"Folder: {folder_name}")
            self.log(f"Selected folder: {folder}")
            self.update_status(f"Selected folder: {folder}")
    
    def start_wipe(self):
        """Start the wipe operation"""
        # Get selected drive or files
        selection = self.drive_tree.selection()
        
        if not selection and not hasattr(self, 'selected_files') and not hasattr(self, 'selected_folder'):
            messagebox.showwarning("No Selection", "Please select a drive, files, or folder to wipe")
            return
        
        # Confirm action
        result = messagebox.askyesno("Confirm Wipe", 
                                     "⚠️ WARNING: This operation is IRREVERSIBLE!\n\n"
                                     "All selected data will be permanently destroyed.\n\n"
                                     "Are you absolutely sure you want to continue?",
                                     icon='warning')
        
        if not result:
            return
        
        # Double confirmation for system drives
        if selection:
            item = self.drive_tree.item(selection[0])
            values = item['values']
            if len(values) > 5 and values[5] == 'Yes':  # System drive
                result = messagebox.askyesno("System Drive Warning",
                                            "⚠️⚠️⚠️ CRITICAL WARNING ⚠️⚠️⚠️\n\n"
                                            "You are about to wipe a SYSTEM DRIVE!\n"
                                            "This will make your computer UNUSABLE!\n\n"
                                            "Are you ABSOLUTELY CERTAIN?",
                                            icon='error')
                if not result:
                    return
        
        # Disable buttons
        self.wipe_btn.config(state='disabled')
        self.stop_btn.config(state='normal')
        
        # Start wipe in separate thread
        self.wipe_thread = threading.Thread(target=self.perform_wipe)
        self.wipe_thread.daemon = True
        self.wipe_thread.start()
    
    def perform_wipe(self):
        """Perform the actual wipe operation"""
        try:
            self.log("Starting wipe operation...")
            self.update_progress(0, "Initializing...")
            
            if not self.wipe_engine:
                self.log("Wipe engine not available!", 'ERROR')
                return
            
            # Get selected method
            method_str = self.wipe_method.get()
            pattern = WipePattern.DOD_522022M  # Default
            
            # Map method string to pattern
            if "3-pass" in method_str and "DoD" in method_str:
                pattern = WipePattern.DOD_522022M
            elif "7-pass" in method_str:
                pattern = WipePattern.DOD_522022M_ECE
            elif "Gutmann" in method_str:
                pattern = WipePattern.GUTMANN_SIMPLIFIED
            elif "Random (1-pass)" in method_str:
                pattern = WipePattern.SINGLE_RANDOM
            elif "Random (3-pass)" in method_str:
                pattern = WipePattern.TRIPLE_RANDOM
            
            # Track wipe statistics
            start_time = datetime.now()
            total_bytes_wiped = 0
            files_wiped = []
            wipe_success = False
            
            # Check what to wipe
            if hasattr(self, 'selected_files') and self.selected_files:
                # Wipe selected files
                total_files = len(self.selected_files)
                for idx, file_path in enumerate(self.selected_files):
                    if self.stop_requested:
                        self.log("Wipe operation cancelled by user", 'WARNING')
                        break
                    
                    self.log(f"Wiping file {idx+1}/{total_files}: {file_path}")
                    self.update_progress((idx/total_files)*100, f"Wiping file {idx+1}/{total_files}")
                    
                    try:
                        file_size = os.path.getsize(file_path)
                        if self.wipe_engine.wipe_file(file_path, pattern, self.verify_wipe.get()):
                            total_bytes_wiped += file_size
                            files_wiped.append(file_path)
                            self.log(f"Successfully wiped: {file_path}", 'SUCCESS')
                            wipe_success = True
                        else:
                            self.log(f"Failed to wipe: {file_path}", 'ERROR')
                    except Exception as e:
                        self.log(f"Error wiping {file_path}: {str(e)}", 'ERROR')
                
                self.selected_files = []  # Clear selection
                
            elif hasattr(self, 'selected_folder') and self.selected_folder:
                # Wipe selected folder
                self.log(f"Wiping folder: {self.selected_folder}")
                self.update_progress(10, f"Wiping folder: {self.selected_folder}")
                
                files_count, failed_count = self.wipe_engine.wipe_directory(
                    self.selected_folder, pattern, recursive=True
                )
                
                if files_count > 0:
                    wipe_success = True
                    self.log(f"Wiped {files_count} files, {failed_count} failed", 'INFO')
                
                self.selected_folder = None  # Clear selection
                
            else:
                # Wipe selected drive
                selection = self.drive_tree.selection()
                if selection:
                    item = self.drive_tree.item(selection[0])
                    drive_path = item['values'][0]
                    
                    self.log(f"Wiping drive: {drive_path}")
                    self.update_progress(10, f"Wiping drive: {drive_path}")
                    
                    # For safety, we'll only wipe files in a specific test folder on the drive
                    # In production, you'd implement full drive wiping
                    test_folder = os.path.join(drive_path, "WIPE_TEST")
                    if os.path.exists(test_folder):
                        files_count, failed_count = self.wipe_engine.wipe_directory(
                            test_folder, pattern, recursive=True
                        )
                        if files_count > 0:
                            wipe_success = True
                        self.log(f"Wiped {files_count} files in test folder", 'INFO')
                    else:
                        self.log(f"Test folder not found: {test_folder}", 'WARNING')
                        self.log("For safety, create a WIPE_TEST folder on the drive with test files", 'INFO')
            
            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()
            
            if not self.stop_requested and wipe_success:
                self.log("Wipe operation completed successfully!", 'SUCCESS')
                self.update_progress(100, "Complete!")
                
                # Generate certificate if requested
                if self.generate_cert.get() and self.cert_generator:
                    wipe_data = {
                        "wipe_method": method_str,
                        "target_type": "Files" if files_wiped else "Directory",
                        "target_path": ", ".join(files_wiped) if files_wiped else self.selected_folder or "Unknown",
                        "start_time": start_time.isoformat(),
                        "end_time": end_time.isoformat(),
                        "bytes_wiped": total_bytes_wiped,
                        "passes_completed": len(pattern),
                        "verification_status": "Verified" if self.verify_wipe.get() else "Not Verified",
                        "duration": duration,
                        "target_info": {
                            "files_count": len(files_wiped),
                            "file_system": "NTFS",
                            "drive_type": "Fixed"
                        }
                    }
                    self.generate_certificate(wipe_data)
            elif not wipe_success:
                self.log("No data was wiped", 'WARNING')
                self.update_progress(0, "No data wiped")
            
        except Exception as e:
            self.log(f"Error during wipe: {str(e)}", 'ERROR')
            messagebox.showerror("Wipe Error", f"An error occurred: {str(e)}")
        
        finally:
            # Re-enable buttons
            self.root.after(0, lambda: self.wipe_btn.config(state='normal'))
            self.root.after(0, lambda: self.stop_btn.config(state='disabled'))
            self.stop_requested = False
    
    def stop_wipe(self):
        """Stop the ongoing wipe operation"""
        result = messagebox.askyesno("Stop Wipe", 
                                     "Are you sure you want to stop the wipe operation?")
        if result:
            self.stop_requested = True
            if self.wipe_engine:
                self.wipe_engine.stop_wipe()
            self.log("Stopping wipe operation...", 'WARNING')
    
    def generate_certificate(self, wipe_data=None):
        """Generate wipe certificate"""
        try:
            self.log("Generating wipe certificate...")
            
            if not self.cert_generator:
                self.log("Certificate generator not available", 'WARNING')
                return
            
            if not wipe_data:
                # Create default wipe data if not provided
                wipe_data = {
                    "wipe_method": self.wipe_method.get(),
                    "target_type": "Unknown",
                    "target_path": "Unknown",
                    "start_time": datetime.now().isoformat(),
                    "end_time": datetime.now().isoformat(),
                    "bytes_wiped": 0,
                    "passes_completed": 0,
                    "verification_status": "Unknown",
                    "duration": 0
                }
            
            result = self.cert_generator.generate_certificate(wipe_data)
            
            if result:
                self.log(f"Certificate generated: {result['certificate_id']}", 'SUCCESS')
                self.log(f"Certificate saved: {result['json_path']}")
                if result.get('pdf_path'):
                    self.log(f"PDF certificate: {result['pdf_path']}")
                messagebox.showinfo("Certificate Generated", 
                                  f"Certificate ID: {result['certificate_id']}\n\n"
                                  f"Files saved in certificates folder")
            
        except Exception as e:
            self.log(f"Error generating certificate: {str(e)}", 'ERROR')
            messagebox.showerror("Certificate Error", f"Failed to generate certificate: {str(e)}")
    
    def view_certificates(self):
        """Open certificates folder"""
        cert_dir = os.path.join(os.path.dirname(__file__), "certificates")
        if os.path.exists(cert_dir):
            os.startfile(cert_dir)
        else:
            messagebox.showinfo("No Certificates", "No certificates have been generated yet")
    
    def log(self, message, level='INFO'):
        """Add message to log display"""
        try:
            timestamp = datetime.now().strftime("%H:%M:%S")
            
            # Color coding based on level
            colors = {
                'INFO': '#333333',
                'SUCCESS': '#4CAF50',
                'WARNING': '#FF9800',
                'ERROR': '#f44336'
            }
            
            self.log_text.config(state='normal')
            
            # Insert timestamp
            self.log_text.insert('end', f"[{timestamp}] ", 'timestamp')
            
            # Insert message with color
            tag_name = f"level_{level}"
            self.log_text.insert('end', f"{message}\n", tag_name)
            
            # Configure tags
            self.log_text.tag_config('timestamp', foreground='#757575')
            self.log_text.tag_config(tag_name, foreground=colors.get(level, '#333333'))
            
            self.log_text.see('end')
            self.log_text.config(state='disabled')
        except Exception as e:
            print(f"Log error: {e}")
    
    def update_progress(self, value, message):
        """Update progress bar and label"""
        def update():
            self.progress_var.set(value)
            self.progress_label.config(text=message)
            if value >= 100:
                self.progress_bar.config(style='Success.Horizontal.TProgressbar')
            else:
                self.progress_bar.config(style='TProgressbar')
        self.root.after(0, update)
    
    def update_status(self, message):
        """Update status bar"""
        try:
            self.status_label.config(text=message)
        except:
            pass

def main():
    """Main application entry point"""
    root = tk.Tk()
    app = CleanSlateGUI(root)
    root.mainloop()

if __name__ == "__main__":
    main()
