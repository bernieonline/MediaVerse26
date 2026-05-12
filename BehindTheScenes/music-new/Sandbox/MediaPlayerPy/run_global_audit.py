import os
import json
from pathlib import Path

# --- CONFIGURATION (Verify these paths match your machine) ---
DNA_BANK_PATH = r"D:\MediaVerse1.0\BehindTheScenes\BehindTheScenes\music-new\Assets\xml_collection_data.json"
BASE_COLLECTION_PATH = r"W:\Collection"
VIDEO_EXTS = {'.mp4', '.m2ts', '.ts', '.mkv', '.avi', '.mov', '.m4v', '.iso'}

def run_global_audit():
    print(f"\n[>>] STARTING GLOBAL MEDIAVERSE AUDIT")
    print(f"Comparing: {BASE_COLLECTION_PATH} vs {DNA_BANK_PATH}\n")

    # 1. Load the DNA Bank
    if not os.path.exists(DNA_BANK_PATH):
        print(f"[ERROR] ERROR: DNA Bank not found!")
        return
    with open(DNA_BANK_PATH, "r", encoding="utf-8") as f:
        collection = json.load(f)

    # Convert all DB filenames to a set for lightning-fast lookup
    # We store just the basename (e.g., 'Shane (1953).mp4')
    db_set = {os.path.basename(item.get("Filename", "")) for item in collection if item.get("Filename")}

    total_disk_count = 0
    total_missing_count = 0
    mismatch_report = {}

    # 2. Iterate through all folders in W:\Collection
    for root, dirs, files in os.walk(BASE_COLLECTION_PATH):
        # Get relative folder name for reporting (e.g., "Western HD")
        rel_folder = os.path.relpath(root, BASE_COLLECTION_PATH)
        if rel_folder == ".": continue 

        # Filter for video files only
        videos_on_disk = [f for f in files if os.path.splitext(f)[1].lower() in VIDEO_EXTS]
        if not videos_on_disk:
            continue

        total_disk_count += len(videos_on_disk)
        
        # Check which disk files are NOT in the database set
        missing_here = [f for f in videos_on_disk if f not in db_set]
        
        if missing_here:
            mismatch_report[rel_folder] = missing_here
            total_missing_count += len(missing_here)

    # 3. PRINT SUMMARY REPORT
    print(f"{'='*60}")
    print(f" GLOBAL SUMMARY")
    print(f"{'='*60}")
    print(f"Total Videos on Drive:   {total_disk_count}")
    print(f"Total Records in JSON:   {len(db_set)}")
    print(f"Total Missing (Ghosts):  {total_missing_count}")
    print(f"{'='*60}\n")

    if mismatch_report:
        print("[ERROR] DETAILED BREAKDOWN OF MISSING MOVIES:")
        for folder, items in mismatch_report.items():
            print(f"\n[DIR] {folder} ({len(items)} missing)")
            for movie in sorted(items):
                print(f"   - {movie}")
    else:
        print("[OK] CLEAN SWEEP: Every file on your drive is accounted for in the DNA Bank.")

if __name__ == "__main__":
    run_global_audit()