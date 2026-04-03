# ─────────────────────────────────────────────────────────────────────────────
#  ffmpeg_backend.py — PySide6 QObject backend for the Workbench module
#
#  Exposed to QML as context property "ffmpegBackend".
#  Handles: ffmpeg install check, download, test file, save report.
# ─────────────────────────────────────────────────────────────────────────────

import shutil
import os
import threading
from datetime import datetime
from pathlib import Path
from typing import Optional

from PySide6.QtCore import QObject, Slot, Signal
from PySide6.QtWidgets import QFileDialog

from project_paths import paths as _paths

# ── Config ────────────────────────────────────────────────────────────────────

_project_root = _paths["project_root"]

FFMPEG_LOCAL   = _project_root / "tools" / "ffmpeg" / "ffmpeg.exe"
FFMPEG_DL_URL  = (
    "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/"
    "ffmpeg-master-latest-win64-gpl.zip"
)
VIDEO_EXTENSIONS = {
    ".mkv", ".mp4", ".avi", ".mov", ".m4v", ".mpg", ".mpeg",
    ".ts", ".m2ts", ".wmv", ".flv", ".webm",
}


def _resolve_ffmpeg() -> Optional[str]:
    """Return path to ffmpeg exe, or None if not found."""
    if FFMPEG_LOCAL.exists():
        return str(FFMPEG_LOCAL)
    found = shutil.which("ffmpeg")
    return found  # None if not on PATH


# ── Backend ───────────────────────────────────────────────────────────────────

class FFmpegBackend(QObject):

    # ── Signals ───────────────────────────────────────────────────────────────
    # Test / report
    reportReady      = Signal(str, str)   # (header, body)
    progressChanged  = Signal(int)        # 0–100
    statusMessage    = Signal(str)        # status bar text
    testError        = Signal(str)        # error message if test fails

    # Analysis
    analysisDone     = Signal(str, str)   # (verdict, summary)
    ffmpegAskAI      = Signal(str, str)   # (filename, prompt) → forward to aiController

    # Install / download
    ffmpegMissing    = Signal()
    downloadProgress = Signal(int)        # 0–100
    downloadComplete = Signal()
    downloadFailed   = Signal(str)        # reason string

    def __init__(self, parent=None):
        super().__init__(parent)
        self._ffmpeg_exe: Optional[str] = None
        self._worker = None
        self._current_file: str = ""
        self._current_mode: str = "standard"

    # ── Install check ─────────────────────────────────────────────────────────

    @Slot()
    def checkFFmpeg(self):
        """Call on startup / when Workbench is first opened."""
        self._ffmpeg_exe = _resolve_ffmpeg()
        if not self._ffmpeg_exe:
            self.ffmpegMissing.emit()
        else:
            self.statusMessage.emit(f"ffmpeg ready: {self._ffmpeg_exe}")

    # ── Download ──────────────────────────────────────────────────────────────

    @Slot()
    def downloadFFmpeg(self):
        """Download ffmpeg static build in a background thread."""
        t = threading.Thread(target=self._do_download, daemon=True)
        t.start()

    def _do_download(self):
        import urllib.request
        import zipfile
        import tempfile

        dest_dir = FFMPEG_LOCAL.parent
        dest_dir.mkdir(parents=True, exist_ok=True)
        zip_path = dest_dir / "ffmpeg_download.zip"

        try:
            # Stream download with progress
            with urllib.request.urlopen(FFMPEG_DL_URL, timeout=60) as resp:
                total = int(resp.headers.get("Content-Length", 0))
                downloaded = 0
                chunk = 65536
                with open(zip_path, "wb") as f:
                    while True:
                        data = resp.read(chunk)
                        if not data:
                            break
                        f.write(data)
                        downloaded += len(data)
                        if total > 0:
                            pct = min(int(downloaded / total * 90), 90)
                            self.downloadProgress.emit(pct)

            # Extract ffmpeg.exe
            self.downloadProgress.emit(92)
            with zipfile.ZipFile(zip_path, "r") as zf:
                # BtbN zip contains bin/ffmpeg.exe inside a named folder
                for name in zf.namelist():
                    if name.endswith("bin/ffmpeg.exe"):
                        data = zf.read(name)
                        FFMPEG_LOCAL.write_bytes(data)
                        break
                else:
                    raise FileNotFoundError("ffmpeg.exe not found in zip")

            zip_path.unlink(missing_ok=True)
            self._ffmpeg_exe = str(FFMPEG_LOCAL)
            self.downloadProgress.emit(100)
            self.downloadComplete.emit()

        except Exception as e:
            if zip_path.exists():
                zip_path.unlink(missing_ok=True)
            self.downloadFailed.emit(str(e))

    # ── Test File ─────────────────────────────────────────────────────────────

    @Slot(str)
    def testFile(self, mode: str = "standard"):
        """Open file dialog, run ffmpeg test, emit reportReady."""
        if not self._ffmpeg_exe:
            self.checkFFmpeg()
            if not self._ffmpeg_exe:
                return  # ffmpegMissing already emitted

        file_path, _ = QFileDialog.getOpenFileName(
            None,
            "Select Video File",
            "",
            "Video Files (*.mkv *.mp4 *.avi *.mov *.m4v *.mpg *.mpeg "
            "*.ts *.m2ts *.wmv *.flv *.webm);;All Files (*.*)"
        )
        if not file_path:
            return  # user cancelled

        self._current_file = file_path
        self._current_mode = mode
        self._run_test(file_path, mode)

    def _run_test(self, file_path: str, mode: str):
        from ffmpeg_worker import FFmpegWorker

        # Cancel any previous run
        if self._worker and self._worker.isRunning():
            self._worker.cancel()
            self._worker.wait(3000)

        self._worker = FFmpegWorker(file_path, self._ffmpeg_exe, mode)
        self._worker.setParent(self)   # prevent Python GC while thread runs
        self._worker.progressChanged.connect(self.progressChanged)
        self._worker.errorOccurred.connect(self.testError)
        self._worker.finished.connect(self._on_test_finished)
        self.statusMessage.emit("Running test\u2026")
        self._worker.start()

    def _on_test_finished(self, filtered_output: str):
        print(f"[FFMPEG] Test finished. Errors found: {bool(filtered_output.strip())}")
        p = Path(self._current_file)

        # File size
        try:
            size_bytes = p.stat().st_size
            size_str = _fmt_size(size_bytes)
        except OSError:
            size_str = "unknown"

        # Duration (already measured by worker — re-read from ffprobe for header)
        duration_str = _get_duration_str(self._current_file, self._ffmpeg_exe)

        header = (
            f"File:     {p.name}\n"
            f"Size:     {size_str}\n"
            f"Duration: {duration_str}\n"
            f"Tested:   {datetime.now().strftime('%Y-%m-%d  %H:%M')}\n"
            f"Mode:     {self._current_mode.capitalize()}\n"
            f"{'─' * 45}"
        )

        body = filtered_output if filtered_output.strip() else "\u2713 No errors detected"
        self.statusMessage.emit("Test complete.")
        print(f"[FFMPEG] Emitting reportReady signal")
        self.reportReady.emit(header, body)
        print(f"[FFMPEG] reportReady emitted")

    # ── Save Report ───────────────────────────────────────────────────────────

    @Slot(str)
    def saveReport(self, text: str):
        """Save the (possibly edited) report next to the source file."""
        if not self._current_file:
            return
        p = Path(self._current_file)
        out_path = p.parent / (p.stem + "_ffmpeg.txt")
        try:
            out_path.write_text(text, encoding="utf-8")
            self.statusMessage.emit(f"Saved: {out_path.name}")
        except OSError as e:
            self.testError.emit(f"Save failed: {e}")

    # ── Analyse Report ────────────────────────────────────────────────────────

    @Slot(str, str)
    def analyseReport(self, filename: str, error_text: str):
        """
        Run local severity classifier and emit analysisDone.
        verdict is "none"|"minor"|"major"|"critical".
        If major or critical, also emit ffmpegAskAI with a ready-made prompt.
        """
        from error_library import classify_errors
        verdict, summary = classify_errors(error_text)
        self.analysisDone.emit(verdict, summary)

        if verdict in ("major", "critical"):
            prompt = (
                f"These errors were found when testing a video file with ffmpeg:\n\n"
                f"{error_text}\n\n"
                f"Please explain in plain English:\n"
                f"1. What is likely causing these errors\n"
                f"2. How they will affect playback\n"
                f"3. Whether attempting a repair (remux with ffmpeg -c copy) is worth trying"
            )
            self.ffmpegAskAI.emit(filename, prompt)

    # ── Cancel ────────────────────────────────────────────────────────────────

    @Slot()
    def cancelTest(self):
        if self._worker and self._worker.isRunning():
            self._worker.cancel()
            self.statusMessage.emit("Test cancelled.")


# ── Helpers ───────────────────────────────────────────────────────────────────

def _fmt_size(n: int) -> str:
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if n < 1024:
            return f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} PB"


def _get_duration_str(file_path: str, ffmpeg_exe: str) -> str:
    import subprocess
    ffprobe = ffmpeg_exe.replace("ffmpeg", "ffprobe")
    try:
        r = subprocess.run(
            [ffprobe, "-v", "quiet",
             "-show_entries", "format=duration",
             "-of", "csv=p=0", file_path],
            capture_output=True, text=True, timeout=15
        )
        secs = float(r.stdout.strip())
        h = int(secs // 3600)
        m = int((secs % 3600) // 60)
        s = int(secs % 60)
        return f"{h}:{m:02d}:{s:02d}"
    except Exception:
        return "unknown"
