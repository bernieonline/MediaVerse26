import os
import json
import logging
from PySide6.QtCore import QObject, Signal, Slot, Property
from project_paths import paths

class ArchitectController(QObject):
    resultsCounted = Signal(int)
    foldersUpdated = Signal(list)
    searchResultsUpdated = Signal(list) # Your QML likely connects to this
    saveConfirmed = Signal(str)
    searchResultsChanged = Signal()

    def __init__(self, xml_logic=None):
        super().__init__()
        self.library_data = []
        self._search_results = [] 
        self.collectionLogic = xml_logic 
        self.load_library()

    # We keep the property just in case your QML uses it for the delegate
    @Property('QVariantList', notify=searchResultsChanged)
    def searchResultsModel(self):
        return self._search_results

    @Slot()
    def load_library(self):
        try:
            target_path = paths["xmldate"]
            if os.path.exists(target_path):
                with open(target_path, 'r', encoding='utf-8') as f:
                    self.library_data = json.load(f)
                logging.info(f"🎯 Architect Engine: Loaded {len(self.library_data)} records.")
        except Exception as e:
            logging.error(f"❌ Architect Engine: Load failed: {e}")

    # --- SEARCH LOGIC (Optimized for your Manifest) ---
    @Slot(str)
    def search_library(self, query):
        if not query or len(query) < 2:
            self._search_results = []
            self.searchResultsUpdated.emit([])
            return
            
        matches_for_qml_list = [] # Simple strings for the UI list
        matches_with_paths = []    # Dicts for the 'Add to Stack' logic
        
        q = query.lower()
        for m in self.library_data:
            name = str(m.get('Name', ''))
            fname = str(m.get('Filename', ''))
            
            if q in name.lower():
                matches_for_qml_list.append(name)
                matches_with_paths.append({"title": name, "filename": fname})
        
        self._search_results = matches_with_paths[:15]
        self.searchResultsChanged.emit()
        
        # This is the "old reliable" signal your QML is likely using
        self.searchResultsUpdated.emit(matches_for_qml_list[:15])
        print(f"DEBUG: Search for '{query}' found {len(matches_for_qml_list)} movies.")

    # --- FOLDER NAVIGATION (YOUR WORKING VERSION) ---
    @Slot(str)
    def get_sub_folders(self, current_path):
        base_root = "W:\\Collection"
        if not current_path or current_path in ["", "/", "\\"]:
            search_path = base_root + "\\"
        else:
            search_path = os.path.join(base_root, current_path.replace("/", "\\"))
            if not search_path.endswith("\\"):
                search_path += "\\"

        folders = set()
        for m in self.library_data:
            fpath = m.get("Filename", "")
            if fpath.lower().startswith(search_path.lower()):
                relative = fpath[len(search_path):]
                parts = relative.split("\\")
                if len(parts) > 1:
                    folders.add(parts[0])
        self.foldersUpdated.emit(sorted(list(folders)))

    # --- LIVE PREVIEW / STACK FILTERING ---
    @Slot(str)
    def update_live_preview(self, criteria_json):
        criteria_list = json.loads(criteria_json)
        search_dict = {}
        manual_files = []

        for item in criteria_list:
            if item["category"] == "search_files":
                if item["value"]:
                    manual_files = item["value"].split("|")
            elif item["category"] == "folder":
                search_dict["Filename"] = item["value"].replace("/", "\\")
            else:
                raw_value = item["value"]
                if " = " in raw_value:
                    key, val = raw_value.split(" = ", 1)
                    search_dict[key.strip()] = val.strip()
                else:
                    search_dict[item["category"]] = raw_value

        matches = self.collectionLogic.get_collection_results(search_dict)
        
        # If the 'Search Mode' stack has files, filter the engine results
        if manual_files:
            if not search_dict:
                matches = [m for m in self.library_data if m.get("Filename") in manual_files]
            else:
                matches = [m for m in matches if m.get("Filename") in manual_files]

        self.resultsCounted.emit(len(matches))

    @Slot(str, str, result=list)
    def get_filtered_keywords(self, category, filter_text):
        try:
            keywords = set()
            search_term = filter_text.lower()
            mapping = {"Actors": "Actors", "Director": "Director", "Genre": "Genre", "Keywords": "Keywords", "Series": "Series"}
            cat_key = mapping.get(category, category)
            for movie in self.library_data:
                data = movie.get(cat_key, "")
                if not data: continue
                items = data if isinstance(data, list) else str(data).split(";")
                for item in items:
                    clean_item = item.strip()
                    if not search_term or search_term in clean_item.lower():
                        keywords.add(clean_item)
            return sorted(list(keywords))[:100]
        except: return []

    @Slot(str, str)
    def save_collection(self, name, logic_json):
        self.saveConfirmed.emit(name)