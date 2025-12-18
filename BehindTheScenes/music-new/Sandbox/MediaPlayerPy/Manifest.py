#!/usr/bin/env python3
"""
manifest.py
Builds a unified media manifest from W:\Collection.
- Loads existing manifest instantly at startup if present.
- Always triggers a background refresh to rebuild manifest.json.
- Emits Qt signals so QML can react (refreshStarted, refreshFinished).
- Deduplicates entries by video and image path.
- Normalizes cache paths relative to ROOT_PATH.
"""

import json, threading
from pathlib import Path
from PySide6.QtCore import QObject, Signal

# --- Root location ---
ROOT_PATH = Path(r"W:\Collection")
MANIFEST_PATH = Path(r"W:\Collection\ManifestCache\manifest.json")

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

    def build_manifest_for_folder(self, folder: Path):
        manifest_entries = []

        # Collect video stems
        video_files = [v for v in folder.glob("*") if v.suffix.lower() in VIDEO_EXTS]
        video_stems = {v.stem for v in video_files}

        # For each stem, find preferred image and xml
        for stem in sorted(video_stems):
            img = None
            for ext in IMAGE_EXTS:
                candidate = folder / f"{stem}{ext}"
                if candidate.exists():
                    img = candidate
                    break
            if not img:
                continue

            video_path = None
            for ext in VIDEO_EXTS:
                candidate = folder / f"{stem}{ext}"
                if candidate.exists():
                    video_path = candidate
                    break
            if not video_path:
                continue

            # Attach XML if present
            xml_path = None
            for xml in folder.glob("*.xml"):
                if stem.lower() in xml.stem.lower():
                    xml_path = xml
                    break

            entry = {
                "title": stem,
                "shared": {
                    "original": str(img),
                    "video": str(video_path),
                    "dvd_root": None,
                    "xml": str(xml_path) if xml_path else None
                },
                "cache": {
                    "relative_thumb": str(img.relative_to(ROOT_PATH)).replace(".png", ".jpg"),
                    "relative_display": str(img.relative_to(ROOT_PATH)).replace(".png", ".jpg")
                },
                "metadata": {
                    "type": "tv" if "TV Shows" in str(folder) else "movie",
                    "year": None,
                    "id": None
                }
            }
            manifest_entries.append(entry)

        if not manifest_entries:
            exceptions.append(str(folder))

        return manifest_entries

    def build_full_manifest(self):
        manifest = {"items": []}
        seen_videos = set()
        seen_images = set()

        if ROOT_PATH.exists():
            print(f"Scanning {ROOT_PATH} recursively...")
            for folder in ROOT_PATH.glob("**/*"):
                if folder.is_dir():
                    if any(str(folder).startswith(excluded) for excluded in EXCLUDE_FOLDERS):
                        continue
                    entries = self.build_manifest_for_folder(folder)
                    for entry in entries:
                        video = entry["shared"]["video"]
                        image = entry["shared"]["original"]

                        # Deduplication
                        if video in seen_videos or image in seen_images:
                            continue
                        seen_videos.add(video)
                        seen_images.add(image)

                        manifest["items"].append(entry)

        MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
        with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
            json.dump(manifest, f, indent=2)
        print(f"Manifest written to {MANIFEST_PATH}")
        return manifest

    def update_manifest_background(self):
        self.refreshStarted.emit()
        print(">>> Signal: refreshStarted emitted")
        self.build_full_manifest()
        self.refreshFinished.emit()
        print(">>> Signal: refreshFinished emitted")


def load_manifest():
    if MANIFEST_PATH.exists():
        with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    else:
        return {"items": []}


def main():
    updater = ManifestUpdater()

    # Connect signals to console output for testing
    updater.refreshStarted.connect(lambda: print(">>> Connected slot: refreshStarted"))
    updater.refreshFinished.connect(lambda: print(">>> Connected slot: refreshFinished"))

    # 1. Load instantly
    manifest = load_manifest()
    print(f"Loaded manifest with {len(manifest['items'])} entries.")

    # 2. Kick off background refresh with signals
    threading.Thread(target=updater.update_manifest_background, daemon=True).start()


if __name__ == "__main__":
    main()