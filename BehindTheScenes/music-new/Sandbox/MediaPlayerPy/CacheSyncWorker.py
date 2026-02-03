from PySide6.QtCore import QObject, Signal, Slot, QThread
from pathlib import Path
import subprocess
from types import SimpleNamespace


class CacheSyncWorker(QObject):
    """
    Standalone worker that mirrors the server cache to the local cache
    using Robocopy for maximum speed. Designed to run in a QThread.

    Usage:
        worker = CacheSyncWorker(paths)
        thread = QThread()
        worker.moveToThread(thread)
        thread.started.connect(worker.run)
        worker.finished.connect(thread.quit)
        thread.start()
    """

    finished = Signal()
    progress = Signal(str)   # emits "Thumb", "Display", etc.

    def __init__(self, paths):
        """
        paths: a dict containing:
            - server_cache_thumb_v2
            - server_cache_display_v2
            - server_cache_carousel_v2
            - local_thumb_v2
            - local_display_v2
            - local_carousel_v2
        """
        super().__init__()

        # Convert dict → object with attribute access
        self.paths = SimpleNamespace(**paths)

        # Build sync map in correct order
        self.sync_map = [
            ("Thumb",    self.paths.server_cache_thumb_v2,    self.paths.local_thumb_v2),
            ("Display",  self.paths.server_cache_display_v2,  self.paths.local_display_v2),
            ("Carousel", self.paths.server_cache_carousel_v2, self.paths.local_carousel_v2),

            # ------------------------------------------------------------
            # Full resolution (currently unused — intentionally commented)
            # ------------------------------------------------------------
            # ("Full", self.paths.server_cache_full_v2, self.paths.local_full_v2),
        ]

    # ------------------------------------------------------------
    # Internal helper: run robocopy
    # ------------------------------------------------------------
    def _mirror(self, src, dst):
        src = Path(src)
        dst = Path(dst)

        if not src.exists():
            print(f"[CacheSyncWorker] SKIP — Source missing: {src}")
            return

        dst.mkdir(parents=True, exist_ok=True)

        cmd = [
            "robocopy",
            str(src),
            str(dst),
            "/MIR",        # mirror source → destination
            "/MT:16",      # 16 threads (fast + safe)
            "/R:1",        # retry once
            "/W:1",        # wait 1 second
            "/NFL", "/NDL", "/NJH", "/NJS",  # quiet output
            "/NC", "/NS", "/NP"
        ]

        subprocess.run(cmd, shell=True)

    # ------------------------------------------------------------
    # Main entry point (runs inside QThread)
    # ------------------------------------------------------------
    @Slot()
    def run(self):
        print("\n==============================")
        print(" CacheSyncWorker: START")
        print("==============================")

        for label, src, dst in self.sync_map:
            print(f"\n>>> Syncing {label}...")
            self.progress.emit(label)
            self._mirror(src, dst)
            print(f"    ✔ {label} complete")

        print("\n==============================")
        print(" CacheSyncWorker: FINISHED")
        print("==============================")

        self.finished.emit()