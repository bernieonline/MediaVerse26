import sys
import psutil
import wmi
import os
import logging
import urllib.parse
from pathlib import Path
from urllib.parse import quote, urlparse, unquote

from PySide6.QtCore import QObject, Signal, Property, Slot, QThread
# Ensure FolderMapper.py is in the same directory
from FolderMapper import FolderMapper

VIDEO_EXTS = [".avi", ".webm", ".mp4", ".m2ts", ".ts", ".vob", ".mkv"]

def normalize_path(url_or_path: str) -> str:
    """
    Convert a file:/// URL to a Windows filesystem path if needed.
    """
    try:
        if url_or_path.startswith("file:///"):
            parsed = urlparse(url_or_path)
            fs_path = unquote(parsed.path)
            if fs_path.startswith("/"):
                fs_path = fs_path[1:]
            return str(Path(fs_path))
        else:
            return url_or_path
    except Exception as e:
        logging.error(f"Error normalizing path {url_or_path}: {e}")
        return url_or_path

class Worker(QObject):
    """
    Worker for multi-threaded folder scanning to keep the UI responsive.
    """
    finished = Signal(list)

    def __init__(self, path):
        super().__init__()
        self.path = path

    @Slot()
    def run(self):
        folders = []
        try:
            target_path = self.path
            # Special handling for W: root redirection
            if target_path == "W:\\" or target_path == "W:/":
                target_path = "W:\\Collection"

            if os.path.isdir(target_path):
                for item in os.listdir(target_path):
                    item_path = os.path.join(target_path, item)
                    if os.path.isdir(item_path):
                        folders.append({'folderName': item, 'folderPath': item_path})
        except Exception as e:
            logging.error(f"Error listing folders in {self.path}: {e}")

        self.finished.emit(folders)

class FileSystem(QObject):
    drivesChanged = Signal()
    foldersChanged = Signal()
    imageFilesChanged = Signal()
    images_listed = Signal(list) # The primary signal for the new V2 Grid

    def __init__(self, parent=None):
        super().__init__(parent)
        self._drives = []
        self._folders = []
        self._imageFiles = []
        self.thread = None
        self.worker = None
        
        # 1. INITIALIZE FOLDER MAPPER
        # We pass the path here to avoid the TypeError crash
        manifest_path = r"W:\MediaVerse\manifest\manifest.json"
        self.mapper = FolderMapper(manifest_path)
        
        print(f"--- FileSystem V2 Initialized ---")
        print(f"Mapper ready for: {manifest_path}")
        
        # 2. LOAD DRIVES
        self.update_drives()

    # --- PRIMARY V2 SCAN LOGIC ---
    @Slot(str)
    def list_image_files_in_folder(self, folder_url):
        """
        DIAGNOSTIC STEP 1: Just print the path to the terminal.
        """
        print("\n" + "="*40)
        print("[TARGET] CONNECTION SUCCESSFUL")
        print(f"[DIR] Folder Clicked: {folder_url}")
        print("="*40 + "\n")

        # We must still emit something so the UI doesn't hang, 
        # even if it's an empty list for now.
        self.images_listed.emit([])

    # --- LEGACY SCOUT LOGIC ---
    @Slot(str, str, result=str)
    def findVideoInFolder(self, folder_path: str, image_filename: str) -> str:
        """
        Locates a video file matching a specific image's base name.
        Used by the legacy V1 loop.
        """
        try:
            stem = Path(image_filename).stem
            for ext in VIDEO_EXTS:
                candidate = Path(folder_path) / f"{stem}{ext}"
                if candidate.exists():
                    # Return as encoded file URI
                    url = "file:///" + quote(str(candidate).replace("\\", "/"))
                    return url
        except Exception as e:
            logging.error(f"Error finding video for {image_filename}: {e}")
        return ""

    # --- PROPERTIES ---
    @Property('QVariantList', notify=drivesChanged)
    def drives(self):
        return self._drives

    @Property('QVariantList', notify=foldersChanged)
    def folders(self):
        return self._folders

    @Property('QVariantList', notify=imageFilesChanged)
    def imageFiles(self):
        return self._imageFiles

    # --- DRIVE & THREAD LOGIC ---
    @Slot()
    def update_drives(self):
        drives = []
        try:
            # Local Physical Drives
            for partition in psutil.disk_partitions():
                drives.append(partition.device)
            # Mapped Network Drives
            c = wmi.WMI()
            for drive in c.Win32_MappedLogicalDisk():
                drives.append(drive.DeviceID + "\\")
        except Exception as e:
            print(f"Drive detection error: {e}")

        self._drives = sorted(list(set(drives)))
        self.drivesChanged.emit()

    @Slot(str)
    def update_folders(self, path):
        """
        Triggers the background thread to list subfolders.
        """
        if self.thread and self.thread.isRunning():
            return

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

    def on_thread_finished(self):
        self.thread = None
        
    @Slot(str)
    def list_folder_content_v2(self, folder_url):
        """
        STEP 3: Fixed to use the internal method of FolderMapper correctly.
        """
        print("\n" + "--"*60)
        print(f"[>>] V2 MAPPING STARTING")
        
        try:
            # 1. Clean the path
            clean_path = folder_url.replace("file:///", "")
            clean_path = urllib.parse.unquote(clean_path)
            clean_path = os.path.normpath(clean_path)

            # 2. CALL THE METHOD (Don't use self.mapper.data)
            # This triggers the logic we just reviewed in FolderMapper.py
            mapped_results = self.mapper.get_items_for_folder(clean_path)

            # 3. Print the results to the terminal as requested
            print(f"[DIR] Folder: {clean_path}")
            print(f"  Mapped {len(mapped_results)} items:")

            for item in mapped_results:
                title = item.get('title')
                thumb = item.get('filePath') # This is the D:/... path now
                print(f"  [MOVIE] {title}")
                print(f"    {thumb}")
                print("-" * 10)

            print(f"[OK] Mapping Complete")
            print("--"*60 + "\n")

            # 4. Hand off to QML
            self.images_listed.emit(mapped_results)

        except Exception as e:
            # This is where the "'FolderMapper' object has no attribute 'data'" error was caught
            print(f"[ERROR] Step 3 Mapping Error: {e}")