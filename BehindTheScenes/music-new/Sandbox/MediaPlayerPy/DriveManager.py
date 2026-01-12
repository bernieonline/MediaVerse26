import os
import psutil
from PySide6.QtCore import QObject, Slot

class DriveManager(QObject):
    def __init__(self):
        super().__init__()

    @Slot(result=list)
    def get_available_drives(self):
        import psutil
        import os
        drives = []
        
        # 1. Use all=True to catch Network/Mapped drives
        partitions = psutil.disk_partitions(all=True)
        
        for partition in partitions:
            try:
                # Filter out system/virtual drives that aren't useful
                if partition.fstype == '' or 'cdrom' in partition.opts:
                    continue
                
                drive_path = partition.mountpoint
                # Ensure we have a clean letter (e.g., "W:")
                drive_label = partition.device.replace("\\", "") if partition.device else drive_path
                
                drives.append({
                    "label": drive_label.strip(),
                    "path": drive_path,
                    "isCollection": "W:" in drive_path.upper()
                })
            except:
                continue

        # 2. EMERGENCY FALLBACK: If W: is still missing (sometimes happens with mapped drives)
        if not any("W:" in d["label"].upper() for d in drives):
            if os.path.exists("W:/"):
                drives.append({
                    "label": "W:",
                    "path": "W:/",
                    "isCollection": True
                })
                
        return sorted(drives, key=lambda x: x['label'])

    @Slot(str, result=list)
    def get_subfolders(self, parent_path):
        """Returns a list of subfolders for the unfolding panes."""
        if not parent_path:
            return []
            
        folders = []
        try:
            # Clean path for Windows
            normalized_path = os.path.normpath(parent_path)
            
            for item in os.listdir(normalized_path):
                full_path = os.path.join(normalized_path, item)
                
                # Only include directories and skip hidden system folders
                if os.path.isdir(full_path) and not item.startswith('$'):
                    folders.append({
                        "name": item,
                        "path": full_path.replace("\\", "/") # Normalize for QML
                    })
            
            # Sort alphabetically for a clean UI
            return sorted(folders, key=lambda x: x['name'].lower())
            
        except Exception as e:
            print(f"⚠️ Freestyle Error reading folders at {parent_path}: {e}")
            return []

    @Slot(str, result=bool)
    def has_media(self, folder_path):
        """Checks if a folder contains video files to trigger the Preview Pane."""
        video_extensions = ('.mp4', '.mkv', '.avi', '.mov', '.wmv')
        try:
            return any(f.lower().endswith(video_extensions) for f in os.listdir(folder_path))
        except:
            return False

    @Slot(str, result=str)
    def get_thumb_for_video(self, video_path):
        """
        Implementation of the matching rule: 
        Shared Video Path -> Converted Cache Key -> Thumb Path
        """
        # Example conversion: W:\Collection\Movie.mp4 -> cached_thumb_path
        # You can plug your specific cache-lookup logic here
        return video_path # Placeholder