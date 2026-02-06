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
        
        self.foldersUpdated.emit(sorted(list(folders)))
        self.resultsCounted.emit(-1, matches_in_folder)

    def _run_panel_search(self, source, item):
        """ Internal logic for surgical filtering """
        category = item.get("category", "")
        value = str(item.get("value", "")).strip()
        
        # HARD ZERO: Return empty list if no value is provided
        if not value or value == "":
            return []

        if category == "folder":
            target = value.replace("/", "\\").lower()
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
        search_value = str(results[0]) if results else ""
        
        # HARD ZERO: Handle empty search values immediately
        if not search_value or search_value == "" or search_value == "search_files = ":
            print(f"🚀 [Python] Committing Panel {index} | Empty | Matches: 0")
            self.resultsCounted.emit(index, 0)
            self.totalCountUpdated.emit(0)
            return

        matches = []
        
        if (mode == "search_files") or (mode == "search" and "search_files =" in search_value):
            raw_paths = search_value.split("=")[1].strip() if " = " in search_value else search_value
            manual_files = [f.replace("/", "\\").lower() for f in raw_paths.split("|") if f.strip()]
            
            matches = [
                m for m in self.library_data 
                if str(m.get("Filename", "")).replace("/", "\\").lower() in manual_files
            ]
        else:
            criteria_item = {"category": mode, "value": search_value}
            matches = self._run_panel_search(self.library_data, criteria_item)
        
        print(f"🚀 [Python] Committing Panel {index} | Mode: {mode} | Matches: {len(matches)}")
        self.resultsCounted.emit(index, len(matches))
        self.totalCountUpdated.emit(len(matches)) 
        self.saveConfirmed.emit(f"Panel {index} Logic Committed")

    @Slot(str)
    def update_live_preview(self, criteria_json):
        try:
            criteria_list = json.loads(criteria_json)
            if not criteria_list: return

            active_item = criteria_list[-1]
            active_index = active_item.get("panelIndex", 0)
            category = active_item.get("category", "")
            value = str(active_item.get("value", "")).strip()

            # HARD ZERO: Return 0 if empty
            if not value:
                self.resultsCounted.emit(active_index, 0)
                return

            matches = []

            if category == "search_files" or (category == "search" and "search_files =" in value):
                raw_paths = value.split("=")[1].strip() if " = " in value else value
                manual_files = [f.replace("/", "\\").lower() for f in raw_paths.split("|") if f.strip()]
                
                matches = [
                    m for m in self.library_data 
                    if str(m.get("Filename", "")).replace("/", "\\").lower() in manual_files
                ]
            elif category == "folder":
                target = value.replace("/", "\\").lower()
                matches = [
                    m for m in self.library_data 
                    if target in str(m.get("Filename", "")).replace("/", "\\").lower()
                ]
            else:
                mapping = {"Actors": "Actors", "Director": "Director", "Genre": "Genre"}
                search_dict = {}
                if " = " in value:
                    k, v = value.split(" = ", 1)
                    search_dict[mapping.get(k.strip(), k.strip())] = v.strip()
                else:
                    search_dict[mapping.get(category, category)] = value
                
                matches = self.collectionLogic.get_collection_results(search_dict)

            print(f"🚀 [Python] Result: {len(matches)} matches found for {category}")
            self.resultsCounted.emit(active_index, len(matches))

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
        print(f"💾 Saving Collection: {name}")
        self.saveConfirmed.emit(name)

    @Slot(str, str)
    def request_category_matches(self, category, items_str):
        search_value = f"{category} = {items_str}"
        matches = self._run_panel_search(self.library_data, {"category": category, "value": search_value})
        self.resultsCounted.emit(-1, len(matches))

    @Slot(str)
    def search_library(self, text):
        if not text or len(text) < 2:
            self._search_results = []
            self.searchResultsChanged.emit()
            return

        search_item = {"category": "Name", "value": text}
        matches = self._run_panel_search(self.library_data, search_item)
        
        formatted_results = []
        for m in matches[:15]:
            formatted_results.append({
                "title": m.get("Name", "Unknown"),
                "filename": m.get("Filename", "")
            })
            
        self._search_results = formatted_results
        self.searchResultsChanged.emit()