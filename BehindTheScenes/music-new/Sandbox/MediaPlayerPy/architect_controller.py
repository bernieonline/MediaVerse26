import os
import json
import logging
from PySide6.QtCore import QObject, Signal, Slot, Property
from project_paths import paths

class ArchitectController(QObject):
    resultsCounted = Signal(int)
    foldersUpdated = Signal(list)
    searchResultsUpdated = Signal(list)
    saveConfirmed = Signal(str)
    onResultsCounted = Signal(int)
    searchResultsChanged = Signal() 

    def __init__(self, xml_logic=None):
        super().__init__()
        self.library_data = []
        self._search_results = [] # Required for the new property
        self.collectionLogic = xml_logic 
        self.load_library()

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

    @Slot(str)
    def update_live_preview(self, criteria_json):
        criteria_list = json.loads(criteria_json)
        search_dict = {}
        manual_files = []

        for item in criteria_list:
            # Check for our new Search Mode category
            if item["category"] == "search_files":
                val = item["value"]
                if val:
                    manual_files = val.split("|")
            
            # --- YOUR EXISTING LOGIC (KEEPING UNTOUCHED) ---
            elif item["category"] == "folder":
                search_dict["Filename"] = item["value"].replace("/", "\\")
            else:
                raw_value = item["value"]
                if " = " in raw_value:
                    key, val = raw_value.split(" = ", 1)
                    search_dict[key.strip()] = val.strip()
                else:
                    search_dict[item["category"]] = raw_value

        # Get matches from your existing Engine
        matches = self.collectionLogic.get_collection_results(search_dict)
        
        # --- NEW: Filter by the 'Stack' if items exist ---
        if manual_files:
            # If other rules exist, we find the intersection. 
            # If only Search Mode is active, we just show the stack.
            if not search_dict:
                matches = [m for m in self.library_data if m.get("Filename") in manual_files]
            else:
                matches = [m for m in matches if m.get("Filename") in manual_files]

        print(f"🔍 Architect Search: {search_dict} | Stack: {len(manual_files)} | Found: {len(matches)}")
        self.resultsCounted.emit(len(matches))
        self.onResultsCounted.emit(len(matches))

    @Slot(str)
    def search_library(self, query):
        """Title search for search card mode - Populates the results model."""
        if not query or len(query) < 2:
            self._search_results = []
        else:
            # We return dicts so QML can get .title and .filename
            matches = []
            for m in self.library_data:
                name = m.get('Name', m.get('title', 'Unknown'))
                fname = m.get('Filename', m.get('filename', ''))
                if query.lower() in str(name).lower():
                    matches.append({"title": name, "filename": fname})
            self._search_results = matches[:15]
        
        self.searchResultsChanged.emit()
        # Also emit your existing signal just in case other components use it
        self.searchResultsUpdated.emit([item["title"] for item in self._search_results])

    # --- REST OF YOUR EXISTING METHODS (get_sub_folders, etc.) ---