import json
from pathlib import Path
from collections import Counter, defaultdict

MANIFEST_PATH = Path(r"W:\Collection\ManifestCache\manifest.json")

with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
    manifest = json.load(f)

items = manifest.get("items", [])

# Summary counts
type_counts = Counter(i.get("metadata", {}).get("type", "unknown") for i in items)
print("Counts by type:", dict(type_counts))

# Top folders contributing entries (by image parent)
folder_counts = Counter(Path(i["shared"]["original"]).parent for i in items if i.get("shared", {}).get("original"))
top_folders = folder_counts.most_common(20)
print("\nTop contributing folders:")
for folder, count in top_folders:
    print(f"- {folder} : {count}")

# Duplicates by key
dup_by_title = {t: c for t, c in Counter(i["title"] for i in items).items() if c > 1}
dup_by_video = {v: c for v, c in Counter(i["shared"]["video"] for i in items if i["shared"].get("video")).items() if c > 1}
dup_by_image = {o: c for o, c in Counter(i["shared"]["original"] for i in items if i["shared"].get("original")).items() if c > 1}

print("\nDuplicate titles (top 20):", dict(list(dup_by_title.items())[:20]))
print("Duplicate video paths (top 20):", dict(list(dup_by_video.items())[:20]))
print("Duplicate images (top 20):", dict(list(dup_by_image.items())[:20]))

# Spot patterns: per-folder duplicate titles
dups_per_folder = defaultdict(list)
for i in items:
    folder = str(Path(i["shared"]["original"]).parent)
    dups_per_folder[folder].append(i["title"])

print("\nFolders with many titles (possible over-inclusion):")
for folder, titles in dups_per_folder.items():
    if len(titles) > 20:
        print(f"- {