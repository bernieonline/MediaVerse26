from PySide6.QtCore import QObject, Slot, Signal
import os
from project_paths import coll_data
import json


class ArchitectController(QObject):
    # --- CRITICAL SIGNALS ---
    
    resultsCounted = Signal(int, int) # Updates hitCount on individual panels
    foldersUpdated = Signal(list)



    def __init__(self, file_system=None):
        super().__init__()
        self.file_system = file_system


        # Load the full movie collection once
        with open(coll_data, "r", encoding="utf-8") as f:
            self.collection = json.load(f)        

        # Panel state: mode, criteria, and temporary movie list
        self.panels = {
            0: {"mode": None, "criteria": None, "movies": []},
            1: {"mode": None, "criteria": None, "movies": []},
            2: {"mode": None, "criteria": None, "movies": []},
            3: {"mode": None, "criteria": None, "movies": []},
        }

    # --- CRITICAL SLOTS FOR QML ---

    #this sets up a path of a folder to search xml_collection_data for records
    def build_folder_prefix(self, folder_name):
        return f"W:\\Collection\\{folder_name}\\"
    
    @Slot(int, str)
    def folder_mode_select(self, panel_index, folder_name):


        # 1. Build prefix
        prefix = self.build_folder_prefix(folder_name)

        # 2. Filter JSON
        movies = [
            item for item in self.collection
            if item["Filename"].startswith(prefix)
        ]

        # 3. Store in panel state
        self.panels[panel_index]["mode"] = "folder"
        self.panels[panel_index]["criteria"] = folder_name
        self.panels[panel_index]["movies"] = movies

        # 4. Print for verification
        print(f"\n🎬 Panel {panel_index} — Folder Mode: {folder_name}")
        print(f"📄 {len(movies)} movies found:")
        for m in movies:
            print("   ", m["Filename"])

        # 5. Emit count to QML
        self.resultsCounted.emit(panel_index, len(movies))

   

    @Slot(str)
    def get_sub_folders(self, folder_path):
        if not self.file_system:
            return
        target = folder_path if folder_path else "W:\\"
        self.file_system.update_folders(target)