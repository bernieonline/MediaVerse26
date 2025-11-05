import sys
import os
from PyQt5.QtWidgets import QApplication, QFileDialog, QWidget

class FileExplorer(QWidget):
    def __init__(self):
        super().__init__()

    def select_directory(self):
        # Create a file dialog to select a directory
        options = QFileDialog.Options()
        directory = QFileDialog.getExistingDirectory(self, "Select Directory", "", options=options)
        
        # Return the selected directory if any
        if directory:
            return directory
        else:
            return None

def search_media_files(start_directory):
    # Walk through the selected directory and look for media files (e.g., .mp4, .mkv, .avi)
    media_extensions = ('.mp4', '.mkv', '.avi', '.mp3', '.flac', '.mov')
    for dirpath, dirnames, filenames in os.walk(start_directory):
        for filename in filenames:
            if filename.lower().endswith(media_extensions):
                print(f"Found media file: {os.path.join(dirpath, filename)}")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    
    # Initialize the file explorer
    explorer = FileExplorer()
    
    # Let the user select a directory (local or network share)
    selected_directory = explorer.select_directory()
    
    if selected_directory:
        print(f"Selected directory: {selected_directory}")
        # Now call the function to search for media files
        search_media_files(selected_directory)
    else:
        print("No directory selected.")
