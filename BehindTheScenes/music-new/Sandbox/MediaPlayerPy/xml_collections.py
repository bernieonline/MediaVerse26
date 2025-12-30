import os
import json
import threading
from pathlib import Path
from collections import Counter
from PySide6.QtCore import QObject, Signal, Slot

# Import your centralized path definitions
from project_paths import paths

import re  # <--- Add this line
import xml.etree.ElementTree as ET
from urllib.parse import quote
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
        """Adds a collection recipe to the master registry for the Display Window."""
        try:
            if hasattr(criteria, "toVariant"):
                criteria = criteria.toVariant()

            file_path = Path("W:/MediaVerse/collections/Movies_Collections.json")
            file_path.parent.mkdir(parents=True, exist_ok=True)

            # 1. Load the existing Library
            library = []
            if file_path.exists():
                with open(file_path, 'r', encoding='utf-8') as f:
                    try:
                        library = json.load(f)
                    except: library = []

            # 2. Overwrite if name exists, otherwise append
            library = [item for item in library if item.get("name") != name]
            
            # 3. Store the 'Recipe'
            new_collection = {
                "name": name,
                "rules": criteria,
                "created": "2025-12-29" # Useful for sorting cards by 'Newest'
            }
            library.append(new_collection)

            # 4. Save
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(library, f, indent=4)
                
            print(f"✅ Collection '{name}' added to Library.")
            return True
        except Exception as e:
            print(f"❌ Registry Save Error: {e}")
            return False
        

    def _extract_sidecar_metadata(self, video_path, xml_path, cache_info):
        """Helper to parse J.River XML and map local/server image paths."""
        
        # 1. Year Extraction from filename
        year_match = re.search(r"\((\d{4})\)", video_path.name)
        extracted_year = year_match.group(1) if year_match else ""

        # 2. Image Path Logic
        rel_thumb = cache_info.get("relative_thumb", "")
        local_img = paths["local_thumb_v2"] / rel_thumb
        server_img = f"file:///W:/MediaVerse/cache/images/thumb/{quote(rel_thumb)}"
        final_thumb = f"file:///{local_img}" if local_img.exists() else server_img

        # Initial structure
        data = {
            "Filename": str(video_path),
            "Year": extracted_year,
            "Genre": "",
            "Keywords": "",
            "Actors": [],
            "Director": "Unknown",
            "Name": video_path.stem.split(' (')[0],
            "Series": "",
            "Thumb_URL": final_thumb,
            "Display_URL": final_thumb.replace("thumb", "display")
        }

        # 3. Parse J.River XML
        if xml_path.exists():
            try:
                tree = ET.parse(xml_path)
                root = tree.getroot()
                
                # Define helper function here, at the start of the XML block
                def get_field(name):
                    node = root.find(f".//Field[@Name='{name}']")
                    return node.text if node is not None and node.text else ""

                # Now use it safely
                data["Genre"] = get_field("Genre")
                data["Keywords"] = get_field("Keywords")
                data["Director"] = get_field("Director") or "Unknown"
                
                data.update({
                    "IMDb ID": get_field("IMDb ID"),
                    "Media Sub Type": get_field("Media Sub Type"),
                    "Series": get_field("Series"),
                    "Season": get_field("Season"),
                    "Episode": get_field("Episode"),
                    "TheTVDB Series ID": get_field("TheTVDB Series ID"),
                    "TheMovieDB Series ID": get_field("TheMovieDB Series ID")
                })
                
                actors_raw = get_field("Actors")
                if actors_raw:
                    actor_list = [a.strip() for a in actors_raw.split(";") if a.strip()]
                    data["Actors"] = actor_list[:5]

            except Exception as e:
                print(f"⚠️ XML Parse Error for {video_path.name}: {e}")

        return data
    
    @Slot()
    def build_collection_data_json(self):
        source_manifest = paths.get("server_manifest_v2")
        output_json = paths.get("xmldate")

        if not source_manifest or not source_manifest.exists():
            return

        def run_build():
            # 1. NOTIFY START
            from NotificationManager import notifier # Import locally if not at top
            notifier.post_notification("🔍 Starting Deep Metadata Scan...", False)
            
            print("🚀 Starting deep scan of J.River XML sidecars...")
            try:
                with open(source_manifest, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                
                raw_items = data.get("items", [])
                total_items = len(raw_items)
                enriched_data = []
                
                for index, item in enumerate(raw_items):
                    shared = item.get("shared", {})
                    cache_info = item.get("cache", {})
                    v_str, x_str = shared.get("video"), shared.get("xml")
                    
                    if v_str and x_str:
                        movie_entry = self._extract_sidecar_metadata(
                            Path(v_str), Path(x_str), cache_info
                        )
                        enriched_data.append(movie_entry)

                    # 2. OPTIONAL: NOTIFY PROGRESS (Every 100 items)
                    if index > 0 and index % 100 == 0:
                        notifier.post_notification(f"⏳ Processed {index} of {total_items}...", False)

                # Save the file
                output_json.parent.mkdir(parents=True, exist_ok=True)
                with open(output_json, 'w', encoding='utf-8') as f:
                    json.dump(enriched_data, f, indent=4)
                
                # 3. NOTIFY SUCCESS
                notifier.post_notification(f"✅ Collection Ready: {len(enriched_data)} movies scanned.", False)
                print(f"✅ DNA Bank Created: {len(enriched_data)} items saved.")
                
                self.refresh_master_cache()

            except Exception as e:
                notifier.post_notification("❌ Metadata Build Failed!", True)
                print(f"❌ CRITICAL BUILD ERROR: {e}")
                import traceback
                traceback.print_exc()

        threading.Thread(target=run_build, daemon=True).start()