"""
Drive Detection Module
Detects and lists available storage drives on Windows
"""

import os
import subprocess
import json
import platform
import psutil
import win32api
import win32file
import ctypes
from ctypes import wintypes

class DriveDetector:
    def __init__(self):
        self.platform = platform.system()
        
    def get_drives_windows(self):
        """Get list of drives on Windows with detailed information"""
        drives = []
        
        # Get all drive letters
        drive_letters = win32api.GetLogicalDriveStrings()
        drive_letters = drive_letters.split('\000')[:-1]
        
        for drive_letter in drive_letters:
            try:
                drive_type = win32file.GetDriveType(drive_letter)
                drive_info = {
                    'path': drive_letter,
                    'type': self._get_drive_type_name(drive_type),
                    'mounted': True
                }
                
                # Get volume information
                try:
                    volume_info = win32api.GetVolumeInformation(drive_letter)
                    drive_info['label'] = volume_info[0] if volume_info[0] else 'No Label'
                    drive_info['filesystem'] = volume_info[4]
                    drive_info['serial'] = volume_info[1]
                except:
                    drive_info['label'] = 'Unknown'
                    drive_info['filesystem'] = 'Unknown'
                    drive_info['serial'] = 'Unknown'
                
                # Get disk usage
                try:
                    usage = psutil.disk_usage(drive_letter)
                    drive_info['total_size'] = usage.total
                    drive_info['used_size'] = usage.used
                    drive_info['free_size'] = usage.free
                    drive_info['percent_used'] = usage.percent
                    drive_info['size_readable'] = self._format_bytes(usage.total)
                except:
                    drive_info['total_size'] = 0
                    drive_info['used_size'] = 0
                    drive_info['free_size'] = 0
                    drive_info['percent_used'] = 0
                    drive_info['size_readable'] = 'Unknown'
                
                # Only include fixed and removable drives (not network or CD-ROM)
                if drive_type in [win32file.DRIVE_FIXED, win32file.DRIVE_REMOVABLE]:
                    drives.append(drive_info)
                    
            except Exception as e:
                print(f"Error processing drive {drive_letter}: {e}")
                
        return drives
    
    def _get_drive_type_name(self, drive_type):
        """Convert Windows drive type constant to readable name"""
        types = {
            0: 'Unknown',
            1: 'No Root Directory',
            2: 'Removable',
            3: 'Fixed',
            4: 'Network',
            5: 'CD-ROM',
            6: 'RAM Disk'
        }
        return types.get(drive_type, 'Unknown')
    
    def _format_bytes(self, bytes):
        """Format bytes to human readable format"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes < 1024.0:
                return f"{bytes:.2f} {unit}"
            bytes /= 1024.0
        return f"{bytes:.2f} PB"
    
    def get_physical_disks(self):
        """Get physical disk information using WMI"""
        physical_disks = []
        
        try:
            # Use WMIC to get physical disk information
            cmd = 'wmic diskdrive get DeviceID,Model,Size,MediaType,SerialNumber /format:csv'
            result = subprocess.run(cmd, capture_output=True, text=True, shell=True)
            
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                # Skip header lines
                for line in lines[2:]:  # Skip empty line and headers
                    if line.strip():
                        parts = line.split(',')
                        if len(parts) >= 6:
                            disk = {
                                'device_id': parts[1],
                                'media_type': parts[2] if parts[2] else 'Unknown',
                                'model': parts[3] if parts[3] else 'Unknown',
                                'serial': parts[4] if parts[4] else 'Unknown',
                                'size': int(parts[5]) if parts[5] and parts[5].isdigit() else 0,
                                'size_readable': self._format_bytes(int(parts[5])) if parts[5] and parts[5].isdigit() else 'Unknown'
                            }
                            physical_disks.append(disk)
        except Exception as e:
            print(f"Error getting physical disks: {e}")
            
        return physical_disks
    
    def get_all_drives(self):
        """Get comprehensive drive information"""
        if self.platform == "Windows":
            logical_drives = self.get_drives_windows()
            physical_disks = self.get_physical_disks()
            
            return {
                'logical_drives': logical_drives,
                'physical_disks': physical_disks,
                'platform': self.platform
            }
        else:
            # For Linux/Unix systems (future implementation)
            return {
                'logical_drives': [],
                'physical_disks': [],
                'platform': self.platform
            }
    
    def is_system_drive(self, drive_path):
        """Check if the drive is a system drive"""
        try:
            system_drive = os.environ.get('SystemDrive', 'C:')
            return drive_path.upper().startswith(system_drive.upper())
        except:
            return False

# Fallback implementation without win32api
class SimpleDriveDetector:
    """Simplified drive detector that works without pywin32"""
    
    def __init__(self):
        self.platform = platform.system()
    
    def get_drives_windows(self):
        """Get list of drives using basic Python methods"""
        drives = []
        
        # Check common drive letters
        for letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ':
            drive_path = f'{letter}:\\'
            if os.path.exists(drive_path):
                try:
                    drive_info = {
                        'path': drive_path,
                        'type': 'Fixed',
                        'mounted': True,
                        'label': f'Drive {letter}',
                        'filesystem': 'NTFS'  # Default assumption
                    }
                    
                    # Get disk usage
                    if hasattr(psutil, 'disk_usage'):
                        usage = psutil.disk_usage(drive_path)
                        drive_info['total_size'] = usage.total
                        drive_info['used_size'] = usage.used
                        drive_info['free_size'] = usage.free
                        drive_info['percent_used'] = usage.percent
                        drive_info['size_readable'] = self._format_bytes(usage.total)
                    else:
                        # Fallback without psutil
                        import shutil
                        usage = shutil.disk_usage(drive_path)
                        drive_info['total_size'] = usage.total
                        drive_info['used_size'] = usage.used
                        drive_info['free_size'] = usage.free
                        drive_info['percent_used'] = (usage.used / usage.total * 100) if usage.total > 0 else 0
                        drive_info['size_readable'] = self._format_bytes(usage.total)
                    
                    drives.append(drive_info)
                except Exception as e:
                    print(f"Error processing drive {drive_path}: {e}")
        
        return drives
    
    def _format_bytes(self, bytes):
        """Format bytes to human readable format"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes < 1024.0:
                return f"{bytes:.2f} {unit}"
            bytes /= 1024.0
        return f"{bytes:.2f} PB"
    
    def get_all_drives(self):
        """Get drive information"""
        return {
            'logical_drives': self.get_drives_windows(),
            'physical_disks': [],  # Not available in simple mode
            'platform': self.platform
        }
    
    def is_system_drive(self, drive_path):
        """Check if the drive is a system drive"""
        system_drive = os.environ.get('SystemDrive', 'C:')
        return drive_path.upper().startswith(system_drive.upper())

# Factory function to get appropriate detector
def get_drive_detector():
    """Returns appropriate drive detector based on available modules"""
    try:
        import win32api
        import win32file
        return DriveDetector()
    except ImportError:
        print("Note: pywin32 not installed. Using simplified drive detection.")
        return SimpleDriveDetector()

if __name__ == "__main__":
    detector = get_drive_detector()
    drives = detector.get_all_drives()
    print(json.dumps(drives, indent=2))
