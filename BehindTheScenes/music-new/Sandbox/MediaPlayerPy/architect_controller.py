import os
import json
import logging
from PySide6.QtCore import QObject, Signal, Slot
from project_paths import paths

class ArchitectController(QObject):
    """
    The Brain of the Collection Architect.
    Processes metadata, handles folder navigation, and manages the filter count.
    """
    resultsCounted = Signal(int)
    foldersUpdated = Signal(list)
    searchResultsUpdated = Signal(list)
    saveConfirmed = Signal(str)

    def __init__(self, xml_logic=None):
        super().__init__()
        self.library_data = []
        self.last_filtered_results = []
        self.load_library()
        self.collectionLogic = xml_logic # This is the "Hammer" it was missing

    @Slot()
    def load_library(self):
        """Initial load of the rich metadata records."""
        try:
            target_path = paths["xmldate"]
            if os.path.exists(target_path):
                with open(target_path, 'r', encoding='utf-8') as f:
                    self.library_data = json.load(f)
                logging.info(f"🎯 Architect Engine: Loaded {len(self.library_data)} records.")
            else:
                logging.error(f"❌ Architect Engine: File not found at {target_path}")
        except Exception as e:
            logging.error(f"❌ Architect Engine: Load failed: {e}")

    # --- FOLDER NAVIGATION ---
    @Slot(str)
    def get_sub_folders(self, current_path):
        """
        Scans Filenames to find unique sub-folders.
        Emits foldersUpdated signal for QML Connections.
        """
        # Define the base library path
        base_root = "W:\\Collection"
        
        # Build the full path to scan
        if not current_path or current_path in ["", "/", "\\"]:
            search_path = base_root + "\\"
        else:
            # Join base root with the relative path from QML
            search_path = os.path.join(base_root, current_path.replace("/", "\\"))
            if not search_path.endswith("\\"):
                search_path += "\\"

        print(f"DEBUG: Scanning Architect for sub-folders under: {search_path}")
        folders = set()

        for m in self.library_data:
            fpath = m.get("Filename", "")
            if fpath.lower().startswith(search_path.lower()):
                relative = fpath[len(search_path):]
                parts = relative.split("\\")
                if len(parts) > 1:
                    folders.add(parts[0])

        result = sorted(list(folders))
        print(f"DEBUG: Found {len(result)} sub-folders. Emitting signal...")
        self.foldersUpdated.emit(result)

    # --- KEYWORD CLOUD ---
    @Slot(str, str, result=list)
    def get_filtered_keywords(self, category, filter_text):
        """Returns unique values (Directors, Actors, etc.) for the discovery cloud."""
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
            cat_key = mapping.get(category, category)

            for movie in self.library_data:
                data = movie.get(cat_key, "")
                if not data: continue

                if isinstance(data, list):
                    items = data
                else:
                    items = str(data).split(";")

                for item in items:
                    clean_item = item.strip()
                    if not search_term or search_term in clean_item.lower():
                        keywords.add(clean_item)
            
            return sorted(list(keywords))[:100]
        except Exception as e:
            print(f"❌ Cloud Error: {e}")
            return []

    # --- FILTERING LOGIC ---
    # Inside architect_controller.py

    @Slot(str)
    def update_live_preview(self, criteria_json):
        import json
        criteria_list = json.loads(criteria_json)
        
        search_dict = {}
        for item in criteria_list:
            # --- FOLDER LOGIC (UNTOUCHED) ---
            if item["category"] == "folder":
                search_dict["Filename"] = item["value"].replace("/", "\\")
            
            # --- CATEGORY LOGIC (UPDATED) ---
            else:
                raw_value = item["value"]
                # If UI sends "Actors = Sean Connery", we split it 
                # to create {"Actors": "Sean Connery"} for the search_dict
                if " = " in raw_value:
                    key, val = raw_value.split(" = ", 1)
                    search_dict[key.strip()] = val.strip()
                else:
                    # Fallback for simple values
                    search_dict[item["category"]] = raw_value

        # --- CALL ENGINE & EMIT (UNTOUCHED) ---
        matches = self.collectionLogic.get_collection_results(search_dict)
        print(f"🔍 Architect Search: {search_dict} | Found: {len(matches)}")
        self.resultsCounted.emit(len(matches))

    @Slot(str)
    def search_library(self, query):
        """Title search for search card mode."""
        if not query or len(query) < 2:
            self.searchResultsUpdated.emit([])
            return
        results = [m.get('Name', 'Unknown') for m in self.library_data 
                   if query.lower() in str(m.get('Name', '')).lower()]
        self.searchResultsUpdated.emit(results[:15])

    @Slot(str, str)
    def save_collection(self, name, logic_json):
        """Saves current filtered list."""
        logging.info(f"💾 Saving collection '{name}' with {len(self.last_filtered_results)} items.")
        self.saveConfirmed.emit(name)