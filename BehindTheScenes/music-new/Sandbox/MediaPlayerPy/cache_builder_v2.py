from pathlib import Path
import os
from PySide6.QtCore import QObject, Signal

class CacheBuilder_v2(QObject):
    cacheStarted = Signal()
    cacheProgress = Signal(int, int)
    cacheFinished = Signal()

    def __init__(self, manifest, cache_root):
        super().__init__()
        self.manifest = manifest
        self.cache_root = Path(cache_root)

        print(">>> CacheBuilder_v2.__init__ called")
        print(f"    cache_root set to: {self.cache_root}")
        print(f"    manifest type: {type(self.manifest)}")

    def run(self):
        print(">>> CacheBuilder_v2.run() started")
        self.cacheStarted.emit()

        items = self.manifest.get("items", [])
        total = len(items)
        done = 0

        print(f">>> Manifest contains {total} items")

        for index, item in enumerate(items):
            print(f"\n>>> Processing item {index + 1} of {total}")

            shared = item.get("shared", {})
            cache_info = item.get("cache", {})

            source_str = shared.get("original")
            thumb_rel_str = cache_info.get("thumb")
            display_rel_str = cache_info.get("display")
            carousel_rel_str = cache_info.get("carousel")

            print(f"    source_str: {source_str}")
            print(f"    thumb_rel_str: {thumb_rel_str}")
            print(f"    display_rel_str: {display_rel_str}")
            print(f"    carousel_rel_str: {carousel_rel_str}")

            if not source_str:
                print("    ⚠️ Missing source image, skipping item")
                continue

            if not any([thumb_rel_str, display_rel_str, carousel_rel_str]):
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

                targets = []

                if thumb_rel_str:
                    thumb_name = Path(thumb_rel_str).name
                    targets.append(("thumb", self.cache_root / "thumb" / thumb_name))

                if display_rel_str:
                    display_name = Path(display_rel_str).name
                    targets.append(("display", self.cache_root / "display" / display_name))

                if carousel_rel_str:
                    carousel_name = Path(carousel_rel_str).name
                    targets.append(("carousel", self.cache_root / "carousel" / carousel_name))

                for label, target in targets:
                    print(f"    [{label}] Target path: {target}")
                    os.makedirs(target.parent, exist_ok=True)
                    img.save(target)

                done += 1
                print(f"    ✅ Cached {done} of {total} items")
                self.cacheProgress.emit(done, total)

            except Exception as e:
                print(f"    ⚠️ Exception while processing {source}: {e}")

        print("\n>>> All items processed")
        self.cacheFinished.emit()
        print(">>> CacheBuilder_v2.run() finished")