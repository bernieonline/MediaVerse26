import sys
from PySide6.QtCore import QObject, Signal, Property, Slot

class FileSystem(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)
        self._drives = []
        self._folders = []
        self.update_drives()
        self.update_folders("W:\\Collections") # Default path

    drivesChanged = Signal()
    foldersChanged = Signal()

    @Property('QVariantList', notify=drivesChanged)
    def drives(self):
        return self._drives

    @Property('QVariantList', notify=foldersChanged)
    def folders(self):
        return self._folders

    @Slot()
    def update_drives(self):
        # In the future, this will be populated with actual network drives
        self._drives = ["W:", "Y:", "Z:"]
        self.drivesChanged.emit()

    @Slot(str)
    def update_folders(self, path):
        # In the future, this will be populated with actual folders from the path
        self._folders = [f"Folder {i+1} from {path}" for i in range(5)]
        self.foldersChanged.emit()

if __name__ == '__main__':
    fs = FileSystem()
    print("Drives:", fs.drives)
    print("Folders:", fs.folders)
    fs.update_folders("Y:\\Movies")
    print("Folders:", fs.folders)
