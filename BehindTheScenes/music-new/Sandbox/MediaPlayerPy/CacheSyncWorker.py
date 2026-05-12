from PySide6.QtCore import QObject, Signal, Slot, QThread
from pathlib import Path
import subprocess
from types import SimpleNamespace


class CacheSyncWorker(QObject):
    """
    Mirrors the server image cache to the local device using Robocopy.
    Only syncs the two tiers that views actually use: thumb and display.
    Carousel is excluded -- no view currently requests it.

    Usage:
        worker = CacheSyncWorker(paths)
        thread = QThread()
        worker.moveToThread(thread)
        thread.started.connect(worker.run)
        worker.finished.connect(thread.quit)
        thread.start()
    """

    finished = Signal(dict)   # emits a result dict: {label: {server, local, ok}}
    progress = Signal(str)    # emits "Thumb", "Display" as each tier starts

    def __init__(self, paths):
        super().__init__()
        self.paths = SimpleNamespace(**paths)

        # carousel removed -- not used by any view
        self.sync_map = [
            ("Thumb",   self.paths.server_cache_thumb_v2,   self.paths.local_thumb_v2),
            ("Display", self.paths.server_cache_display_v2, self.paths.local_display_v2),
        ]

    # ----------------------------------------------------------------
    # Internal helper: robocopy mirror
    # ----------------------------------------------------------------
    def _mirror(self, src, dst):
        src = Path(src)
        dst = Path(dst)

        if not src.exists():
            print(f"[CacheSyncWorker] SKIP -- Source missing: {src}")
            return

        dst.mkdir(parents=True, exist_ok=True)

        cmd = [
            "robocopy",
            str(src),
            str(dst),
            "/MIR",         # mirror source -> destination (incremental)
            "/MT:16",       # 16 threads
            "/R:1",         # retry once on failure
            "/W:1",         # wait 1 second between retries
            "/NFL", "/NDL", "/NJH", "/NJS",
            "/NC", "/NS", "/NP"
        ]

        subprocess.run(cmd, shell=True)

    # ----------------------------------------------------------------
    # Main entry point (runs inside QThread)
    # ----------------------------------------------------------------
    @Slot()
    def run(self):
        print("\n==============================")
        print(" CacheSyncWorker: START")
        print("==============================")

        tier_results = {}

        for label, src, dst in self.sync_map:
            print(f"\n>>> Syncing {label}...")
            self.progress.emit(label)
            self._mirror(src, dst)
            print(f"     {label} robocopy complete")

            # Verification: count files on server vs local
            src_path = Path(src)
            dst_path = Path(dst)
            server_count = sum(1 for f in src_path.iterdir() if f.is_file()) if src_path.exists() else 0
            local_count  = sum(1 for f in dst_path.iterdir() if f.is_file()) if dst_path.exists() else 0
            ok = local_count >= server_count * 0.95

            tier_results[label] = {
                "server": server_count,
                "local":  local_count,
                "ok":     ok,
            }

            if ok:
                print(f"    [OK] {label} verified: local {local_count} / server {server_count}")
            else:
                print(f"    [WARN] {label} gap: local {local_count} / server {server_count}")

        print("\n==============================")
        print(" CacheSyncWorker: FINISHED")
        print("==============================")

        self.finished.emit(tier_results)
