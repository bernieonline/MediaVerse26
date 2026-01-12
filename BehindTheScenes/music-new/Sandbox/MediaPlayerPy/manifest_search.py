import json
from pathlib import Path

manifest_path = Path(r"W:\MediaVerse\manifest\manifest_v2.json")

with manifest_path.open("r", encoding="utf-8") as f:
    manifest = json.load(f)

items = manifest.get("items", [])

# Find items where shared.original is missing or null
missing_original = [item for item in items if not item.get("shared", {}).get("original")]

#print(f"Total items: {len(items)}")
#print(f"Items with missing/null original: {len(missing_original)}")

# Show a few examples
for i, item in enumerate(missing_original[:5], start=1):
    print(f"{i}. Title: {item.get('title')} | shared.original: {item.get('shared', {}).get('original')}")