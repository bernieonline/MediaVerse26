# ─────────────────────────────────────────────────────────────────────────────
#  ffmpeg_worker.py — QThread worker for FFMPEG test operations
#
#  Runs ffprobe to get duration, then ffmpeg with -progress pipe to emit
#  real percentage progress.  Error lines streamed live via lineReady signal.
# ─────────────────────────────────────────────────────────────────────────────

import subprocess
import re
from pathlib import Path

from PySide6.QtCore import QThread, Signal


def _parse_duration(raw: str) -> float:
    """Convert HH:MM:SS.ss or bare seconds string to float seconds."""
    raw = raw.strip()
    if ":" in raw:
        parts = raw.split(":")
        try:
            h, m, s = float(parts[0]), float(parts[1]), float(parts[2])
            return h * 3600 + m * 60 + s
        except (ValueError, IndexError):
            return 0.0
    try:
        return float(raw)
    except ValueError:
        return 0.0


class FFmpegWorker(QThread):
    """
    Runs an ffmpeg test on a single file.

    Signals
    -------
    lineReady(str)        — each filtered error line as it arrives
    progressChanged(int)  — 0–100 percentage based on out_time vs duration
    finished(str)         — full filtered output when complete (empty = clean)
    errorOccurred(str)    — emitted if ffmpeg/ffprobe itself fails to launch
    """

    lineReady       = Signal(str)
    progressChanged = Signal(int)
    finished        = Signal(str)
    errorOccurred   = Signal(str)

    # Modes
    MODE_STANDARD  = "standard"
    MODE_THOROUGH  = "thorough"

    def __init__(self, file_path: str, ffmpeg_exe: str, mode: str = MODE_STANDARD):
        super().__init__()
        self._file_path  = file_path
        self._ffmpeg_exe = ffmpeg_exe
        self._mode       = mode
        self._cancelled  = False
        self._duration   = 0.0
        self._error_lines: list[str] = []

    def cancel(self):
        self._cancelled = True

    # ── ffprobe duration ──────────────────────────────────────────────────────

    def _get_duration(self) -> float:
        ffprobe = str(Path(self._ffmpeg_exe).parent / "ffprobe.exe")
        try:
            result = subprocess.run(
                [ffprobe, "-v", "quiet",
                 "-show_entries", "format=duration",
                 "-of", "csv=p=0",
                 self._file_path],
                capture_output=True, text=True, timeout=15
            )
            return _parse_duration(result.stdout)
        except Exception:
            return 0.0

    # ── main thread entry ─────────────────────────────────────────────────────

    def run(self):
        from error_library import filter_lines

        self._duration = self._get_duration()

        # Build ffmpeg command
        err_flags = ["-err_detect", "+careful"] if self._mode == self.MODE_THOROUGH else []

        cmd = (
            [self._ffmpeg_exe,
             "-v", "error",
             "-progress", "pipe:1",
             "-nostats",
             "-nostdin"]
            + err_flags
            + ["-i", self._file_path,
               "-map", "0",
               "-f", "null", "-"]
        )

        try:
            proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
        except FileNotFoundError:
            self.errorOccurred.emit(f"ffmpeg not found at: {self._ffmpeg_exe}")
            return
        except Exception as e:
            self.errorOccurred.emit(str(e))
            return

        raw_errors: list[str] = []

        # Read stdout (progress) and stderr (errors) via polling
        import selectors, sys

        if sys.platform == "win32":
            # Windows: read both pipes in a simple loop
            import threading

            def read_stderr():
                for line in proc.stderr:
                    raw_errors.append(line)

            stderr_thread = threading.Thread(target=read_stderr, daemon=True)
            stderr_thread.start()

            for line in proc.stdout:
                if self._cancelled:
                    proc.kill()
                    break
                self._handle_progress_line(line.strip())

            stderr_thread.join(timeout=5)
        else:
            sel = selectors.DefaultSelector()
            sel.register(proc.stdout, selectors.EVENT_READ)
            sel.register(proc.stderr, selectors.EVENT_READ)

            while True:
                if self._cancelled:
                    proc.kill()
                    break
                events = sel.select(timeout=0.1)
                if not events and proc.poll() is not None:
                    break
                for key, _ in events:
                    line = key.fileobj.readline()
                    if not line:
                        continue
                    if key.fileobj is proc.stdout:
                        self._handle_progress_line(line.strip())
                    else:
                        raw_errors.append(line)

            sel.close()

        proc.wait()

        # Filter and emit
        filtered = filter_lines(raw_errors)
        for line in filtered:
            self.lineReady.emit(line)

        self.progressChanged.emit(100)
        self.finished.emit("\n".join(filtered))

    def _handle_progress_line(self, line: str):
        """Parse ffmpeg -progress output and emit percentage."""
        if not line.startswith("out_time="):
            return
        # out_time=HH:MM:SS.ffffff
        time_str = line.split("=", 1)[1]
        elapsed = _parse_duration(time_str)
        if self._duration > 0:
            pct = min(int(elapsed / self._duration * 100), 99)
            self.progressChanged.emit(pct)
