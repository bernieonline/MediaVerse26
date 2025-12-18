import json
from pathlib import Path
from collections import Counter

MANIFEST_PATH = Path(r"W:\Collection\ManifestCache\manifest.json")

with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
    manifest = json.load(f)

items = manifest["items"]

# Count duplicates by title
title_counts = Counter(item["title"] for item in items)
dup_titles = [t for t, c in title_counts.items() if c > 1]

# Count duplicates by video path
video_counts = Counter(item["shared"]["video"] for item in items if item["shared"]["video"])
dup_videos = [v for v, c in video_counts.items() if c > 1]

# Count duplicates by original image
image_counts = Counter(item["shared"]["original"] for item in items if item["shared"]["original"])
dup_images = [i for i, c in image_counts.items() if c > 1]

print("Duplicate titles:", dup_titles)
#print("Duplicate video paths:", dup_videos)
#print("Duplicate images:", dup_images)