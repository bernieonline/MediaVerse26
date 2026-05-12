from PySide6.QtCore import QObject, Signal, Slot
from pathlib import Path
import json
import threading
import copy

from CacheSyncWorker import CacheSyncWorker
from PySide6.QtCore import QThread

from manifest_v3 import write_manifest_to_disk
from SyncEngine_v2 import SyncEngine_v2
from project_paths import paths
from PySide6.QtCore import QThread
from NotificationManager import notifier
from json_safe import safe_json_read, safe_json_write

import shutil
from project_paths import (
    server_cache_thumb_v2, server_cache_display_v2, server_cache_carousel_v2,
    local_thumb_v2, local_display_v2, local_carousel_v2
)


class ManifestUpdater_v2(QObject):
    print("loading Manifest_v2_wrapper")
    manifestLoaded = Signal(dict)
    manifestError = Signal(str)
    manifestUpdated = Signal()
    cacheRebuildFinished = Signal()
    serverCheckFailed = Signal()
    serverCheckPassed = Signal()


    def __init__(self, parent=None):
        super().__init__(parent)
        #the current manifest file
        #self.manifest_path = Path(r"W:\MediaVerse\manifest\manifest.json")
        self.manifest_path = paths["server_manifest_v2"]

        #the manifest newly created from library data for comparison with current manifest
        self.comparison_path = paths["server_manifest_v2"].parent / "manifest_b.json"
        #sync engine has a check 0 method that compares the two manifests and decides if there is an update needed to the cache
        self.sync_engine = SyncEngine_v2()

    # ------------------------------------------------------------
    # PUBLIC API -- QML and Framework.py expect these
    # ------------------------------------------------------------

    @Slot()
    def update_manifest_background(self):
        """Run canonical manifest build + load in a background thread."""
        print("[ManifestUpdater_v2] Starting background manifest update...")
        thread = threading.Thread(target=self._update_and_check_manifest, daemon=True)
        thread.start()

    @Slot()
    def load_manifest(self):
        """Load manifest without rebuilding."""
        print("[ManifestUpdater_v2] Loading manifest only...")
        self._load_manifest()

    @Slot()
    def force_rebuild_manifest(self):
        """
        Recovery tool: bypass the hash comparison and force a full manifest
        rebuild from scratch. Runs in a background thread.
        Use when manifest.json is suspected corrupt or incomplete.
        """
        print("[ManifestUpdater_v2] force_rebuild_manifest called -- bypassing hash check.")
        notifier.post_notification("Rebuilding manifest from scratch...", False)
        thread = threading.Thread(target=self.bootstrap_manifest, daemon=True)
        thread.start()

    # ------------------------------------------------------------
    # INTERNAL WORK
    # ------------------------------------------------------------

    def _update_and_check_manifest(self):
        """Full Check 0 flow: build A, build B, compare, trigger cache if needed."""
        try:
            # do not uncomment this else you create 2 identical manifest
            # Step 1: Build canonical manifest.json
            #print("running _update_and_check_manifest inside manifest_v2_wrapper")
            #print(f"[ManifestUpdater_v2] Building canonical manifest at {self.manifest_path}...")
            #write_manifest_to_disk(self.manifest_path)
            #notifier.post_notification("Wrapper - Manifest Written to server.", False)

            # Step 2: Build comparison manifest_b.json
            print(f"[ManifestUpdater_v2] Building comparison manifest at {self.comparison_path}...")
            processed, stats = write_manifest_to_disk(self.comparison_path)
            self._save_build_log(stats)
            self._notify_build_result(stats)

            # Step 3: Run Check 0
            print("[ManifestUpdater_v2] Running Check 0...")


            #result is manifest.json returned
            result = self.sync_engine._check_library_vs_manifest(
                self.manifest_path, self.comparison_path
            )

            # If Check 0 found a hash mismatch, it returned manifest_b with content_changed = True
            if result and result.get("content_changed"):
                # Guard: refuse swap if manifest_b has fewer than 80% of manifest.json items
                # (protects against a partial/failed library scan silently shrinking the manifest)
                current_count = self._safe_item_count(self.manifest_path)
                candidate_count = self._safe_item_count(self.comparison_path)

                if current_count > 0 and candidate_count < current_count * 0.8:
                    msg = (f"[WARN] Manifest swap refused -- candidate has {candidate_count} items "
                           f"vs {current_count} in current manifest (less than 80%). "
                           f"Library scan may be incomplete. Restart to retry.")
                    print(f"[ManifestUpdater_v2] {msg}")
                    notifier.post_notification(msg, is_urgent=True)
                else:
                    print("[ManifestUpdater_v2] Swapping files: Candidate is now the Master.")
                    # This physically moves manifest_candidate.json to manifest.json
                    # .replace() is atomic and safe.
                    self.comparison_path.replace(self.manifest_path)
                    self.manifestUpdated.emit()
            # ----------------------------

            # Step 4: Load canonical manifest and inject content_changed
            if not self.manifest_path.exists():
                raise FileNotFoundError("Manifest file not found after build.")

            manifest = safe_json_read(self.manifest_path, "manifest")
            if not manifest.get("items"):
                raise ValueError("Manifest loaded but items list is empty -- aborting.")

            if not manifest.get("scan_complete"):
                notifier.post_notification(
                    "Manifest scan_complete flag missing -- scan may have been interrupted. Restart recommended.",
                    is_urgent=True
                )
            if not manifest.get("manifest_hash"):
                notifier.post_notification(
                    "Manifest hash missing -- hash step failed. Cache comparison unreliable.",
                    is_urgent=True
                )

            manifest["content_changed"] = bool(result.get("content_changed", True)) if result else True
            manifest["_source"] = "update_and_check"

            print("[ManifestUpdater_v2] Manifest loaded:")
            print(f"  Version:   {manifest.get('version')}")
            print(f"  Generated: {manifest.get('generated')}")
            print(f"  Items:     {len(manifest.get('items', []))}")
            print(f"  Content changed: {manifest.get('content_changed')}")

            # Step 5: Emit manifest to Framework
            self.manifestLoaded.emit(copy.deepcopy(manifest))



            # Step 6: Determine if cache rebuild is needed (three scenarios)
            # A. manifest["content_changed"] = True  -> Library was updated on server
            # B. local_cache_empty = True           -> Fresh install or cache corrupted
            # C. cache_stale = True                 -> Device missed a sync cycle
            #
            # Rebuild triggers on ANY of these conditions (logical OR).
            # After rebuild, save cache_manifest.json with current server state.
            local_cache_empty = self._is_local_cache_empty()
            cache_stale = self._check_cache_freshness(manifest)
            needs_rebuild = manifest["content_changed"] or local_cache_empty or cache_stale

            if local_cache_empty:
                print("[ManifestUpdater_v2] Local cache is empty (fresh install) -- forcing cache rebuild.")
            if cache_stale and not local_cache_empty:
                print("[ManifestUpdater_v2] Local cache is stale (missed sync) -- forcing cache rebuild.")

            if needs_rebuild:
                print("[ManifestUpdater_v2] Triggering cache rebuild.")
                self.sync_engine.run_server_cache_builder(manifest)
                # After rebuild: count current server cache and record it locally
                # Next startup will compare these counts to detect future changes
                manifest_hash = manifest.get("manifest_hash", "")
                server_counts = self._count_server_cache_files()
                self._write_cache_manifest(server_counts, manifest_hash)
                self.cacheRebuildFinished.emit()
            else:
                print("[ManifestUpdater_v2] No content change detected.")

        except Exception as e:
            msg = f"Manifest update failed: {e}"
            print("[ManifestUpdater_v2]", msg)
            self.manifestError.emit(msg)
    
    def _is_local_cache_empty(self) -> bool:
        """Return True if the local display cache has fewer than 5 images."""
        try:
            count = sum(1 for f in local_display_v2.iterdir() if f.suffix.lower() in ('.jpg', '.png', '.webp'))
            return count < 5
        except Exception:
            return True

    def _safe_item_count(self, path: Path) -> int:
        """Return the number of items in a manifest JSON file, or 0 on any failure."""
        try:
            data = safe_json_read(path, "manifest")
            return len(data.get("items", []))
        except Exception:
            return 0

    # -- Cache Freshness Detection (Stale Device Handling) --
    # Strategy: Track server cache state (file counts per tier) locally.
    # On startup: compare stored vs current server counts.
    # If mismatch detected -> device missed a sync cycle -> force rebuild.
    #
    # This handles devices that:
    # 1. Missed a full cache rebuild (library changed while device was offline)
    # 2. Have a fresh install (no cache_manifest.json yet)
    # 3. Are used rarely and become out of sync
    #
    # Files involved:
    # - cache_manifest.json (local): {last_sync, server_counts, local_manifest_hash}
    # - Server cache tiers: W:\MediaVerse\cache\images\{display, thumb, carousel}
    # - Local cache: cacheV2\images\{display, thumb, carousel}

    def _count_server_cache_files(self) -> dict:
        """Count image files in each server cache tier. Returns {display: N, thumb: N, carousel: N}."""
        counts = {"display": 0, "thumb": 0, "carousel": 0}
        cache_dirs = {
            "display": server_cache_display_v2,
            "thumb": server_cache_thumb_v2,
            "carousel": server_cache_carousel_v2,
        }
        for tier, cache_dir in cache_dirs.items():
            try:
                if cache_dir.exists():
                    count = sum(1 for f in cache_dir.iterdir()
                               if f.is_file() and f.suffix.lower() in ('.jpg', '.png', '.webp'))
                    counts[tier] = count
            except Exception as e:
                print(f"[ManifestUpdater_v2] Error counting {tier} cache: {e}")
        return counts

    def _write_cache_manifest(self, server_counts: dict, manifest_hash: str) -> None:
        """Write cache_manifest.json with server cache counts and manifest hash."""
        from datetime import datetime
        cache_manifest_path = paths["cache_manifest"]
        cache_data = {
            "last_sync": datetime.now().isoformat(),
            "server_counts": server_counts,
            "local_manifest_hash": manifest_hash,
        }
        try:
            safe_json_write(cache_manifest_path, cache_data)
            print(f"[ManifestUpdater_v2] Cache manifest written: {server_counts}")
        except Exception as e:
            print(f"[ManifestUpdater_v2] Error writing cache manifest: {e}")

    def _check_cache_freshness(self, current_manifest: dict) -> bool:
        """
        Detect stale cache by comparing server vs stored cache file counts.

        Algorithm:
        1. If no cache_manifest.json exists -> Fresh install, needs rebuild
        2. If cache_manifest.json corrupted -> Rebuild (fail-safe)
        3. Count current server cache files in each tier (display/thumb/carousel)
        4. Compare counts against stored counts from last sync
        5. If any tier has different count -> Cache is stale, needs rebuild
        6. If all counts match -> Cache is fresh, no rebuild needed

        Returns True if cache is stale/missing (rebuild needed).
        Returns False if cache is fresh (skip rebuild).

        This approach handles:
        - Fresh installs: no cache_manifest yet
        - Stale devices: server library changed while device was offline
        - Synced devices: cache_manifest matches current server state
        """
        cache_manifest_path = paths["cache_manifest"]

        # No local cache_manifest = fresh install, needs rebuild
        if not cache_manifest_path.exists():
            print("[ManifestUpdater_v2] No cache_manifest found (fresh install)")
            return True

        # Read stored counts
        try:
            stored = safe_json_read(cache_manifest_path, "cache_manifest")
            stored_counts = stored.get("server_counts", {})
        except Exception as e:
            print(f"[ManifestUpdater_v2] Error reading cache_manifest: {e} - forcing rebuild")
            return True

        # Count current server cache
        current_counts = self._count_server_cache_files()

        # Compare each tier
        for tier in ["display", "thumb", "carousel"]:
            stored = stored_counts.get(tier, 0)
            current = current_counts.get(tier, 0)
            if stored != current:
                print(f"[ManifestUpdater_v2] Cache mismatch in {tier}: stored={stored}, current={current}")
                return True

        print("[ManifestUpdater_v2] Cache is fresh - no rebuild needed")
        return False

    def bootstrap_manifest(self):
        """
        First-run manifest builder.

        Reuse the existing manifest_v3.write_manifest_to_disk logic
        to build the canonical manifest at self.manifest_path,
        then load it, inject V2 flags, and emit manifestLoaded so
        Framework can trigger CacheBuilder_v2.

        This avoids needing scan_library/normalize_item/sort_items
        while we prove the V2 pipeline.
        """
        try:
            print("[ManifestUpdater_v2] BOOTSTRAP: Building full manifest via write_manifest_to_disk...")

            # 1. Build manifest.json at self.manifest_path using existing logic
            processed, stats = write_manifest_to_disk(self.manifest_path)
            self._save_build_log(stats)
            self._notify_build_result(stats)

            if not self.manifest_path.exists():
                raise FileNotFoundError(f"Manifest file not found after bootstrap build: {self.manifest_path}")

            # 2. Load manifest from disk
            manifest = safe_json_read(self.manifest_path, "manifest")
            if not manifest.get("items"):
                raise ValueError("Bootstrap manifest loaded but items list is empty -- aborting.")

            # 3. Inject V2 flags/metadata
            manifest["content_changed"] = True          # bootstrap always forces cache rebuild
            manifest["_source"] = "bootstrap"

            print("[ManifestUpdater_v2] BOOTSTRAP: Manifest loaded after build")
            print(f"  Version:   {manifest.get('version')}")
            print(f"  Generated: {manifest.get('generated')}")
            print(f"  Items:     {len(manifest.get('items', []))}")
            print(f"  Content changed: {manifest.get('content_changed')}")

            # 4. Emit manifest to Framework
            self.manifestLoaded.emit(copy.deepcopy(manifest))
            print("[ManifestUpdater_v2] BOOTSTRAP: manifestLoaded emitted")

            # 5. Build server image cache (was missing -- update path has this, bootstrap didn't)
            print("[ManifestUpdater_v2] BOOTSTRAP: triggering cache build...")
            self.sync_engine.run_server_cache_builder(manifest)
            # Write cache_manifest after bootstrap rebuild completes
            manifest_hash = manifest.get("manifest_hash", "")
            server_counts = self._count_server_cache_files()
            self._write_cache_manifest(server_counts, manifest_hash)
            self.cacheRebuildFinished.emit()

        except Exception as e:
            print(f"[ManifestUpdater_v2] ERROR during bootstrap: {e}")
            import traceback
            traceback.print_exc()
            self.manifestError.emit(f"Bootstrap failed: {e}")
    
    def _load_manifest(self):
        """Load manifest from disk and emit it with default content_changed = False."""
        if not self.manifest_path.exists():
            self.manifestError.emit("Manifest file not found.")
            return

        manifest = safe_json_read(self.manifest_path, "manifest")

        manifest["content_changed"] = False
        manifest["_source"] = "load_manifest"

        print("[ManifestUpdater_v2] Loaded manifest from disk (no rebuild).")
        self.manifestLoaded.emit(copy.deepcopy(manifest))

    def _do_server_check_and_start(self):
        """
        Check server accessibility. Emits serverCheckFailed if unreachable (QML shows popup),
        or serverCheckPassed then kicks off manifest work. Safe to call from any thread.
        """
        server_root = paths["server_manifest_v2"].parent.parent
        if not server_root.exists():
            print(f"[ManifestUpdater_v2] Server unreachable: {server_root}")
            self.serverCheckFailed.emit()
            return

        print(f"[ManifestUpdater_v2] Server confirmed accessible: {server_root}")
        self.serverCheckPassed.emit()

        if not self.manifest_path.exists():
            notifier.post_notification("Building manifest...", False)
            self.bootstrap_manifest()
        else:
            self.update_manifest_background()

    @Slot()
    def retry_server_check(self):
        """Called by QML Retry button. Runs server check in a background thread."""
        threading.Thread(target=self._do_server_check_and_start, daemon=True).start()

    def _save_build_log(self, stats: dict) -> None:
        """Write build stats to Assets/manifest_build_log.json. Non-fatal on failure."""
        log_path = paths["manifest_build_log"]
        try:
            safe_json_write(log_path, stats)
            print(f"[ManifestUpdater_v2] Build log written: {stats['accepted']} accepted, "
                  f"{stats['rejected']} rejected.")
        except Exception as e:
            print(f"[ManifestUpdater_v2] Build log write failed (non-fatal): {e}")

    def _notify_build_result(self, stats: dict) -> None:
        """Post a user-visible notification summarising the build."""
        accepted = stats.get("accepted", 0)
        rejected = stats.get("rejected", 0)
        no_xml   = stats.get("no_xml", 0)
        total    = stats.get("total_videos", 0)

        high_rejection = total > 0 and (rejected / total) > 0.10

        parts = [f"Manifest built: {accepted} items"]
        if rejected:
            parts.append(f"{rejected} rejected")
        if no_xml:
            parts.append(f"{no_xml} without XML")
        if rejected:
            parts.append("See Assets/manifest_build_log.json for details")

        msg = " | ".join(parts) + "."
        notifier.post_notification(msg, high_rejection)

    def build_comparison_manifest(self, comparison_path: Path):
        """Build a comparison manifest (e.g. Manifest_B.json) without loading it into QML."""
        print(f"[ManifestUpdater_v2] Building comparison manifest at {comparison_path}...")
        thread = threading.Thread(target=self._update_manifest, args=(comparison_path,), daemon=True)
        thread.start()


    def clone_server_to_local(self):
        """Independent clone: Forces D: to match W:"""
        print("\n" + "="*40)
        print("[Sync] Initiating Master Clone: Server -> Local")
        print("="*40)

        # Pairs: (Source on W, Destination on D)
        sync_map = [
            (server_cache_thumb_v2, local_thumb_v2),
            (server_cache_display_v2, local_display_v2),
            (server_cache_carousel_v2, local_carousel_v2)
        ]

        for src, dst in sync_map:
            try:
                if Path(src).exists():
                    print(f"  > Copying {Path(src).name}...")
                    # dirs_exist_ok=True performs a 'merge/overwrite' clone
                    shutil.copytree(src, dst, dirs_exist_ok=True)
                    print(f"  [OK] {Path(src).name} synced.")
                else:
                    print(f"  [WARN] Source missing on server: {src}")
            except Exception as e:
                print(f"  [ERROR] Error cloning {src}: {e}")

        print("="*40)
        print("[Sync] Clone operation finished.")
        print("="*40)

    def start_local_cache_sync(self):
        print("Starting async local cache sync...")
        notifier.post_notification("Syncing image cache to local device...", False)

        self.sync_thread = QThread()
        self.sync_worker = CacheSyncWorker(paths)

        self.sync_worker.moveToThread(self.sync_thread)

        # Lifecycle
        self.sync_thread.started.connect(self.sync_worker.run)
        self.sync_worker.finished.connect(self.sync_thread.quit)
        self.sync_worker.finished.connect(self.sync_worker.deleteLater)
        self.sync_thread.finished.connect(self.sync_thread.deleteLater)

        # Progress label -> discreet notification
        self.sync_worker.progress.connect(
            lambda label: notifier.post_notification(f"Syncing {label} cache...", False)
        )

        # Result summary notification
        def _on_sync_finished(tier_results):
            parts = []
            has_gaps = False
            for label, info in tier_results.items():
                if info["ok"]:
                    parts.append(f"{label}: {info['local']}/{info['server']} ")
                else:
                    parts.append(f"{label}: {info['local']}/{info['server']} [WARN]")
                    has_gaps = True
            msg = "Local cache sync complete -- " + ", ".join(parts)
            notifier.post_notification(msg, has_gaps)
            print(f"[CacheSyncWorker] {msg}")

        self.sync_worker.finished.connect(_on_sync_finished)

        self.sync_thread.start()        