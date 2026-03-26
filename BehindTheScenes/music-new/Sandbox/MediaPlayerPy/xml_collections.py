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
import XMLCollectionBuilder
from json_safe import safe_json_write, safe_json_read, _backup_candidates

class XMLCollections(QObject):
    cacheRebuilt = Signal()

    def __init__(self):
        super().__init__()
        self.paths = paths
        self.master_cache = []
        self.image_lookup = {} 

        # 1. SETUP PATHS
        self.manifest_path = Path(paths.get("xmldate")) if paths.get("xmldate") else None
        self.source_manifest = Path(paths.get("server_manifest_v2")) if paths.get("server_manifest_v2") else None
        self.cache_dir = paths.get("server_cache_root_v2")
        self.cache_file = Path(self.cache_dir) / "collections_cache.json" if self.cache_dir else None

        # 2. SURGICAL SYNC LOGIC
        if not self.manifest_path:
            print("❌ [INIT] ERROR: 'xmldate' missing from project_paths.py!")
            return

        rebuild_reason = None
        if not self.manifest_path.exists():
            rebuild_reason = "File missing"
        elif self.source_manifest and self.source_manifest.exists():
            # Only compare if both exist; rebuild if source is newer
            if self.source_manifest.stat().st_mtime > self.manifest_path.stat().st_mtime:
                rebuild_reason = "Source manifest updated"

        # 3. EXECUTE BUILDER IF NECESSARY
        if rebuild_reason:
            print(f"🔄 [INIT xml_collection_data] {rebuild_reason}. Triggering XMLCollectionBuilder...")
            import XMLCollectionBuilder
            build_result = XMLCollectionBuilder.build_dna_bank()
            if not build_result.get("success"):
                print(f"⚠️ [INIT xml_collection_data] Build failed: {build_result.get('error')} — loading previous data.")
        else:
            print(f"✅ [INIT] DNA Bank is up to date: {self.manifest_path}")

        # 4. LOAD DATA
        self.load_data()
        self._load_image_map()
        print(f"🛠️ XMLCollections initialized.")
    def load_data(self):
        """Loads the master movie data."""
        data_path = paths.get("xmldate")
        if not data_path:
            print(f"❌ [DATA DEBUG] Load aborted: 'xmldate' path not configured.")
            return
        self.master_cache = safe_json_read(data_path, "xml_collection_data")
        if self.master_cache:
            print(f"🛠️ [DATA DEBUG] Successfully loaded {len(self.master_cache)} movies.")
        else:
            print(f"❌ [DATA DEBUG] Load failed or empty: {data_path}")
    # start
    def _load_image_map(self):
        """Links Video Filenames to Thumbnails using relative project paths."""
        # 1. Get the paths from your central dictionary
        manifest_path = paths.get("server_manifest_v2")
        local_base = paths.get("local_thumb_v2")

        # 2. Safety Check: Ensure the manifest exists
        if manifest_path and Path(manifest_path).exists():
            data = safe_json_read(manifest_path)
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

        print(f"!!! HANDSHAKE SUCCESS !!! Called with rules: {rules}")

        # DEBUG 1: What did QML actually send?
        print(f"\n[FAN DEBUG] Incoming Rules: {rules}")

        matches = self.get_collection_results(rules)
        raw_paths = [m["filePath"] for m in matches if m.get("filePath")]

        # DEBUG 2: How many movies did the logic find?
        print(f"[FAN DEBUG] Logic found {len(matches)} matches for these rules.")
        
        if not raw_paths:
            return []

        random.shuffle(raw_paths)
        # raw_paths are already correct thumb URIs from image_lookup — return directly
        return raw_paths[:3]
    #start
    @Slot('QVariant', result=list)
    def get_collection_results(self, criteria):
        if hasattr(criteria, 'toVariant'):
            criteria = criteria.toVariant()
        
        results = []
        print(f"\n📂 --- DEEP DATA TRACE ---")
        
        for item in self.master_cache:
            match = True
            for key, value in criteria.items():
                # --- LEAST DISRUPTIVE BRANCHING START ---
                if key == "Decade":
                    # 1. The Slice: Turn "1980s" into "198"
                    target_prefix = str(value)[:3]
                    # 2. The Redirect: Look at "Year" field instead of "Decade"
                    item_year = str(item.get("Year") or item.get("year", ""))

                    # DEBUG: See the logic in action
                    # print(f"[DECADE TRACE] Testing: {item.get('Title')} ({item_year}) against Prefix: {target_prefix}")
                    
                    if not item_year.startswith(target_prefix):
                        match = False
                        break
                    continue  # Successfully handled, skip the standard logic below
                # --- LEAST DISRUPTIVE BRANCHING END -

                # Flexible key check (handles Filename or filename)
                item_val = str(item.get(key) or item.get(key.lower(), "")).lower()
                if str(value).lower() not in item_val:
                    match = False
                    break
            
            if match:
                v_path = item.get("Filename") or item.get("shared", {}).get("video")
                thumb_uri = self.image_lookup.get(v_path, "")
                
                # FALLBACK LOGIC: If Title is missing, use the filename from the path
                raw_title = item.get("Title") or item.get("title")
                display_name = raw_title if raw_title else os.path.basename(v_path) if v_path else "Total Unknown"

                if thumb_uri:
                    results.append({
                        "filePath": thumb_uri, 
                        "originalPath": v_path,
                        "fileName": display_name
                    })
                    # PRINT THE TRUTH:
                    #print(f"MATCH {len(results)}: {display_name} | Path: {v_path}")

        return results
    @Slot(str, result=list)
    def get_filter_options(self, category):
        """Calculates Top 10 for the Sidebar buttons."""
        if not self.master_cache:
            self.refresh_master_cache()
            return []

        counts = Counter()
        print("============  inside row 179   ============")

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

            file_path = paths.get("movies_coll_v2")
            file_path.parent.mkdir(parents=True, exist_ok=True)

            library = safe_json_read(file_path, "collections")

            # Deduplicate by name
            library = [item for item in library if item.get("name") != name]
            
            library.append({
                "name": name,
                "rules": criteria,
                "created": "2025-12-29"
            })

            safe_json_write(file_path, library)
            return True
        except Exception as e:
            print(f"❌ Registry Save Error: {e}")
            return False

    @Slot()
    def rebuild_after_manifest_change(self):
        """
        Called when the manifest background thread swaps in a new manifest.json.
        Rebuilds xml_collection_data.json from scratch (reads all sidecar XML files),
        then reloads master_cache so search/filter results are current without a restart.
        Runs in a background thread — does not block the UI.
        """
        def _run():
            try:
                from NotificationManager import notifier
                print("[XMLCollections] manifest changed — rebuilding xml_collection_data.json...")
                import XMLCollectionBuilder
                build_result = XMLCollectionBuilder.build_dna_bank()
                if build_result.get("success"):
                    self.load_data()
                    msg = (
                        f"Collection data rebuilt: {build_result['accepted']} movies"
                        + (f" | {build_result['xml_parse_errors']} XML errors" if build_result.get('xml_parse_errors') else "")
                        + (f" | {build_result['blank_metadata_count']} blank metadata" if build_result.get('blank_metadata_count') else "")
                    )
                    notifier.post_notification(msg, False)
                    print(f"[XMLCollections] rebuild complete — {len(self.master_cache)} movies in cache.")
                else:
                    err = build_result.get("error", "Unknown error")
                    notifier.post_notification(f"Collection data rebuild failed: {err}", True)
                    print(f"[XMLCollections] rebuild failed — keeping previous data. Reason: {err}")
            except Exception as e:
                print(f"[XMLCollections] rebuild_after_manifest_change failed: {e}")

        thread = threading.Thread(target=_run, daemon=True)
        thread.start()

    @Slot()
    def force_rebuild_xml_collection_data(self):
        """
        Recovery tool: force a full rebuild of xml_collection_data.json on demand,
        regardless of whether the manifest has changed. Useful when the file is
        suspected corrupt or out of date.
        """
        self.rebuild_after_manifest_change()

    @Slot(str, result=bool)
    def restore_from_backup(self, file_key):
        """
        Recovery tool: replace a critical JSON file with its most recent backup.

        file_key options:
          "collections"        → Movies_Collections_v2.json  (_bak1 or .bak)
          "xml_collection_data"→ xml_collection_data.json    (.bak)
          "config"             → Config.json                 (.bak)
          "manifest"           → manifest.json               (.bak)

        Returns True on success, False on failure.
        """
        key_to_path = {
            "collections":         Path(paths["movies_coll_v2"]),
            "xml_collection_data": Path(paths["xmldate"]),
            "config":              Path(paths["config"]),
            "manifest":            Path(paths["server_manifest_v2"]),
        }

        target = key_to_path.get(file_key)
        if target is None:
            print(f"[XMLCollections] restore_from_backup: unknown key '{file_key}'")
            return False

        candidates = _backup_candidates(target)
        for bak in candidates:
            if bak.exists():
                try:
                    import shutil
                    shutil.copy2(bak, target)
                    msg = f"✅ '{target.name}' restored from {bak.name}"
                    print(f"[XMLCollections] {msg}")
                    from NotificationManager import notifier
                    notifier.post_notification(msg, False)
                    return True
                except Exception as e:
                    print(f"[XMLCollections] restore_from_backup failed: {e}")
                    return False

        msg = f"⚠️ No backup found for '{target.name}'"
        print(f"[XMLCollections] {msg}")
        from NotificationManager import notifier
        notifier.post_notification(msg, True)
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
            raw_data = safe_json_read(self.manifest_path)
            items = raw_data if isinstance(raw_data, list) else raw_data.get("items", [])
            
            # Movies Only Filter
            self.master_cache = [
                item for item in items 
                if "TV Shows" not in item.get("Filename", "")
            ]

            # Save clean cache
            self.cache_dir.mkdir(parents=True, exist_ok=True)
            safe_json_write(self.cache_file, self.master_cache)

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
        
        all_data = safe_json_read(json_file, "collections")
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
        print("============  inside row 330   ============")

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
            
        library = safe_json_read(file_path, "collections")
        return [str(item.get('name', '')) for item in library]
    
    
    
    
    @Slot(str, 'QVariant', str, bool)
    def save_collection_v2(self, name, criteria, category, is_favorite):
        """Saves collection with extra V2 metadata."""
        try:
            if hasattr(criteria, "toVariant"):
                criteria = criteria.toVariant()

            # Using your V2 path
            file_path = Path("W:/MediaVerse/Collections/Movies_Collections_v2.json")
            file_path.parent.mkdir(parents=True, exist_ok=True)

            library = safe_json_read(file_path, "collections")

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

            safe_json_write(file_path, library)
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

            data = safe_json_read(file_path, "collections")

            updated = False
            for item in data:
                if item.get("name") == old_name:
                    item["name"] = new_name
                    updated = True
                    break

            if not updated:
                return False

            safe_json_write(file_path, data)

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

            library = safe_json_read(file_path, "collections")

            # Remove the entry
            new_library = [item for item in library if item.get("name") != name]

            # Save back
            safe_json_write(file_path, new_library)

            print(f"🗑️ Collection '{name}' deleted successfully.")
            return True

        except Exception as e:
            print(f"❌ Delete Error: {e}")
            return False

    @Slot(str)
    def toggle_favorite(self, name):
        print(f"PYTHON DEBUG: toggle_favorite called for '{name}'")

        try:
            file_path = Path("W:/MediaVerse/Collections/Movies_Collections_v2.json")

            if not file_path.exists():
                print("⚠️ Favorite toggle failed: JSON file does not exist.")
                return False

            library = safe_json_read(file_path, "collections")

            # Modify the matching entry
            updated = False
            for item in library:
                if item.get("name") == name:
                    item["favorite"] = not item.get("favorite", False)
                    updated = True
                    break

            if not updated:
                print(f"⚠️ Favorite toggle failed: '{name}' not found.")
                return False

            # Save back
            safe_json_write(file_path, library)

            print(f"⭐ Favorite toggled for '{name}'.")
            return True

        except Exception as e:
            print(f"❌ Favorite Toggle Error: {e}")
            return False
    @Slot(str, str)
    def rename_collection(self, old_name, new_name):
        print(f"PYTHON DEBUG: rename_collection '{old_name}' -> '{new_name}'")

        try:
            file_path = Path("W:/MediaVerse/Collections/Movies_Collections_v2.json")

            if not file_path.exists():
                print("⚠️ Rename failed: JSON file does not exist.")
                return False

            library = safe_json_read(file_path, "collections")

            updated = False
            for item in library:
                if item.get("name") == old_name:
                    item["name"] = new_name
                    updated = True
                    break

            if not updated:
                print(f"⚠️ Rename failed: '{old_name}' not found.")
                return False

            safe_json_write(file_path, library)

            print(f"✏️ Collection renamed to '{new_name}'.")
            return True

        except Exception as e:
            print(f"❌ Rename Error: {e}")
            return False
        

    @Slot('QVariant', str, result=list)
    def get_collection_results_v2(self, criteria, resolution):
        print(f"\n[PYTHON DEBUG get_collection_results_v2] Criteria received from QML: {criteria}")
        """
        Tier-aware version of get_collection_results().
        Reuses the same filtering logic but swaps the image path
        to the correct cache tier (thumb, display, carousel).

        NOW ALSO:
        - Ensures results are always ordered OLDEST FIRST by Year.
        """
        cache_size = len(self.master_cache) if self.master_cache else 0
        print(f"🔍 [TRACE] Scanning through {cache_size} movies in master_cache")
        print(f"🔍 [TRACE] Criteria: {criteria}")


        # ------------------------------------------------------------
        # 1. Convert QJSValue → dict if needed
        # ------------------------------------------------------------
        if hasattr(criteria, 'toVariant'):
            criteria = criteria.toVariant()

        if not isinstance(criteria, dict) or not self.master_cache:
            print(f"⚠️ XMLCollections V2: Invalid criteria type: {type(criteria)}")
            return []

        print(f"\n[V2] get_collection_results_v2 called")
        print(f"[V2] Requested resolution = '{resolution}'")

        # ------------------------------------------------------------
        # 2. Choose cache root based on resolution
        # ------------------------------------------------------------
        if resolution == "carousel":
            cache_root = self.paths["local_carousel_v2"]
        elif resolution == "display":
            cache_root = self.paths["local_display_v2"]
        else:
            cache_root = self.paths["local_thumb_v2"]

        print(f"[V2] Selected cache root = {cache_root}")

        results = []

        # ------------------------------------------------------------
        # 3. FILTERING LOGIC (copied from V1)
        # ------------------------------------------------------------
        filtered_items = []
        print("============  inside row 613   ============")
        for item in self.master_cache:
            # Skip any TV records that may exist in the current on-disk file
            if item.get("Media Sub Type", "").lower() == "tv show" or item.get("Season", ""):
                continue

            match = True
            for key, value in criteria.items():

                # --- DECADE LOGIC ---
                #print(f"DEBUG: Processing Key: '{key}' with Value: '{value}'") # Check the casing!
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
                filtered_items.append(item)

        print(f"[V2] Items matched by criteria = {len(filtered_items)}")

        # ------------------------------------------------------------
        # 3b. GLOBAL ORDERING: OLDEST FIRST BY YEAR
        # ------------------------------------------------------------
        def safe_year(it):
            raw = it.get("Year") or it.get("year") or ""
            try:
                return int(raw)
            except (TypeError, ValueError):
                return 0

        # Oldest first
        filtered_items.sort(key=safe_year)

        # Optional: debug-check ordering
        if filtered_items:
            print("[V2] First few years after sort:",
                [safe_year(it) for it in filtered_items[:10]])

        # ------------------------------------------------------------
        # 4. Build final model with tier-aware paths
        # ------------------------------------------------------------
        for item in filtered_items:
            video_path = item.get("Filename")
            rel_cache_path = self.image_lookup.get(video_path, "")

            filename = os.path.basename(rel_cache_path)
            local_path = cache_root / filename

            file_uri = "file:///" + str(local_path).replace("\\", "/")

            year_value = safe_year(item)

            #print(f"[V2] Final path → {file_uri} (Year={year_value})")

            results.append({
                "filePath": file_uri,
                "originalPath": video_path,
                "fileName": item.get("Title", "Unknown"),
                # Expose year if QML ever wants it directly
                "year": year_value,
                "display": rel_cache_path
            })

        print(f"[V2] Total results returned = {len(results)}\n")
        return results