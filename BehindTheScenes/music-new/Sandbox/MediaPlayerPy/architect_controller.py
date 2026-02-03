import os
import json
import logging
from PySide6.QtCore import QObject, Signal, Slot, Property
from project_paths import paths

class ArchitectController(QObject):
    resultsCounted = Signal(int, int)   # (panelIndex, panelCount)
    foldersUpdated = Signal(list)
    searchResultsUpdated = Signal(list) 
    saveConfirmed = Signal(str)
    searchResultsChanged = Signal()
    

    def __init__(self, xml_logic=None):
        super().__init__()
        self.library_data = []
        self._search_results = [] 
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
    def search_library(self, query):
        if not query or len(query) < 2:
            self._search_results = []
            self.searchResultsUpdated.emit([])
            return
            
        matches_for_qml_list = []
        matches_with_paths = []
        q = query.lower()
        for m in self.library_data:
            name = str(m.get('Name', ''))
            fname = str(m.get('Filename', ''))
            if q in name.lower():
                matches_for_qml_list.append(name)
                matches_with_paths.append({"title": name, "filename": fname})
        
        self._search_results = matches_with_paths[:15]
        self.searchResultsChanged.emit()
        self.searchResultsUpdated.emit(matches_for_qml_list[:15])

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

    @Slot(str)
    def update_live_preview(self, criteria_json):
        """Processes criteria and returns panel-specific counts for the Architect HUD."""
        try:
            criteria_list = json.loads(criteria_json)
            if not criteria_list:
                return

            # --- STEP 1: Identify the Panel that just changed ---
            # We assume the last item in the list is the one the user just interacted with
            active_item = criteria_list[-1]
            active_index = active_item.get("panelIndex", 0)
            
            # Temporary variables for this specific panel's calculation
            search_dict = {}
            manual_files = []
            
            # Map UI categories to actual Manifest keys
            mapping = {"Actors": "Actors", "Director": "Director", "Genre": "Genre", 
                       "Keywords": "Keywords", "Series": "Series"}

            category = active_item["category"]
            value = active_item["value"]

            # --- STEP 2: Logic Branching (Folder vs Search vs Category) ---
            if category == "search_files":
                if value:
                    manual_files = value.split("|")
            elif category == "folder":
                # Ensure the folder path is correctly formatted for manifest lookup
                search_dict["Filename"] = value.replace("/", "\\")
            else:
                # Handle Cloud selections (e.g., "Actors = Sean Connery")
                if " = " in value:
                    key, val = value.split(" = ", 1)
                    clean_key = mapping.get(key.strip(), key.strip())
                    search_dict[clean_key] = val.strip()
                else:
                    # Direct category mapping
                    clean_key = mapping.get(category, category)
                    search_dict[clean_key] = value

            # --- STEP 3: Run the existing Quick Collection logic ---
            # If we are in 'search_files' mode, we count the manual stack
            if category == "search_files":
                matches = [m for m in self.library_data if m.get("Filename") in manual_files]
            else:
                # Use your proven collectionLogic for folders and categories
                matches = self.collectionLogic.get_collection_results(search_dict)

            # --- STEP 4: Audit and Emit ---
            match_count = len(matches)
            
            print(f"--- ARCHITECT DATA PIPE AUDIT ---")
            print(f"Panel Index: {active_index}")
            print(f"Criteria:    {category} -> {value}")
            print(f"Matches:     {match_count}")
            print(f"---------------------------------")

            # Repurposed Signal: emit(panelIndex, panelCount)
            # --- STEP 4: Audit and Emit ---
            match_count = len(matches)
            
            print(f"--- ARCHITECT DATA PIPE AUDIT ---")
            print(f"Panel Index: {active_index}")
            print(f"Criteria:    {category} -> {value}")
            print(f"Matches:     {match_count}")
            
            if match_count > 0:
                print("--- FILE LIST ---")
                for i, m in enumerate(matches, 1):
                    # Check 'fileName' (from V2 logic) or 'Name' (from library_data)
                    title = m.get('fileName') or m.get('Name') or m.get('Title') or "Unknown"
                    print(f"{i}. {title}")
            print(f"---------------------------------")
            
            
            
            
            
            
            self.resultsCounted.emit(active_index, match_count)

        except Exception as e:
            print(f"❌ Architect Preview Error: {e}")
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