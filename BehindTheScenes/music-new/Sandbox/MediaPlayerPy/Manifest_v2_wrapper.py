"""
Manifest_v2_wrapper.py
----------------
This replaces the old ManifestUpdater class.

It wraps:
    - manifest_v2.write_manifest_to_disk()
    - manifest loading
    - background update thread
    - QML signals

It keeps the SAME public API as the old ManifestUpdater so Framework.py
and QML do NOT need to change.
"""

from PySide6.QtCore import QObject, Signal, Slot
from pathlib import Path
import json
import threading

# IMPORTANT: import the function that WRITES the manifest
from manifest_v2 import write_manifest_to_disk


class ManifestUpdater_v2(QObject):

    manifestLoaded = Signal(dict)
    manifestError = Signal(str)
    manifestUpdated = Signal()   # optional: QML can listen for refresh

    def __init__(self, parent=None):
        super().__init__(parent)
        # Correct manifest path (matches builder)
        self.manifest_path = Path(r"W:\MediaVerse\manifest\manifest.json")

    # ------------------------------------------------------------
    # PUBLIC API — QML and Framework.py expect these
    # ------------------------------------------------------------

    @Slot()
    def update_manifest_background(self):
        """Run manifest build + load in a background thread."""
        print("[ManifestUpdater_v2] Starting background manifest update...")
        thread = threading.Thread(target=self._update_manifest, daemon=True)
        thread.start()

    @Slot()
    def load_manifest(self):
        """Load manifest without rebuilding."""
        print("[ManifestUpdater_v2] Loading manifest only...")
        self._load_manifest()

    # ------------------------------------------------------------
    # INTERNAL WORK
    # ------------------------------------------------------------

    def _update_manifest(self):
        """Build manifest_v2 then load it."""
        try:
            print("[ManifestUpdater_v2] Building manifest_v2...")
            write_manifest_to_disk()   # <-- THIS NOW WRITES THE FILE
            print("[ManifestUpdater_v2] Manifest build complete.")
            self.manifestUpdated.emit()
        except Exception as e:
            msg = f"Manifest build failed: {e}"
            print("[ManifestUpdater_v2]", msg)
            self.manifestError.emit(msg)
            return

        self._load_manifest()

    def _load_manifest(self):
        """Load manifest.json and emit to QML."""
        try:
            if not self.manifest_path.exists():
                msg = "Manifest file not found after build."
                print("[ManifestUpdater_v2]", msg)
                self.manifestError.emit(msg)
                return

            with open(self.manifest_path, "r", encoding="utf-8") as f:
                manifest = json.load(f)

            print("[ManifestUpdater_v2] Manifest loaded:")
            print(f"  Version:   {manifest.get('version')}")
            print(f"  Generated: {manifest.get('generated')}")
            print(f"  Items:     {len(manifest.get('items', []))}")

            self.manifestLoaded.emit(manifest)

        except Exception as e:
            msg = f"Failed to load manifest: {e}"
            print("[ManifestUpdater_v2]", msg)
            self.manifestError.emit(msg)