from PySide6.QtCore import QObject, Slot, Signal, Property
import json
import random
import os
#from project_paths import paths, movies_coll_v2, local_manifest_v2
from pathlib import Path          # <--- Add this line!
from project_paths import paths   # Ensure this is here too

class ArchitectView(QObject):
    # Signal to send the list of 10 image paths to QML
    atmosphereReady = Signal(list)

    def __init__(self):
        super().__init__()
        #self._manifest_data = []
        #self._load_manifest()

        # Ensure these are assigned to self.
        # If 'paths' isn't imported, make sure it's at the top of the file!
        self._manifest_path = paths.get('server_manifest_v2', "")
        self._collections_path = paths.get('movies_coll_v2', "")
        self._fallback = paths.get('fallback_image', "")
        
        # Debugging: Let's see if the paths actually loaded during init
        print(f"📂 [ARCHITECT INIT] Collections Path: {self._collections_path}")

    def _load_manifest(self):
        """Loads the master manifest for random fallbacks."""
        try:
            path = paths["local_manifest_v2"]
            if os.path.exists(path):
                with open(path, "r", encoding="utf-8") as f:
                    self._manifest_data = json.load(f)
        except Exception as e:
            print(f"❌ [ArchitectView] Manifest Load Error: {e}")

    @Slot()
    def prepare_atmosphere(self):
        """Builds the background image list from the TopTen Architect collection."""
        print("\n🔍 [ARCHITECT DEBUG] Starting Atmosphere Retrieval...")
        try:
            image_list = []

            # 1. Try to resolve images from the TopTen Architect collection
            collections_path = str(self._collections_path)
            if os.path.exists(collections_path):
                print(f"📂 Reading Collections: {collections_path}")
                with open(collections_path, 'r', encoding='utf-8') as f:
                    colls = json.load(f)

                top_ten = next(
                    (c for c in colls
                     if c.get('type') == 'Architect' and c.get('category') == 'TopTen'),
                    None
                )

                if top_ten:
                    print(f"✅ Found TopTen collection: '{top_ten.get('name')}'")
                    image_list = self._resolve_images_from_collection(top_ten)
                else:
                    print("⚠️ No TopTen Architect collection found in collections file.")

            # 2. Fallback to random manifest images
            if not image_list:
                print("⚠️ Falling back to random manifest images.")
                image_list = self._get_random_manifest_images(10)

            # 3. Format all paths for QML and emit
            final_paths = []
            for raw_p in image_list:
                formatted = self._format_path(raw_p)
                final_paths.append(formatted)
                print(f"🖼️  IMAGE MAPPING: [RAW]: {raw_p}  -->  [QML]: {formatted}")

            if not final_paths:
                print("❌ CRITICAL: No images found at all. Sending fallback.")
                final_paths = [self._format_path(str(self._fallback))]

            self.atmosphereReady.emit(final_paths)

        except Exception as e:
            print(f"❌ ARCHITECT ERROR: {str(e)}")
            self.atmosphereReady.emit([self._format_path(str(self._fallback))])

    def _resolve_images_from_collection(self, collection):
        """Maps the file paths stored in collection rules to local display cache URIs."""
        image_uris = []
        cache_root = paths.get("local_display_v2")
        if not cache_root:
            print("❌ [ARCHITECT] local_display_v2 path not found in project_paths.")
            return []

        for rule in collection.get("rules", []):
            if rule.get("mode") != "Files":
                continue
            for file_path in rule.get("data", {}).get("files", []):
                # "W:\Collection\rocky\Rocky (1976).mp4" → "Rocky (1976)"
                stem = Path(file_path).stem
                img_path = Path(cache_root) / (stem + ".jpg")
                if img_path.exists():
                    image_uris.append(img_path.as_uri())
                else:
                    print(f"⚠️ [ATMOSPHERE] Image not in cache: {img_path}")

        print(f"✅ [ATMOSPHERE] Resolved {len(image_uris)} images from collection.")
        return image_uris

    def _get_random_atmosphere(self, count):
        """Picks random movies and returns their local display cache paths."""
        movies = [item for item in self._manifest_data if item.get("metadata", {}).get("type") == "movie"]
        if not movies:
            return []
        
        selection = random.sample(movies, min(len(movies), count))
        # Return the local display path (Hero quality)
        return [item["cache"]["display"] for item in selection]

    def _resolve_from_rules(self, rules):
        """Logic to turn DNA rules into actual manifest display paths."""
        # This will grow as we implement the 'DNA to Path' linker
        return []
    
    def _format_path(self, path):
        """Ensures QML can read the Windows path while cleaning encoding."""
        if not path: return ""
        path_str = str(path)

        # Already a file URI (e.g. from Path.as_uri()) — return as-is.
        # Calling os.path.normpath on a URI corrupts it on Windows.
        if path_str.startswith("file:"):
            return path_str

        # Plain filesystem path — convert slashes then prepend scheme.
        clean_p = path_str.replace("\\", "/")
        if len(clean_p) >= 2 and clean_p[1] == ":":   # Windows drive letter
            return "file:///" + clean_p
        elif clean_p.startswith("/"):
            return "file://" + clean_p
        else:
            return "file:///" + clean_p
    
    def _get_random_manifest_images(self, count):
        """
        Extracts high-res movie backdrops using the local_display_v2 anchor.
        Matches the path-logic in XMLCollections to avoid double-prefixing.
        """
        try:
            # 1. Get the V2 anchor from your project_paths dictionary
            # D:\MediaVerse1.0\...\cacheV2\images\display
            cache_root = paths.get("local_display_v2")

            if not self._manifest_path or not os.path.exists(self._manifest_path):
                print(f"⚠️ [ARCHITECT] Manifest missing at: {self._manifest_path}")
                return []
                
            with open(self._manifest_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Handle list vs dict manifest structures
            items = data if isinstance(data, list) else data.get("items", [])
            valid_pool = []

            for item in items:
                # 2. Extract the relative filename
                # Your manifest uses "Cache/display/Movie (Year).jpg"
                raw_path = item.get("cache", {}).get("display", "")
                
                if raw_path:
                    # Use Path().name to extract just the filename regardless of
                    # whatever prefix/subfolder the manifest stores in this field.
                    filename = Path(raw_path).name  # e.g. "Creed (2015).jpg"

                    # 3. Pathlib Join (Portable & Clean)
                    local_path = Path(cache_root) / filename
                    
                    if local_path.exists():
                        # 4. Convert to URI
                        # .as_uri() automatically adds 'file:///' correctly 
                        # and handles slashes for Windows/QML compatibility.
                        file_uri = local_path.as_uri()
                        valid_pool.append(file_uri)
            
            if not valid_pool:
                print(f"❌ [ARCHITECT] No matching files found in: {cache_root}")
                return []

            # 5. Return a random sample
            selection = random.sample(valid_pool, min(len(valid_pool), count))
            
            # Debugging to verify the path isn't doubled
            if selection:
                print(f"🎨 [ATMOSPHERE] Sample Path: {selection[0]}")
                
            return selection
            
        except Exception as e:
            print(f"💥 [ARCHITECT ERROR] in _get_random_manifest_images: {e}")
            return []