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
from NotificationManager import notifier
import shutil
import traceback
from CacheSyncWorker import CacheSyncWorker
from PySide6.QtCore import QThread



from PySide6.QtCore import QObject, Signal
from project_paths import (
    server_manifest_v2,
    server_cache_thumb_v2,
    server_cache_display_v2,
    server_cache_carousel_v2,
    local_manifest_v2,
    local_thumb_v2,
    local_display_v2,
    local_carousel_v2,
)

print("loading cacheBuilderOnServer_v2..........................")

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
        try:
            #print(">>> CacheBuilder_v2.run() started")
            notifier.post_notification("Building server cache…", False)
            self.cacheStarted.emit()

            items = self.manifest.get("items", [])
            total = len(items)
            done = 0

            # ADD THESE TWO LINES HERE
            print(f"DEBUG: Manifest keys found: {list(self.manifest.keys())}")
            print(f"DEBUG: Type of 'items' found: {type(items)}")

            print(f">>> Manifest contains {total} items")


            for index, item in enumerate(items):
                #print(f"\n>>> Processing item {index + 1} of {total}")

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
                    #print(f"    Opening image: {source}")
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

                        #print(f"    [thumb] → {thumb_target}")
                        thumb_img = self._resize_portrait(img, self.THUMB_HEIGHT)
                        thumb_img.save(thumb_target, quality=85, optimize=True)

                    if display_rel:
                        display_name = Path(display_rel).name
                        display_target = self.cache_root / "display" / display_name
                        os.makedirs(display_target.parent, exist_ok=True)

                        #print(f"    [display] → {display_target}")
                        display_img = self._resize_portrait(img, self.DISPLAY_HEIGHT)
                        display_img.save(display_target, quality=85, optimize=True)

                    if carousel_rel:
                        carousel_name = Path(carousel_rel).name
                        carousel_target = self.cache_root / "carousel" / carousel_name
                        os.makedirs(carousel_target.parent, exist_ok=True)

                        #print(f"    [carousel] → {carousel_target}")
                        carousel_img = self._resize_carousel(img, self.CAROUSEL_WIDTH)
                        carousel_img.save(carousel_target, quality=85, optimize=True)

                    done += 1
                    print(f"    ✅ Cached {done} of {total}")
                    self.cacheProgress.emit(done, total)
                    print("############   after cachProgress emit   ###################")

                except Exception as e:
                    print(f"    ⚠️ Error processing {source}: {e}")

           

            #update local copies from server copies
            #self.sync_to_local()
            
            print("############   next is sync to local ###################")
            # DIAGNOSTIC CALL
            #try:
                #print(f"!!!  SYNC CALL : ")
                ##self.sync_to_local()
            #except Exception as sync_err:
                #print(f"!!! CRITICAL SYNC CALL FAILURE: {sync_err}")
                #traceback.print_exc()

            print("\n>>> Cache building complete")
            self.cacheFinished.emit()
            print(">>> CacheBuilder_v2.run() finished")

            #
            #HAND BACK TO WRAPPER TO CLONE SERVER CACH TO LOCAL DRIVE


        except Exception as e:
            print(f"[CacheBuilder_v2] ERROR in run(): {e}")
            traceback.print_exc()

            



    def sync_to_local_old(self):
        #this ensures that the local cache and manifest are updated
        #each time that the cache on the server is built
        

        print("[CacheBuilder_v2] Syncing server → local...")
        print("[CacheBuilder_v2] Sync complete.")



        # Ensure local directories exist
        local_manifest_v2.parent.mkdir(parents=True, exist_ok=True)
        local_thumb_v2.mkdir(parents=True, exist_ok=True)
        local_display_v2.mkdir(parents=True, exist_ok=True)
        local_carousel_v2.mkdir(parents=True, exist_ok=True)

        # Copy manifest
        #no longer need a cocal copy
        #shutil.copy2(server_manifest_v2, local_manifest_v2 / "manifest.json")

        # Copy cache folders
        for src, dst in [
            (server_cache_thumb_v2, local_thumb_v2),
            (server_cache_display_v2, local_display_v2),
            (server_cache_carousel_v2, local_carousel_v2),
        ]:
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(src, dst)

        print("[CacheBuilder_v2] Sync complete.")   
        notifier.post_notification("Local cache updated.", False) 

    def sync_to_local(self):
        print("\n" + "="*50)
        print("[DEBUG] STARTING SYNC_TO_LOCAL")
        print("="*50)

        sync_map = [
            ("Thumb", server_cache_thumb_v2, local_thumb_v2),
            ("Display", server_cache_display_v2, local_display_v2),
            ("Carousel", server_cache_carousel_v2, local_carousel_v2),
        ]

        for label, src, dst in sync_map:
            print(f"\n>>> Checking {label}:")
            
            # Convert to Path objects to be 100% sure
            src_p = Path(src)
            dst_p = Path(dst)

            print(f"    Source Path: {src_p} (Exists: {src_p.exists()})")
            print(f"    Dest Path:   {dst_p} (Exists: {dst_p.exists()})")

            if not src_p.exists():
                print(f"    ⚠️ SKIPPING: {label} source folder not found on server.")
                continue

            # Check file counts on server
            src_files = list(src_p.glob("*"))
            print(f"    Server files found: {len(src_files)}")

            try:
                # Step 1: Handle Destination
                if dst_p.exists():
                    print(f"    Attempting to remove old local folder: {dst_p}")
                    # We use ignore_errors=False here for debugging so we see the lock!
                    shutil.rmtree(dst_p) 
                    print("    Successfully removed old folder.")
                
                # Step 2: Ensure Parent exists
                dst_p.parent.mkdir(parents=True, exist_ok=True)

                # Step 3: Copy
                print(f"    Copying {len(src_files)} files to {dst_p}...")
                
                # If your Python is 3.8+, use dirs_exist_ok=True for extra reliability
                shutil.copytree(src_p, dst_p, dirs_exist_ok=True)
                
                # Verify result
                new_count = len(list(dst_p.glob("*")))
                print(f"    ✅ {label} Sync Success! Local count: {new_count}")

            except Exception as e:
                print(f"    ❌ ERROR syncing {label}:")
                print(f"    Type: {type(e).__name__}")
                print(f"    Message: {str(e)}")
                # This is the "God mode" debug info for Windows locks
                if "PermissionError" in str(type(e)):
                    print("    💡 ANALYSIS: A file is likely LOCKED by the QML UI or Windows Explorer.")

        print("\n" + "="*50)
        print("[DEBUG] SYNC_TO_LOCAL FINISHED")
        print("="*50)
        notifier.post_notification("Local cache sync attempted (see logs).", False)


