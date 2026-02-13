from PySide6.QtCore import QObject, Slot, Signal
import os
from project_paths import coll_data
import json


class ArchitectController(QObject):
    # --- CRITICAL SIGNALS ---
    
    resultsCounted = Signal(int, int) # Updates hitCount on individual panels
    foldersUpdated = Signal(list)
    VIDEO_EXTS = {'.mp4', '.m2ts', '.ts', '.mkv', '.avi', '.mov', '.m4v', '.iso'}



    def __init__(self, file_system=None):
        super().__init__()
        self.file_system = file_system

        # ADD THIS LINE NEAR THE TOP OF THE FILE
        print("DEBUG SLOT SIGNATURE:", self.category_mode_select)

       


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


    @Slot(str, int)
    def load_movies_for_path(self, folder_path, panel_index):
        """Scan the actual filesystem and list ONLY movie files inside the selected folder."""

        if not folder_path:
            print("⚠ No folder path provided.")
            self.resultsCounted.emit(panel_index, 0)
            return

        base_path = "W:\\Collection\\"
        full_path = os.path.join(base_path, folder_path.replace("/", "\\"))

        print(f"📁 Scanning folder: {full_path}")

        if not os.path.exists(full_path):
            print("❌ Folder does not exist:", full_path)
            self.resultsCounted.emit(panel_index, 0)
            return

        # Filter ONLY movie files
        files = [
            f for f in os.listdir(full_path)
            if os.path.isfile(os.path.join(full_path, f))
            and os.path.splitext(f)[1].lower() in self.VIDEO_EXTS
        ]

        print(f"🎬 Movie files found ({len(files)}):")
        for f in files:
            print("   ", f)

        # Emit count to QML
        self.resultsCounted.emit(panel_index, len(files))

    @Slot(int, str, str)
    def category_mode_select(self, panel_index, category, value):
        """Filter movies by category/value pair, including decade logic."""

        print(f"\n🎬 Panel {panel_index} — Category Mode: {category} = {value}")

        movies = []

        mapping = {
            "Actors": "Actors",
            "Director": "Director",
            "Genre": "Genre",
            "Keywords": "Keywords",
            "Series": "Series"
        }

        # --- DECADE SPECIAL CASE ---
        if category == "Decade":
            decade = value[:-1]  # "1950s" → "1950"

            for item in self.collection:
                if item.get("Media Sub Type") == "TV Show":
                    continue

                year = item.get("Year")
                if not year or not year.isdigit():
                    continue

                item_decade = year[:-1] + "0"
                if item_decade == decade:
                    movies.append(item)

        else:
            json_key = mapping.get(category, category)

            for item in self.collection:
                if item.get("Media Sub Type") == "TV Show":
                    continue

                data = item.get(json_key, "")

                if isinstance(data, list):
                    if value in data:
                        movies.append(item)
                else:
                    parts = str(data).split(";")
                    if value in parts:
                        movies.append(item)

        self.panels[panel_index]["mode"] = "category"
        self.panels[panel_index]["criteria"] = f"{category} = {value}"
        self.panels[panel_index]["movies"] = movies

        print(f"📄 {len(movies)} movies found:")
        for m in movies:
            print("   ", m["Filename"])

        self.resultsCounted.emit(panel_index, len(movies))

        
    @Slot(str, str, result=list)
    def get_filtered_keywords(self, category, filter_text):
        try:
            keywords = set()
            search_term = filter_text.lower()

            mapping = {
                "Actors": "Actors",
                "Director": "Director",
                "Genre": "Genre",
                "Keywords": "Keywords",
                "Series": "Series"
            }

            json_key = mapping.get(category, category)

            for movie in self.collection:
                data = movie.get(json_key, "")
                if not data:
                    continue

                # Actors is a list; others are semicolon-separated
                items = data if isinstance(data, list) else str(data).split(";")

                for item in items:
                    clean_item = item.strip()
                    if not search_term or search_term in clean_item.lower():
                        keywords.add(clean_item)

            return sorted(list(keywords))[:100]

        except Exception as e:
            print("Keyword filter error:", e)
            return []

