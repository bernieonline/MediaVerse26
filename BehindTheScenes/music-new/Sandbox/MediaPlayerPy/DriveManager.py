import os
import psutil
import ctypes
import traceback
from pathlib import Path
from PySide6.QtCore import QObject, Slot

from project_paths import paths  # centralized path map

class DriveManager(QObject):
    def __init__(self):
        super().__init__()
        self.network_root = "W:/"      
        self.folder_mapper = None

    def set_mapper(self, mapper_instance):
        self.folder_mapper = mapper_instance

    @Slot(str, result=list)
    def get_video_triage_data(self, folder_path):
        """
        Scans a folder for videos and prepares data for the FreestyleView carousel.
        Includes extensive debug logging to verify data flow to QML.
        """
        video_data = []
        # Case-insensitive check for common video types
        video_exts = {'.mp4', '.m2ts', '.ts', '.mkv', '.avi', '.mov', '.wmv', '.m4v'}
        
        print(f"\n{'='*60}")
        print(f"[DEBUG] TRIAGE START: {folder_path}")
        
        try:
            p = Path(folder_path)
            if not p.exists():
                print(f"[DEBUG] ❌ ERROR: Path does not exist on disk: {folder_path}")
                return []

            # 1. Iterate through files
            items = list(p.iterdir())
            print(f"[DEBUG] Found {len(items)} total items in directory.")

            for item in items:
                if not item.is_file():
                    continue

                raw_ext = item.suffix.lower()

                if raw_ext in video_exts:
                    display_ext = raw_ext.replace('.', '').upper()
                    
                    # --- SIZE CALCULATION ---
                    size_str = "0 MB"
                    try:
                        size_bytes = item.stat().st_size
                        if size_bytes > 1024**3:
                            size_str = f"{size_bytes / (1024**3):.1f} GB"
                        else:
                            size_str = f"{size_bytes / (1024**2):.0f} MB"
                    except Exception as e:
                        print(f"[DEBUG] ! Size calculation failed for {item.name}: {e}")

                    # Normalizing for manifest lookup
                    video_key = str(item).replace('/', '\\')
                    image_path = ""

                    # --- THUMBNAIL LOGIC ---
                    # A. Manifest lookup
                    if self.folder_mapper:
                        record = self.folder_mapper.get_record(video_key)
                        if record and "cache" in record:
                            rel_cache_path = record["cache"].get("thumb", "")
                            if rel_cache_path:
                                thumb_filename = Path(rel_cache_path).name
                                full_path = paths["local_thumb_v2"] / thumb_filename
                                if full_path.exists():
                                    image_path = full_path.as_uri()

                    # B. Local JPG lookup
                    if not image_path:
                        local_jpg = item.with_suffix('.jpg')
                        if local_jpg.exists():
                            image_path = "file:///" + str(local_jpg).replace("\\", "/")

                    # C. Fallback
                    if not image_path:
                        fallback = paths.get("fallback_image")
                        if fallback and Path(fallback).exists():
                            image_path = Path(fallback).as_uri()

                    # --- ASSEMBLE DATA ENTRY ---
                    entry = {
                        "title": str(item.stem),
                        "filename": str(item.stem),
                        "thumb": str(image_path),
                        "videoPath": str(item.as_posix()),
                        "extension": display_ext,
                        "size": size_str,
                        "folder": p.name
                    }
                    
                    # LOG THE FIRST ITEM AS A SAMPLE
                    if len(video_data) == 0:
                        print(f"[DEBUG] ✅ FIRST VIDEO DETECTED: {item.name}")
                        print(f"[DEBUG]    -> filename: {entry['filename']}")
                        print(f"[DEBUG]    -> size:     {entry['size']}")
                        print(f"[DEBUG]    -> thumb:    {entry['thumb'][:60]}...")
                        print(f"[DEBUG]    -> folder:   {entry['folder']}")

                    video_data.append(entry)

            print(f"[DEBUG] COMPLETED: Found {len(video_data)} videos total.")
            print(f"{'='*60}\n")
            
            # Sort alphabetically by title
            return sorted(video_data, key=lambda x: x["title"].lower())
            
        except Exception as e:
            print(f"[DEBUG] ❌ CRITICAL TRIAGE ERROR: {e}")
            traceback.print_exc()
            return []

    @Slot(str, result=dict)
    def get_folder_contents(self, parent_path):
        if not parent_path:
            return {"files": [], "folders": []}
        files, folders = [], []
        media_exts = {'.mp4', '.mkv', '.avi', '.mov', '.wmv', '.m4v'}
        try:
            normalized = os.path.normpath(parent_path)
            if not os.path.exists(normalized):
                return {"files": [], "folders": []}
            for item in os.listdir(normalized):
                if item.startswith(('.', '$', 'System Volume')):
                    continue
                full = os.path.join(normalized, item)
                if os.path.isdir(full):
                    folders.append({
                        "name": item,
                        "path": full.replace("\\", "/"),
                        "isFolder": True
                    })
                else:
                    ext = os.path.splitext(item)[1].lower()
                    files.append({
                        "name": item,
                        "path": full.replace("\\", "/"),
                        "ext": ext,
                        "isVideo": ext in media_exts
                    })
            return {
                "folders": sorted(folders, key=lambda x: x['name'].lower()),
                "files": sorted(files, key=lambda x: x['name'].lower())
            }
        except:
            return {"files": [], "folders": []}

    @Slot(result=dict)
    def get_grouped_drives(self):
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
                    "label": volume_name if volume_name else f"Drive ({letter})",
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