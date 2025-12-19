"""
manifest.py
Builds a unified media manifest from W:\Collection.
- Loads existing manifest instantly at startup if present.
- Always triggers a background refresh to rebuild manifest.json.
- Emits Qt signals so QML can react (refreshStarted, refreshFinished).
- Deduplicates entries by video and image path.
- Normalizes cache paths relative to ROOT_PATH.
"""

import os
import sys
import json
import threading
from pathlib import Path
from PySide6.QtCore import QObject, Signal

# add project paths
sys.path.append(r"D:\MediaVerse1.0\BehindTheScenes\BehindTheScenes\music-new")
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))

from project_paths import paths

# --- Root location ---
ROOT_PATH = Path(r"W:\Collection")
MANIFEST_PATH = paths["manifest"] / "manifest.json"   # use MediaVerse manifest folder

# --- Folders to exclude ---
EXCLUDE_FOLDERS = [
    r"W:\Collection\TV Shows\Slow Horses",
    r"W:\Collection\Movies\The Accountant (2016)",
    r"W:\Collection\Clips",
    r"W:\Collection\Extras",
    r"W:\Collection\Temp"
]

IMAGE_EXTS = (".jpg", ".jpeg", ".png")
VIDEO_EXTS = (".mp4", ".mkv", ".avi", ".m2ts", ".ts", ".webm")
XML_EXTS   = (".xml",)

exceptions = []

class ManifestUpdater(QObject):
    refreshStarted = Signal()
    refreshFinished = Signal()

    def __init__(self):
        super().__init__()
        print("inside manifest __init__")

    def update_manifest_background(self):
        print(">>> Signal: refreshStarted emitted")
        self.refreshStarted.emit()
        manifest = self.build_full_manifest()
        with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
            json.dump(manifest, f, indent=2)
        print(f"Manifest written to {MANIFEST_PATH}")
        print(">>> Signal: refreshFinished emitted")
        self.refreshFinished.emit()

    def build_full_manifest(self):
        manifest = {"items": []}
        print(f"Scanning root: {ROOT_PATH}")
        for folder in ROOT_PATH.rglob("*"):
            if not folder.is_dir():
                continue
            if any(str(folder).startswith(ex) for ex in EXCLUDE_FOLDERS):
                continue
            entries = self.build_manifest_for_folder(folder)
            manifest["items"].extend(entries)
        return manifest

    def build_manifest_for_folder(self, folder: Path):
        manifest_entries = []

        # --- DVD detection: current folder IS VIDEO_TS ---
        if folder.name.upper() == "VIDEO_TS":
            dvd_image = next(
                (f for f in folder.iterdir() if f.stem.upper() == "VIDEO_TS" and f.suffix.lower() in (".jpg", ".jpeg")),
                None
            )
            if dvd_image and dvd_image.exists():
                parent_movie_folder = folder.parent  # two levels up from image
                title = parent_movie_folder.name

                entry = {
                    "title": title,
                    "shared": {
                        "original": str(dvd_image),
                        "video": None,
                        "dvd_root": str(folder),
                        "xml": None
                    },
                    "cache": {
                        # logical rename for UI
                        "relative_thumb": str(Path(title + ".jpg")),
                        "relative_display": str(Path(title + ".jpg"))
                    },
                    "metadata": {
                        "type": "movie",
                        "year": self.extract_year_from_title(title),
                        "id": None
                    }
                }
                manifest_entries.append(entry)
                return manifest_entries

        # --- Normal video/image pairing ---
        videos = [f for f in folder.iterdir() if f.suffix.lower() in VIDEO_EXTS]
        images = [f for f in folder.iterdir() if f.suffix.lower() in IMAGE_EXTS]
        xmls   = [f for f in folder.iterdir() if f.suffix.lower() in XML_EXTS]

        for video in videos:
            stem = video.stem
            img = next((i for i in images if i.stem == stem), None)
            xml = next((x for x in xmls if x.stem.startswith(stem)), None)

            if img:
                entry = {
                    "title": stem,
                    "shared": {
                        "original": str(img),
                        "video": str(video),
                        "dvd_root": None,
                        "xml": str(xml) if xml else None
                    },
                    "cache": {
                        "relative_thumb": str(img.relative_to(ROOT_PATH)),
                        "relative_display": str(img.relative_to(ROOT_PATH))
                    },
                    "metadata": {
                        "type": "tv" if "S" in stem and "E" in stem else "movie",
                        "year": self.extract_year_from_title(stem),
                        "id": None
                    }
                }
                manifest_entries.append(entry)

        return manifest_entries

    def extract_year_from_title(self, title: str):
        import re
        match = re.search(r"\((\d{4})\)", title)
        if match:
            return int(match.group(1))
        return None


def load_manifest():
    if MANIFEST_PATH.exists():
        with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"items": []}


def main():
    print("starting main()")
    updater = ManifestUpdater()
    updater.refreshStarted.connect(lambda: print(">>> Connected slot: refreshStarted"))
    updater.refreshFinished.connect(lambda: print(">>> Connected slot: refreshFinished"))

    manifest = load_manifest()
    print(f"Loaded manifest with {len(manifest['items'])} entries.")
    print("MANIFEST_PATH is:", MANIFEST_PATH)

    # Run synchronously for debugging
    updater.update_manifest_background()

    # Reload after refresh to see updated count
    manifest = load_manifest()
    print(f"Reloaded manifest with {len(manifest['items'])} entries.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        import traceback
        print(">>> Fatal error:", e)
        traceback.print_exc()