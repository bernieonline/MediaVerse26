import sys
import psutil
import wmi
import os
import logging
from pathlib import Path
from urllib.parse import quote, urlparse, unquote

from PySide6.QtCore import QObject, Signal, Property, Slot, QThread

VIDEO_EXTS = [".avi", ".webm", ".mp4", ".m2ts", ".ts", ".vob", ".mkv"]


def normalize_path(url_or_path: str) -> str:
    """
    Convert a file:/// URL to a Windows filesystem path if needed.
    If it's already a Windows path, return it unchanged.
    """
    try:
        if url_or_path.startswith("file:///"):
            parsed = urlparse(url_or_path)
            fs_path = unquote(parsed.path)
            # On Windows, strip leading slash and convert to backslashes
            if fs_path.startswith("/"):
                fs_path = fs_path[1:]
            return str(Path(fs_path))
        else:
            return url_or_path
    except Exception as e:
        logging.error(f"Error normalizing path {url_or_path}: {e}")
        return url_or_path


class Worker(QObject):
    finished = Signal(list)

    def __init__(self, path):
        super().__init__()
        self.path = path

    @Slot()
    def run(self):
        folders = []
        try:
            if self.path == "W:\\":
                self.path = "W:\\Collections"

            if os.path.isdir(self.path):
                for item in os.listdir(self.path):
                    item_path = os.path.join(self.path, item)
                    if os.path.isdir(item_path):
                        folders.append({'folderName': item, 'folderPath': item_path})
        except Exception as e:
            logging.error(f"Error listing folders in {self.path}: {e}")

        self.finished.emit(folders)


class FileSystem(QObject):
    drivesChanged = Signal()
    foldersChanged = Signal()
    imageFilesChanged = Signal()
    print("inside filesystem class")




    @Slot(str,str, result=str)
    def findVideoInFolder(self, folder_path: str, image_filename: str) -> str:

        """
        Given an image path (possibly a file:/// URL), try to locate the matching video file.
        Returns a file:/// URL for the video if found, else empty string.
        """
        try:
            print("inside findVideoForImage : ",str)

            stem = Path(image_filename).stem  # strip extension from image


            for ext in VIDEO_EXTS:
                candidate = Path(folder_path) / f"{stem}{ext}"

                if candidate.exists():
                    # Convert to file:/// URL with forward slashes + URL encoding
                    url = "file:///" + quote(str(candidate).replace("\\", "/"))
                    print("🎬 Resolved video path:", url)  # evidence in terminal


                    logging.info(f"Resolved video path: {url}")  # ✅ evidence in terminal
                    print("movie url is :",url)
                    return url
            print(f"⚠️ No video found for {image_filename} in {folder_path}")

        except Exception as e:
            logging.error(f"Error finding video for {image_filename} in {folder_path}: {e}")

        return ""

    def __init__(self, parent=None):
        super().__init__(parent)
        self._drives = []
        self._folders = []
        self._imageFiles = []
        self.thread = None
        self.worker = None
        self.update_drives()

    @Property('QVariantList', notify=drivesChanged)
    def drives(self):
        return self._drives

    @Property('QVariantList', notify=foldersChanged)
    def folders(self):
        return self._folders

    @Property('QVariantList', notify=imageFilesChanged)
    def imageFiles(self):
        return self._imageFiles

    @Slot()
    def update_drives(self):
        drives = []
        # Get local drives
        for partition in psutil.disk_partitions():
            drives.append(partition.device)

        # Get network drives
        c = wmi.WMI()
        for drive in c.Win32_MappedLogicalDisk():
            drives.append(drive.DeviceID + "\\")

        self._drives = sorted(list(set(drives)))
        self.drivesChanged.emit()

    @Slot(str)
    def update_folders(self, path):
        if self.thread and self.thread.isRunning():
            return

        logging.info(f"Updating folders for path: {path}")
        self.thread = QThread()
        self.worker = Worker(path)
        self.worker.moveToThread(self.thread)

        self.thread.started.connect(self.worker.run)
        self.worker.finished.connect(self.on_worker_finished)
        self.worker.finished.connect(self.thread.quit)
        self.worker.finished.connect(self.worker.deleteLater)
        self.thread.finished.connect(self.thread.deleteLater)
        self.thread.finished.connect(self.on_thread_finished)

        self.thread.start()

    def on_worker_finished(self, folders):
        self._folders = folders
        self.foldersChanged.emit()
        logging.info(f"Found {len(folders)} folders.")

    def on_thread_finished(self):
        self.thread = None


    @Slot(str)
    def list_image_files_in_folder(self, folder_path):
        image_files = []
        image_extensions = ('.jpg', '.jpeg', '.bmp', '.webp')
        try:
            if os.path.isdir(folder_path):
                parent_folder = os.path.basename(folder_path)

                for item in os.listdir(folder_path):
                    # 1. Standardize the path
                    item_path = os.path.join(folder_path, item).replace('\\', '/')
                    
                    if os.path.isfile(item_path) and item.lower().endswith(image_extensions):
                        # 2. TRIGGER THE ORIGINAL SCOUT LOGIC
                        # Instead of sending the .jpg to 'originalPath', we find the real video
                        video_uri = self.findVideoInFolder(folder_path, item)
                        
                        # 3. Convert URI back to a clean path for JRiver if needed
                        # (JRiver usually prefers W:/path/movie.mp4 over file:///W:/...)
                        actual_video_path = normalize_path(video_uri) if video_uri else ""

                        image_files.append({
                            'fileName': item,
                            'filePath': Path(item_path).as_uri(), # Visual (UI)
                            'originalPath': actual_video_path,     # Playable (Video)
                            'parentFolder': parent_folder,
                            'relativePath': parent_folder + "/" + item
                        })
        except Exception as e:
            logging.error(f"Error listing image files: {e}")

        self._imageFiles = image_files
        self.imageFilesChanged.emit()

