import os
import json
import re
from pathlib import Path
from datetime import datetime
from manifest_hash_processor import process_and_save

print("loading manifest_v3.py")

# --- Root location ---
ROOT_PATH = Path(r"W:\Collection")
MANIFEST_OUTPUT = Path(r"W:\MediaVerse\manifest\manifest.json")

# --- Folders to exclude ---
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
    base = f"{title}.jpg"
    return {
        "thumb": f"Cache/thumb/{base}",
        "display": f"Cache/display/{base}",
        "carousel": f"Cache/carousel/{base}",
    }

def build_manifest_for_folder(folder: Path):
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
        img = next((i for i in images if i.stem == stem), None)
        xml = next((x for x in xmls if x.stem.startswith(stem)), None)

        if not img:
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

    return manifest_entries

def build_manifest() -> dict:
    manifest_items = []
    print(f"[{datetime.now()}] Scanning root: {ROOT_PATH}")

    for folder in ROOT_PATH.rglob("*"):
        if not folder.is_dir():
            continue
        if is_excluded(folder):
            continue

        entries = build_manifest_for_folder(folder)
        if entries:
            manifest_items.extend(entries)

    print(f"[{datetime.now()}] Scan complete. {len(manifest_items)} items collected.\n")
    manifest = {
        "version": 3,
        "generated": datetime.now().isoformat(),
        "items": manifest_items
    }
    return manifest

def write_manifest_to_disk(output_path: Path = None) -> dict:
    manifest = build_manifest()

    if output_path is None:
        output_path = MANIFEST_OUTPUT

    output_path.parent.mkdir(parents=True, exist_ok=True)

    with output_path.open("w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    print(f"Raw manifest written to {output_path}")

    processed = process_and_save(output_path)
    print(f"Processed + hashed manifest saved to {output_path}")
    return processed