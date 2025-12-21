from pathlib import Path
import os  # needed for os.makedirs

from PySide6.QtCore import QObject, Signal


class CacheBuilder_v2(QObject):
    # Signal emitted when the cache building process starts
    cacheStarted = Signal()

    # Signal emitted during progress: done items, total items
    cacheProgress = Signal(int, int)

    # Signal emitted when the cache building process finishes
    cacheFinished = Signal()

    def __init__(self, manifest, cache_root):
        """
        :param manifest: dict with structure:
            {
              "version": 2,
              "generated": "...",
              "items": [ ... ]
            }
        :param cache_root: root folder for server cache, e.g.
            r"W:\MediaVerse\cache\images"
        """
        super().__init__()

        self.manifest = manifest
        self.cache_root = Path(cache_root)

        # Debug: confirm we received manifest and cache_root correctly
        print(">>> CacheBuilder_v2.__init__ called")
        print(f"    cache_root set to: {self.cache_root}")
        print(f"    manifest type: {type(self.manifest)}")

    def run(self):
        """
        Main method that builds the image cache from the v2 manifest.
        Intended to be run in a background thread.
        """

        print(">>> CacheBuilder_v2.run() started")

        # Emit signal to tell any listeners that cache building has started
        print(">>> Emitting cacheStarted signal")
        self.cacheStarted.emit()

        # Safely get the list of items from the manifest dictionary (v2 structure)
        items = self.manifest.get("items", [])

        print(f">>> Manifest contains {len(items)} items")
        total = len(items)
        done = 0

        for index, item in enumerate(items):
            print(f"\n>>> Processing item {index + 1} of {total}")

            shared = item.get("shared", {})
            cache_info = item.get("cache", {})

            # v2 source image: shared.original
            source_str = shared.get("original")
            print(f"    source_str: {source_str}")

            # v2 cache targets: thumb / display / carousel
            thumb_rel_str = cache_info.get("thumb")
            display_rel_str = cache_info.get("display")
            carousel_rel_str = cache_info.get("carousel")

            print(f"    thumb_rel_str: {thumb_rel_str}")
            print(f"    display_rel_str: {display_rel_str}")
            print(f"    carousel_rel_str: {carousel_rel_str}")

            if not source_str:
                print("    ⚠️ Missing source image, skipping item")
                continue

            # At least thumb should exist to consider this cacheable
            if not thumb_rel_str and not display_rel_str and not carousel_rel_str:
                print("    ⚠️ No cache paths defined, skipping item")
                continue

            source = Path(source_str)

            try:
                if not source.exists():
                    print(f"    ⚠️ Source file does not exist, skipping: {source}")
                    continue

                from PIL import Image

                print(f"    Opening image: {source}")
                img = Image.open(source)

                # Build target paths under server cache root:
                # W:\MediaVerse\cache\images\thumb\..., display\..., carousel\...
                targets = []

                if thumb_rel_str:
                    thumb_name = Path(thumb_rel_str).name
                    thumb_target = self.cache_root / "thumb" / thumb_name
                    targets.append(("thumb", thumb_target))

                if display_rel_str:
                    display_name = Path(display_rel_str).name
                    display_target = self.cache_root / "display" / display_name
                    targets.append(("display", display_target))

                if carousel_rel_str:
                    carousel_name = Path(carousel_rel_str).name
                    carousel_target = self.cache_root / "carousel" / carousel_name
                    targets.append(("carousel", carousel_target))

                # Save image for each required cache variant
                for label, target in targets:
                    print(f"    [{label}] Target path: {target}")
                    print(f"    Ensuring target directory exists: {target.parent}")
                    os.makedirs(target.parent, exist_ok=True)

                    # For now, same image saved; later you can add resizing per type
                    print(f"    Saving {label} cached image to: {target}")
                    img.save(target)

                done += 1
                print(f"    ✅ Cached {done} of {total} items")
                print("    Emitting cacheProgress signal")
                self.cacheProgress.emit(done, total)

            except Exception as e:
                print(f"    ⚠️ Exception while processing {source}: {e}")

        print("\n>>> All items processed (loop complete)")
        print(">>> Emitting cacheFinished signal")
        self.cacheFinished.emit()
        print(">>> CacheBuilder_v2.run() finished")