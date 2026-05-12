import os
from pathlib import Path
from PySide6.QtCore import QObject, Signal, Slot
from project_paths import paths


class SearchController(QObject):
    resultsUpdated = Signal(list)
    detailRequested = Signal(dict)   # <-- NEW SIGNAL

    def __init__(self, master_data_items=None):
        super().__init__()

        # Load manifest directly from disk
        self.search_root = Path(r"W:\Collection")
        self.master_data = self.load_manifest_direct()

        # Local display base for thumbnails
        self.local_display_base = paths.get("local_display_v2")

        print(f"[PKG] [Search] Ready. Monitoring {len(self.master_data)} manifest items.")

    # ------------------------------------------------------------
    # Normalization (shared across search + resolver)
    # ------------------------------------------------------------
    def normalize(self, p):
        if not p:
            return ""
        return str(p).replace("\\", "/").strip().lower()

    # ------------------------------------------------------------
    # SEARCH
    # ------------------------------------------------------------
    @Slot(str)
    def perform_search(self, query):
        query = query.lower().strip()
        if not query:
            self.resultsUpdated.emit([])
            return

        found_items = []

        # Build lookup map: normalized manifest video path -> manifest item
        lookup_map = {
            self.normalize(item.get("shared", {}).get("video")): item
            for item in self.master_data
        }

        # Walk the disk
        for root, dirs, files in os.walk(self.search_root):
            for file in files:
                if query in file.lower() and file.lower().endswith(('.mp4', '.mkv', '.avi', '.m2ts', '.ts')):
                    full_disk_path = os.path.join(root, file)
                    norm_disk_path = self.normalize(full_disk_path)

                    match = lookup_map.get(norm_disk_path)

                    if match:
                        title = match.get("title", file)
                        img_filename = os.path.basename(match.get("cache", {}).get("display", ""))
                        local_img = Path(self.local_display_base) / img_filename

                        found_items.append({
                            "name": title,
                            "filePath": full_disk_path.replace("\\", "/"),
                            "hasMetadata": True,
                            "xmlPath": match.get("shared", {}).get("xml", ""),
                            "imageFilename": local_img.as_uri() if local_img.exists() else ""
                        })
                    else:
                        found_items.append({
                            "name": file,
                            "filePath": full_disk_path.replace("\\", "/"),
                            "hasMetadata": False,
                            "xmlPath": "",
                            "imageFilename": ""
                        })

                    if len(found_items) >= 20:
                        break
            if len(found_items) >= 20:
                break

        self.resultsUpdated.emit(found_items)

    # ------------------------------------------------------------
    # SELECTION -> RESOLVE -> EMIT DETAIL REQUEST
    # ------------------------------------------------------------
    @Slot(str)
    def confirm_selection(self, movie_path):
        from project_paths import paths
        from pathlib import Path
        import os

        print("\n--- [SEARCH SELECTION] ---")
        print("Incoming path from QML:", movie_path)

        # 1. Get the raw result (contains relative paths from manifest)
        result = self.resolve_from_search(movie_path)

        if result and "error" not in result:
            # 2. Get the relative image path from manifest (e.g., "Cache/display/Dr No (1962).jpg")
            raw_image_str = result.get("image", "")
            
            # 3. Extract the part after "Cache/" to get "display/Dr No (1962).jpg"
            # We use split to handle cases where the manifest might use different slashes
            relative_part = raw_image_str.split("Cache/")[-1] 

            # 4. Join with your PORTABLE local path from project_paths.py
            # This uses D:\MediaVerse... automatically based on where the app is running
            absolute_img_path = Path(paths["local_cache_images_v2"]) / relative_part
            
            # 5. Convert to QML-friendly URI (file:///...)
            # This is the "magic" that makes the image load on any device
            result["image"] = absolute_img_path.as_uri()

            # 6. Ensure XML and Movie are also clean URIs/Paths for the Detail View
            if result.get("xml"):
                result["xml"] = Path(result["xml"]).as_uri()

        # Emit to QML so detail_view can load it
        self.detailRequested.emit(result)

        # Debug print
        print(f"[OK] RESOLVED PORTABLE URI: {result.get('image')}")
        print(f" XML PATH:   {result.get('xml')}")
        print(f"[MOVIE] MOVIE PATH: {result.get('movie')}")
        print("--------------------------\n")

        return result

    # ------------------------------------------------------------
    # RESOLVER
    # ------------------------------------------------------------
    def resolve_from_search(self, movie_path):
        print("\n--- [SEARCH RESOLVER] ---")
        print("Incoming path from QML:", movie_path)

        win_path = movie_path.replace("/", "\\")
        print("[SEARCH] WINDOWS-STYLE SEARCH STRING:", win_path)

        match = None

        for item in self.master_data:
            manifest_video = item.get("shared", {}).get("video")
            if not manifest_video:
                continue

            # Debug: show Dr No entries
            if "dr no" in manifest_video.lower():
                print(" FOUND MANIFEST ENTRY FOR DR NO:", repr(manifest_video))

            # Normalized comparison
            if self.normalize(manifest_video) == self.normalize(win_path):
                match = item
                break

        if match:
            print("[TARGET] MATCH FOUND IN MANIFEST")
            return {
                "movie": match["shared"]["video"],
                "xml": match["shared"]["xml"],
                "image": match["cache"]["display"]
            }

        # No match -> tell QML to show "No Details Found"
        print("[ERROR] NO MATCH FOUND FOR:", win_path)
        return {
            "error": "No Details Found",
            "movie": movie_path,
            "xml": None,
            "image": None
        }

    # ------------------------------------------------------------
    # DIRECT MANIFEST LOADER
    # ------------------------------------------------------------
    def load_manifest_direct(self, path=r"W:\MediaVerse\manifest\manifest.json"):
        import json

        try:
            manifest_path = Path(path)
            print(" Loading manifest directly from:", manifest_path)

            if not manifest_path.exists():
                print("[ERROR] Manifest file not found:", manifest_path)
                return []

            with manifest_path.open("r", encoding="utf-8") as f:
                data = json.load(f)

            items = data.get("items", [])
            print(f"[PKG] Direct manifest load complete. Items: {len(items)}")
            return items

        except Exception as e:
            print("[ERROR] Error loading manifest directly:", e)
            return []