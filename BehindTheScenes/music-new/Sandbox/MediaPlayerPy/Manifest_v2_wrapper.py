from PySide6.QtCore import QObject, Signal, Slot
from pathlib import Path
import json
import threading
import copy

from manifest_v3 import write_manifest_to_disk
from SyncEngine_v2 import SyncEngine_v2
from project_paths import paths
from NotificationManager import notifier


class ManifestUpdater_v2(QObject):
    print("loading Manifest_v2_wrapper")
    #send out 3 signals
    manifestLoaded = Signal(dict)
    manifestError = Signal(str)
    manifestUpdated = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        #the current manifest file
        #self.manifest_path = Path(r"W:\MediaVerse\manifest\manifest.json")
        self.manifest_path = paths["server_manifest_v2"]

        #the manifest newly created from library data for comparison with current manifest
        self.comparison_path = Path(r"W:\MediaVerse\manifest\manifest_b.json")
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

    # ------------------------------------------------------------
    # INTERNAL WORK
    # ------------------------------------------------------------

    def _update_and_check_manifest(self):
        """Full Check 0 flow: build A, build B, compare, trigger cache if needed."""
        try:
            # Step 1: Build canonical manifest.json
            #print("running _update_and_check_manifest inside manifest_v2_wrapper")
            #print(f"[ManifestUpdater_v2] Building canonical manifest at {self.manifest_path}...")
            #write_manifest_to_disk(self.manifest_path)
            #notifier.post_notification("Wrapper - Manifest Written to server.", False)

            # Step 2: Build comparison manifest_b.json
            print(f"[ManifestUpdater_v2] Building comparison manifest at {self.comparison_path}...")
            write_manifest_to_disk(self.comparison_path)

            # Step 3: Run Check 0
            print("[ManifestUpdater_v2] Running Check 0...")
            result = self.sync_engine._check_library_vs_manifest(
                self.manifest_path, self.comparison_path
            )

            # Step 4: Load canonical manifest and inject content_changed
            if not self.manifest_path.exists():
                raise FileNotFoundError("Manifest file not found after build.")

            with open(self.manifest_path, "r", encoding="utf-8") as f:
                manifest = json.load(f)

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
            else:
                print("[ManifestUpdater_v2] No content change detected.")

        except Exception as e:
            msg = f"Manifest update failed: {e}"
            print("[ManifestUpdater_v2]", msg)
            self.manifestError.emit(msg)
    
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
            write_manifest_to_disk(self.manifest_path)

            if not self.manifest_path.exists():
                raise FileNotFoundError(f"Manifest file not found after bootstrap build: {self.manifest_path}")

            # 2. Load manifest from disk
            with open(self.manifest_path, "r", encoding="utf-8") as f:
                manifest = json.load(f)

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

        with open(self.manifest_path, "r", encoding="utf-8") as f:
            manifest = json.load(f)

        manifest["content_changed"] = False
        manifest["_source"] = "load_manifest"

        print("[ManifestUpdater_v2] Loaded manifest from disk (no rebuild).")
        self.manifestLoaded.emit(copy.deepcopy(manifest))

    def build_comparison_manifest(self, comparison_path: Path):
        """Build a comparison manifest (e.g. Manifest_B.json) without loading it into QML."""
        print(f"[ManifestUpdater_v2] Building comparison manifest at {comparison_path}...")
        thread = threading.Thread(target=self._update_manifest, args=(comparison_path,), daemon=True)
        thread.start()