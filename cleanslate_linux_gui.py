import tkinter as tk
from tkinter import ttk
import subprocess
import os
import json
import signal

class RoundedButton(tk.Canvas):
    """A custom rounded button widget for tkinter."""
    def __init__(self, parent, text, command, width, height, bg, fg, hover_bg, active_bg, border_radius=20, **kwargs):
        super().__init__(parent, width=width, height=height, bg=parent.cget("bg"), highlightthickness=0, **kwargs)
        self.command = command
        self.colors = {'bg': bg, 'fg': fg, 'hover': hover_bg, 'active': active_bg}
        self.border_radius = border_radius
        
        self.tag_id = f"button_{id(self)}"
        self.text_id = f"text_{id(self)}"

        self.rect = self.create_rounded_rect(0, 0, width, height, radius=border_radius, fill=bg, tag=self.tag_id)
        self.text_item = self.create_text(width/2, height/2, text=text, fill=fg, font=('Helvetica', 11, 'bold'), tag=self.tag_id)

        self.bind_events()

    def create_rounded_rect(self, x1, y1, x2, y2, radius, **kwargs):
        points = [
            x1+radius, y1, x1+radius, y1, x2-radius, y1, x2-radius, y1, x2, y1, x2, y1+radius,
            x2, y1+radius, x2, y2-radius, x2, y2-radius, x2, y2, x2-radius, y2, x2-radius, y2,
            x1+radius, y2, x1+radius, y2, x1, y2, x1, y2-radius, x1, y2-radius, x1, y1+radius,
            x1, y1+radius, x1, y1
        ]
        return self.create_polygon(points, **kwargs, smooth=True)

    def bind_events(self):
        self.tag_bind(self.tag_id, "<Enter>", self.on_enter)
        self.tag_bind(self.tag_id, "<Leave>", self.on_leave)
        self.tag_bind(self.tag_id, "<ButtonPress-1>", self.on_press)
        self.tag_bind(self.tag_id, "<ButtonRelease-1>", self.on_release)

    def on_enter(self, event):
        self.itemconfig(self.rect, fill=self.colors['hover'])

    def on_leave(self, event):
        self.itemconfig(self.rect, fill=self.colors['bg'])

    def on_press(self, event):
        self.itemconfig(self.rect, fill=self.colors['active'])

    def on_release(self, event):
        self.on_enter(event)
        if self.command:
            self.command()
            
    def configure_state(self, state):
        if state == 'disabled':
            self.itemconfig(self.rect, fill="#555", outline="#777")
            self.itemconfig(self.text_item, fill="#999")
            self.tag_unbind(self.tag_id, "<Enter>")
            self.tag_unbind(self.tag_id, "<Leave>")
            self.tag_unbind(self.tag_id, "<ButtonPress-1>")
            self.tag_unbind(self.tag_id, "<ButtonRelease-1>")
        elif state == 'normal':
            self.itemconfig(self.rect, fill=self.colors['bg'], outline=self.colors['bg'])
            self.itemconfig(self.text_item, fill=self.colors['fg'])
            self.bind_events()


class CustomDialog(tk.Toplevel):
    """Base class for custom styled dialogs."""
    def __init__(self, parent, title, message, dialog_type='info'):
        super().__init__(parent)
        self.title(title)
        self.transient(parent)
        self.grab_set()
        
        self.result = None
        
        # Style
        bg_color = "#3a3a3a"
        fg_color = "#E0E0E0"
        self.configure(bg=bg_color)
        
        # Center the dialog
        parent.update_idletasks()
        x = parent.winfo_x() + (parent.winfo_width() / 2) - 200
        y = parent.winfo_y() + (parent.winfo_height() / 2) - 100
        self.geometry(f"400x200+{int(x)}+{int(y)}")
        self.resizable(False, False)

        self.main_frame = tk.Frame(self, bg=bg_color, padx=20, pady=20)
        self.main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Icon (simple text-based for now)
        icon_colors = {'warning': '#FFA500', 'error': '#DC3545', 'info': '#17A2B8'}
        icon_char = {'warning': '!', 'error': 'X', 'info': 'i'}
        
        icon_label = tk.Label(self.main_frame, text=icon_char.get(dialog_type, 'i'), font=('Helvetica', 36, 'bold'), bg=bg_color, fg=icon_colors.get(dialog_type, '#FFF'))
        icon_label.pack(pady=(0, 10))

        message_label = tk.Label(self.main_frame, text=message, font=('Helvetica', 10), wraplength=360, justify='center', bg=bg_color, fg=fg_color)
        message_label.pack(fill=tk.X, expand=True, pady=10)

        self.button_frame = tk.Frame(self.main_frame, bg=bg_color)
        self.button_frame.pack(side='bottom', pady=(10, 0))

    def wait(self):
        self.wait_window()
        return self.result

class AskOkCancelDialog(CustomDialog):
    def __init__(self, parent, title, message, dialog_type='warning'):
        super().__init__(parent, title, message, dialog_type)
        
        ok_btn = RoundedButton(self.button_frame, "OK", self.on_ok, 100, 35, bg="#DC3545", fg="#FFF", hover_bg="#c82333", active_bg="#a02531")
        ok_btn.pack(side='left', padx=10)
        
        cancel_btn = RoundedButton(self.button_frame, "Cancel", self.on_cancel, 100, 35, bg="#6c757d", fg="#FFF", hover_bg="#5a6268", active_bg="#494f54")
        cancel_btn.pack(side='right', padx=10)

    def on_ok(self):
        self.result = True
        self.destroy()

    def on_cancel(self):
        self.result = False
        self.destroy()

class InfoDialog(CustomDialog):
    def __init__(self, parent, title, message, dialog_type='info'):
        super().__init__(parent, title, message, dialog_type)
        ok_btn = RoundedButton(self.button_frame, "OK", self.on_ok, 100, 35, bg="#007BFF", fg="#FFF", hover_bg="#0069d9", active_bg="#0056b3")
        ok_btn.pack(pady=10)

    def on_ok(self):
        self.destroy()

class AskStringDialog(CustomDialog):
    def __init__(self, parent, title, message):
        super().__init__(parent, title, message, dialog_type='warning')
        
        # Adjust geometry to make space for the entry widget
        parent.update_idletasks()
        dialog_width = 400
        dialog_height = 230
        x = parent.winfo_x() + (parent.winfo_width() / 2) - (dialog_width / 2)
        y = parent.winfo_y() + (parent.winfo_height() / 2) - (dialog_height / 2)
        self.geometry(f"{dialog_width}x{dialog_height}+{int(x)}+{int(y)}")

        self.entry = ttk.Entry(self.main_frame, justify='center', font=('Helvetica', 12))
        # Pack the entry into the main frame, *before* the button frame which is at the bottom
        self.entry.pack(pady=10, before=self.button_frame, fill='x')
        self.entry.focus_set()
        
        ok_btn = RoundedButton(self.button_frame, "Confirm", self.on_ok, 100, 35, bg="#DC3545", fg="#FFF", hover_bg="#c82333", active_bg="#a02531")
        ok_btn.pack(pady=10)
        self.bind('<Return>', lambda e: self.on_ok())

    def on_ok(self):
        self.result = self.entry.get()
        self.destroy()


class CleanSlateApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("CleanSlate Secure Wiper for Linux")
        self.geometry("800x650")
        self.minsize(700, 600)
        self.configure(bg="#212529")
        self.wipe_process = None

        # --- Style Configuration ---
        style = ttk.Style(self)
        style.theme_use("clam")
        style.configure("Treeview", background="#2c3034", foreground="#E0E0E0", fieldbackground="#2c3034", rowheight=25, borderwidth=0)
        style.map("Treeview", background=[('selected', '#007BFF')])
        style.configure("Treeview.Heading", background="#343a40", foreground="#E0E0E0", font=('Helvetica', 11, 'bold'), borderwidth=0)
        style.configure("Vertical.TScrollbar", background='#343a40', troughcolor='#2c3034', bordercolor='#2c3034', arrowcolor='white')
        style.configure("TEntry", fieldbackground="#343a40", foreground="white", insertcolor="white", bordercolor="#495057", padding=5)

        # --- Initial Check ---
        self.check_root_privileges()

        # --- Main Layout ---
        header = tk.Frame(self, bg="#343a40", height=50)
        header.pack(fill='x', side='top')
        tk.Label(header, text="CleanSlate Secure Wiper", font=('Helvetica', 16, 'bold'), bg="#343a40", fg="white").pack(pady=10)

        main_frame = tk.Frame(self, bg="#212529", padx=20, pady=20)
        main_frame.pack(fill=tk.BOTH, expand=True)
        main_frame.columnconfigure(0, weight=1)
        main_frame.rowconfigure(0, weight=1)
        
        # Drive List
        drive_frame = tk.Frame(main_frame, bg="#212529")
        drive_frame.grid(row=0, column=0, sticky="nsew", pady=(0, 20))
        drive_frame.rowconfigure(0, weight=1)
        drive_frame.columnconfigure(0, weight=1)
        
        columns = ("device", "size", "type", "mountpoint")
        self.drive_tree = ttk.Treeview(drive_frame, columns=columns, show="headings", style="Treeview")
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
        
        scrollbar = ttk.Scrollbar(drive_frame, orient=tk.VERTICAL, command=self.drive_tree.yview, style="Vertical.TScrollbar")
        self.drive_tree.configure(yscroll=scrollbar.set)
        scrollbar.grid(row=0, column=1, sticky="ns")

        # Controls Area
        controls_frame = tk.Frame(main_frame, bg="#212529")
        controls_frame.grid(row=1, column=0, sticky="ew")
        controls_frame.columnconfigure(0, weight=1)
        
        target_frame = tk.Frame(controls_frame, bg="#212529")
        target_frame.grid(row=0, column=0, sticky="ew", pady=(0, 15))
        target_frame.columnconfigure(1, weight=1)
        tk.Label(target_frame, text="Target Device Path:", bg="#212529", fg="white").grid(row=0, column=0, sticky="w", padx=(0, 10))
        self.target_drive_entry = ttk.Entry(target_frame)
        self.target_drive_entry.grid(row=0, column=1, sticky="ew")
        
        self.refresh_button = RoundedButton(target_frame, "Refresh", self.populate_drives, 100, 35, bg="#007BFF", fg="#FFF", hover_bg="#0069d9", active_bg="#0056b3")
        self.refresh_button.grid(row=0, column=2, sticky="e", padx=(10, 0))

        # Actions Area
        actions_frame = tk.Frame(controls_frame, bg="#2c3034", pady=15, padx=15)
        actions_frame.grid(row=1, column=0, sticky="ew", pady=10)
        actions_frame.columnconfigure((0, 1), weight=1)
        
        self.quick_wipe_btn = RoundedButton(actions_frame, "Quick Wipe", lambda: self.initiate_wipe("quick"), 150, 40, bg="#17A2B8", fg="#FFF", hover_bg="#138496", active_bg="#117a8b")
        self.quick_wipe_btn.grid(row=0, column=0, padx=(0,10))
        tk.Label(actions_frame, text="Fast. Overwrites partition table.", bg="#2c3034", fg="#ccc", font=('Helvetica', 8)).grid(row=1, column=0, pady=(5,0), padx=(0,10))
        
        self.secure_wipe_btn = RoundedButton(actions_frame, "Secure Wipe", lambda: self.initiate_wipe("secure"), 150, 40, bg="#DC3545", fg="#FFF", hover_bg="#c82333", active_bg="#a02531")
        self.secure_wipe_btn.grid(row=0, column=1, padx=(10,0))
        tk.Label(actions_frame, text="Slow. Overwrites all data.", bg="#2c3034", fg="#ccc", font=('Helvetica', 8)).grid(row=1, column=1, pady=(5,0), padx=(10,0))
        
        self.cancel_button = RoundedButton(controls_frame, "Cancel Current Wipe", self.cancel_wipe, 200, 40, bg="#ffc107", fg="#212529", hover_bg="#e0a800", active_bg="#d39e00")
        self.cancel_button.grid(row=2, column=0, pady=10)
        self.cancel_button.configure_state('disabled')

        self.populate_drives()

    def toggle_buttons(self, is_wiping):
        state = 'disabled' if is_wiping else 'normal'
        self.quick_wipe_btn.configure_state(state)
        self.secure_wipe_btn.configure_state(state)
        self.refresh_button.configure_state(state)
        self.cancel_button.configure_state('normal' if is_wiping else 'disabled')

    def check_root_privileges(self):
        if os.geteuid() != 0:
            InfoDialog(self, "Root Privileges Required", "This application requires root privileges.\nPlease run with 'sudo'.", 'error')
            self.destroy()

    def populate_drives(self):
        for i in self.drive_tree.get_children(): self.drive_tree.delete(i)
        try:
            result = subprocess.run(["lsblk", "-b", "-o", "NAME,SIZE,TYPE,MOUNTPOINT", "--json"], capture_output=True, text=True, check=True)
            for device in json.loads(result.stdout).get("blockdevices", []):
                if device.get("type") == "loop": continue
                size_bytes = int(device.get('size', 0))
                if size_bytes > 1024**4: size_str = f"{size_bytes / 1024**4:.2f} TB"
                elif size_bytes > 1024**3: size_str = f"{size_bytes / 1024**3:.2f} GB"
                elif size_bytes > 1024**2: size_str = f"{size_bytes / 1024**2:.2f} MB"
                else: size_str = f"{size_bytes} B"
                self.drive_tree.insert("", tk.END, values=("/dev/" + device.get("name", "N/A"), size_str, device.get("type", "N/A"), device.get("mountpoint", "Not mounted") or "Not mounted"))
        except Exception as e:
            InfoDialog(self, "Error", f"Failed to list drives: {e}", 'error')

    def on_drive_select(self, event):
        selected_item = self.drive_tree.selection()
        if selected_item:
            device_info = self.drive_tree.item(selected_item[0])['values']
            self.target_drive_entry.delete(0, tk.END)
            self.target_drive_entry.insert(0, device_info[0])

    def initiate_wipe(self, wipe_mode):
        target_device = self.target_drive_entry.get().strip()
        if not target_device or not target_device.startswith("/dev/"):
            InfoDialog(self, "No Target", "Please select or enter a valid target device (e.g., /dev/sdb).", 'warning')
            return
        try:
            result = subprocess.run(["lsblk", "-b", "--json", target_device], capture_output=True, text=True, check=True)
            device_info = json.loads(result.stdout).get("blockdevices", [{}])[0]
            if any(child.get("mountpoint") for child in device_info.get("children", [])) or device_info.get("mountpoint"):
                InfoDialog(self, "Safety Check Failed", f"'{target_device}' is mounted. Please unmount before wiping.", 'error')
                return
        except Exception:
            InfoDialog(self, "Error", f"Could not verify status of '{target_device}'. Aborting.", 'error')
            return

        mode_text = "QUICK WIPE" if wipe_mode == "quick" else "SECURE WIPE"
        if not AskOkCancelDialog(self, "ARE YOU SURE?", f"You are about to perform a {mode_text} on:\n{target_device}\n\nThis will PERMANENTLY DESTROY ALL DATA.").wait():
            return
        
        challenge = AskStringDialog(self, "Final Confirmation", f"To proceed, type the full device path\n'{target_device}'\nbelow.").wait()
        if challenge != target_device:
            InfoDialog(self, "Confirmation Failed", "The device path did not match. Wipe operation cancelled.", 'error')
            return

        command = f"shred -vfn 1 -z {target_device}" if wipe_mode == "secure" else f"dd if=/dev/zero of={target_device} bs=4M count=25 status=progress"
        self.run_in_terminal(command, target_device)

    def run_in_terminal(self, command, device):
        try:
            term_cmd = f"gnome-terminal -- bash -c '{command}; read -p \"Wipe process finished. Press Enter to close...\"'"
            self.wipe_process = subprocess.Popen(term_cmd, shell=True, preexec_fn=os.setsid)
            self.toggle_buttons(is_wiping=True)
            self.check_wipe_status()
        except FileNotFoundError:
            InfoDialog(self, "Terminal Error", "Could not open 'gnome-terminal'. Please ensure it is installed.", 'error')
            
    def check_wipe_status(self):
        if self.wipe_process and self.wipe_process.poll() is not None:
            if self.wipe_process.returncode == 0:
                InfoDialog(self, "Success!", "Wipe completed successfully!")
            else:
                # If cancelled, the return code will be non-zero.
                InfoDialog(self, "Process Ended", "The wipe process has been terminated.", 'warning')

            self.wipe_process = None
            self.toggle_buttons(is_wiping=False)
            self.populate_drives()
        else:
            self.after(1000, self.check_wipe_status)

    def cancel_wipe(self):
        if self.wipe_process and self.wipe_process.poll() is None:
            try:
                os.killpg(os.getpgid(self.wipe_process.pid), signal.SIGTERM)
            except Exception:
                pass # Process might have just ended
        else:
            InfoDialog(self, "No Process", "No wipe process is currently running.", 'info')

if __name__ == "__main__":
    app = CleanSlateApp()
    app.mainloop()


