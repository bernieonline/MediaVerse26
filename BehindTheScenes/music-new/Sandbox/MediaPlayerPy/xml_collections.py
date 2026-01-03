import os
import json
import threading
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from collections import Counter
from urllib.parse import quote
from PySide6.QtCore import QObject, Signal, Slot
import random  # <--- Crucial for the random posters
from project_paths import paths  # <--- Loads your relative path dictionary
# Import your centralized path definitions


class XMLCollections(QObject):
    cacheRebuilt = Signal()

    def __init__(self):
        super().__init__()

        # This stores the dictionary so get_collections_by_category can find it
        self.paths = paths


        self.master_cache = []
        self.image_lookup = {} # Map for Filename -> Thumb Path
        
        # SOURCE OF TRUTH: xml_collection_data.json
        self.manifest_path = paths["xmldate"]

        self.load_data()
        
        # INTERNAL CACHING
        self.cache_dir = Path("W:/MediaVerse/cache")
        self.cache_file = self.cache_dir / "collections_cache.json"
        
        # Initialize internal maps
        self._load_image_map()
        print(f"🛠️ XMLCollections initialized. Target: {self.manifest_path}")
    
    def load_data(self):
        """Loads the master movie data."""
        data_path = paths.get("xmldate")
        if data_path and Path(data_path).exists():
            with open(data_path, 'r', encoding='utf-8') as f:
                self.master_cache = json.load(f)
            print(f"🛠️ XMLCollections: Loaded {len(self.master_cache)} movies.")

    # start
    def _load_image_map(self):
        """Links Video Filenames to Thumbnails using relative project paths."""
        # 1. Get the paths from your central dictionary
        manifest_path = paths.get("server_manifest_v2")
        local_base = paths.get("local_thumb_v2")

        # 2. Safety Check: Ensure the manifest exists
        if manifest_path and Path(manifest_path).exists():
            with open(manifest_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                items = data if isinstance(data, list) else data.get("items", [])

                # 3. Use enumerate so 'i' is defined for your first-item test
                for i, item in enumerate(items):
                    # Extract the video ID and the relative thumbnail path
                    v_path = item.get("shared", {}).get("video")
                    #t_rel = item.get("cache", {}).get("relative_thumb")
                    t_path_raw = item.get("cache", {}).get("thumb", "") # "Cache/thumb/A Hard Days Night (1964).jpg"
                    t_rel = t_path_raw.replace("Cache/thumb/", "")     # "A Hard Days Night (1964).jpg"

                    # 4. Only proceed if we have all three components
                    if v_path and t_rel and local_base:
                        # Combine: D:/.../thumb/ + folder/image.jpg
                        thumb_path = Path(local_base) / t_rel

                        # 5. Link only if the file actually exists on your D: drive
                        if thumb_path.exists():
                            self.image_lookup[v_path] = thumb_path.as_uri()
                        
                        # Keeping your first-item check for peace of mind
                        if i == 0:
                            print(f"\n--- FIRST ITEM VERIFIED ---")
                            print(f"Target: {thumb_path}")
                            print(f"Status: {'✅ FOUND' if thumb_path.exists() else '❌ MISSING ON D: DRIVE'}")

        print(f"🖼️ Linked {len(self.image_lookup)} videos to local thumbnails.")

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
    #START
    @Slot('QVariant', result=list)
    def get_collection_images_by_rules(self, rules):
        matches = self.get_collection_results(rules)
        raw_paths = [m["filePath"] for m in matches if m.get("filePath")]
        
        if not raw_paths:
            return []

        random.shuffle(raw_paths)
        
        # This is the EXACT path from your "First Item Verified" log
        # Note: Using forward slashes for QML compatibility
        thumb_base = "D:/MediaVerse1.0/BehindTheScenes/BehindTheScenes/music-new/cacheV2/images/thumb/"
        
        final_fan_paths = []
        for path in raw_paths[:3]:
            # Get just the filename without extension (e.g., "Water (1985)")
            file_name = os.path.splitext(os.path.basename(path))[0]
            
            # Construct the path to the thumbnail
            full_thumb_path = f"{thumb_base}{file_name}.jpg"
            
            # Convert to QML-friendly file URL
            final_fan_paths.append("file:///" + full_thumb_path)
            
        return final_fan_paths
    #start
    @Slot('QVariant', result=list)
    def get_collection_results(self, criteria):
        """Filters master cache and returns data compatible with ImageGridView."""
        # --- NEW SAFETY CONVERSION ---
        # If criteria is a QJSValue (from QML), convert it to a dict
        if hasattr(criteria, 'toVariant'):
            criteria = criteria.toVariant()
        
        # Double check it's actually a dictionary now
        if not isinstance(criteria, dict) or not self.master_cache:
            print(f"⚠️ XMLCollections: Invalid criteria type: {type(criteria)}")
            return []

        results = []
        for item in self.master_cache:
            match = True
            for key, value in criteria.items():
                # --- DECADE LOGIC ---
                if key == "Decade":
                    target_decade_prefix = str(value).strip()[:3]
                    item_year = str(item.get("Year") or item.get("year") or "").strip()
                    if not item_year.startswith(target_decade_prefix):
                        match = False
                        break
                
                # --- STANDARD LOGIC ---
                else:
                    item_val = str(item.get(key, "")).lower()
                    if str(value).lower() not in item_val:
                        match = False
                        break
            
            if match:
                video_path = item.get("Filename")
                thumb_uri = self.image_lookup.get(video_path, "")
                results.append({
                    "filePath": thumb_uri, 
                    "originalPath": video_path,
                    "fileName": item.get("Title", "Unknown")
                })
        
        print(f"🔍 Builder Update: '{criteria}' found {len(results)} movies.")
        return results
    #start
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
   
    @Slot(str, result=list)
    def get_collections_by_category(self, category_key):
        # Use the path we just added to project_paths.py
        json_file = self.paths["movies_coll_v2"] 
        
        if not json_file.exists():
            return []

        with open(json_file, 'r') as f:
            all_data = json.load(f)

        # Return only the ones matching the "primary_category"
        return [item for item in all_data if item.get("primary_category") == category_key]
    

    @Slot(str, str, result=list)
    def get_filtered_keywords(self, category, filter_text):
        # SAFETY: If master_cache is empty, try to reload it once
        if not self.master_cache:
            self.load_data() 
        
        if not self.master_cache:
            return []

        all_options = set()
        query = filter_text.lower().strip()

        for item in self.master_cache:
            # 1. Get the value safely
            val = item.get(category)
            
            # 2. Handle Decade specifically
            if category == "Decade":
                year = str(item.get("Year") or item.get("year") or "")
                if year.isdigit() and len(year) >= 4:
                    all_options.add(year[:3] + "0s")
                continue

            # 3. Handle standard fields
            if val is None:
                continue
                
            if isinstance(val, list):
                all_options.update([str(v) for v in val if v])
            elif isinstance(val, str):
                if ";" in val:
                    parts = [p.strip() for p in val.split(";") if p.strip()]
                    all_options.update(parts)
                elif val.strip():
                    all_options.add(val.strip())

        # Filter out junk
        clean_list = [opt for opt in all_options if opt and str(opt).lower() != "unknown"]
        
        if not query:
            return sorted(clean_list)[:100]

        matches = [opt for opt in clean_list if query in str(opt).lower()]
        return sorted(matches)[:50]

    @Slot(result=list)
    def get_existing_collection_names(self):
        """
        FIXED: Loads from the actual V2 file instead of a missing variable.
        """
        file_path = Path("W:/MediaVerse/Collections/Movies_Collections_v2.json")
        if not file_path.exists():
            return []
            
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                library = json.load(f)
                return [str(item.get('name', '')) for item in library]
        except Exception as e:
            print(f"❌ Error reading collection names: {e}")
            return []
    
    
    
    
    @Slot(str, 'QVariant', str, bool)
    def save_collection_v2(self, name, criteria, category, is_favorite):
        """Saves collection with extra V2 metadata."""
        try:
            if hasattr(criteria, "toVariant"):
                criteria = criteria.toVariant()

            # Using your V2 path
            file_path = Path("W:/MediaVerse/Collections/Movies_Collections_v2.json")
            file_path.parent.mkdir(parents=True, exist_ok=True)

            library = []
            if file_path.exists():
                with open(file_path, 'r', encoding='utf-8') as f:
                    try: library = json.load(f)
                    except: library = []

            # Remove existing entry with same name
            library = [item for item in library if item.get("name") != name]
            
            # Save with NEW fields
            library.append({
                "name": name,
                "rules": criteria,
                "primary_category": category,
                "favorite": is_favorite,
                "created": "2026-01-01" 
            })

            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(library, f, indent=4)
            print(f"✅ Collection '{name}' saved to V2 registry.")
            return True
        except Exception as e:
            print(f"❌ V2 Save Error: {e}")
            return False
        
    @Slot(str, str, result=bool)
    def rename_collection(self, old_name, new_name):
        """
        Rename a collection in Movies_Collections_v2.json.
        """
        try:
            file_path = Path("W:/MediaVerse/Collections/Movies_Collections_v2.json")

            if not file_path.exists():
                return False

            with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            updated = False
            for item in data:
                if item.get("name") == old_name:
                    item["name"] = new_name
                    updated = True
                    break

            if not updated:
                return False

            with open(file_path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=4)

            print(f"✏️ Renamed '{old_name}' → '{new_name}'")
            return True

        except Exception as e:
            print("❌ rename_collection error:", e)
            return False
        
    @Slot(str)
    def delete_collection(self, name):
        print(f"PYTHON DEBUG: delete_collection called for '{name}'")

        try:
            file_path = Path("W:/MediaVerse/Collections/Movies_Collections_v2.json")

            if not file_path.exists():
                print("⚠️ Delete failed: JSON file does not exist.")
                return False

            # Load existing library
            with open(file_path, 'r', encoding='utf-8') as f:
                try:
                    library = json.load(f)
                except:
                    library = []

            # Remove the entry
            new_library = [item for item in library if item.get("name") != name]

            # Save back
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(new_library, f, indent=4)

            print(f"🗑️ Collection '{name}' deleted successfully.")
            return True

        except Exception as e:
            print(f"❌ Delete Error: {e}")
            return False
