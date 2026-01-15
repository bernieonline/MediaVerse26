import os
import psutil
import ctypes
import subprocess
import traceback
import requests
from pathlib import Path
from PySide6.QtCore import QObject, Slot

from project_paths import paths  # centralized path map


class DriveManager(QObject):
    def __init__(self):
        super().__init__()
        self.network_root = "W:/"
        self.folder_mapper = None
        self.jriver_exe = r"C:\Program Files\J River\Media Center 32\MC32.exe"

    def set_mapper(self, mapper_instance):
        self.folder_mapper = mapper_instance

    # ---------------------------------------------------------
    # HYBRID PLAYBACK (MASTER LIBRARY = HTTP, OTHER = SUBPROCESS)
    # ---------------------------------------------------------
    @Slot(str, bool)
    def play_video(self, file_path, is_master):
        """
        Hybrid playback:
        - Master library folders → HTTP playback via MCWS
        - Non-master folders → Direct subprocess launch
        """
        try:
            # Clean QML URI → Windows path
            clean_win_path = file_path.replace("file:///", "")
            clean_win_path = clean_win_path.replace("/", "\\")
            clean_win_path = os.path.normpath(clean_win_path)

            print(f"[DEBUG] Playback Request: {clean_win_path}")
            print(f"[DEBUG] isMaster flag: {is_master}")

            # -------------------------------------------------
            # NON-MASTER FOLDER → SKIP MANIFEST LOOKUP ENTIRELY
            # -------------------------------------------------
            if not is_master:
                print("[DEBUG] Non-master folder → Subprocess playback")
                self.play_via_subprocess(clean_win_path)
                return

            # -------------------------------------------------
            # MASTER FOLDER → LOOK UP MANIFEST ID
            # -------------------------------------------------
            video_id = None
            if self.folder_mapper:
                try:
                    record = self.folder_mapper.get_record(clean_win_path)
                    if record:
                        video_id = record.get("id")
                except Exception as e:
                    print(f"[DEBUG] Mapping lookup error: {e}")

            # -------------------------------------------------
            # ROUTING DECISION
            # -------------------------------------------------
            if video_id:
                print(f"[DEBUG] Master folder → HTTP playback (ID={video_id})")
                self.play_via_http(video_id)
            else:
                print("[DEBUG] Master folder but NO ID → Subprocess fallback")
                self.play_via_subprocess(clean_win_path)

        except Exception as e:
            print(f"❌ Playback Controller Error: {e}")
            traceback.print_exc()

    # ---------------------------------------------------------
    # HTTP PLAYBACK (MASTER LIBRARY)
    # ---------------------------------------------------------
    def play_via_http(self, video_id):
        try:
            url = f"http://localhost:52199/MCWS/v1/Playback/PlayById?Id={video_id}"
            requests.get(url, timeout=1.5)
            print("[DEBUG] HTTP Command Sent Successfully")
        except Exception as e:
            print(f"❌ HTTP Playback Failed: {e}")

    # ---------------------------------------------------------
    # SUBPROCESS PLAYBACK (NON-MASTER) — FULL DEBUG VERSION
    # ---------------------------------------------------------
    @Slot(str)
    def play_via_subprocess(self, win_path):
        """
        Launch JRiver using the same path format proven to work in your standalone tests.
        This version prints EVERYTHING clearly for debugging.
        """
        try:
            print("\n" + "="*80)
            print("🔍 SUBPROCESS DEBUG REPORT")
            print("="*80)

            print(f"RAW INPUT PATH FROM QML:\n    {win_path}")

            # 1. Strip QML prefix
            path = win_path.replace("file:///", "")
            print(f"\nAFTER REMOVING 'file:///':\n    {path}")

            # 2. Convert forward slashes to backslashes
            path = path.replace("/", "\\")
            print(f"\nAFTER SLASH NORMALIZATION:\n    {path}")

            # 3. Normalize Windows path
            path = os.path.normpath(path)
            print(f"\nAFTER os.path.normpath():\n    {path}")

            print("\nCHECKING FILE EXISTS:")
            print(f"    os.path.exists(path) → {os.path.exists(path)}")

            print("\nCHECKING JRiver EXE EXISTS:")
            print(f"    {self.jriver_exe} → {os.path.exists(self.jriver_exe)}")

            if not os.path.exists(path):
                print(f"\n❌ ERROR: File does NOT exist on disk:\n    {path}")
                print("="*80 + "\n")
                return

            if not os.path.exists(self.jriver_exe):
                print(f"\n❌ ERROR: JRiver EXE not found:\n    {self.jriver_exe}")
                print("="*80 + "\n")
                return

            # 4. Build the exact command JRiver will receive
            cmd = [self.jriver_exe, "/Play", path]

            print("\nFINAL SUBPROCESS COMMAND LIST:")
            for part in cmd:
                print(f"    {part}")

            print("\n🚀 LAUNCHING JRiver NOW...")
            print("="*80 + "\n")

            subprocess.Popen(cmd)

        except Exception as e:
            print(f"❌ Subprocess Launch Failed: {e}")
            traceback.print_exc()

    # ---------------------------------------------------------
    # TRIAGE VIEW (DETECT MASTER VS NON-MASTER FOLDERS)
    # ---------------------------------------------------------
    @Slot(str, result=list)
    def get_video_triage_data(self, folder_path):
        video_data = []
        video_exts = {'.mp4', '.m2ts', '.ts', '.mkv', '.avi', '.mov', '.wmv', '.m4v'}

        try:
            p = Path(folder_path)
            if not p.exists():
                return []

            all_files = list(p.iterdir())
            video_files = [f for f in all_files if f.suffix.lower() in video_exts]
            if not video_files:
                return []

            # Determine if folder is part of master library
            local_match_count = sum(1 for v in video_files if v.with_suffix('.jpg').exists())
            total_vids = len(video_files)
            correlation = local_match_count / total_vids
            is_master_library = (correlation >= 0.9)

            print(f"[DEBUG] Triage: {total_vids} videos | {correlation:.1%} correlation | Master: {is_master_library}")

            fallback_uri = Path(paths.get("fallback_image", "")).as_uri()

            for item in video_files:
                try:
                    size_bytes = item.stat().st_size
                    size_str = f"{size_bytes / (1024**3):.1f} GB" if size_bytes > 1024**3 else f"{size_bytes / (1024**2):.0f} MB"
                except:
                    size_str = "Unknown"

                image_path = ""

                # MASTER LIBRARY → USE MANIFEST THUMB
                if is_master_library:
                    video_key = str(item).replace('/', '\\')
                    if self.folder_mapper:
                        record = self.folder_mapper.get_record(video_key)
                        if record and "cache" in record:
                            rel_cache_path = record["cache"].get("thumb", "")
                            if rel_cache_path:
                                full_path = paths["local_thumb_v2"] / Path(rel_cache_path).name
                                if full_path.exists():
                                    image_path = full_path.as_uri()

                # LOCAL JPG FALLBACK
                if not image_path:
                    local_jpg = item.with_suffix('.jpg')
                    if local_jpg.exists():
                        image_path = "file:///" + str(local_jpg).replace("\\", "/")

                # GLOBAL FALLBACK
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
            return []

    # ---------------------------------------------------------
    # FOLDER BROWSER
    # ---------------------------------------------------------
    @Slot(str, result=dict)
    def get_folder_contents(self, parent_path):
        if not parent_path:
            return {"files": [], "folders": []}

        files, folders = [], []
        media_exts = {'.mp4', '.mkv', '.avi', '.mov', '.wmv', '.m4v', '.m2ts', '.ts'}

        try:
            normalized = os.path.normpath(parent_path)
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

    # ---------------------------------------------------------
    # DRIVE ENUMERATION
    # ---------------------------------------------------------
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