# run_cache_builder.py

import json
from pathlib import Path
from datetime import datetime

from cache_builder_v2 import CacheBuilder_v2
from NotificationManager import notifier  # optional

MANIFEST_PATH = r"W:\MediaVerse\manifest\manifest.json"
CACHE_ROOT = r"W:\MediaVerse\cache\images"
CACHE_INFO_PATH = r"W:\MediaVerse\cache\cache_info.json"


def write_cache_info(manifest):
    """Write cache_info.json after cache build completes."""
    info = {
        "cache_built": datetime.now().isoformat(),
        "manifest_generated": manifest.get("generated", "")
    }

    with open(CACHE_INFO_PATH, "w") as f:
        json.dump(info, f, indent=2)

    print(f">>> cache_info.json written to {CACHE_INFO_PATH}")


def main():
    print(">>> Stand-alone Cache Builder v2 starting")

    # Load manifest
    manifest_file = Path(MANIFEST_PATH)
    if not manifest_file.exists():
        print(f"ERROR: Manifest not found at {MANIFEST_PATH}")
        notifier.post_notification("Manifest not found — cannot build cache", True)
        return

    with open(manifest_file, "r") as f:
        manifest = json.load(f)

    print(f">>> Manifest loaded: {len(manifest.get('items', []))} items")

    # Create builder
    builder = CacheBuilder_v2(manifest, CACHE_ROOT)

    # Optional: connect signals to print progress
    builder.cacheStarted.connect(lambda: print(">>> Cache build started"))
    builder.cacheProgress.connect(lambda d, t: print(f">>> Progress: {d}/{t}"))
    builder.cacheFinished.connect(lambda result: print(f">>> Cache build finished — {result}"))

    # Run builder
    builder.run()

    # Write cache_info.json
    write_cache_info(manifest)

    notifier.post_notification("Server cache build completed", False)
    print(">>> Stand-alone Cache Builder v2 complete")


if __name__ == "__main__":
    main()