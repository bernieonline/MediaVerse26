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
    # PUBLIC API — QML and Framework.py expect these
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
        print("[ManifestUpdater_v2] force_rebuild_manifest called — bypassing hash check.")
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
                    msg = (f"⚠️ Manifest swap refused — candidate has {candidate_count} items "
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
                raise ValueError("Manifest loaded but items list is empty — aborting.")

            if not manifest.get("scan_complete"):
                notifier.post_notification(
                    "Manifest scan_complete flag missing — scan may have been interrupted. Restart recommended.",
                    is_urgent=True
                )
            if not manifest.get("manifest_hash"):
                notifier.post_notification(
                    "Manifest hash missing — hash step failed. Cache comparison unreliable.",
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



            # Step 6: Trigger cache if needed
            if manifest["content_changed"]:
                print("[ManifestUpdater_v2] Content changed — triggering cache rebuild.")
                self.sync_engine.run_server_cache_builder(manifest)
                #AFTER CACHE REBUILD COPY TO LOCAL DRIVE
                #self.clone_server_to_local()
                #NOW THE LOCAL CACHE
                self.cacheRebuildFinished.emit()

                #self.start_local_cache_sync()


            else:
                print("[ManifestUpdater_v2] No content change detected.")

        except Exception as e:
            msg = f"Manifest update failed: {e}"
            print("[ManifestUpdater_v2]", msg)
            self.manifestError.emit(msg)
    
    def _safe_item_count(self, path: Path) -> int:
        """Return the number of items in a manifest JSON file, or 0 on any failure."""
        try:
            data = safe_json_read(path, "manifest")
            return len(data.get("items", []))
        except Exception:
            return 0

    def bootstrap_manifest(self):
        """
        First‑run manifest builder.

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
                raise ValueError("Bootstrap manifest loaded but items list is empty — aborting.")

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

            # 5. Build server image cache (was missing — update path has this, bootstrap didn't)
            print("[ManifestUpdater_v2] BOOTSTRAP: triggering cache build...")
            self.sync_engine.run_server_cache_builder(manifest)
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
                    print(f"  ✅ {Path(src).name} synced.")
                else:
                    print(f"  ⚠️ Source missing on server: {src}")
            except Exception as e:
                print(f"  ❌ Error cloning {src}: {e}")

        print("="*40)
        print("[Sync] Clone operation finished.")
        print("="*40)

    def start_local_cache_sync(self):
        print("Starting async local cache sync…")

        # Create thread + worker
        self.sync_thread = QThread()
        #self.sync_worker = CacheSyncWorker(self.paths)
        self.sync_worker = CacheSyncWorker(paths)

        # Move worker into thread
        self.sync_worker.moveToThread(self.sync_thread)

        # Connect lifecycle
        self.sync_thread.started.connect(self.sync_worker.run)
        self.sync_worker.finished.connect(self.sync_thread.quit)
        self.sync_worker.finished.connect(self.sync_worker.deleteLater)
        self.sync_thread.finished.connect(self.sync_thread.deleteLater)

        # Optional: progress to QML
        # self.sync_worker.progress.connect(self.qml_root.onSyncProgress)

        # Start thread
        self.sync_thread.start()        