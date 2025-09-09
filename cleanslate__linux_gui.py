import tkinter as tk
from tkinter import ttk, messagebox, simpledialog
import subprocess
import os
import json

class CleanSlateApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("CleanSlate Secure Wiper for Linux")
        self.geometry("800x600")
        self.minsize(700, 500)
        self.configure(bg="#2E2E2E")

        # --- Style Configuration ---
        style = ttk.Style(self)
        style.theme_use("clam")
        
        # Colors
        bg_color = "#2E2E2E"
        fg_color = "#E0E0E0"
        entry_bg = "#3C3C3C"
        entry_fg = "#FFFFFF"
        button_bg = "#007BFF"
        button_fg = "#FFFFFF"
        button_active = "#0056b3"
        quick_wipe_bg = "#17A2B8"
        quick_wipe_active = "#117A8B"
        danger_bg = "#DC3545"
        danger_active = "#a02531"
        tree_bg = "#333333"
        tree_fg = "#E0E0E0"
        tree_field_bg = "#3C3C3C"
        separator_color = "#4A4A4A"

        style.configure(".", background=bg_color, foreground=fg_color, font=('Helvetica', 10))
        style.configure("TLabel", background=bg_color, foreground=fg_color, padding=5)
        style.configure("TButton", background=button_bg, foreground=button_fg, padding=10, font=('Helvetica', 10, 'bold'), borderwidth=0)
        style.map("TButton", background=[('active', button_active)])
        
        style.configure("QuickWipe.TButton", background=quick_wipe_bg, foreground=button_fg)
        style.map("QuickWipe.TButton", background=[('active', quick_wipe_active)])

        style.configure("Danger.TButton", background=danger_bg, foreground=button_fg)
        style.map("Danger.TButton", background=[('active', danger_active)])

        style.configure("TEntry", fieldbackground=entry_bg, foreground=entry_fg, insertcolor=entry_fg)
        style.configure("Treeview", background=tree_bg, foreground=tree_fg, fieldbackground=tree_field_bg, rowheight=25)
        style.map("Treeview", background=[('selected', button_bg)])
        style.configure("Treeview.Heading", background=bg_color, foreground=fg_color, font=('Helvetica', 11, 'bold'))
        style.configure("TLabelframe", background=bg_color, bordercolor=separator_color)
        style.configure("TLabelframe.Label", foreground=fg_color, background=bg_color)
        style.configure("TSeparator", background=separator_color)

        # --- Initial Check ---
        self.check_root_privileges()

        # --- Main Layout ---
        main_frame = ttk.Frame(self, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)
        main_frame.columnconfigure(0, weight=1)
        main_frame.rowconfigure(0, weight=1)

        # Drive List Display
        drive_frame = ttk.LabelFrame(main_frame, text="Available Drives", padding="10")
        drive_frame.grid(row=0, column=0, sticky="nsew", pady=(0, 10))
        drive_frame.rowconfigure(0, weight=1)
        drive_frame.columnconfigure(0, weight=1)
        
        columns = ("device", "size", "type", "mountpoint")
        self.drive_tree = ttk.Treeview(drive_frame, columns=columns, show="headings")
        self.drive_tree.heading("device", text="Device")
        self.drive_tree.heading("size", text="Size")
        self.drive_tree.heading("type", text="Type")
        self.drive_tree.heading("mountpoint", text="Mountpoint")
        
        self.drive_tree.column("device", width=150, stretch=False)
        self.drive_tree.column("size", width=100, anchor="e", stretch=False)
        self.drive_tree.column("type", width=100, anchor="center", stretch=False)
        self.drive_tree.column("mountpoint", width=250)
        self.drive_tree.grid(row=0, column=0, sticky="nsew")
        self.drive_tree.bind('<<TreeviewSelect>>', self.on_drive_select)

        scrollbar = ttk.Scrollbar(drive_frame, orient=tk.VERTICAL, command=self.drive_tree.yview)
        self.drive_tree.configure(yscroll=scrollbar.set)
        scrollbar.grid(row=0, column=1, sticky="ns")

        # --- Controls Area ---
        controls_frame = ttk.Frame(main_frame)
        controls_frame.grid(row=1, column=0, sticky="ew")
        controls_frame.columnconfigure(0, weight=1)

        target_frame = ttk.Frame(controls_frame)
        target_frame.grid(row=0, column=0, sticky="ew", pady=(0, 10))
        target_frame.columnconfigure(1, weight=1)
        ttk.Label(target_frame, text="Target Device Path:").grid(row=0, column=0, sticky="w", padx=(0, 10))
        self.target_drive_entry = ttk.Entry(target_frame)
        self.target_drive_entry.grid(row=0, column=1, sticky="ew")

        # Refresh button
        self.refresh_button = ttk.Button(target_frame, text="Refresh Drive List", command=self.populate_drives)
        self.refresh_button.grid(row=0, column=2, sticky="e", padx=(10, 0))

        ttk.Separator(controls_frame, orient=tk.HORIZONTAL).grid(row=1, column=0, sticky="ew", pady=10)

        # --- Wipe Actions Frame ---
        actions_frame = ttk.LabelFrame(controls_frame, text="Wipe Actions", padding="10")
        actions_frame.grid(row=2, column=0, sticky="ew")
        actions_frame.columnconfigure((0, 1), weight=1)

        # Quick Wipe Option
        quick_wipe_frame = ttk.Frame(actions_frame)
        quick_wipe_frame.grid(row=0, column=0, sticky="ew", padx=(0, 5))
        quick_wipe_frame.columnconfigure(0, weight=1)
        
        quick_wipe_btn = ttk.Button(quick_wipe_frame, text="Quick Wipe (Fast)", style="QuickWipe.TButton", command=lambda: self.initiate_wipe("quick"))
        quick_wipe_btn.grid(row=0, column=0, sticky="ew")
        ttk.Label(quick_wipe_frame, text="Destroys partition table. Fast but less secure.", font=('Helvetica', 8)).grid(row=1, column=0, sticky="ew", pady=(5,0))

        # Secure Wipe Option
        secure_wipe_frame = ttk.Frame(actions_frame)
        secure_wipe_frame.grid(row=0, column=1, sticky="ew", padx=(5, 0))
        secure_wipe_frame.columnconfigure(0, weight=1)

        secure_wipe_btn = ttk.Button(secure_wipe_frame, text="Secure Wipe (Slow)", style="Danger.TButton", command=lambda: self.initiate_wipe("secure"))
        secure_wipe_btn.grid(row=0, column=0, sticky="ew")
        ttk.Label(secure_wipe_frame, text="Overwrites all data. Very slow but highly secure.", font=('Helvetica', 8)).grid(row=1, column=0, sticky="ew", pady=(5,0))

        # Initial Population
        self.populate_drives()

    def check_root_privileges(self):
        """Check if the script is running with root privileges."""
        if os.geteuid() != 0:
            messagebox.showerror(
                "Root Privileges Required",
                "This application must be run with root privileges to access and wipe block devices.\nPlease run it using 'sudo python3 your_script_name.py'"
            )
            self.destroy()
            exit()

    def populate_drives(self):
        """Fetches and displays drive information using lsblk."""
        for i in self.drive_tree.get_children():
            self.drive_tree.delete(i)
        try:
            result = subprocess.run(
                ["lsblk", "-b", "-o", "NAME,SIZE,TYPE,MOUNTPOINT", "--json"],
                capture_output=True, text=True, check=True
            )
            data = json.loads(result.stdout)
            for device in data.get("blockdevices", []):
                if device.get("type") == "loop":
                    continue
                size_bytes = int(device.get('size', 0))
                if size_bytes > 1024**4: size_str = f"{size_bytes / 1024**4:.2f} TB"
                elif size_bytes > 1024**3: size_str = f"{size_bytes / 1024**3:.2f} GB"
                elif size_bytes > 1024**2: size_str = f"{size_bytes / 1024**2:.2f} MB"
                else: size_str = f"{size_bytes} B"
                self.drive_tree.insert("", tk.END, values=(
                    "/dev/" + device.get("name", "N/A"), size_str,
                    device.get("type", "N/A"),
                    device.get("mountpoint", "Not mounted") or "Not mounted"
                ))
        except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError) as e:
            messagebox.showerror("Error", f"Failed to list drives: {e}")

    def on_drive_select(self, event):
        """Update entry box when a drive is selected in the tree view."""
        selected_item = self.drive_tree.selection()
        if selected_item:
            device_info = self.drive_tree.item(selected_item[0])['values']
            self.target_drive_entry.delete(0, tk.END)
            self.target_drive_entry.insert(0, device_info[0])

    def initiate_wipe(self, wipe_mode):
        """Performs safety checks before calling the wipe function."""
        target_device = self.target_drive_entry.get().strip()
        if not target_device or not target_device.startswith("/dev/"):
            messagebox.showwarning("No Target", "Please select or enter a valid target device (e.g., /dev/sdb).")
            return
        if not os.path.exists(target_device):
            messagebox.showerror("Invalid Device", f"The device '{target_device}' does not exist.")
            return

        try:
            result = subprocess.run(["lsblk", "-b", "--json", target_device], capture_output=True, text=True, check=True)
            device_info = json.loads(result.stdout).get("blockdevices", [{}])[0]
            is_mounted = False
            if device_info.get("mountpoint"): is_mounted = True
            for child in device_info.get("children", []):
                if child.get("mountpoint"):
                    is_mounted = True
                    break
            if is_mounted:
                messagebox.showerror("Safety Check Failed", f"'{target_device}' or one of its partitions is mounted.\nPlease unmount all partitions before wiping.")
                return
        except (subprocess.CalledProcessError, json.JSONDecodeError):
            messagebox.showerror("Error", f"Could not verify status of '{target_device}'. Aborting.")
            return

        mode_text = "QUICK WIPE" if wipe_mode == "quick" else "SECURE WIPE"
        if not messagebox.askokcancel("ARE YOU SURE?", f"You are about to perform a {mode_text} on:\n\n{target_device}\n\nThis is IRREVERSIBLE and ALL DATA will be PERMANENTLY DESTROYED.", icon='warning'):
            return

        challenge = simpledialog.askstring("Final Confirmation", f"This is your last chance. To proceed, type the full device path '{target_device}' below and click OK.", parent=self)
        if challenge != target_device:
            messagebox.showerror("Confirmation Failed", "The device path did not match. Wipe operation cancelled.")
            return

        if wipe_mode == "secure":
            self.execute_shred(target_device)
        elif wipe_mode == "quick":
            self.execute_dd(target_device)

    def execute_shred(self, device):
        """Runs the 'shred' command in a new terminal for a secure wipe."""
        command = f"shred -vfn 1 -z {device}"
        self.run_in_terminal(command, device)

    def execute_dd(self, device):
        """Runs the 'dd' command in a new terminal for a quick wipe."""
        command = f"dd if=/dev/zero of={device} bs=4M count=25 status=progress"
        self.run_in_terminal(command, device)

    def run_in_terminal(self, command, device):
        """Executes a command in a new terminal window to show progress."""
        try:
            # Try gnome-terminal first
            terminal_command = f"gnome-terminal -- bash -c '{command}; read -p \"Wipe process finished. Press Enter to close...\"'"
            subprocess.Popen(terminal_command, shell=True)
            messagebox.showinfo("Process Started", f"Wipe process started for {device} in a new terminal window.")
        except FileNotFoundError:
            try:
                # Fallback to xterm if gnome-terminal is not available
                terminal_command = f"xterm -e 'bash -c \"{command}; read -p \\\"Wipe process finished. Press Enter to close...\\\"\"'"
                subprocess.Popen(terminal_command, shell=True)
                messagebox.showinfo("Process Started", f"Wipe process started for {device} in a new terminal window.")
            except Exception as e:
                messagebox.showerror("Execution Error", f"Could not open a terminal window. Please install 'gnome-terminal' or 'xterm'.\nError: {e}")
        except Exception as e:
            messagebox.showerror("Execution Error", f"Failed to start the wipe process: {e}")
        finally:
            self.populate_drives()


if __name__ == "__main__":
    app = CleanSlateApp()
    app.mainloop()

