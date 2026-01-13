import os
import re
import psutil
import ctypes
from pathlib import Path
from PySide6.QtCore import QObject, Slot
from project_paths import paths # We need this for the cache lookup

class DriveManager(QObject):
    def __init__(self):
        super().__init__()
        # Reference the local thumb cache from your project_paths.py
        self.local_thumb_v2 = Path(paths["local_thumb_v2"])

    @Slot(result=dict)
    def get_grouped_drives(self):
        """RESTORED: Detects all system drives dynamically."""
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
        """RESTORED: Your original folder splitter."""
        if not parent_path: 
            return {"files": [], "folders": []}
            
        files = []
        folders = []
        video_exts = {'.mp4', '.mkv', '.avi', '.mov', '.wmv', '.m4v'}
        
        try:
            normalized = os.path.normpath(parent_path)
            for item in os.listdir(normalized):
                if item.startswith('$') or item.startswith('System Volume Information'):
                    continue
                full_path = os.path.join(normalized, item)
                if os.path.isdir(full_path):
                    folders.append({"name": item, "path": full_path.replace("\\", "/")})
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
            return {"files": [], "folders": []}

    @Slot(str, result=list)
    def get_video_triage_data(self, folder_path):
        """NEW: Added to support the spacing/text standout view."""
        video_data = []
        video_exts = {'.mp4', '.mkv', '.avi', '.mov', '.m4v'}
        try:
            normalized = Path(folder_path)
            for item in normalized.iterdir():
                if item.is_file() and item.suffix.lower() in video_exts:
                    has_year = bool(re.search(r'\(\d{4}\)', item.name))
                    
                    # Cache-First Image Logic
                    thumb_source = ""
                    cache_thumb = self.local_thumb_v2 / f"{item.stem}.jpg"
                    if has_year and cache_thumb.exists():
                        thumb_source = cache_thumb.as_posix()
                    else:
                        local_jpg = item.with_suffix(".jpg")
                        if local_jpg.exists():
                            thumb_source = local_jpg.as_posix()

                    video_data.append({
                        "filename": item.name,
                        "path": item.as_posix(),
                        "folder": item.parent.as_posix(),
                        "thumb": f"file:///{thumb_source}" if thumb_source else "",
                        "size": f"{round(item.stat().st_size / (1024**3), 2)} GB",
                        "isStandard": has_year
                    })
            return sorted(video_data, key=lambda x: x["filename"].lower())
        except:
            return []