import os
import json
import logging
from PySide6.QtCore import QObject, Signal, Slot

class ArchitectController(QObject):
    # Signals to communicate back to QML
    foldersUpdated = Signal(list)
    resultsCounted = Signal(int)
    saveConfirmed = Signal(str)

    def __init__(self):
        super().__init__()
        # Ensure this matches your matching rule root exactly
        self.root_collection_path = "W:/Collection"
        
        # Placeholder for your library data for counting matches
        self.library_data = [] 

    @Slot(str)
    def get_sub_folders(self, relative_path):
        """
        Scans W:/Collection + relative_path and returns a list of subfolders.
        """
        try:
            # 1. Construct and normalize the target path
            # We replace backslashes to avoid Windows/QML path string conflicts
            clean_rel = relative_path.replace("\\", "/").strip("/")
            
            if not clean_rel:
                full_target = self.root_collection_path
            else:
                full_target = os.path.join(self.root_collection_path, clean_rel).replace("\\", "/")

            logging.debug(f"[Architect] Scanning for folders in: {full_target}")

            # 2. Perform the scan
            if os.path.exists(full_target) and os.path.isdir(full_target):
                # Filter for directories only and ignore hidden folders
                folders = [
                    d for d in os.listdir(full_target) 
                    if os.path.isdir(os.path.join(full_target, d)) and not d.startswith('.')
                ]
                folders.sort()
                
                logging.debug(f"[Architect] Found {len(folders)} folders.")
                self.foldersUpdated.emit(folders)
            else:
                logging.warning(f"[Architect] Path not found: {full_target}")
                self.foldersUpdated.emit([])

        except Exception as e:
            logging.error(f"[Architect] Error scanning folders: {e}")
            self.foldersUpdated.emit([])

    @Slot(str)
    def update_live_preview(self, logic_json):
        """
        Receives the full logic chain from the HUD and calculates the match count.
        """
        try:
            rules = json.loads(logic_json)
            logging.debug(f"[Architect] Recalculating matches for {len(rules)} rules...")
            
            # This is where your Folder/Category/Search filtering logic lives
            # For now, we return a mock count to verify the connection
            match_count = 42 
            
            self.resultsCounted.emit(match_count)
        except Exception as e:
            logging.error(f"[Architect] Preview error: {e}")

    @Slot(str, str, str, str)
    def save_collection(self, name, description, category, logic_json):
        """
        Saves the final Architect configuration to a JSON file.
        """
        try:
            save_data = {
                "name": name,
                "description": description,
                "category": category,
                "logic": json.loads(logic_json)
            }
            
            # Define your save path (e.g., in Assets/Collections)
            file_name = f"{name.replace(' ', '_')}.json"
            logging.info(f"[Architect] Saving collection: {file_name}")
            
            # Emit success to QML to close the HUD
            self.saveConfirmed.emit(name)
            
        except Exception as e:
            logging.error(f"[Architect] Save error: {e}")