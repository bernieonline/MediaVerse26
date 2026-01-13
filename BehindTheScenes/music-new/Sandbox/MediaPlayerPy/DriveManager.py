import os
import psutil
import ctypes
from PySide6.QtCore import QObject, Slot

class DriveManager(QObject):
    def __init__(self):
        super().__init__()

    @Slot(result=dict)
    def get_grouped_drives(self):
        """Detects drives, fetches Volume Names, and groups them."""
        kernel32 = ctypes.windll.kernel32
        grouped = {"local": [], "network": []}
        
        for partition in psutil.disk_partitions(all=True):
            try:
                if partition.fstype == '' or 'cdrom' in partition.opts:
                    continue
                
                path = partition.mountpoint
                letter = partition.device.replace("\\", "")
                
                buf = ctypes.create_unicode_buffer(1024)
                volume_name = ""
                if kernel32.GetVolumeInformationW(path, buf, 1024, None, None, None, None, 0):
                    volume_name = buf.value
                
                d_type = kernel32.GetDriveTypeW(path)
                
                drive_data = {
                    "label": volume_name if volume_name else "Local Disk",
                    "letter": letter,
                    "path": path.replace("\\", "/"),
                    "isCollection": "W:" in path.upper()
                }

                if d_type == 4: # DRIVE_REMOTE
                    grouped["network"].append(drive_data)
                else:
                    grouped["local"].append(drive_data)
            except:
                continue
        return grouped

    @Slot(str, result=dict)
    def get_folder_contents(self, parent_path):
        """The heart of Freestyle: Splits contents into files and folders."""
        if not parent_path: 
            return {"files": [], "folders": []}
            
        files = []
        folders = []
        video_exts = {'.mp4', '.mkv', '.avi', '.mov', '.wmv', '.m4v'}
        
        try:
            normalized = os.path.normpath(parent_path)
            if not os.path.exists(normalized):
                return {"files": [], "folders": []}

            for item in os.listdir(normalized):
                if item.startswith('$') or item.startswith('System Volume Information'):
                    continue
                    
                full_path = os.path.join(normalized, item)
                
                if os.path.isdir(full_path):
                    folders.append({
                        "name": item, 
                        "path": full_path.replace("\\", "/")
                    })
                else:
                    ext = os.path.splitext(item)[1].lower()
                    files.append({
                        "name": item,
                        "path": full_path.replace("\\", "/"),
                        "ext": ext,
                        "isVideo": ext in video_exts
                    })
            
            return {
                "folders": sorted(folders, key=lambda x: x['name'].lower()),
                "files": sorted(files, key=lambda x: x['name'].lower())
            }
        except Exception as e:
            print(f"Error scanning {parent_path}: {e}")
            return {"files": [], "folders": []}