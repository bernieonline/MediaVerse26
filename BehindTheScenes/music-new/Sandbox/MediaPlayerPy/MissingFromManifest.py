import json
import os
from pathlib import Path

# --- CONFIGURATION ---
MANIFEST_PATH = Path(r"W:\MediaVerse\manifest\manifest.json")
COLLECTION_ROOT = Path(r"W:\Collection")
IGNORE_DIR_TV = Path(r"W:\Collection\TV Shows")
OUTPUT_FILE = Path(r"D:\MediaVerse1.0\BehindTheScenes\BehindTheScenes\music-new\Sandbox\Test Folder\movies not in manifest.txt")

# Standard video extensions
VIDEO_EXTS = {'.mp4', '.m2ts', '.ts', '.mkv', '.avi', '.mov', '.m4v', '.iso'}

def run_manifest_audit():
    print(f"🚀 Starting Manifest Audit...")
    
    # 1. Load the Manifest
    if not MANIFEST_PATH.exists():
        print(f"❌ ERROR: Manifest not found at {MANIFEST_PATH}")
        return

    try:
        with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
            data = json.load(f)
            items = data.get("items", [])
    except Exception as e:
        print(f"❌ ERROR reading JSON: {e}")
        return

    # 2. Extract all 'video' paths from manifest
    manifest_videos = set()
    for item in items:
        video_path = item.get("shared", {}).get("video")
        if video_path:
            manifest_videos.add(os.path.normpath(video_path).lower())

    print(f"📊 Manifest contains {len(manifest_videos)} video records.")

    # 3. Scan the Disk
    orphans = []
    
    for root, dirs, files in os.walk(COLLECTION_ROOT):
        current_path = Path(root)
        
        # --- IGNORE LOGIC ---
        # 1. Skip the TV Shows folder tree
        if IGNORE_DIR_TV in current_path.parents or current_path == IGNORE_DIR_TV:
            continue
            
        # 2. Skip any folder named "football" (case-insensitive)
        if "football" in [d.lower() for d in current_path.parts]:
            continue

        for file in files:
            if Path(file).suffix.lower() in VIDEO_EXTS:
                full_path = os.path.join(root, file)
                normalized_path = os.path.normpath(full_path).lower()

                if normalized_path not in manifest_videos:
                    orphans.append(full_path)

    # 4. Sort and Save Results
    orphans.sort() 

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as out:
        if orphans:
            out.write(f"MOVIES ON DISK BUT NOT IN MANIFEST\n")
            out.write(f"Found: {len(orphans)} missing records\n")
            out.write("="*50 + "\n\n")
            for path in orphans:
                out.write(f"{path}\n")
            print(f"✅ Audit Complete. {len(orphans)} orphans found.")
        else:
            out.write("CLEAN SWEEP: All video files on disk are present in the manifest.")
            print("✅ Audit Complete. No orphans found.")

    print(f"📄 Report saved to: {OUTPUT_FILE}")

if __name__ == "__main__":
    run_manifest_audit()