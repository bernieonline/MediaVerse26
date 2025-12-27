import os
import json
from pathlib import Path
from datetime import datetime
import re
from manifest_hash_processor import process_and_save


"""
Manifest Builder v2 (based on working v1 logic)

- Uses the same folder traversal and DVD detection as v1.
- Preserves v1 behavior for:
    - DVD handling (VIDEO_TS folders)
    - Video/image pairing
    - XML association
    - Year extraction from title
    - Type detection (movie vs tv)
- Adds v2 cache fields with relative paths:
    - cache.thumb
    - cache.display
    - cache.carousel

Standalone script: no Qt, no threads.
"""
print("loading manifest_v2.py")
# --- Root location ---
ROOT_PATH = Path(r"W:\Collection")
MANIFEST_OUTPUT = Path(r"W:\MediaVerse\manifest\manifest.json")

# --- Folders to exclude (same as v1) ---
EXCLUDE_FOLDERS = [
    r"W:\Collection\TV Shows\Slow Horses",
    r"W:\Collection\Movies\The Accountant (2016)",
    r"W:\Collection\Clips",
    r"W:\Collection\Extras",
    r"W:\Collection\Temp",
]

IMAGE_EXTS = (".jpg", ".jpeg", ".png")
VIDEO_EXTS = (".mp4", ".mkv", ".avi", ".m2ts", ".ts", ".webm")
XML_EXTS   = (".xml",)


def is_excluded(folder: Path) -> bool:
    folder_str = str(folder)
    return any(folder_str.startswith(ex) for ex in EXCLUDE_FOLDERS)


def extract_year_from_title(title: str):
    m = re.search(r"\((\d{4})\)", title)
    if m:
        return int(m.group(1))
    return None


def build_cache_paths_for_title(title: str):
    """
    v2 cache fields, but relative (portable):
        Cache/thumb/<title>.jpg
        Cache/display/<title>.jpg
        Cache/carousel/<title>.jpg
    """
    base = f"{title}.jpg"
    return {
        "thumb": f"Cache/thumb/{base}",
        "display": f"Cache/display/{base}",
        "carousel": f"Cache/carousel/{base}",
    }


def build_manifest_for_folder(folder: Path):
    """
    This is a direct adaptation of your v1 build_manifest_for_folder,
    with v2 cache fields added.

    Returns a list of entries (0, 1, or many).
    """
    manifest_entries = []

    # --- DVD detection: current folder IS VIDEO_TS ---
    if folder.name.upper() == "VIDEO_TS":
        dvd_image = next(
            (
                f for f in folder.iterdir()
                if f.stem.upper() == "VIDEO_TS"
                and f.suffix.lower() in (".jpg", ".jpeg")
            ),
            None
        )
        if dvd_image and dvd_image.exists():
            parent_movie_folder = folder.parent
            title = parent_movie_folder.name

            cache_paths = build_cache_paths_for_title(title)

            entry = {
                "title": title,
                "shared": {
                    "original": str(dvd_image),
                    "video": None,
                    "dvd_root": str(folder),
                    "xml": None,
                },
                "cache": {
                    # v1-style:
                    "relative_thumb": str(Path(title + ".jpg")),
                    "relative_display": str(Path(title + ".jpg")),
                    # v2-style relative cache:
                    "thumb": cache_paths["thumb"],
                    "display": cache_paths["display"],
                    "carousel": cache_paths["carousel"],
                },
                "metadata": {
                    "type": "movie",
                    "year": extract_year_from_title(title),
                    "id": None,
                },
            }
            manifest_entries.append(entry)
            return manifest_entries

    # --- Normal video/image pairing (v1 logic) ---
    try:
        entries = list(folder.iterdir())
    except PermissionError:
        return manifest_entries

    videos = [f for f in entries if f.suffix.lower() in VIDEO_EXTS]
    images = [f for f in entries if f.suffix.lower() in IMAGE_EXTS]
    xmls   = [f for f in entries if f.suffix.lower() in XML_EXTS]

    for video in videos:
        stem = video.stem
        img = next((i for i in images if i.stem == stem), None)
        xml = next((x for x in xmls if x.stem.startswith(stem)), None)

        if not img:
            continue

        # v1 title / year / type logic
        title = stem
        year = extract_year_from_title(stem)
        media_type = "tv" if ("S" in stem and "E" in stem) else "movie"

        cache_paths = build_cache_paths_for_title(title)

        entry = {
            "title": title,
            "shared": {
                "original": str(img),
                "video": str(video),
                "dvd_root": None,
                "xml": str(xml) if xml else None,
            },
            "cache": {
                # v1-style:
                "relative_thumb": str(img.relative_to(ROOT_PATH)),
                "relative_display": str(img.relative_to(ROOT_PATH)),
                # v2-style relative cache:
                "thumb": cache_paths["thumb"],
                "display": cache_paths["display"],
                "carousel": cache_paths["carousel"],
            },
            "metadata": {
                "type": media_type,
                "year": year,
                "id": None,
            },
        }
        manifest_entries.append(entry)

    return manifest_entries


def build_manifest():
    manifest_items = []
    print(f"[{datetime.now()}] Scanning root: {ROOT_PATH}")

    for folder in ROOT_PATH.rglob("*"):
        if not folder.is_dir():
            continue
        if is_excluded(folder):
            continue

        entries = build_manifest_for_folder(folder)
        if entries:
            #print(f"  - Folder: {folder.relative_to(ROOT_PATH)} -> {len(entries)} item(s)")
            manifest_items.extend(entries)

    print(f"[{datetime.now()}] Scan complete. {len(manifest_items)} items collected.\n")
    #return {"items": manifest_items}
    manifest = {
        "version": 2,
        "generated": datetime.now().isoformat(),
        "items": manifest_items
    }
    return manifest

def write_manifest_to_disk():
    """Builds the manifest and writes it to MANIFEST_OUTPUT."""
    manifest = build_manifest()
    MANIFEST_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with open(MANIFEST_OUTPUT, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    print(f"Manifest written to {MANIFEST_OUTPUT}")
    
    # NEW: immediately normalize + hash + append
    processed = process_and_save(MANIFEST_OUTPUT)

    return processed   # return the final, hashed manifest


def write_and_hash_manifest(output_path: Path) -> dict:
    """
    Build a manifest, write it to the given path,
    then normalize + hash via manifest_hash_processor.
    Returns the processed manifest dict. so it sorts it and hashes it and appends the result to
    the foot of the manifest
    """
    manifest = build_manifest()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Save raw manifest first
    with output_path.open("w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    print(f"Raw manifest written to {output_path}")

    # Pass through hash processor (sort + hash + overwrite)
    processed = process_and_save(output_path)
    print(f"Processed + hashed manifest saved to {output_path}")
    return processed



def main():
    print("==============================================")
    print("     MediaVerse Manifest Builder v2 (v1-core)")
    print("==============================================\n")

    manifest = build_manifest()

    MANIFEST_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with open(MANIFEST_OUTPUT, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    print(f"Manifest written to {MANIFEST_OUTPUT}")


if __name__ == "__main__":
    main()