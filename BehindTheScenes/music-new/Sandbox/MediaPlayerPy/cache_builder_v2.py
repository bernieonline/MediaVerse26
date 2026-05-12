from pathlib import Path
import os
from PySide6.QtCore import QObject, Signal


class CacheBuilder_v2(QObject):
    cacheStarted  = Signal()
    cacheProgress = Signal(int, int)   # (written_so_far, total_items)
    cacheFinished = Signal(dict)       # emits a result dict on completion

    print("loading cache_builder_v2")

    def __init__(self, manifest, cache_root):
        super().__init__()
        self.manifest   = manifest
        self.cache_root = Path(cache_root)

        print(">>> CacheBuilder_v2.__init__ called")
        print(f"    cache_root set to: {self.cache_root}")
        print(f"    manifest type: {type(self.manifest)}")

    # ----------------------------------------------------------------
    # Main entry point
    # ----------------------------------------------------------------
    def run(self):
        """
        Incremental build -- only writes image files that do not yet exist.
        Skips carousel tier entirely (not used by any view).

        Emits cacheFinished(result) where result contains:
          written (int)   -- files newly written this run
          skipped (int)   -- files already present, no action needed
          errors  (int)   -- items that failed
          expected_thumb  (int) -- manifest items with a thumb path
          expected_display(int) -- manifest items with a display path
          found_thumb     (int) -- files present in thumb folder after run
          found_display   (int) -- files present in display folder after run
        """
        print(">>> CacheBuilder_v2.run() started")
        self.cacheStarted.emit()

        items   = self.manifest.get("items", [])
        total   = len(items)
        written = 0
        skipped = 0
        errors  = 0
        expected_thumb   = 0
        expected_display = 0

        print(f">>> Manifest contains {total} items")

        # Ensure output folders exist
        (self.cache_root / "thumb").mkdir(parents=True, exist_ok=True)
        (self.cache_root / "display").mkdir(parents=True, exist_ok=True)

        for item in items:
            shared     = item.get("shared", {})
            cache_info = item.get("cache", {})

            source_str      = shared.get("original")
            thumb_rel_str   = cache_info.get("thumb")
            display_rel_str = cache_info.get("display")
            # carousel intentionally excluded -- no view requests it

            if not source_str:
                continue
            if not any([thumb_rel_str, display_rel_str]):
                continue

            source = Path(source_str)

            # Build the list of (label, target_path) pairs for this item
            targets = []
            if thumb_rel_str:
                expected_thumb += 1
                t = self.cache_root / "thumb" / Path(thumb_rel_str).name
                if not t.exists():
                    targets.append(("thumb", t))
                else:
                    skipped += 1

            if display_rel_str:
                expected_display += 1
                t = self.cache_root / "display" / Path(display_rel_str).name
                if not t.exists():
                    targets.append(("display", t))
                else:
                    skipped += 1

            if not targets:
                # Both outputs already present for this item
                continue

            try:
                if not source.exists():
                    errors += 1
                    continue

                from PIL import Image
                img = Image.open(source)

                for label, target in targets:
                    os.makedirs(target.parent, exist_ok=True)
                    img.save(target)
                    written += 1

                self.cacheProgress.emit(written, total)

            except Exception as e:
                errors += 1
                print(f"    [WARN] Exception while processing {source}: {e}")

        # ----------------------------------------------------------------
        # Verification: count actual files on disk vs expected
        # ----------------------------------------------------------------
        found_thumb   = sum(1 for f in (self.cache_root / "thumb").iterdir()   if f.is_file())
        found_display = sum(1 for f in (self.cache_root / "display").iterdir() if f.is_file())

        result = {
            "written":          written,
            "skipped":          skipped,
            "errors":           errors,
            "expected_thumb":   expected_thumb,
            "expected_display": expected_display,
            "found_thumb":      found_thumb,
            "found_display":    found_display,
        }

        thumb_ok   = found_thumb   >= expected_thumb   * 0.95
        display_ok = found_display >= expected_display * 0.95

        if thumb_ok and display_ok:
            print(
                f"[OK] [CacheBuilder_v2] Build complete -- "
                f"written:{written} skipped:{skipped} errors:{errors} | "
                f"thumb:{found_thumb}/{expected_thumb} display:{found_display}/{expected_display}"
            )
        else:
            print(
                f"[WARN] [CacheBuilder_v2] Build finished with gaps -- "
                f"thumb:{found_thumb}/{expected_thumb} display:{found_display}/{expected_display}"
            )

        self.cacheFinished.emit(result)
        print(">>> CacheBuilder_v2.run() finished")
