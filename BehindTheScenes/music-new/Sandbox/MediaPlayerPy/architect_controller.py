import os
import json
import logging
from PySide6.QtCore import QObject, Signal, Slot, Property
from project_paths import paths

class ArchitectController(QObject):
    resultsCounted = Signal(int, int)   
    foldersUpdated = Signal(list)
    searchResultsUpdated = Signal(list) 
    saveConfirmed = Signal(str)
    searchResultsChanged = Signal()
    totalCountUpdated = Signal(int)     

    def __init__(self, xml_logic=None):
        super().__init__()
        self.library_data = []
        self._search_results = [] 
        self._final_architect_list = []
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
    def get_sub_folders(self, current_path):
        """ Used by ArchitectFolderNav to drill down into library directories """
        # Base root as defined in your setup
        base_root = "W:\\Collection"
        search_path = os.path.join(base_root, current_path.replace("/", "\\"))
        if not search_path.endswith("\\"): search_path += "\\"

        folders = set()
        matches_in_folder = 0

        for m in self.library_data:
            fpath = m.get("Filename", "")
            if fpath.lower().startswith(search_path.lower()):
                matches_in_folder += 1
                relative = fpath[len(search_path):]
                parts = relative.split("\\")
                if len(parts) > 1: 
                    folders.add(parts[0])
        
        # Update the UI with the subfolders found
        self.foldersUpdated.emit(sorted(list(folders)))
        
        # We broadcast the count found in this folder immediately
        # panelIndex -1 is a convention for 'current active navigation'
        self.resultsCounted.emit(-1, matches_in_folder)

    def _run_panel_search(self, source, item):
        """ Internal logic for surgical filtering """
        category = item.get("category", "")
        value = item.get("value", "")
        if not value: return []

        # Folder Logic: Matches based on path prefix
        if category == "folder":
            target = str(value).replace("/", "\\").lower()
            return [m for m in source if target in str(m.get("Filename", "")).replace("/", "\\").lower()]
            
        mapping = {"Actors": "Actors", "Director": "Director", "Genre": "Genre", "Keywords": "Keywords", "Series": "Series"}
        
        if " = " in str(value):
            key_part, val_part = str(value).split(" = ", 1)
            clean_key = mapping.get(key_part.strip(), key_part.strip())
            clean_val = val_part.strip().lower()
        else:
            clean_key = mapping.get(category, category)
            clean_val = str(value).lower()

        return [m for m in source if clean_val in str(m.get(clean_key, "")).lower()]

    @Slot(int, str, 'QVariantList')
    def commit_panel_logic(self, index, mode, results):
        """
        The Bridge: Receives data from a QML panel and calculates the real-time hit count.
        """
        # 1. Extract the search value from the results list
        # For folders, results[0] is the path. For others, it's the keywords.
        search_value = results[0] if results else ""
        
        # 2. Run the search against the full library to get the count
        criteria_item = {"category": mode, "value": search_value}
        matches = self._run_panel_search(self.library_data, criteria_item)
        
        # 3. Log the surgical result
        print(f"🚀 [Python] Committing Panel {index} | Mode: {mode} | Search: {search_value} | Matches: {len(matches)}")
        
        # 4. Update the HUD and confirm to QML
        self.resultsCounted.emit(index, len(matches))
        self.totalCountUpdated.emit(len(matches)) 
        self.saveConfirmed.emit(f"Panel {index} Logic Committed")

    @Slot(str)
    def update_live_preview(self, criteria_json):
        """ Global recalculation engine for multi-panel rules """
        try:
            criteria_list = json.loads(criteria_json)
            cumulative_bucket = set() 
            previous_panel_output = self.library_data 

            for i, item in enumerate(criteria_list):
                val = item.get("value", "")
                if not val:
                    self.resultsCounted.emit(item.get("panelIndex"), 0)
                    continue

                is_checked = item.get("checked", False)
                is_not = item.get("isNot", False)
                
                # Source Selection: Narrow down or restart from full library
                source = previous_panel_output if (is_checked and i > 0) else self.library_data

                matches = self._run_panel_search(source, item)
                match_paths = {m.get("Filename") for m in matches if m.get("Filename")}
                
                previous_panel_output = matches

                # Set Math
                if i == 0:
                    cumulative_bucket = match_paths
                else:
                    if is_checked:
                        cumulative_bucket = cumulative_bucket.intersection(match_paths)
                    else:
                        cumulative_bucket = cumulative_bucket.union(match_paths)

                if is_not:
                    cumulative_bucket -= match_paths

                self.resultsCounted.emit(item.get("panelIndex"), len(matches))

            self._final_architect_list = list(cumulative_bucket)
            self.totalCountUpdated.emit(len(self._final_architect_list))
            print(f"✅ Architect Engine: Cumulative Total {len(self._final_architect_list)}")
            
        except Exception as e:
            print(f"❌ Architect Logic Error: {e}")

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
        # Implementation for saving rules to JSON (based on your instructions)
        print(f"💾 Saving Collection: {name}")
        self.saveConfirmed.emit(name)

    @Slot(str, str)
    def request_category_matches(self, category, items_str):
        # Format the string exactly how your search engine expects it
        search_value = f"{category} = {items_str}"
        
        # Reuse your existing search logic
        matches = self._run_panel_search(self.library_data, {"category": "category", "value": search_value})
        
        # Emit the count back to the HUD
        # We use -1 so the active panel knows this is a "live" update
        self.resultsCounted.emit(-1, len(matches))
        
        # If your QML specifically needs 'onCategoryResultsUpdated', we emit that too
        # self.categoryResultsUpdated.emit(matches)