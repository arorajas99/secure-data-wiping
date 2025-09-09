import tkinter as tk
from tkinter import ttk, messagebox, simpledialog
import subprocess
import os
import json

class CleanSlateApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("CleanSlate Secure Wiper for Linux")
        self.geometry("750x550")
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
        danger_bg = "#DC3545"
        danger_active = "#a02531"
        tree_bg = "#333333"
        tree_fg = "#E0E0E0"
        tree_field_bg = "#3C3C3C"

        style.configure(".", background=bg_color, foreground=fg_color, font=('Helvetica', 10))
        style.configure("TLabel", background=bg_color, foreground=fg_color, padding=5)
        style.configure("TButton", background=button_bg, foreground=button_fg, padding=10, font=('Helvetica', 10, 'bold'), borderwidth=0)
        style.map("TButton", background=[('active', button_active)])
        
        style.configure("Danger.TButton", background=danger_bg, foreground=button_fg)
        style.map("Danger.TButton", background=[('active', danger_active)])

        style.configure("TEntry", fieldbackground=entry_bg, foreground=entry_fg, insertcolor=entry_fg)
        style.configure("Treeview", background=tree_bg, foreground=tree_fg, fieldbackground=tree_field_bg, rowheight=25)
        style.map("Treeview", background=[('selected', button_bg)])
        style.configure("Treeview.Heading", background=bg_color, foreground=fg_color, font=('Helvetica', 11, 'bold'))

        # --- Initial Check ---
        self.check_root_privileges()

        # --- Main Layout ---
        main_frame = ttk.Frame(self, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)

        # Drive List Display
        drive_frame = ttk.Frame(main_frame)
        drive_frame.pack(fill=tk.BOTH, expand=True, pady=10)

        columns = ("device", "size", "type", "mountpoint")
        self.drive_tree = ttk.Treeview(drive_frame, columns=columns, show="headings")
        self.drive_tree.heading("device", text="Device")
        self.drive_tree.heading("size", text="Size")
        self.drive_tree.heading("type", text="Type")
        self.drive_tree.heading("mountpoint", text="Mountpoint")
        
        self.drive_tree.column("device", width=150)
        self.drive_tree.column("size", width=100, anchor="e")
        self.drive_tree.column("type", width=100, anchor="center")
        self.drive_tree.column("mountpoint", width=250)

        self.drive_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        # Scrollbar
        scrollbar = ttk.Scrollbar(drive_frame, orient=tk.VERTICAL, command=self.drive_tree.yview)
        self.drive_tree.configure(yscroll=scrollbar.set)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # Controls Frame
        controls_frame = ttk.Frame(main_frame)
        controls_frame.pack(fill=tk.X, pady=10)

        ttk.Label(controls_frame, text="Target Device Path (e.g., /dev/sdb):").pack(side=tk.LEFT, padx=(0, 10))
        self.target_drive_entry = ttk.Entry(controls_frame, width=30)
        self.target_drive_entry.pack(side=tk.LEFT, expand=True, fill=tk.X, ipady=5)
        self.drive_tree.bind('<<TreeviewSelect>>', self.on_drive_select)

        # Buttons Frame
        buttons_frame = ttk.Frame(self)
        buttons_frame.pack(fill=tk.X, padx=10, pady=(0, 10))

        self.refresh_button = ttk.Button(buttons_frame, text="Refresh Drive List", command=self.populate_drives)
        self.refresh_button.pack(side=tk.LEFT, expand=True, fill=tk.X, padx=5)

        self.wipe_button = ttk.Button(buttons_frame, text="WIPE SELECTED DRIVE", style="Danger.TButton", command=self.initiate_wipe)
        self.wipe_button.pack(side=tk.LEFT, expand=True, fill=tk.X, padx=5)

        # --- Initial Population ---
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
            # Use JSON output for reliable parsing
            result = subprocess.run(
                ["lsblk", "-b", "-o", "NAME,SIZE,TYPE,MOUNTPOINT", "--json"],
                capture_output=True, text=True, check=True
            )
            data = json.loads(result.stdout)

            for device in data.get("blockdevices", []):
                # Skip loop devices
                if device.get("type") == "loop":
                    continue
                
                # Format size for readability
                size_bytes = int(device.get('size', 0))
                if size_bytes > 1024**4:
                    size_str = f"{size_bytes / 1024**4:.2f} TB"
                elif size_bytes > 1024**3:
                    size_str = f"{size_bytes / 1024**3:.2f} GB"
                elif size_bytes > 1024**2:
                    size_str = f"{size_bytes / 1024**2:.2f} MB"
                else:
                    size_str = f"{size_bytes} B"

                self.drive_tree.insert(
                    "",
                    tk.END,
                    values=(
                        "/dev/" + device.get("name", "N/A"),
                        size_str,
                        device.get("type", "N/A"),
                        device.get("mountpoint", "Not mounted") or "Not mounted"
                    )
                )

        except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError) as e:
            messagebox.showerror("Error", f"Failed to list drives: {e}")

    def on_drive_select(self, event):
        """Update entry box when a drive is selected in the tree view."""
        selected_item = self.drive_tree.selection()
        if selected_item:
            device_info = self.drive_tree.item(selected_item[0])['values']
            self.target_drive_entry.delete(0, tk.END)
            self.target_drive_entry.insert(0, device_info[0])

    def initiate_wipe(self):
        """Performs safety checks before calling the wipe function."""
        target_device = self.target_drive_entry.get().strip()

        if not target_device:
            messagebox.showwarning("No Target", "Please select or enter a target device.")
            return

        if not os.path.exists(target_device):
            messagebox.showerror("Invalid Device", f"The device '{target_device}' does not exist.")
            return

        # --- CRITICAL SAFETY CHECKS ---
        try:
            result = subprocess.run(
                ["lsblk", "-b", "--json", target_device],
                capture_output=True, text=True, check=True
            )
            data = json.loads(result.stdout)
            device_info = data.get("blockdevices", [{}])[0]

            # Check if the target or any of its children are mounted
            is_mounted = False
            if device_info.get("mountpoint"):
                is_mounted = True
            for child in device_info.get("children", []):
                if child.get("mountpoint"):
                    is_mounted = True
                    break
            
            if is_mounted:
                messagebox.showerror(
                    "Safety Check Failed",
                    f"'{target_device}' or one of its partitions is currently mounted.\n"
                    "Please unmount the device and all its partitions before wiping."
                )
                return

        except (subprocess.CalledProcessError, json.JSONDecodeError):
            messagebox.showerror("Error", f"Could not verify status of '{target_device}'. Aborting.")
            return

        # --- USER CONFIRMATION ---
        confirm1 = messagebox.askokcancel(
            "ARE YOU SURE?",
            f"You are about to securely wipe the device:\n\n{target_device}\n\n"
            "This operation is IRREVERSIBLE and ALL DATA on the device will be PERMANENTLY DESTROYED.",
            icon='warning'
        )
        if not confirm1:
            return

        # Final confirmation requiring user to type the device name
        challenge = simpledialog.askstring(
            "Final Confirmation",
            f"This is your last chance. To proceed, type the full device path '{target_device}' below and click OK.",
            parent=self
        )

        if challenge != target_device:
            messagebox.showerror("Confirmation Failed", "The device path did not match. Wipe operation cancelled.")
            return

        # --- EXECUTE WIPE ---
        self.execute_shred(target_device)
        
    def execute_shred(self, device):
        """Runs the shred command in a new terminal window to show progress."""
        try:
            # Using shred: 1 pass of random data, then zero-out, verbose output
            command = f"shred -vfn 1 -z {device}"
            
            # Use gnome-terminal or xterm as a fallback
            terminal_command = f"gnome-terminal -- bash -c '{command}; read -p \"Wipe process finished. Press Enter to close...\"'"
            
            try:
                subprocess.Popen(terminal_command, shell=True)
                messagebox.showinfo("Process Started", f"Wipe process started for {device} in a new terminal window. Please monitor the progress there.")
            except FileNotFoundError:
                # Fallback to xterm if gnome-terminal is not available
                terminal_command = f"xterm -e 'bash -c \"{command}; read -p \\\"Wipe process finished. Press Enter to close...\\\"\"'"
                subprocess.Popen(terminal_command, shell=True)
                messagebox.showinfo("Process Started", f"Wipe process started for {device} in a new terminal window. Please monitor the progress there.")

        except Exception as e:
            messagebox.showerror("Execution Error", f"Failed to start the wipe process: {e}")
        finally:
            self.populate_drives()


if __name__ == "__main__":
    app = CleanSlateApp()
    app.mainloop()
