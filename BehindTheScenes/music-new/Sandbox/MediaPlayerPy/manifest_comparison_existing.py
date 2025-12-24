# manifest_comparison_existing.py
"""
Compare two previously built manifests (A and B).
Loads manifest_A.json and manifest_B.json, processes each with
manifest_hash_processor to normalize + add a hash, writes the updated
manifests back to disk, and compares the hash values.
"""

import json
from pathlib import Path
from manifest_hash_processor import process_manifest

# Paths to the existing manifests
manifest_A_path = Path(r"\\FREENAS\\movies\\MediaVerse\\manifest\\manifest_A.json")
manifest_B_path = Path(r"\\FREENAS\\movies\\MediaVerse\\manifest\\manifest_B.json")

def load_process_and_save(path: Path) -> dict:
    """Load an existing manifest, process it to add hash, and overwrite the file."""
    with path.open("r", encoding="utf-8") as f:
        manifest = json.load(f)

    # Strip volatile fields if present
    manifest.pop("generated", None)
    manifest.pop("_test_run_time", None)

    # Process to normalize + hash
    manifest = process_manifest(manifest)

    # Write the updated manifest back to disk
    with path.open("w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    print(f"{path.name}: {len(manifest.get('items', []))} items, hash={manifest['manifest_hash']}")
    return manifest

if __name__ == "__main__":
    print(f"Manifest A path: {manifest_A_path.resolve()}")
    print(f"Manifest B path: {manifest_B_path.resolve()}")

    manifest_A = load_process_and_save(manifest_A_path)
    manifest_B = load_process_and_save(manifest_B_path)

    # Compare hashes
    if manifest_A["manifest_hash"] == manifest_B["manifest_hash"]:
        print("✅ Manifests are identical (hashes match).")
    else:
        print("❌ Manifests differ (hashes do not match).")
        print(f"Hash A: {manifest_A['manifest_hash']}")
        print(f"Hash B: {manifest_B['manifest_hash']}")