"""
manifest_hash_processor.py
Normalize and hash manifests for deterministic comparison.
Optionally writes the updated manifest back to disk.
"""

import hashlib
import json
from pathlib import Path

def process_manifest(manifest: dict) -> dict:
    """
    Sort manifest row items by shared.original (fallback 'zzz') and compute a hash based on
    title, original, and xml. Store the hash at the head of the manifest.
    """
    items = manifest.get("items", [])

    # Sort deterministically by shared.original, fallback to 'zzz'
    items_sorted = sorted(
        items,
        key=lambda x: x.get("shared", {}).get("original") or "zzz"
    )

    # Build concatenated strings for hashing
    concat_list = []
    for item in items_sorted:
        original = item.get("shared", {}).get("original") or "zzz"
        xml = item.get("shared", {}).get("xml") or ""
        title = item.get("title", "")
        concat = f"{title}|{original}|{xml}"
        concat_list.append(concat)

    # Compute hash
    combined = "\n".join(concat_list)
    manifest_hash = hashlib.sha256(combined.encode("utf-8")).hexdigest()

    # Update manifest
    manifest["items"] = items_sorted
    manifest["manifest_hash"] = manifest_hash
    return manifest

def process_and_save(path: Path) -> dict:
    """
    Load a manifest from disk, process it to add hash,
    and overwrite the file with the updated manifest.
    """
    with path.open("r", encoding="utf-8") as f:
        manifest = json.load(f)

    manifest.pop("generated", None)
    manifest.pop("_test_run_time", None)

    manifest = process_manifest(manifest)

    with path.open("w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    #print(f"{path.name}: {len(manifest.get('items', []))} items, hash={manifest['manifest_hash']}")
    return manifest