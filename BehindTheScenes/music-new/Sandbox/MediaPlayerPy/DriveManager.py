import os
import psutil
import ctypes
import subprocess
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

    @Slot(str)
    def play_video(self, file_path):
        """
        Launches the video file using the system default player.
        In your case, this will trigger JRiver if it is the default handler.
        """
        try:
            win_path = os.path.normpath(file_path)
            print(f"[DEBUG] Subprocess Launch: {win_path}")
            # os.startfile is the most reliable way to trigger the default Windows player
            os.startfile(win_path)
        except Exception as e:
            print(f"❌ Playback Error: {e}")

    @Slot(str, result=list)
    def get_video_triage_data(self, folder_path):
        """
        Scans a folder and determines if it is a 'Master Library' or 'Non-Master'
        based on a 90% correlation between video files and local images.
        """
        video_data = []
        video_exts = {'.mp4', '.m2ts', '.ts', '.mkv', '.avi', '.mov', '.wmv', '.m4v'}
        
        try:
            p = Path(folder_path)
            if not p.exists():
                print(f"[DEBUG] ❌ Path Not Found: {folder_path}")
                return []

            # --- STEP 1: PRE-SCAN (THE GATEKEEPER) ---
            all_files = list(p.iterdir())
            video_files = [f for f in all_files if f.suffix.lower() in video_exts]
            
            if not video_files:
                return []

            # Count videos with a matching .jpg in the SAME folder
            local_match_count = sum(1 for v in video_files if v.with_suffix('.jpg').exists())
            
            # 90% Correlation Rule
            total_vids = len(video_files)
            correlation = local_match_count / total_vids
            is_master_library = (correlation >= 0.9)
            
            print(f"[DEBUG] Correlation: {correlation:.2%} | Master Mode: {is_master_library}")

            # --- STEP 2: PROCESS VIDEOS ---
            fallback_uri = Path(paths.get("fallback_image", "")).as_uri()

            for item in video_files:
                # Metadata extraction (Size/Ext)
                try:
                    size_bytes = item.stat().st_size
                    if size_bytes > 1024**3:
                        size_str = f"{size_bytes / (1024**3):.1f} GB"
                    else:
                        size_str = f"{size_bytes / (1024**2):.0f} MB"
                except:
                    size_str = "Unknown"

                image_path = ""

                # IMAGE LOOKUP LOGIC
                if is_master_library:
                    # Search Manifest/Cache only for Master folders
                    video_key = str(item).replace('/', '\\')
                    if self.folder_mapper:
                        record = self.folder_mapper.get_record(video_key)
                        if record and "cache" in record:
                            rel_cache_path = record["cache"].get("thumb", "")
                            if rel_cache_path:
                                full_path = paths["local_thumb_v2"] / Path(rel_cache_path).name
                                if full_path.exists():
                                    image_path = full_path.as_uri()
                
                # If Non-Master (OR Master lookup failed), look for local .jpg
                if not image_path:
                    local_jpg = item.with_suffix('.jpg')
                    if local_jpg.exists():
                        image_path = "file:///" + str(local_jpg).replace("\\", "/")
                
                # Final Fallback if still no image
                if not image_path:
                    image_path = fallback_uri

                video_data.append({
                    "title": str(item.stem),
                    "filename": str(item.stem),
                    "thumb": image_path,
                    "videoPath": str(item.as_posix()),
                    "extension": item.suffix.replace('.', '').upper(),
                    "size": size_str,
                    "isMaster": is_master_library
                })

            return sorted(video_data, key=lambda x: x["title"].lower())
            
        except Exception as e:
            print(f"❌ DriveManager Triage Error: {e}")
            traceback.print_exc()
            return []

    @Slot(str, result=dict)
    def get_folder_contents(self, parent_path):
        if not parent_path: return {"files": [], "folders": []}
        files, folders = [], []
        media_exts = {'.mp4', '.mkv', '.avi', '.mov', '.wmv', '.m4v'}
        try:
            normalized = os.path.normpath(parent_path)
            if not os.path.exists(normalized): return {"files": [], "folders": []}
            for item in os.listdir(normalized):
                if item.startswith(('.', '$', 'System Volume')): continue
                full = os.path.join(normalized, item)
                if os.path.isdir(full):
                    folders.append({"name": item, "path": full.replace("\\", "/"), "isFolder": True})
                else:
                    ext = os.path.splitext(item)[1].lower()
                    files.append({"name": item, "path": full.replace("\\", "/"), "ext": ext, "isVideo": ext in media_exts})
            return {"folders": sorted(folders, key=lambda x: x['name'].lower()), "files": sorted(files, key=lambda x: x['name'].lower())}
        except:
            return {"files": [], "folders": []}

    @Slot(result=dict)
    def get_grouped_drives(self):
        kernel32 = ctypes.windll.kernel32
        grouped = {"local": [], "network": []}
        for partition in psutil.disk_partitions(all=True):
            try:
                if partition.fstype == '' or 'cdrom' in partition.opts: continue
                path = partition.mountpoint
                letter = partition.device.replace("\\", "")
                buf = ctypes.create_unicode_buffer(1024)
                volume_name = ""
                if kernel32.GetVolumeInformationW(path, buf, 1024, None, None, None, None, 0):
                    volume_name = buf.value
                d_type = kernel32.GetDriveTypeW(path)
                drive_data = {"label": volume_name if volume_name else f"Drive ({letter})", "letter": letter, "path": path.replace("\\", "/"), "isCollection": "W:" in path.upper()}
                if d_type == 4: grouped["network"].append(drive_data)
                else: grouped["local"].append(drive_data)
            except: continue
        return grouped