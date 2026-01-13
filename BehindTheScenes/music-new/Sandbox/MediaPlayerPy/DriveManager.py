import os
import re
import psutil
import ctypes
import mimetypes
from pathlib import Path
from PySide6.QtCore import QObject, Slot

class DriveManager(QObject):
    def __init__(self):
        super().__init__()
        # Internal path for the Library Standard matching rule
        try:
            from project_paths import paths
            self.local_thumb_v2 = Path(paths["local_thumb_v2"])
        except ImportError:
            # Absolute fallback for your specific environment
            self.local_thumb_v2 = Path("D:/MediaVerse1.0/BehindTheScenes/BehindTheScenes/music-new/cacheV2/images/thumb")

    @Slot(result=dict)
    def get_grouped_drives(self):
        """Detects all system drives dynamically."""
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
            except Exception:
                continue
        return grouped

    @Slot(str, result=dict)
    def get_folder_contents(self, parent_path):
        """Standard file/folder splitter for the Panel view."""
        if not parent_path: 
            return {"files": [], "folders": []}
            
        files = []
        folders = []
        video_exts = {'.mp4', '.mkv', '.avi', '.mov', '.wmv', '.m4v', '.jpg', '.jpeg', '.png'}
        
        try:
            normalized = os.path.normpath(parent_path)
            if not os.path.exists(normalized):
                return {"files": [], "folders": []}

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
        """Advanced Deduplication: Groups video/image pairs and cleans titles."""
        video_data = []
        video_exts = {'.mp4', '.mkv', '.avi', '.mov', '.wmv', '.m4v'}
        image_exts = {'.jpg', '.jpeg', '.png', '.webp', '.bmp'}
        
        try:
            normalized = Path(folder_path)
            if not normalized.exists():
                return []

            all_items = list(normalized.iterdir())
            
            # Map to keep track of what we've processed
            # Key: lowercase stem (e.g., "gladiator")
            # Value: boolean (True if we've already added a video for this stem)
            processed_stems = {}

            # --- PASS 1: COLLECT VIDEOS ---
            for item in all_items:
                if not item.is_file() or item.name.startswith(('.', '$')):
                    continue

                ext = item.suffix.lower()
                stem_key = item.stem.lower()

                if ext in video_exts:
                    processed_stems[stem_key] = True
                    
                    has_year = bool(re.search(r'\(\d{4}\)', item.name))
                    thumb_source = ""
                    
                    # Look for thumb in Cache V2
                    cache_thumb = self.local_thumb_v2 / f"{item.stem}.jpg"
                    if cache_thumb.exists():
                        thumb_source = cache_thumb.as_posix()
                    else:
                        # Look for ANY image with the same stem (jpg, jpeg, or png)
                        for img_ext in image_exts:
                            local_img = item.with_suffix(img_ext)
                            if local_img.exists():
                                thumb_source = local_img.as_posix()
                                break

                    video_data.append({
                        "filename": item.stem, # <--- REMOVED EXTENSION FOR UI
                        "extension": ext.replace('.', '').upper(),
                        "path": item.as_posix(),
                        "folder": item.parent.name,
                        "thumb": f"file:///{thumb_source}" if thumb_source else "",
                        "size": self._get_size_str(item),
                        "isStandard": has_year
                    })

            # --- PASS 2: COLLECT STANDALONE IMAGES ---
            for item in all_items:
                if not item.is_file() or item.name.startswith(('.', '$')):
                    continue
                    
                ext = item.suffix.lower()
                stem_key = item.stem.lower()

                if ext in image_exts:
                    # If we already have a video with this name, SKIP THIS IMAGE
                    if stem_key in processed_stems:
                        continue
                    
                    # If this is the first time seeing this stem, add it and mark it
                    processed_stems[stem_key] = True
                    
                    video_data.append({
                        "filename": item.stem, # <--- REMOVED EXTENSION FOR UI
                        "extension": ext.replace('.', '').upper(),
                        "path": item.as_posix(),
                        "folder": item.parent.name,
                        "thumb": item.as_uri(),
                        "size": self._get_size_str(item),
                        "isStandard": False
                    })

            return sorted(video_data, key=lambda x: x["filename"].lower())

        except Exception as e:
            print(f"DEBUG ERROR: {str(e)}")
            return []

    

    def _get_size_str(self, path_obj):
        """Helper to format size: GB for movies, KB/MB for images."""
        size_bytes = path_obj.stat().st_size
        if size_bytes > 1024**3:
            return f"{round(size_bytes / (1024**3), 2)} GB"
        elif size_bytes > 1024**2:
            return f"{round(size_bytes / (1024**2), 1)} MB"
        else:
            return f"{round(size_bytes / 1024, 0)} KB"