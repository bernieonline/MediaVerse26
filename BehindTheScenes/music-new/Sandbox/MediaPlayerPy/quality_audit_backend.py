"""
QualityAuditBackend
===================
PySide6 QObject wrapper that exposes the video quality audit (quality_audit.py)
to the QML layer via signals and slots.

Context property name: qualityAuditBackend
"""

from __future__ import annotations

import sys
import threading
import webbrowser
from datetime import datetime
from pathlib import Path

from PySide6.QtCore import QObject, Signal, Slot, QThread

# ── Paths ────────────────────────────────────────────────────────────────────
_this_dir   = Path(__file__).resolve().parent       # .../Sandbox/MediaPlayerPy/
_sandbox    = _this_dir.parent                       # .../Sandbox/
_proj_root  = _sandbox.parent                        # .../music-new/

REPORTS_DIR = _sandbox / "Reports" / "Quality Audits"
HELP_FILE   = _proj_root / "video_quality_audit_guide.html"

# Ensure quality_audit.py can be imported from the same directory
if str(_this_dir) not in sys.path:
    sys.path.insert(0, str(_this_dir))


# ── Worker thread ─────────────────────────────────────────────────────────────

class _AuditThread(QThread):
    """Runs scan_directory + generate_html_report in a background thread."""

    progressChanged = Signal(int, int)   # (completed, total)
    auditComplete   = Signal(str)        # absolute path of saved report
    statusMessage   = Signal(str)

    def __init__(self, folder: str, output: Path, threshold: int = 25) -> None:
        super().__init__()
        self._folder    = folder
        self._output    = output
        self._threshold = threshold
        self._cancel    = threading.Event()

    def cancel(self) -> None:
        self._cancel.set()

    def run(self) -> None:
        try:
            # Lazy import keeps module load fast
            from quality_audit import scan_directory, generate_html_report

            scan_path = Path(self._folder)
            self.statusMessage.emit(f"Scanning {scan_path.name}…")

            results, total_scanned, errors = scan_directory(
                scan_path,
                progress_callback=lambda done, total: self.progressChanged.emit(done, total),
                cancel_flag=self._cancel,
            )

            if self._cancel.is_set():
                self.statusMessage.emit("Audit cancelled.")
                return

            self.statusMessage.emit("Generating report…")
            generate_html_report(
                results, total_scanned, scan_path,
                self._threshold, self._output, errors,
            )
            self.auditComplete.emit(str(self._output))

        except Exception as exc:  # pylint: disable=broad-except
            self.statusMessage.emit(f"Error: {exc}")


# ── QObject backend ───────────────────────────────────────────────────────────

class QualityAuditBackend(QObject):
    """QML context property — qualityAuditBackend."""

    progressChanged = Signal(int, int)   # (completed, total)
    auditComplete   = Signal(str)        # absolute report path
    statusMessage   = Signal(str)

    def __init__(self) -> None:
        super().__init__()
        self._thread: _AuditThread | None = None
        REPORTS_DIR.mkdir(parents=True, exist_ok=True)

    # ── Slots ─────────────────────────────────────────────────────────────────

    @Slot(str)
    def startAudit(self, folder_path: str) -> None:
        """Begin a quality audit of folder_path in a background thread."""
        if self._thread and self._thread.isRunning():
            return  # already running

        # Normalise file:// URL emitted by QML FolderDialog
        if folder_path.startswith("file:///"):
            folder_path = folder_path[8:]
        elif folder_path.startswith("file://"):
            folder_path = folder_path[7:]
        # On Windows the path may have forward slashes — Path() handles this
        folder = Path(folder_path)

        if not folder.exists():
            self.statusMessage.emit(f"Folder not found: {folder_path}")
            return

        # Check ffprobe is reachable before spinning up the thread
        from quality_audit import FFPROBE_EXE
        if not FFPROBE_EXE:
            self.statusMessage.emit(
                "Error: ffprobe not found — install FFmpeg or add it to your PATH"
            )
            return

        timestamp  = datetime.now().strftime("%Y%m%d_%H%M%S")
        safe_name  = "".join(
            c if (c.isalnum() or c in "-_") else "_" for c in folder.name
        )
        report_path = REPORTS_DIR / f"QA_{timestamp}_{safe_name}.html"

        self._thread = _AuditThread(str(folder), report_path)
        self._thread.progressChanged.connect(self.progressChanged)
        self._thread.auditComplete.connect(self.auditComplete)
        self._thread.statusMessage.connect(self.statusMessage)
        self._thread.start()

    @Slot()
    def cancelAudit(self) -> None:
        """Signal the running audit to stop after the current file."""
        if self._thread and self._thread.isRunning():
            self._thread.cancel()

    @Slot(result="QVariantList")
    def getReportList(self) -> list:
        """Return all saved report paths, newest first."""
        if not REPORTS_DIR.exists():
            return []
        reports = sorted(
            REPORTS_DIR.glob("QA_*.html"),
            key=lambda p: p.stat().st_mtime,
            reverse=True,
        )
        return [str(p) for p in reports]

    @Slot(str)
    def openReport(self, path: str) -> None:
        """Open a report file in the default browser."""
        p = Path(path)
        if p.exists():
            webbrowser.open(p.as_uri())

    @Slot(str)
    def diagnoseFirst(self, folder_path: str) -> None:
        """Run MediaInfo on the first video file in the folder (in a thread)."""
        self.statusMessage.emit("Starting diagnostic…")

        def _run():
            try:
                from quality_audit import VIDEO_EXTENSIONS, FFPROBE_EXE

                fp = folder_path
                if fp.startswith("file:///"):
                    fp = fp[8:]
                elif fp.startswith("file://"):
                    fp = fp[7:]

                folder = Path(fp)
                if not folder.exists():
                    self.statusMessage.emit(f"Diagnose: folder not found — {fp}")
                    return

                video_files = [
                    p for p in folder.rglob("*")
                    if p.is_file() and p.suffix.lower() in VIDEO_EXTENSIONS
                ]

                if not video_files:
                    self.statusMessage.emit("Diagnose: no video files found in folder")
                    return

                test_file = video_files[0]
                self.statusMessage.emit(f"Diagnosing: {test_file.name}…")

                from quality_audit import get_ffprobe, FFPROBE_EXE
                self.statusMessage.emit(f"ffprobe: {FFPROBE_EXE}")
                probe = get_ffprobe(test_file)
                if probe is None:
                    self.statusMessage.emit(
                        f"FAIL: ffprobe returned nothing for {test_file.name}"
                    )
                else:
                    streams = probe.get("streams", [])
                    vid = next((s for s in streams if s.get("codec_type") == "video"), {})
                    w   = vid.get("width",  vid.get("coded_width",  "?"))
                    h   = vid.get("height", vid.get("coded_height", "?"))
                    fps = vid.get("avg_frame_rate", "?")
                    self.statusMessage.emit(
                        f"OK: {test_file.name}  |  W={w}  H={h}  fps={fps}"
                    )

            except Exception as exc:
                self.statusMessage.emit(f"Diagnose exception: {exc}")

        import threading
        threading.Thread(target=_run, daemon=True).start()

    @Slot()
    def openHelp(self) -> None:
        """Open the quality audit help page in the default browser."""
        if HELP_FILE.exists():
            webbrowser.open(HELP_FILE.as_uri())
        else:
            self.statusMessage.emit(f"Help file not found: {HELP_FILE}")
