
from PySide6.QtCore import QObject, Slot, Signal 

import os
import random
from project_paths import coll_data
import json
from PySide6.QtCore import Property
from search_results_model import SearchResultsModel
from Architect_Summary import ArchitectSummary # Add this at the top
from project_paths import movies_coll_v2 # Ensure this is imported
from project_paths import paths




class ArchitectController(QObject):
    # --- CRITICAL SIGNALS ---
    
    images_listed = Signal(list)
    categoriesChanged = Signal()
    resultsCounted = Signal(int, int) # Updates hitCount on individual panels
    foldersUpdated = Signal(list)
    #cateriesChanged = pyqtSignal()
    #deletionComplete = pyqtSignal(int) # Sends the count of orphaned collections
    deletionComplete = Signal(int) # Sends the count of orphaned collections
    categoryModelChanged = Signal()

    VIDEO_EXTS = {'.mp4', '.m2ts', '.ts', '.mkv', '.avi', '.mov', '.m4v', '.iso'}
    # --- CRITICAL SIGNALS ---
    onMovieListReady = Signal(int, list, str) # panel_index, movie_list, display_label
    
    # --- NEW BOOKSHELF SIGNALS ---
    countChanged = Signal(int) 
    bookshelfListChanged = Signal()

    # Premium Palette for the Spines
    SPINE_PALETTE = ["#2c3e50", "#2980b9", "#8e44ad", "#27ae60", "#d35400", "#c0392b", "#16a085", "#34495e"]


    def __init__(self, file_system=None):   
        super().__init__()
        self.file_system = file_system

        self._categories = []
        self._category_model = []
        self.load_categories()

        self.summary_engine = ArchitectSummary()

        # ADD THIS LINE NEAR THE TOP OF THE FILE
        print("DEBUG SLOT SIGNATURE:", self.category_mode_select)

        self._searchResultsModel = SearchResultsModel()
        self._bookshelfList = [] # This holds the final "DNA" for the shelf
        self._current_ids = []  # Initialize it here

        # Load the full movie collection once
        with open(coll_data, "r", encoding="utf-8") as f:
            self.collection = json.load(f)        

        # Panel state: mode, criteria, and temporary movie list
        self.panels = {
            0: {"mode": None, "criteria": None, "movies": []},
            1: {"mode": None, "criteria": None, "movies": []},
            2: {"mode": None, "criteria": None, "movies": []},
            3: {"mode": None, "criteria": None, "movies": []},
        }

    # --- CRITICAL SLOTS FOR QML ---

    #this sets up a path of a folder to search xml_collection_data for records
    def build_folder_prefix(self, folder_name):
        return f"W:\\Collection\\{folder_name}\\"
    

# Note: Assuming 'paths' is accessible within your class scope 
# or passed in via project_paths.py [2026-01-26]

    # This "Property" decorator makes 'categories' visible to QML
    @Property(list, notify=categoriesChanged)
    def categories(self):
        return self._categories
    
    
    def load_categories(self):
        """
        Loads categories from Assets/categories.json via PySide6.
        Guarantees the existence of a locked 'unassigned' pillar.
        """
        try:
            # project_paths.py provides the Path object [2026-01-26]
            category_path = paths["categories"] 
            
            if category_path.exists():
                with open(category_path, 'r', encoding='utf-8') as f:
                    self._categories = json.load(f)
                
                # --- The Architect Safety Net ---
                # Search for the 'unassigned' key in the loaded list
                has_unassigned = any(c.get('key') == 'unassigned' for c in self._categories)
                
                if not has_unassigned:
                    self._categories.append({
                        "key": "unassigned", 
                        "label": "UNASSIGNED", 
                        "locked": True 
                    })
                    # Auto-sync the disk if we had to inject the safety net
                    self._save_to_disk()

                print(f"🚀 [ARCHITECT] Registry Loaded: {len(self._categories)} items")
                # PySide6 uses .emit() just like PyQt5
                self.categoriesChanged.emit()
                
            else:
                print(f"⚠️ [ARCHITECT] Registry file not found at {category_path}")
                # Fallback initialization
                self._categories = [{"key": "unassigned", "label": "UNASSIGNED", "locked": True}]
                self.categoriesChanged.emit()

        except Exception as e:
            print(f"❌ [ARCHITECT] Registry Load Error: {e}")
    
    
    @Property("QVariantList", notify=categoriesChanged)
    def categoryModel(self):
        return self._categories
    
    @Slot(result=list)
    def get_current_results(self):
        """
        Returns the final filtered list of movie paths 
        to the QML Finish logic.
        """
        # We use _current_ids because that is where process_commit stores the list
        results = getattr(self, "_current_ids", [])
        
        # LOGIC CHECK: Are these full paths or just filenames? 
        # If they are just filenames, we reconstruct the full W:\ path for the DB
        final_paths = []
        for item in results:
            if not item.startswith("W:\\"):
                # Reconstruct the path based on your collection data
                # This ensures the 'movies' list in the JSON is valid for playback
                for entry in self.collection:
                    if entry.get("Filename", "").endswith(item):
                        final_paths.append(entry.get("Filename"))
                        break
            else:
                final_paths.append(item)

        print(f"🎬 [CONTROLLER]: Exporting {len(final_paths)} full paths to QML.")
        return final_paths
    
   
    @Property(QObject, constant=True)
    def searchResultsModel(self):
        return self._searchResultsModel

   
    @Slot(result=list)
    def get_bookshelf_list(self):
        """Standard Slot to return the current spine data to QML."""
        # This print will show up in your terminal whenever the HUD refreshes
        print(f"📦 [PYTHON] Handing {len(self._bookshelfList)} spines to HUD.")
        return self._bookshelfList
   
    @Slot(int, str)
    def folder_mode_select(self, panel_index, folder_name):


        # 1. Build prefix
        prefix = self.build_folder_prefix(folder_name)

        # 2. Filter JSON
        movies = [
            item for item in self.collection
            if item["Filename"].startswith(prefix)
        ]

        # 3. Store in panel state
        self.panels[panel_index]["mode"] = "folder"
        self.panels[panel_index]["criteria"] = folder_name
        self.panels[panel_index]["movies"] = movies

        # 4. Print for verification
        print(f"\n🎬 Panel {panel_index} — Folder Mode: {folder_name}")
        print(f"📄 {len(movies)} movies found:")
        for m in movies:
            print("   ", m["Filename"])

        # 5. Emit count to QML
        self.resultsCounted.emit(panel_index, len(movies))

        #mapped_results = [{"filePath": m["Filename"]} for m in movies]
        mapped_results = self.file_system.map_folder_v2(full_path)

        self.images_listed.emit(mapped_results)
        


    @Slot(str)
    def list_folder_content_v2(self, folder_path):
        """
        Bridge function so QML can call the V2 file scanner.
        Converts the relative folder path into a full path and
        forwards it to FileSystem.list_folder_content_v2().
        """

        if not folder_path:
            print("⚠ list_folder_content_v2 called with empty path")
            self.images_listed.emit([])
            return

        base_path = "W:\\Collection\\"
        full_path = os.path.join(base_path, folder_path.replace("/", "\\"))

        # Convert to file:/// URL for the FileSystem
        url = "file:///" + full_path.replace("\\", "/")

        print(f"🔗 Controller forwarding to FileSystem.list_folder_content_v2: {url}")

        # Call the FileSystem V2 function
        self.file_system.list_folder_content_v2(url)

    @Slot(str)
    def get_sub_folders(self, folder_path):
        if not self.file_system:
            return
        target = folder_path if folder_path else "W:\\"
        self.file_system.update_folders(target)


    @Slot(str, int)
    def load_movies_for_path(self, folder_path, panel_index):
        """Scan the actual filesystem and list ONLY movie files inside the selected folder."""

        if not folder_path:
            print("⚠ No folder path provided.")
            self.resultsCounted.emit(panel_index, 0)
            return

        base_path = "W:\\Collection\\"
        full_path = os.path.join(base_path, folder_path.replace("/", "\\"))

        print(f"📁 Scanning folder: {full_path}")

        if not os.path.exists(full_path):
            print("❌ Folder does not exist:", full_path)
            self.resultsCounted.emit(panel_index, 0)
            return

        # Filter ONLY movie files
        files = [
            f for f in os.listdir(full_path)
            if os.path.isfile(os.path.join(full_path, f))
            and os.path.splitext(f)[1].lower() in self.VIDEO_EXTS
        ]

        #print(f"🎬 Movie files found ({len(files)}):")
        #for f in files:
            #print("   ", f)

        # Emit count to QML
        self.resultsCounted.emit(panel_index, len(files))

        # Emit the actual list back to QML
        mapped_results = [{"filePath": f} for f in files]
        self.images_listed.emit(mapped_results)

    @Slot(int, str, str)
    def category_mode_select(self, panel_index, category, value):
        """Filter movies by category/value pair, including decade logic and stripped paths."""
        import os  # Ensure os is imported at the top of your file

        print(f"\n🎬 Panel {panel_index} — Category Mode: {category} = {value}")
        movies = []

        mapping = {
            "Actors": "Actors",
            "Director": "Director",
            "Genre": "Genre",
            "Keywords": "Keywords",
            "Series": "Series"
        }

        # --- 1. FILTERING LOGIC (Preserved) ---
        if category == "Decade":
            decade = value[:-1]  # "1950s" → "1950"
            for item in self.collection:
                if item.get("Media Sub Type") == "TV Show": continue
                year = item.get("Year")
                if not year or not year.isdigit(): continue
                item_decade = year[:-1] + "0"
                if item_decade == decade:
                    movies.append(item)
        else:
            json_key = mapping.get(category, category)
            for item in self.collection:
                if item.get("Media Sub Type") == "TV Show": continue
                data = item.get(json_key, "")
                if isinstance(data, list):
                    if value in data: movies.append(item)
                else:
                    parts = [p.strip() for p in str(data).split(";")]
                    if value in parts: movies.append(item)

        # --- 2. STATE STORAGE ---
        self.panels[panel_index]["mode"] = "category"
        self.panels[panel_index]["criteria"] = f"{category} = {value}"
        # Note: Storing full records in 'movies' for logic, but we send 'leafs' to QML
        self.panels[panel_index]["movies"] = movies

        print(f"📄 {len(movies)} movies found for {category}: {value}")

        # --- 3. EMIT SIGNALS TO QML (With the Strip Join) ---
        self.resultsCounted.emit(panel_index, len(movies))

        mapped_results = []
        for m in movies:
            full_path = m.get("Filename", "")
            # THE STRIP JOIN: Get "Movie.mp4" from "W:\Path\Movie.mp4"
            leaf_name = os.path.basename(full_path) if full_path else ""
            
            mapped_results.append({
                "title": m.get("Name", "Unknown Title"),
                "filePath": leaf_name # <--- HUD uses this to look up thumb
            })
        
        display_label = f"{category}: {value}"
        
        # Send to ArchitectHUD to open the popup
        if hasattr(self, 'onMovieListReady'):
            self.onMovieListReady.emit(panel_index, mapped_results, display_label)
            print(f"🚀 Sent {len(mapped_results)} stripped filenames to HUD.")
        else:
            print("⚠ Signal 'onMovieListReady' not found.")

    @Slot(str, str, result=list)
    def get_filtered_keywords(self, category, filter_text):
        try:
            keywords = set()
            search_term = filter_text.lower()

            mapping = {
                "Actors": "Actors",
                "Director": "Director",
                "Genre": "Genre",
                "Keywords": "Keywords",
                "Series": "Series"
            }

            json_key = mapping.get(category, category)

            for movie in self.collection:

                # ⭐ FIX: Skip TV shows in the cloud
                if movie.get("Media Sub Type") == "TV Show":
                    continue

                data = movie.get(json_key, "")
                if not data:
                    continue

                items = data if isinstance(data, list) else str(data).split(";")

                for item in items:
                    clean_item = item.strip()
                    if not search_term or search_term in clean_item.lower():
                        keywords.add(clean_item)

            return sorted(list(keywords))[:100]

        except Exception as e:
            print("Keyword filter error:", e)
            return []
            
        

    
    @Slot()
    def reset_logic(self):
        # 1. Clear your internal Python lists/logic
        self.active_rules = []
        self.current_results = []
        self._current_total = 0 
        
        # 2. Use the EXISTING signal to tell QML the count is now 0
        # This is what updates the "CUMULATIVE MATCHES" text
        self.countChanged.emit(0) 
        
        # 3. Tell the bookshelf spines to refresh (which will now be empty)
        self.bookshelfListChanged.emit()
        
        print("🧹 Python: Logic reset and signals broadcasted.")
    @Slot(str)
    def search_library(self, text):
        """Search movie names only, skip TV shows, dedupe by name."""
        try:
            text = text.strip().lower()
            self.searchResultsModel.clear()

            if not text:
                return

            seen_titles = set()

            for item in self.collection:

                # Skip TV shows
                if item.get("Media Sub Type") == "TV Show":
                    continue

                name = item.get("Name", "")
                if not name:
                    continue

                # Match name only
                if text in name.lower():

                    # Deduplicate by movie name
                    if name in seen_titles:
                        continue
                    seen_titles.add(name)

                    path = item.get("Filename", "")

                    self.searchResultsModel.append({
                        "title": name,
                        "filePath": path
                    })

        except Exception as e:
            print("Search error:", e)


    @Slot(int)
    def generate_list_for_panel(self, panel_index):
        """
        THE STRIP JOIN:
        1. Grabs the stored criteria (e.g., Genre: Western)
        2. Searches the collection for matches
        3. Strips the path from the Filename record
        4. Sends ONLY the filename+extension to QML
        """
        try:
            # Retrieve the intent we stored during 'category_mode_select'
            state = self.panels.get(panel_index, {})
            criteria_str = state.get("criteria", "") # "Genre: Western"
            
            if not criteria_str or ":" not in criteria_str:
                return

            category, value = [x.strip() for x in criteria_str.split(":")]
            
            # Recalculate matches to ensure we are fresh
            matches = []
            for item in self.collection:
                if item.get("Media Sub Type") == "TV Show": 
                    continue
                
                # Map QML Category to JSON Key
                json_key = category # Simplified for brevity, uses your mapping
                data = item.get(json_key, "")
                if value in [p.strip() for p in str(data).split(";")]:
                    # THE STRIP: Get "The Searchers (1956).mp4" from "W:\Movies\The Searchers (1956).mp4"
                    full_path = item.get("Filename", "")
                    if full_path:
                        leaf_name = os.path.basename(full_path)
                        matches.append({
                            "title": item.get("Name", leaf_name),
                            "filePath": leaf_name  # This is the Name + Extension join
                        })

            # Send the clean list back to the HUD
            self.onMovieListReady.emit(panel_index, matches, criteria_str)
            print(f"📦 Joint Complete: Sent {len(matches)} stripped filenames to HUD.")

        except Exception as e:
            print(f"❌ Error in Generate List Join: {e}")

    @Slot(int, str)
    def process_commit(self, panel_index, snippet_json):
        print(f"🆔 DEBUG: Controller ID {id(self)} is processing Panel {panel_index}")

        try:
            # 1. PARSE THE INCOMING DNA
            snippet = json.loads(snippet_json)
            
            # 2. LOG THE EVENT
            #print(f"\n📂📂📂📂📂📂📂📂📂📂📂📂📂📂📂")
            #print(f"   PANEL {panel_index} RULE COMMITTED")
            #print(f"——————————————————————————————")
            #print(json.dumps(snippet, indent=4))
            #print(f"——————————————————————————————")

            # 3. EXTRACT AND NORMALIZE DETAILS
            mode = snippet.get("mode", "")
            gate = snippet.get("gate", "NONE")
            is_narrowing = snippet.get("checked", False) # The "FILTER" checkbox
            data_payload = snippet.get("data", {})
            
            current_ids = []

            # --- MODE: FOLDER ---
            if mode == "Folder":
                target_folder = data_payload.get("folder", "")
                search_term = target_folder.strip().lower()
                current_ids = [
                    os.path.basename(item.get("Filename")) for item in self.collection 
                    if item.get("Filename") and (
                        f"\\{search_term}\\" in item.get("Filename", "").lower() 
                        or f"/{search_term}/" in item.get("Filename", "").lower()
                    )
                ]

            # --- MODE: CATEGORY ---
            elif mode == "Category":
                cat = data_payload.get("category", "")
                val = data_payload.get("value", "")
                
                key_map = {
                    "Genres": ["Genre"],
                    "Actors": ["Actors"],
                    "Directors": ["Director"],
                    "Decade": ["Year"]
                }
                search_keys = key_map.get(cat, [cat])

                for item in self.collection:
                    if item.get("Media Sub Type") != "Movie": continue
                    
                    match_found = False
                    for k in search_keys:
                        raw_data = item.get(k, "")
                        
                        if cat == "Decade":
                            target_prefix = str(val)[:3] 
                            if str(raw_data).startswith(target_prefix):
                                match_found = True
                        
                        elif isinstance(raw_data, list):
                            if val in raw_data:
                                match_found = True
                        
                        elif isinstance(raw_data, str):
                            parts = [p.strip() for p in raw_data.split(";")]
                            if val in parts:
                                match_found = True

                        if match_found: break 

                    if match_found:
                        path = item.get("Filename")
                        if path:
                            current_ids.append(os.path.basename(path))

            # --- MODE: FILES ---
            elif mode == "Files":
                file_list = data_payload.get("files", []) or data_payload.get("list", [])
                current_ids = [os.path.basename(f) for f in file_list if f]

            # --- THE SURGICAL CHECK ---
            #print(f"\n🧪 --- NORMALIZATION CHECK (Panel {panel_index}) ---")
            #print(f"Panel Selection Found: {len(current_ids)} items")
            
            # 4. PERFORM THE MATH (THE LOGIC ENGINE)
            if hasattr(self, 'summary_engine'):
                # This triggers the Architect_Summary logic
                # is_narrowing=True will now trigger 'list_featuring'
                new_total = self.summary_engine.apply_logic(
                    panel_index, current_ids, gate, is_narrowing
                )
                # Update the controller's internal tracking
                self._current_ids = self.summary_engine.get_current_result()
            else:
                # Fallback if engine is missing
                new_total = len(current_ids)
                self._current_ids = current_ids

            # 5. EMIT SIGNALS BACK TO HUD
            print(f"📊 RESULT: Bookshelf now contains {new_total} items.")
            self.countChanged.emit(new_total)
            
            # Refresh the bookshelf list in the HUD (the "spines")
            self.bookshelfListChanged.emit()
            
            import sys
            sys.stdout.flush()

        except Exception as e:
            print(f"❌ Error in process_commit: {e}")
            import traceback
            traceback.print_exc()

    @Slot(int)
    def handle_shelf_request(self, panel_index):
        # self._current_ids was saved during the 'process_commit'
        print(f"📚 [SHELF] Baking spines for {len(self._current_ids)} items...")
        
        new_spines = []
        for path in self._current_ids:
            if not path: continue
            
            # 1. Clean up the title (e.g., "Rocky (1976).mp4" -> "Rocky (1976)")
            filename = os.path.basename(path)
            title_clean = os.path.splitext(filename)[0]
            
            # 2. Package it for QML
            new_spines.append({
                "title": title_clean,
                "spineColor": random.choice(self.SPINE_PALETTE),
                "filePath": path
            })
        
        # 3. Store in the 'warehouse' and ring the 'dinner bell'
        self._bookshelfList = new_spines
        self.bookshelfListChanged.emit()
        
        print(f"✅ [SHELF] {len(new_spines)} spines ready in warehouse.")


    @Slot(str)
    def save_collection(self, json_payload):
        try:
            # DEBUG: See exactly what QML sent
            print("--- DEBUG: Incoming Save Request ---")
            print(json_payload) 
            print("------------------------------------")

            data = json.loads(json_payload)
            target_path = str(movies_coll_v2) 

            # 1. Load existing
            collections_db = []
            if os.path.exists(target_path):
                with open(target_path, "r", encoding="utf-8") as f:
                    try:
                        collections_db = json.load(f)
                    except: collections_db = []

            new_name = data.get("name", "New Architect Collection")
            
            # Deduplication
            collections_db = [c for c in collections_db if c.get("name") != new_name]

            # 2. Build the Record
            final_entry = {
                "name": new_name,
                "category": data.get("category", "unassigned"), 
                "type": "Architect",
                "description": data.get("description", ""),
                "rules": data.get("rules", []), 
                "created": data.get("created", "2026-02-28"),
                "favorite": data.get("favorite", False),
                "imagePath": data.get("imagePath", "None")
            }

            collections_db.append(final_entry)
            
            with open(target_path, "w", encoding="utf-8") as f:
                json.dump(collections_db, f, indent=4)

            print(f"✅ [DYNAMIC SAVE]: '{new_name}' recorded in category '{final_entry['category']}'.")

        except Exception as e:
            print(f"❌ [SAVE ERROR]: {e}")


    @Slot(result=list)
    def get_architect_categories(self):
        """
        Harvests unique categories from the JSON where type is 'Architect'.
        """
        # 1. Start with your mandatory core categories
        defaults = ["Actors", "Director", "Genre", "Year", "Top Ten"]
        harvested = set(defaults)

        try:
            # Using the path from project_paths.py as per [2026-01-26]
            target_path = str(movies_coll_v2) 
            
            if os.path.exists(target_path):
                with open(target_path, "r", encoding="utf-8") as f:
                    collections = json.load(f)
                    
                    for item in collections:
                        # ACTION POINT: Only grab categories from 'Architect' types
                        if item.get("type") == "Architect":
                            cat = item.get("category")
                            
                            # Guard against 'Keywords', 'unassigned', or empty values
                            if cat and cat not in ["Keywords", "unassigned", ""]:
                                harvested.add(cat)
                                
        except Exception as e:
            print(f"⚠️ [CATEOGRY HARVEST ERROR]: {e}")

        # 2. Return as a sorted list for the ComboBox
        final_list = sorted(list(harvested))
        print(f"📊 [ARCHITECT] Refreshed {len(final_list)} categories for the UI.")
        return final_list
    
    @Property(list, notify=categoryModelChanged)
    def categoryModel(self):
        # 1. THE LOCKED DEFAULTS
        # These are your 'hard-coded' anchors
        registry = [
            {"key": "Actors",   "label": "Actors",   "tooltip": "Primary cast members",   "locked": True},
            {"key": "Director", "label": "Director", "tooltip": "Film directors",        "locked": True},
            {"key": "Genre",    "label": "Genre",    "tooltip": "Movie genres",          "locked": True},
            {"key": "Year",     "label": "Year",     "tooltip": "Release timeline",      "locked": True},
            {"key": "TopTen",   "label": "Top Ten",  "tooltip": "Personal favorites",    "locked": True}
            
        ]
        
        existing_keys = {item["key"] for item in registry}

        # 2. THE UNLOCKED HARVEST
        try:
            # Using movies_coll_v2 path from project_paths.py
            if os.path.exists(str(movies_coll_v2)):
                with open(str(movies_coll_v2), "r", encoding="utf-8") as f:
                    collections = json.load(f)
                    for item in collections:
                        # Only grab 'Architect' types
                        if item.get("type") == "Architect":
                            cat = item.get("category")
                            
                            # If it's a new unique category, add it as UNLOCKED
                            if cat and cat not in existing_keys and cat != "Keywords":
                                registry.append({
                                    "key": cat,
                                    "label": cat,
                                    "tooltip": "User-defined Architect category",
                                    "locked": False
                                })
                                existing_keys.add(cat)
        except Exception as e:
            print(f"❌ [REGISTRY REFRESH ERROR]: {e}")

        return registry

    @Slot()
    def refresh_registry(self):
        """Call this from QML just before opening the Registry Popup."""
        self.categoryModelChanged.emit()

    @Slot(str, str)
    def rename_category_global(self, old_name, new_name):
        """Searches the entire JSON and updates all instances of a category name."""
        try:
            target_path = str(movies_coll_v2)
            if not os.path.exists(target_path): return

            with open(target_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            changes_made = 0
            for collection in data:
                if collection.get("category") == old_name:
                    collection["category"] = new_name
                    changes_made += 1

            if changes_made > 0:
                with open(target_path, "w", encoding="utf-8") as f:
                    json.dump(data, f, indent=4)
                print(f"✅ Backflushed {changes_made} collections to new category: {new_name}")
                self.categoryModelChanged.emit() # Refresh the UI list
                return True
        except Exception as e:
            print(f"❌ Rename Failed: {e}")
        return False

    @Slot(str)
    def delete_category_global(self, category_to_remove):
        """Replaces category with 'Unassigned' for all matching Architect collections."""
        return self.rename_category_global(category_to_remove, "Unassigned")