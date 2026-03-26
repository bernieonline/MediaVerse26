import os
import json
import re
from pathlib import Path
from datetime import datetime
from manifest_hash_processor import process_and_save

print("loading manifest_v3.py")

from project_paths import paths

# --- Root location ---
ROOT_PATH       = paths["library_root"]
MANIFEST_OUTPUT = paths["server_manifest_v2"]

# --- Folders to exclude ---
EXCLUDE_FOLDER_NAMES = [
    "TV Shows/Slow Horses",
    "Movies/The Accountant (2016)",
    "Clips",
    "Extras",
    "Temp",
]
EXCLUDE_FOLDERS = [str(ROOT_PATH / rel) for rel in EXCLUDE_FOLDER_NAMES]

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
    base = f"{title}.jpg"
    return {
        "thumb": f"Cache/thumb/{base}",
        "display": f"Cache/display/{base}",
        "carousel": f"Cache/carousel/{base}",
    }

def build_manifest_for_folder(folder: Path, stats: dict) -> list:
    manifest_entries = []

    # --- DVD detection: VIDEO_TS folder ---
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
                    "relative_thumb": str(Path(title + ".jpg")),
                    "relative_display": str(Path(title + ".jpg")),
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

    # --- Normal video/image pairing ---
    try:
        entries = list(folder.iterdir())
    except PermissionError:
        print(f"[Skip] Permission denied: {folder}")
        return manifest_entries

    videos = [f for f in entries if f.suffix.lower() in VIDEO_EXTS]
    images = [f for f in entries if f.suffix.lower() in IMAGE_EXTS]
    xmls   = [f for f in entries if f.suffix.lower() in XML_EXTS]

    for video in videos:
        stem = video.stem
        stem_lower = stem.lower()
        img = next((i for i in images if i.stem.lower() == stem_lower), None)
        xml = next((x for x in xmls if x.stem.lower().startswith(stem_lower)), None)

        stats["total_videos"] += 1
        if not img:
            stats["rejected"] += 1
            stats["rejected_files"].append({"path": str(video), "reason": "no_image"})
            continue

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
                "relative_thumb": str(img.relative_to(ROOT_PATH)),
                "relative_display": str(img.relative_to(ROOT_PATH)),
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
        stats["accepted"] += 1
        if not xml:
            stats["no_xml"] += 1

    return manifest_entries

def build_manifest() -> tuple:
    stats = {
        "run_timestamp":  datetime.now().isoformat(),
        "total_videos":   0,
        "accepted":       0,
        "rejected":       0,
        "no_xml":         0,
        "rejected_files": [],
    }
    manifest_items = []
    print(f"[{datetime.now()}] Scanning root: {ROOT_PATH}")

    for folder in ROOT_PATH.rglob("*"):
        if not folder.is_dir():
            continue
        if is_excluded(folder):
            continue

        entries = build_manifest_for_folder(folder, stats)
        if entries:
            manifest_items.extend(entries)

    print(f"[{datetime.now()}] Scan complete. {len(manifest_items)} items collected.\n")
    manifest = {
        "version":       3,
        "generated":     datetime.now().isoformat(),
        "scan_complete": True,
        "items":         manifest_items,
    }
    return manifest, stats

def write_manifest_to_disk(output_path: Path = None) -> tuple:
    manifest, stats = build_manifest()

    if output_path is None:
        output_path = MANIFEST_OUTPUT

    output_path.parent.mkdir(parents=True, exist_ok=True)

    from json_safe import safe_json_write
    safe_json_write(output_path, manifest)
    print(f"Raw manifest written to {output_path}")

    processed = process_and_save(output_path)
    print(f"Processed + hashed manifest saved to {output_path}")
    return processed, stats