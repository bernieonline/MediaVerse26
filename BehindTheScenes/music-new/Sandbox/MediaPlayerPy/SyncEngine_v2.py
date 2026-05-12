

import json
import shutil
from pathlib import Path
from datetime import datetime

from PySide6.QtCore import QObject
from NotificationManager import notifier

from project_paths import paths
from cache_builder_v2 import CacheBuilder_v2
from NotificationManager import notifier


class SyncEngine_v2(QObject):

    def __init__(self):
        super().__init__()

        # ---------------------------------------------------------
        # SERVER PATHS
        # ---------------------------------------------------------
        self.server_manifest_path = paths["server_manifest_v2"]

        self.server_cache_root = paths["server_cache_root_v2"]
        self.server_cache_thumb = paths["server_cache_thumb_v2"]
        self.server_cache_display = paths["server_cache_display_v2"]
        self.server_cache_carousel = paths["server_cache_carousel_v2"]

        # cache_info.json lives one level above images/
        self.server_cache_info_path = self.server_cache_root.parent / "cache_info.json"

        # ---------------------------------------------------------
        # LOCAL PATHS
        # ---------------------------------------------------------
        self.local_manifest_dir = paths["local_manifest_v2"]
        self.local_cache_root = paths["local_cache_v2"]
        self.local_cache_images = paths["local_cache_images_v2"]

        self.local_thumb = paths["local_thumb_v2"]
        self.local_display = paths["local_display_v2"]
        self.local_carousel = paths["local_carousel_v2"]

        self.local_cache_info_path = self.local_cache_root / "cache_info.json"

        # ---------------------------------------------------------
        # LIBRARY ROOT (source of truth)
        # ---------------------------------------------------------
        self.library_root = Path(r"W:\Collection")

        # ---------------------------------------------------------
        # SYNC REPORT (populated during run_sync)
        # ---------------------------------------------------------
        self.report = {
            "library_check": "",
            "manifest_check": "",
            "server_cache_check": "",
            "local_cache_check": "",
            "errors": [],
            "completed_at": None,
        }

    # ---------------------------------------------------------
    # Helpers
    # ---------------------------------------------------------
    def _ensure_local_structure(self):
        for p in [
            self.local_manifest_dir,
            self.local_thumb,
            self.local_display,
            self.local_carousel,
        ]:
            p.mkdir(parents=True, exist_ok=True)

    def _load_json(self, path):
        if not path.exists():
            return None
        try:
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            msg = f"Failed to load JSON from {path}: {e}"
            print("[WARN] " + msg)
            self.report["errors"].append(msg)
            return None

    def _write_cache_info(self, manifest):
        info = {
            "cache_built": datetime.now().isoformat(),
            "manifest_generated": manifest.get("generated", "")
        }
        with open(self.server_cache_info_path, "w", encoding="utf-8") as f:
            json.dump(info, f, indent=2)
        print(f">>> server cache_info.json written to {self.server_cache_info_path}")

    def _get_library_last_modified(self):
        latest = 0
        for path in self.library_root.rglob("*"):
            try:
                latest = max(latest, path.stat().st_mtime)
            except Exception:
                # Ignore files we can't stat
                pass
        return datetime.fromtimestamp(latest) if latest > 0 else datetime.fromtimestamp(0)

    def _notify_action(self, message):
        """Only used when something actually changes or an error occurs."""
        notifier.post_notification(message, True)

    def _write_server_manifest(self, manifest):
        """Write the given manifest dict to the server manifest path."""
        try:
            with open(self.server_manifest_path, "w", encoding="utf-8") as f:
                json.dump(manifest, f, indent=2)
            print(f">>> Server manifest written to {self.server_manifest_path}")
        except Exception as e:
            msg = f"Failed to write server manifest: {e}"
            print("[WARN] " + msg)
            self.report["errors"].append(msg)
    
    
    
    
    
    def _build_manifest_candidate(self):
        """
        Build a candidate manifest from the library folder.
        Returns a dict with 'version', 'generated', and 'items'.
        """
        items = []
        for path in self.library_root.rglob("*"):
            if path.is_file():
                items.append({
                    "id": str(path.relative_to(self.library_root)),
                    "title": path.stem,
                    "type": path.suffix.lower().lstrip("."),
                })

        manifest = {
            "version": 2,
            "generated": datetime.now().isoformat(),
            "items": items,
        }
        return manifest


    # ---------------------------------------------------------
    # Check 0 -- Library folder vs manifest .....
    # ---------------------------------------------------------
        # ---------------------------------------------------------
    # ---------------------------------------------------------
    # Check 0 -- Library folder vs manifest (content-aware)
    # ---------------------------------------------------------
    def _check_library_vs_manifest(self, path_a: Path, path_b: Path) -> dict:
        print(">>> Check 0: Comparing manifest A vs B")
        notifier.post_notification("syncengine comparing manifests.", False)


        manifest_a = self._load_json(path_a)
        manifest_b = self._load_json(path_b)

        if manifest_a is None or manifest_b is None:
            msg = "One or both manifest files could not be loaded."
            print("[ERROR] " + msg)
            self.report["library_check"] = msg
            self.report["errors"].append(msg)
            return None

        count_A = len(manifest_a.get("items", []))
        count_B = len(manifest_b.get("items", []))

        hash_A = manifest_a.get("manifest_hash")
        hash_B = manifest_b.get("manifest_hash")

        print(f"    Count A: {count_A}, Hash A: {hash_A}")
        print(f"    Count B: {count_B}, Hash B: {hash_B}")

        if count_A != count_B:
            print(f"[WARN] Item count changed ({count_A} vs {count_B}) -- content changed.")
            self.report["library_check"] = "Item count differs -- content changed"
            self.report["manifest_check"] = "Server manifest should be updated"
            notifier.post_notification("Manifest content changed - Rebuild.", False)

            manifest_a["content_changed"] = True
            return manifest_a

        if hash_A != hash_B:
            print("[WARN] Hash mismatch -- content changed.")
            self.report["library_check"] = "Hash mismatch -- content changed"
            self.report["manifest_check"] = "Server manifest should be updated"
            #manifest_a["content_changed"] = True
            #return manifest_a
        
            manifest_b["content_changed"] = True  # Inject flag into NEW data
            return manifest_b                     # Return the NEW data



        msg = "Manifest hashes and item counts are identical -- no rebuild required"
        notifier.post_notification("Manifest contents unchanged no action needed.", False)

        print("    " + msg)
        self.report["library_check"] = msg
        self.report["manifest_check"] = "No change"
        manifest_a["content_changed"] = False
        return manifest_a
    '''


    # ---------------------------------------------------------
    # Check A -- Server cache vs manifest
    # ---------------------------------------------------------
    def _check_and_rebuild_server_cache_if_needed(self):
        print(">>> Check A: Server cache vs manifest")

        manifest = self._load_json(self.server_manifest_path)
        if manifest is None:
            msg = f"Server manifest not found at {self.server_manifest_path}"
            print("[ERROR] " + msg)
            self.report["manifest_check"] = msg
            self.report["errors"].append(msg)
            return None

        manifest_generated = manifest.get("generated", "")
        print(f"    manifest.generated = {manifest_generated}")

        cache_info = self._load_json(self.server_cache_info_path)
        cache_manifest_generated = cache_info.get("manifest_generated", "") if cache_info else ""

        print(f"    cache_info.manifest_generated = {cache_manifest_generated or 'None'}")

        if manifest_generated != cache_manifest_generated:
            msg = "Manifest and server cache differ -- rebuilding server cache"
            print("[WARN] " + msg)
            self.report["server_cache_check"] = msg
            self._notify_action("Rebuilding server cache for MediaVerse")

            builder = CacheBuilder_v2(manifest, self.server_cache_root)

            builder.cacheStarted.connect(lambda: print(">>> CacheBuilder_v2: started"))
            #builder.cacheProgress.connect(lambda d, t: print(f">>> CacheBuilder_v2: {d}/{t}"))
            builder.cacheFinished.connect(lambda: print(">>> CacheBuilder_v2: finished"))

            builder.run()

            self._write_cache_info(manifest)
            self._notify_action("Server cache rebuild completed")
        else:
            msg = "Server cache already matches manifest -- no action required"
            print("    " + msg)
            self.report["server_cache_check"] = msg

        # Reload cache_info after potential rebuild
        cache_info = self._load_json(self.server_cache_info_path)
        if cache_info is None:
            msg = "Server cache_info.json missing or unreadable after rebuild"
            print("[ERROR] " + msg)
            self.report["errors"].append(msg)
        return cache_info
    
    # ---------------------------------------------------------
    # Check C -- Local manifest vs server manifest
    # ---------------------------------------------------------
    def _sync_local_manifest_if_needed(self):
        print(">>> Check C: Local manifest vs server manifest")

        self._ensure_local_structure()

        # Load server manifest
        server_manifest = self._load_json(self.server_manifest_path)
        if server_manifest is None:
            msg = "Server manifest missing -- cannot compare with local manifest"
            print("[ERROR] " + msg)
            self.report["manifest_check"] = msg
            self.report["errors"].append(msg)
            return False

        server_generated = server_manifest.get("generated", "")
        print(f"    server manifest.generated = {server_generated}")

        # Load local manifest
        local_manifest_path = self.local_manifest_dir / "manifest.json"
        local_manifest = self._load_json(local_manifest_path)
        local_generated = local_manifest.get("generated", "") if local_manifest else ""

        print(f"    local  manifest.generated = {local_generated or 'None'}")

        # If timestamps match -> nothing to do
        if local_generated == server_generated and local_generated != "":
            msg = "Local manifest already matches server manifest -- no action required"
            print("    " + msg)
            self.report["manifest_check"] = msg
            return False

        # Otherwise -> update local manifest
        msg = "Local manifest missing or outdated -- updating from server"
        print("[WARN] " + msg)
        self.report["manifest_check"] = msg
        self._notify_action("Updating local MediaVerse manifest from server")

        try:
            shutil.copy2(self.server_manifest_path, local_manifest_path)
            print("    Local manifest updated")
        except Exception as e:
            err = f"Failed to update local manifest: {e}"
            print("[ERROR] " + err)
            self.report["errors"].append(err)
            return False

        return True  # local manifest changed
    


    # ---------------------------------------------------------
    # Check B -- Server cache vs local cache
    # ---------------------------------------------------------
    def _sync_server_to_local_if_needed(self, server_cache_info):
        print(">>> Check B: Server cache vs local cache")

        self._ensure_local_structure()

        local_cache_info = self._load_json(self.local_cache_info_path)
        server_built = server_cache_info.get("cache_built", "")
        local_built = local_cache_info.get("cache_built", "") if local_cache_info else ""

        print(f"    server cache_built = {server_built or 'None'}")
        print(f"    local  cache_built = {local_built or 'None'}")

        if server_built == local_built and local_built != "":
            msg = "Local cache is already up to date -- no action required"
            print("    " + msg)
            self.report["local_cache_check"] = msg
            return

        # If we reach here, local cache is missing or outdated
        msg = "Local cache missing or outdated -- syncing from server"
        print("[WARN] " + msg)
        self.report["local_cache_check"] = msg
        self._notify_action("Updating local MediaVerse cache from server")

        # Copy manifest
        shutil.copy2(self.server_manifest_path, self.local_manifest_dir / "manifest.json")

        # Copy cache_info.json
        shutil.copy2(self.server_cache_info_path, self.local_cache_info_path)

        # Copy images
        for src_dir, dst_dir in [
            (self.server_cache_thumb, self.local_thumb),
            (self.server_cache_display, self.local_display),
            (self.server_cache_carousel, self.local_carousel),
        ]:
            for src_file in src_dir.iterdir():
                if src_file.is_file():
                    shutil.copy2(src_file, dst_dir / src_file.name)

        self._notify_action("Local MediaVerse cache sync completed")
        print(">>> Local cache sync completed")
    '''
    # ---------------------------------------------------------
    # Reporting
    # ---------------------------------------------------------
    def _print_report(self):
        self.report["completed_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        print("\n=== MediaVerse V2 Sync Report ===\n")

        print("Library Check:")
        print("  " + (self.report["library_check"] or "No result recorded"))

        print("\nManifest Check:")
        print("  " + (self.report["manifest_check"] or "No explicit manifest rebuild logic here (assumed external)"))

        print("\nServer Cache Check:")
        print("  " + (self.report["server_cache_check"] or "No result recorded"))

        print("\nLocal Cache Check:")
        print("  " + (self.report["local_cache_check"] or "No result recorded"))

        print("\nErrors:")
        if self.report["errors"]:
            for err in self.report["errors"]:
                print("  - " + err)
        else:
            print("  None")

        print(f"\nSync completed at: {self.report['completed_at']}")
        print("=================================\n")

    # ---------------------------------------------------------
    # Public API
    # ---------------------------------------------------------
    def run_sync(self):
        print("\n=== MediaVerse V2 Sync Started ===")

        # Check 0 -- Library freshness
        library_requires_rebuild = self._check_library_vs_manifest()
        # Note: actual manifest rebuild is assumed to be handled externally
        # (e.g. ManifestBuilder_v2), then rerun sync.

        # Check A -- Server cache freshness
        server_cache_info = self._check_and_rebuild_server_cache_if_needed()
        if server_cache_info is None:
            print(">>> Aborting sync: server cache_info unavailable")
            self._print_report()
            return

        # Check B -- Local cache freshness
        #self._sync_server_to_local_if_needed(server_cache_info)

        # Final report to terminal
        self._print_report()

        print("=== MediaVerse V2 Sync Finished ===\n")

# ------------------------------------------------------------
    # Helper: run server cache builder in background
    # -----ADDED JAN COS IT WAS MISSING THIS IS FROM DEC-------------------------------------------------------
    def run_server_cache_builder(self, manifest: dict):
        """
        Run CacheBuilder_v2 on the server using the given manifest.
        Skips images that already exist (incremental).
        Posts a user notification with the result summary on completion.
        """
        try:
            print("[CacheBuilder_v2] Initializing server cache builder...")
            builder = CacheBuilder_v2(manifest, self.server_cache_root)

            builder.cacheStarted.connect(
                lambda: notifier.post_notification("Image cache build started...", False)
            )

            # Progress: notify every 100 items so the user sees activity
            def _on_progress(done, total):
                if total > 0 and done % 100 == 0:
                    notifier.post_notification(
                        f"Building image cache: {done} of {total}...", False
                    )
            builder.cacheProgress.connect(_on_progress)

            def _on_finished(result):
                written  = result.get("written", 0)
                skipped  = result.get("skipped", 0)
                errors   = result.get("errors", 0)
                exp_t    = result.get("expected_thumb", 0)
                exp_d    = result.get("expected_display", 0)
                found_t  = result.get("found_thumb", 0)
                found_d  = result.get("found_display", 0)

                thumb_ok   = found_t   >= exp_t   * 0.95
                display_ok = found_d   >= exp_d   * 0.95
                has_gaps   = not thumb_ok or not display_ok or errors > 0

                parts = [f"Cache build complete -- {written} new, {skipped} unchanged"]
                if errors:
                    parts.append(f"{errors} errors")
                if not thumb_ok:
                    parts.append(f"[WARN] thumb: {found_t}/{exp_t}")
                if not display_ok:
                    parts.append(f"[WARN] display: {found_d}/{exp_d}")

                notifier.post_notification(" | ".join(parts), has_gaps)
                print(f"[CacheBuilder_v2] {' | '.join(parts)}")

            builder.cacheFinished.connect(_on_finished)

            builder.run()

        except Exception as e:
            print(f"[CacheBuilder_v2] ERROR during cache build: {e}")
            notifier.post_notification(f"Cache build failed: {e}", True)
             


        