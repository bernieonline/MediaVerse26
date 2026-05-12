import os
import json

class FolderMapper:
    def __init__(self, manifest_path):
        self.manifest_path = manifest_path
        self.manifest_data = {}
        # Set a local path for your placeholder if qrc is not available
        self.placeholder = "qrc:/Assets/no_poster.png" 
        self.video_extensions = ('.mp4', '.mkv', '.avi', '.m2ts', '.ts', '.mov')
        self.load_manifest()

    def load_manifest(self):
        try:
            if os.path.exists(self.manifest_path):
                with open(self.manifest_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    items = data.get("items", [])
                    self.manifest_data = {}
                    
                    for item in items:
                        # RULE: Use the 'shared' -> 'video' path as the key
                        video_path = item.get("shared", {}).get("video")
                        if video_path:
                            # Normalize path (W:\\Path -> W:\Path) for Windows consistency
                            normalized_key = os.path.normpath(video_path)
                            self.manifest_data[normalized_key] = item
                            
                print(f"[TARGET] FolderMapper: Indexed {len(self.manifest_data)} records using 'shared.video' keys.")
            else:
                print(f"[WARN] FolderMapper: Manifest not found at {self.manifest_path}")
        except Exception as e:
            print(f"[ERROR] FolderMapper Error: {e}")

    def get_items_for_folder(self, folder_path):
        """
        Scans a physical folder on W: and maps files to their manifest records
        using the normalized 'shared.video' path as the lookup key.
        """
        # 1. Clean the incoming folder path (standardize slashes for Windows)
        clean_folder = folder_path.replace("file:///", "").replace("/", "\\")
        if clean_folder.endswith("\\"): 
            clean_folder = clean_folder[:-1]
        
        # Ensure the whole path is normalized to match our indexed manifest keys
        clean_folder = os.path.normpath(clean_folder)
        
        results = []
        try:
            if not os.path.exists(clean_folder):
                print(f"[WARN] FolderMapper: Path does not exist: {clean_folder}")
                return []

            # List every file in the directory
            all_files = os.listdir(clean_folder)
            
            for file_name in all_files:
                # Create the full Windows path (e.g., W:\Collection\1960s...\Movie.mp4)
                full_path = os.path.normpath(os.path.join(clean_folder, file_name))
                
                # --- MATCHING LOGIC ---
                # Check if this exact file path exists as a 'shared.video' key in manifest_data
                if full_path in self.manifest_data:
                    m_item = self.manifest_data[full_path]
                    
                    # 1. Get the EXACT relative path from the manifest cache
                    # This returns "Cache/thumb/MovieName.jpg"
                    rel_thumb = m_item.get("cache", {}).get("thumb", "")
                    
                    # 2. Get Year from metadata
                    item_year = m_item.get("metadata", {}).get("year", 0)

                    results.append({
                        "title": m_item.get("title", file_name),
                        "filePath": rel_thumb,         # RELATIVE PATH: Cache/thumb/...
                        "originalPath": full_path,     # PHYSICAL PATH: W:\...
                        "sourceType": "MANIFEST",
                        "year": item_year
                    })

                # If file is not in manifest but is a video file, treat as RAW
                elif file_name.lower().endswith(self.video_extensions):
                    results.append({
                        "title": file_name,
                        "filePath": self.placeholder,
                        "originalPath": full_path,
                        "sourceType": "RAW",
                        "year": 0
                    })
            
            print(f"[DIR] FolderMapper: Processed {len(results)} items in {clean_folder}")
            
        except Exception as e:
            print(f"[ERROR] FolderMapper Scan Error: {e}")
            
        return results       

    