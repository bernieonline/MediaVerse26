"""
Run manifest_v2 twice on the same library root and compare results.
Relies on manifest_hash_processor for normalization + hash processing.
Saves manifests to W:\MediaVerse\manifest.
"""

import json
from pathlib import Path
from datetime import datetime

from manifest_v2 import write_manifest_to_disk
from manifest_hash_processor import process_and_save

# Canonical server manifest path (where the builder writes)
manifest_dir = Path(r"W:\MediaVerse\manifest")
server_manifest_path = manifest_dir / "manifest.json"

# Ensure the target directory exists
manifest_dir.mkdir(parents=True, exist_ok=True)

# Paths for comparison outputs (saved in the same folder)
manifest_A_path = manifest_dir / "manifest_A.json"
manifest_B_path = manifest_dir / "manifest_B.json"


def build_manifest(out_path: Path) -> dict:
    """Build raw server manifest, then normalize + hash and save to out_path."""
    # Step 1: builder writes raw manifest to server_manifest_path
    write_manifest_to_disk()

    # Step 2: normalize + hash the raw manifest and save to out_path
    # process_and_save loads from out_path itself, so we need to pass the raw data.
    # To keep single-source truth, read raw, process, then write to out_path:

    with server_manifest_path.open("r", encoding="utf-8") as f:
        manifest = json.load(f)

    # Strip volatile fields (if present)
    manifest.pop("generated", None)
    manifest.pop("_test_run_time", None)

    # Normalize + hash
    from manifest_hash_processor import process_manifest
    manifest = process_manifest(manifest)

    # Stamp for clarity (does not affect comparison since it’s not in hash inputs)
    manifest["_test_run_time"] = datetime.now().isoformat()

    # Save processed manifest to the requested output path in W:\MediaVerse\manifest
    with out_path.open("w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    #print(f"Saved: {out_path} ({len(manifest.get('items', []))} items), hash={manifest['manifest_hash']}")
    return manifest


if __name__ == "__main__":
    #print(f"Server manifest dir: {manifest_dir.resolve()}")
    #print(f"Server manifest path: {server_manifest_path.resolve()}")
    #print(f"Manifest A path: {manifest_A_path.resolve()}")
    #print(f"Manifest B path: {manifest_B_path.resolve()}")

    # Build two manifests back-to-back, both saved under W:\MediaVerse\manifest
    manifest_A = build_manifest(manifest_A_path)
    manifest_B = build_manifest(manifest_B_path)

    # Report hashes and verdict
    hash_A = manifest_A["manifest_hash"]
    hash_B = manifest_B["manifest_hash"]

    print("\n--- Hash Comparison Report ---")
    print(f"Manifest A hash: {hash_A}")
    print(f"Manifest B hash: {hash_B}")
    if hash_A == hash_B:
        print("✅ Hashes MATCH — manifests are identical.")
    else:
        print("❌ Hashes DO NOT MATCH — manifests differ.")

    # One sample record from each
    #print("\nSample record from Manifest A:")
    sample_A = manifest_A["items"][0]
    #print(f"Title: {sample_A.get('title')}")
    #print(f"Original path: {sample_A.get('shared', {}).get('original') or 'zzz'}")

    #print("\nSample record from Manifest B:")
    sample_B = manifest_B["items"][0]
    #print(f"Title: {sample_B.get('title')}")
    #print(f"Original path: {sample_B.get('shared', {}).get('original') or 'zzz'}")