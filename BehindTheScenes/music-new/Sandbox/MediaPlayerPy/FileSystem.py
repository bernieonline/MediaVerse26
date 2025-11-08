import sys
import psutil
import wmi
import os
import logging
from PySide6.QtCore import QObject, Signal, Property, Slot, QThread

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
            logging.info(f"Error listing folders in {self.path}:")
        
        print(f"Folders found: {folders}")
        self.finished.emit(folders)
    

class FileSystem(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)
        self._drives = []
        self._folders = []
        self.thread = None
        self.update_drives()

    drivesChanged = Signal()
    foldersChanged = Signal()
    imageFilesFound = Signal(list)

    @Property('QVariantList', notify=drivesChanged)
    def drives(self):
        return self._drives

    @Property('QVariantList', notify=foldersChanged)
    def folders(self):
        return self._folders

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
        image_extensions = ('.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp')
        try:
            if os.path.isdir(folder_path):
                for item in os.listdir(folder_path):
                    item_path = os.path.join(folder_path, item)
                    if os.path.isfile(item_path) and item.lower().endswith(image_extensions):
                        image_files.append({'fileName': item, 'filePath': item_path})
        except Exception as e:
            logging.error(f"Error listing image files in {folder_path}: {e}")
        
        print(f"Image files found in {folder_path}: {image_files}")
        self.imageFilesFound.emit(image_files)
    

if __name__ == '__main__':
    # This part is for direct testing of the script and will not run in the QML app
    # It needs to be adapted to work with the threaded version if direct testing is needed
    pass