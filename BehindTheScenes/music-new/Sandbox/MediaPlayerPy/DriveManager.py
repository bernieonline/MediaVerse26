import os
import psutil
import ctypes
from pathlib import Path
from PySide6.QtCore import QObject, Slot

from project_paths import paths  # centralized path map


class DriveManager(QObject):
    def __init__(self):
        super().__init__()
        self.network_root = "W:/"      # kept for now (not used in new lookup)
        self.folder_mapper = None

    def set_mapper(self, mapper_instance):
        self.folder_mapper = mapper_instance

    @Slot(str, result=list)
    def get_video_triage_data(self, folder_path):
        """
        Scans folder and matches keys to FreestyleView.qml.
        FIX: Extension now correctly reflects the video type (MP4/MKV)
        even when a JPG/PNG thumbnail is loaded.
        """
        video_data = []
        video_exts = {'.mp4', '.mkv', '.avi', '.mov', '.wmv', '.m4v'}

        try:
            p = Path(folder_path)
            if not p.exists():
                return []

            for item in p.iterdir():
                if not item.is_file():
                    continue

                # Capture the original video extension first
                raw_ext = item.suffix.lower()

                if raw_ext in video_exts:
                    # LOCK THE VIDEO TYPE FOR THE LABEL (e.g., MP4)
                    display_ext = raw_ext.replace('.', '').upper()

                    video_key = str(item).replace('/', '\\')
                    image_path = ""

                    # 🔍 Look up thumb in manifest → LOCAL CACHE V2
                    if self.folder_mapper:
                        record = self.folder_mapper.get_record(video_key)
                        if record and "cache" in record:
                            rel_cache_path = record["cache"].get("thumb", "")
                            if rel_cache_path:
                                # manifest gives e.g. "Cache/thumb/She Wore A Yellow Ribbon (1949).jpg"
                                filename = Path(rel_cache_path).name
                                local_thumb_dir = paths["local_thumb_v2"]
                                full_path = local_thumb_dir / filename

                                if full_path.exists():
                                    image_path = full_path.as_uri()

                    # Fallback to local .jpg next to the video
                    if not image_path:
                        local_jpg = item.with_suffix('.jpg')
                        if local_jpg.exists():
                            image_path = "file:///" + str(local_jpg).replace("\\", "/")

                    # FINAL FALLBACK: global default image via project_paths
                    if not image_path:
                        fallback = paths.get("fallback_image")
                        if fallback and Path(fallback).exists():
                            image_path = Path(fallback).as_uri()

                    video_data.append({
                        "title": str(item.stem),
                        "filename": str(item.stem),
                        "thumb": str(image_path),
                        "filePath": str(image_path),
                        "videoPath": str(item.as_posix()),
                        "originalPath": str(item.as_posix()),
                        "extension": display_ext,  # FIXED: Shows Video Ext, not Image Ext
                        "sourceType": "PROCESSED" if image_path else "RAW"
                    })

            return sorted(video_data, key=lambda x: x["title"].lower())
        except Exception as e:
            print(f"❌ DriveManager Triage Error: {e}")
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