# CacheBuilder_v2.py
# MediaVerse V2 Cache Builder
#
# Generates three optimized image sizes:
#   - thumb:   300px tall (grid view)
#   - display: 900px tall (detail view)
#   - carousel: 1600px wide (hero banner)
#
# All images are resized, compressed, and saved to the server cache.

from pathlib import Path
import os

from PySide6.QtCore import QObject, Signal


class CacheBuilder_v2(QObject):
    cacheStarted = Signal()
    cacheProgress = Signal(int, int)
    cacheFinished = Signal()

    # ---------------------------------------------------------
    # Target resolutions
    # ---------------------------------------------------------
    THUMB_HEIGHT = 300
    DISPLAY_HEIGHT = 900
    CAROUSEL_WIDTH = 1600

    def __init__(self, manifest, cache_root):
        super().__init__()

        self.manifest = manifest
        self.cache_root = Path(cache_root)

        print(">>> CacheBuilder_v2 initialized")
        print(f"    cache_root = {self.cache_root}")

    # ---------------------------------------------------------
    # Image resizing helpers
    # ---------------------------------------------------------
    def _resize_portrait(self, img, target_height):
        """Resize portrait poster to a specific height, preserving 2:3 ratio."""
        w, h = img.size
        scale = target_height / h
        new_w = int(w * scale)
        new_h = int(h * scale)
        return img.resize((new_w, new_h))

    def _resize_carousel(self, img, target_width):
        """
        Resize portrait poster into a landscape hero banner.
        Strategy:
          1. Scale image so width >= target_width
          2. Crop vertically to create a cinematic banner
        """
        w, h = img.size
        scale = target_width / w
        new_w = target_width
        new_h = int(h * scale)

        img = img.resize((new_w, new_h))

        # Crop to cinematic height (900px)
        target_h = 900
        if new_h > target_h:
            top = (new_h - target_h) // 2
            bottom = top + target_h
            img = img.crop((0, top, new_w, bottom))

        return img

    # ---------------------------------------------------------
    # Main processing loop
    # ---------------------------------------------------------
    def run(self):
        print(">>> CacheBuilder_v2.run() started")
        self.cacheStarted.emit()

        items = self.manifest.get("items", [])
        total = len(items)
        done = 0

        print(f">>> Manifest contains {total} items")

        from PIL import Image, ImageOps

        for index, item in enumerate(items):
            print(f"\n>>> Processing item {index + 1} of {total}")

            shared = item.get("shared", {})
            cache_info = item.get("cache", {})

            source_str = shared.get("original")
            if not source_str:
                print("    ⚠️ No source image path — skipping")
                continue

            source = Path(source_str)
            if not source.exists():
                print(f"    ⚠️ Source file missing: {source}")
                continue

            # Cache filenames
            thumb_rel = cache_info.get("thumb")
            display_rel = cache_info.get("display")
            carousel_rel = cache_info.get("carousel")

            # Skip if no cache targets
            if not any([thumb_rel, display_rel, carousel_rel]):
                print("    ⚠️ No cache targets defined — skipping")
                continue

            try:
                print(f"    Opening image: {source}")
                img = Image.open(source)

                # Fix EXIF orientation if needed
                img = ImageOps.exif_transpose(img)

                # Ensure RGB for JPEG output
                if img.mode not in ("RGB", "RGBA"):
                    img = img.convert("RGB")

                # ---------------------------------------------------------
                # Build each cache variant
                # ---------------------------------------------------------
                if thumb_rel:
                    thumb_name = Path(thumb_rel).name
                    thumb_target = self.cache_root / "thumb" / thumb_name
                    os.makedirs(thumb_target.parent, exist_ok=True)

                    print(f"    [thumb] → {thumb_target}")
                    thumb_img = self._resize_portrait(img, self.THUMB_HEIGHT)
                    thumb_img.save(thumb_target, quality=85, optimize=True)

                if display_rel:
                    display_name = Path(display_rel).name
                    display_target = self.cache_root / "display" / display_name
                    os.makedirs(display_target.parent, exist_ok=True)

                    print(f"    [display] → {display_target}")
                    display_img = self._resize_portrait(img, self.DISPLAY_HEIGHT)
                    display_img.save(display_target, quality=85, optimize=True)

                if carousel_rel:
                    carousel_name = Path(carousel_rel).name
                    carousel_target = self.cache_root / "carousel" / carousel_name
                    os.makedirs(carousel_target.parent, exist_ok=True)

                    print(f"    [carousel] → {carousel_target}")
                    carousel_img = self._resize_carousel(img, self.CAROUSEL_WIDTH)
                    carousel_img.save(carousel_target, quality=85, optimize=True)

                done += 1
                print(f"    ✅ Cached {done} of {total}")
                self.cacheProgress.emit(done, total)

            except Exception as e:
                print(f"    ⚠️ Error processing {source}: {e}")

        print("\n>>> Cache building complete")
        self.cacheFinished.emit()
        print(">>> CacheBuilder_v2.run() finished")