import os
import json
import threading
from pathlib import Path
from collections import Counter
from PySide6.QtCore import QObject, Signal, Slot

# Import your centralized path definitions
from project_paths import paths

class XMLCollections(QObject):
    cacheRebuilt = Signal()

    def __init__(self):
        super().__init__()
        self.master_cache = []
        
        # SOURCE OF TRUTH: xml_collection_data.json (enriched metadata)
        self.manifest_path = paths["xmldate"]
        
        # INTERNAL CACHING: Optimized copy stored on W: drive
        self.cache_dir = Path("W:/MediaVerse/cache")
        self.cache_file = self.cache_dir / "collections_cache.json"
        
        print(f"🛠️ XMLCollections initialized. Target: {self.manifest_path}")

    @Slot()
    def refresh_master_cache(self):
        """Triggers a fresh scan and build of the movie-only cache."""
        self.force_rebuild()

    @Slot()
    def force_rebuild(self):
        """Threaded reload of the enriched JSON file to prevent UI lag."""
        thread = threading.Thread(target=self._threaded_scan)
        thread.daemon = True
        thread.start()

    def _threaded_scan(self):
        """Worker thread that parses JSON and filters out TV Shows immediately."""
        if not self.manifest_path.exists():
            print(f"❌ ERROR: File not found at {self.manifest_path}")
            return

        try:
            print(f"🔍 Reading and Filtering Source: {self.manifest_path}")
            with open(self.manifest_path, 'r', encoding='utf-8') as f:
                raw_data = json.load(f)
            
            # Extract the list regardless of JSON structure (list vs dict)
            items = raw_data if isinstance(raw_data, list) else raw_data.get("items", [])
            
            # --- GLOBAL FILTER: EXCLUDE TV SHOWS ---
            # This ensures Robert Taylor (Longmire) or Iain Glen (GoT) don't skew the top 10
            self.master_cache = [
                item for item in items 
                if "TV Shows" not in item.get("Filename", "")
            ]
            # ----------------------------------------

            # Update the local W: drive cache with the CLEAN list
            try:
                self.cache_dir.mkdir(parents=True, exist_ok=True)
                with open(self.cache_file, 'w', encoding='utf-8') as f:
                    json.dump(self.master_cache, f)
            except Exception as cache_err:
                print(f"⚠️ Could not write cache file: {cache_err}")

            print(f"✅ Master Cache Rebuilt (Movies Only): {len(self.master_cache)} items found.")
            self.cacheRebuilt.emit()
            
        except Exception as e:
            print(f"❌ Scan failed: {e}")

    @Slot(str, result=list)
    def get_filter_options(self, category):
        """Returns top 10 unique values for the QML Gold Buttons."""
        #tv series excluded
        if not self.master_cache:
            # Sync fallback if memory is empty
            print("⚠️ Cache empty, triggering refresh...")
            self.refresh_master_cache()
            return []

        counts = Counter()
        for item in self.master_cache:
            # Match Title Case keys found in xml_collection_data.json
            
            if category == "Actors":
                val = item.get("Actors")
                if isinstance(val, list):
                    counts.update(val)
            
            elif category == "Decade":
                val = item.get("Year")
                # Build decade string (e.g., '1973' -> '1970s')
                if val and str(val).isdigit() and len(str(val)) >= 4:
                    counts.update([str(val)[:3] + "0s"])
            
            elif category in ["Genre", "Keywords"]:
                val = item.get(category)
                if val and isinstance(val, str):
                    # Handle semicolon separated metadata
                    parts = [x.strip() for x in val.split(";") if x.strip()]
                    counts.update(parts)
            
            else:
                # Direct match for Director, Name, etc.
                val = item.get(category)
                if val and isinstance(val, str):
                    counts.update([val.strip()])

        # Filter out 'Unknown' and empty results, then take top 10
        top_10 = [name for name, count in counts.most_common(10) 
                  if name and str(name).lower() != "unknown"]
        
        print(f"📡 DATA READY ({category}): {top_10}")
        return top_10

    @Slot('QVariant', result=list)
    def get_collection_results(self, criteria):
        """Returns matching objects for the grid. Handles translation between QML and JSON keys."""
        if not self.master_cache:
            return []
            
        # Convert QML JavaScript object to Python Dictionary
        if hasattr(criteria, "toVariant"):
            criteria = criteria.toVariant()

        if not criteria or not isinstance(criteria, dict):
            return self.master_cache

        results = []
        for item in self.master_cache:
            match = True
            for key, val in criteria.items():
                if not val:
                    continue
                
                # --- CATEGORY TRANSLATION LOGIC ---
                
                # 1. Handle Actors (List check)
                if key == "Actors":
                    if val not in item.get("Actors", []):
                        match = False
                
                # 2. Handle Decade (Year prefix check)
                elif key == "Decade":
                    # val is '1970s', year is '1973'
                    yr = str(item.get("Year", ""))
                    if not yr.startswith(str(val)[:3]):
                        match = False
                
                # 3. Handle Genre and Keywords (String contains check)
                elif key in ["Genre", "Keywords"]:
                    # JSON stores these as "Drama; Action"
                    if val not in item.get(key, ""):
                        match = False
                
                # 4. Handle Everything Else (Director, etc.)
                else:
                    if str(item.get(key)) != str(val):
                        match = False
            
            if match:
                results.append(item)
        
        print(f"🔍 Filter applied: {criteria} | Found: {len(results)} movies")
        return results
    

    
    @Slot(str, 'QVariant')
    def save_collection_template(self, name, criteria):
        """Saves current filters to a named collection on W: drive."""
        try:
            # --- FIX: Convert JavaScript object to Python Dictionary ---
            if hasattr(criteria, "toVariant"):
                criteria = criteria.toVariant()
            # -----------------------------------------------------------

            save_path = Path("W:/MediaVerse/collections")
            save_path.mkdir(parents=True, exist_ok=True)
            
            # Use the collection name as the filename
            file_path = save_path / f"{name}.json"
            
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(criteria, f, indent=4)
                
            print(f"💾 Collection Saved Successfully: {file_path}")
            print(f"📄 Data Saved: {criteria}")
            return True
            
        except Exception as e:
            print(f"❌ Save Failed: {e}")
            return False