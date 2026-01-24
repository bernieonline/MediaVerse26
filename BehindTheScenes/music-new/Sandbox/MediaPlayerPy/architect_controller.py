import os
import json
import logging
from PySide6.QtCore import QObject, Signal, Slot
from project_paths import paths

class ArchitectController(QObject):
    """
    The Brain of the Collection Architect.
    Processes JRiver XML sidecar data with support for '=' delimiters.
    """
    resultsCounted = Signal(int)
    foldersUpdated = Signal(list)
    searchResultsUpdated = Signal(list)
    saveConfirmed = Signal(str)

    def __init__(self):
        super().__init__()
        self.library_data = []
        self.last_filtered_results = []
        self.load_library()

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

    @Slot(str)
    def update_live_preview(self, logic_json):
        """
        Parses rules like 'Director = Martin Scorsese' and filters the library.
        """
        try:
            rules = json.loads(logic_json)
            filtered = self.library_data 

            for rule in rules:
                # Based on your log: [{"type":"category","value":"Director = Martin Scorsese"}]
                rule_text = rule.get("value", "")
                
                # Support both '=' from your UI and ':' just in case
                delimiter = "=" if "=" in rule_text else ":"
                
                if delimiter not in rule_text:
                    continue
                
                # Split "Director = Martin Scorsese" -> ["Director", "Martin Scorsese"]
                raw_cat, raw_val = rule_text.split(delimiter, 1)
                
                cat = raw_cat.strip().lower()
                val = raw_val.strip().lower()

                if not val:
                    continue

                # --- FILTERING ---
                if cat == "director":
                    # Exact string match against 'Director' key
                    filtered = [m for m in filtered if str(m.get('Director', '')).lower() == val]
                
                elif cat == "actors":
                    # Check list membership
                    filtered = [m for m in filtered if any(val == str(a).lower() for a in m.get('Actors', []))]
                
                elif cat == "genre":
                    # Split semicolon string "Drama;Crime"
                    filtered = [m for m in filtered if val in str(m.get('Genre', '')).lower().split(';')]

                elif cat == "year" or cat == "decade":
                    # Handle ranges like "1960 - 1969" or single years
                    clean_val = val.replace("year", "").replace("decade", "").replace("=", "").strip()
                    if "-" in clean_val:
                        try:
                            s_str, e_str = clean_val.split("-")
                            start, end = int(s_str.strip()), int(e_str.strip())
                            filtered = [m for m in filtered if m.get('Year') and start <= int(str(m.get('Year'))) <= end]
                        except: continue
                    else:
                        filtered = [m for m in filtered if str(m.get('Year')) == clean_val]

                elif cat == "folder":
                    filtered = [m for m in filtered if val in str(m.get('Filename', '')).lower()]

            # Update results
            self.last_filtered_results = filtered
            self.resultsCounted.emit(len(filtered))
            
            print(f"✅ Filter Success: '{val}' found {len(filtered)} matches.")

        except Exception as e:
            print(f"❌ Filter Error: {e}")
            self.resultsCounted.emit(0)

    @Slot(str)
    def search_library(self, query):
        """Live search for the search card mode."""
        if not query or len(query) < 2:
            self.searchResultsUpdated.emit([])
            return
        results = [m.get('Name', 'Unknown') for m in self.library_data 
                   if query.lower() in str(m.get('Name', '')).lower()]
        self.searchResultsUpdated.emit(results[:15])

    @Slot(str, str)
    def save_collection(self, name, logic_json):
        """Finalize the filtered list for storage."""
        logging.info(f"💾 Saving {len(self.last_filtered_results)} items to {name}")
        self.saveConfirmed.emit(name)