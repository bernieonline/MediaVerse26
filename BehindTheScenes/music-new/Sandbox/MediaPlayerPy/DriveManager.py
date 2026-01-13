import os
import psutil
import ctypes
from PySide6.QtCore import QObject, Slot

class DriveManager(QObject):
    def __init__(self):
        super().__init__()

    @Slot(result=dict)
    def get_grouped_drives(self):
        """Detects drives, fetches Volume Names, and groups by Local vs Network."""
        kernel32 = ctypes.windll.kernel32
        grouped = {"local": [], "network": []}
        
        # 'all=True' is critical for seeing mapped network drives
        for partition in psutil.disk_partitions(all=True):
            try:
                # Skip empty drives and system reserved
                if partition.fstype == '' or 'cdrom' in partition.opts:
                    continue
                
                path = partition.mountpoint
                letter = partition.device.replace("\\", "")
                
                # Fetch the Volume Label (e.g., "Collection")
                buf = ctypes.create_unicode_buffer(1024)
                volume_name = ""
                if kernel32.GetVolumeInformationW(path, buf, 1024, None, None, None, None, 0):
                    volume_name = buf.value
                
                # Determine if Local (Fixed) or Network (Remote)
                # 3 = DRIVE_FIXED, 4 = DRIVE_REMOTE
                d_type = kernel32.GetDriveTypeW(path)
                
                drive_data = {
                    "label": volume_name if volume_name else "Local Disk",
                    "letter": letter,
                    "path": path.replace("\\", "/"),
                    "isCollection": "W:" in path.upper()
                }

                if d_type == 4:
                    grouped["network"].append(drive_data)
                else:
                    grouped["local"].append(drive_data)
            except:
                continue
                
        return grouped

    @Slot(str, result=list)
    def get_subfolders(self, parent_path):
        """Returns subfolders for the unfolding panels."""
        if not parent_path: return []
        folders = []
        try:
            # Add trailing slash if missing for root drives
            normalized = os.path.normpath(parent_path)
            for item in os.listdir(normalized):
                full_path = os.path.join(normalized, item)
                if os.path.isdir(full_path) and not item.startswith('$'):
                    folders.append({
                        "name": item,
                        "path": full_path.replace("\\", "/")
                    })
            return sorted(folders, key=lambda x: x['name'].lower())
        except:
            return []