import os
import json
import threading
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from collections import Counter
from urllib.parse import quote
from PySide6.QtCore import QObject, Signal, Slot

# Import your centralized path definitions
from project_paths import paths

class XMLCollections(QObject):
    cacheRebuilt = Signal()

    def __init__(self):
        super().__init__()
        self.master_cache = []
        self.image_lookup = {} # Map for Filename -> Thumb Path
        
        # SOURCE OF TRUTH: xml_collection_data.json
        self.manifest_path = paths["xmldate"]
        
        # INTERNAL CACHING
        self.cache_dir = Path("W:/MediaVerse/cache")
        self.cache_file = self.cache_dir / "collections_cache.json"
        
        # Initialize internal maps
        self._load_image_map()
        print(f"🛠️ XMLCollections initialized. Target: {self.manifest_path}")

    def _load_image_map(self):
        """Pre-loads the v2 manifest so we can instantly find posters for collections."""
        source_manifest = paths.get("server_manifest_v2")
        if source_manifest and source_manifest.exists():
            try:
                with open(source_manifest, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    items = data.get("items", [])
                    # Lookup: { "D:/Movies/Gladiator.mp4": "thumb/path.jpg" }
                    self.image_lookup = { 
                        item["shared"]["video"]: item["cache"].get("relative_thumb") 
                        for item in items if "shared" in item and "cache" in item
                    }
                print(f"🖼️ Image lookup map built: {len(self.image_lookup)} links.")
            except Exception as e:
                print(f"⚠️ Image map build failed: {e}")

    @Slot(result='QVariant')
    def load_collections_list(self):
        """Reads the gallery card definitions for the QML Loader."""
        path = Path("W:/MediaVerse/Collections/Movies_Collections.json")
        try:
            if path.exists():
                with open(path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    print(f"📂 UI requested Collections List: Found {len(data)} cards.")
                    return data
            return []
        except Exception as e:
            print(f"❌ Error loading collections list: {e}")
            return []

    @Slot('QVariant', result=list)
    def get_collection_images_by_rules(self, rules):
        """Returns matching local thumb URLs based on the card rules."""
        # Use existing filter logic
        matches = self.get_collection_results(rules)
        image_urls = []

        # Target thumb directory (adjust if your project_paths has a specific thumb root)
        thumb_root = Path("D:/MediaVerse1.0/BehindTheScenes/BehindTheScenes/music-new/Assets/Cache/thumb")

        for movie in matches:
            v_path = movie.get("Filename")
            rel_thumb = self.image_lookup.get(v_path)
            if rel_thumb:
                full_path = thumb_root / rel_thumb
                if full_path.exists():
                    image_urls.append(full_path.as_uri())
        
        return image_urls

    @Slot('QVariant', result=list)
    def get_collection_results(self, criteria):
        """Core filtering engine. Handles both single and (eventually) multiple criteria."""
        if not self.master_cache:
            return []
            
        # Convert JS Object to Python Dict
        if hasattr(criteria, "toVariant"):
            criteria = criteria.toVariant()

        if not criteria or not isinstance(criteria, dict):
            return self.master_cache

        results = []
        for item in self.master_cache:
            match = True
            for key, val in criteria.items():
                if not val: continue
                
                # 1. Actors (List)
                if key == "Actors":
                    if val not in item.get("Actors", []):
                        match = False
                
                # 2. Decade (String Prefix)
                elif key == "Decade":
                    yr = str(item.get("Year", ""))
                    if not yr.startswith(str(val)[:3]):
                        match = False
                
                # 3. Genre/Keywords (Semicolon String)
                elif key in ["Genre", "Keywords"]:
                    if val not in item.get(key, ""):
                        match = False
                
                # 4. Direct Match (Director, Series, Name)
                else:
                    if str(item.get(key)) != str(val):
                        match = False
            
            if match:
                results.append(item)
        
        return results

    @Slot(str, result=list)
    def get_filter_options(self, category):
        """Calculates Top 10 for the Sidebar buttons."""
        if not self.master_cache:
            self.refresh_master_cache()
            return []

        counts = Counter()
        for item in self.master_cache:
            if category == "Actors":
                val = item.get("Actors")
                if isinstance(val, list): counts.update(val)
            
            elif category == "Decade":
                val = item.get("Year")
                if val and str(val).isdigit() and len(str(val)) >= 4:
                    counts.update([str(val)[:3] + "0s"])
            
            elif category in ["Genre", "Keywords"]:
                val = item.get(category)
                if val and isinstance(val, str):
                    parts = [x.strip() for x in val.split(";") if x.strip()]
                    counts.update(parts)
            else:
                val = item.get(category)
                if val and isinstance(val, str):
                    counts.update([val.strip()])

        top_10 = [name for name, count in counts.most_common(10) 
                  if name and str(name).lower() != "unknown"]
        return top_10

    @Slot(str, 'QVariant')
    def save_collection_template(self, name, criteria):
        """Saves a new collection rule-set to the JSON gallery."""
        try:
            if hasattr(criteria, "toVariant"):
                criteria = criteria.toVariant()

            file_path = Path("W:/MediaVerse/Collections/Movies_Collections.json")
            file_path.parent.mkdir(parents=True, exist_ok=True)

            library = []
            if file_path.exists():
                with open(file_path, 'r', encoding='utf-8') as f:
                    try:
                        library = json.load(f)
                    except: library = []

            # Deduplicate by name
            library = [item for item in library if item.get("name") != name]
            
            library.append({
                "name": name,
                "rules": criteria,
                "created": "2025-12-29"
            })

            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(library, f, indent=4)
            return True
        except Exception as e:
            print(f"❌ Registry Save Error: {e}")
            return False

    @Slot()
    def refresh_master_cache(self):
        self.force_rebuild()

    @Slot()
    def force_rebuild(self):
        thread = threading.Thread(target=self._threaded_scan)
        thread.daemon = True
        thread.start()

    def _threaded_scan(self):
        if not self.manifest_path.exists():
            return

        try:
            with open(self.manifest_path, 'r', encoding='utf-8') as f:
                raw_data = json.load(f)
            
            items = raw_data if isinstance(raw_data, list) else raw_data.get("items", [])
            
            # Movies Only Filter
            self.master_cache = [
                item for item in items 
                if "TV Shows" not in item.get("Filename", "")
            ]

            # Save clean cache
            self.cache_dir.mkdir(parents=True, exist_ok=True)
            with open(self.cache_file, 'w', encoding='utf-8') as f:
                json.dump(self.master_cache, f)

            self.cacheRebuilt.emit()
            print(f"✅ Master Cache Rebuilt: {len(self.master_cache)} movies.")
            
        except Exception as e:
            print(f"❌ Scan failed: {e}")

    def _extract_sidecar_metadata(self, video_path, xml_path, cache_info):
        year_match = re.search(r"\((\d{4})\)", video_path.name)
        extracted_year = year_match.group(1) if year_match else ""

        data = {
            "Filename": str(video_path),
            "Year": extracted_year,
            "Genre": "", "Keywords": "", "Actors": [],
            "Director": "Unknown", "Name": video_path.stem.split(' (')[0],
            "Series": "", "Media Sub Type": "Movie"
        }

        if xml_path.exists():
            try:
                tree = ET.parse(xml_path)
                root = tree.getroot()
                def get_f(n):
                    node = root.find(f".//Field[@Name='{n}']")
                    return node.text if node is not None and node.text else ""

                data.update({
                    "Genre": get_f("Genre"), "Keywords": get_f("Keywords"),
                    "Director": get_f("Director") or "Unknown", "Series": get_f("Series")
                })
                
                act = get_f("Actors")
                if act:
                    data["Actors"] = [a.strip() for a in act.split(";") if a.strip()][:5]
            except: pass
        return data