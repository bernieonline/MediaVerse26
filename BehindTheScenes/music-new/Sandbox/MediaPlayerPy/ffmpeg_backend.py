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

    # Compare (ffprobe spec analysis)
    compareReady     = Signal(str, str, float, float)  # (header, body, scoreA, scoreB)

    # Repair
    repairReady      = Signal(str, str)   # (header, body)
    repairProgress   = Signal(int)        # 0-100

    # File Details
    fileDetailsReady = Signal(str, str)   # (header, body)

    # Folder test
    folderTestStarted     = Signal(int)        # total file count
    folderTestFileStarted = Signal(str, int, int)  # (filename, current, total)
    folderTestFileDone    = Signal(str, bool)  # (filename, had_errors)
    folderTestComplete    = Signal(str)        # summary text

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
        self._compare_ref: str = ""
        self._compare_cmp: str = ""
        self._compare_proc = None
        self._repair_proc  = None
        self._details_file: str = ""
        self._folder_cancelled: bool = False

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

    # ── Compare Files (ffprobe spec analysis) ────────────────────────────────

    @Slot()
    def compareFiles(self):
        """Open two file dialogs, probe both with ffprobe, emit compareReady."""
        if not self._ffmpeg_exe:
            self.checkFFmpeg()
            if not self._ffmpeg_exe:
                return

        file_filter = (
            "Video Files (*.mkv *.mp4 *.avi *.mov *.m4v *.mpg *.mpeg "
            "*.ts *.m2ts *.wmv *.flv *.webm);;All Files (*.*)"
        )
        path_a, _ = QFileDialog.getOpenFileName(
            None, "Select File A", "", file_filter
        )
        if not path_a:
            return

        path_b, _ = QFileDialog.getOpenFileName(
            None, "Select File B", "", file_filter
        )
        if not path_b:
            return

        self._compare_ref  = path_a
        self._compare_cmp  = path_b
        self._current_file = path_b
        self.statusMessage.emit("Analysing files…")
        threading.Thread(target=self._do_compare, args=(path_a, path_b), daemon=True).start()

    def _do_compare(self, path_a: str, path_b: str):
        try:
            ffprobe = str(Path(self._ffmpeg_exe).parent / "ffprobe.exe")
            info_a  = _probe_file(ffprobe, path_a)
            info_b  = _probe_file(ffprobe, path_b)
            score_a = _quality_score(info_a)
            score_b = _quality_score(info_b)

            header = (
                f"File A: {Path(path_a).name}\n"
                f"File B: {Path(path_b).name}\n"
                f"Compared: {datetime.now().strftime('%Y-%m-%d  %H:%M')}\n"
                f"{'─' * 52}"
            )
            body = _format_comparison(info_a, info_b, score_a, score_b)

            self.statusMessage.emit("Comparison complete.")
            self.compareReady.emit(header, body, score_a, score_b)

        except Exception as e:
            self.testError.emit(f"Compare failed: {e}")

    # ── Repair File ───────────────────────────────────────────────────────────

    @Slot(str)
    def repairFile(self, mode: str = "remux"):
        """Open file dialog then repair in a background thread."""
        if not self._ffmpeg_exe:
            self.checkFFmpeg()
            if not self._ffmpeg_exe:
                return

        file_path, _ = QFileDialog.getOpenFileName(
            None, "Select File to Repair", "",
            "Video Files (*.mkv *.mp4 *.avi *.mov *.m4v *.mpg *.mpeg "
            "*.ts *.m2ts *.wmv *.flv *.webm);;All Files (*.*)"
        )
        if not file_path:
            return

        self._current_file = file_path
        label = "Remuxing…" if mode == "remux" else "Transcoding…"
        self.statusMessage.emit(label)
        threading.Thread(target=self._do_repair, args=(file_path, mode), daemon=True).start()

    def _do_repair(self, file_path: str, mode: str):
        import subprocess
        p = Path(file_path)

        if mode == "remux":
            out_path = p.parent / (p.stem + "_repair" + p.suffix)
            cmd = [self._ffmpeg_exe, "-y", "-i", file_path, "-c", "copy", str(out_path)]
            try:
                self._repair_proc = subprocess.Popen(
                    cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
                )
                _, stderr = self._repair_proc.communicate()
                self._repair_proc = None
                self._finish_repair(p, out_path, "Remux — lossless stream copy", stderr)
            except Exception as e:
                self._repair_proc = None
                self.testError.emit(f"Repair failed: {e}")

        else:  # transcode
            out_path = p.parent / (p.stem + "_repair.mkv")
            duration = _get_duration_secs(file_path, self._ffmpeg_exe)
            cmd = [
                self._ffmpeg_exe, "-y", "-i", file_path,
                "-c:v", "libx264", "-crf", "18", "-preset", "medium",
                "-c:a", "copy",
                "-progress", "pipe:1", "-nostats",
                str(out_path),
            ]
            try:
                self._repair_proc = subprocess.Popen(
                    cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
                )
                stderr_lines = []
                for line in self._repair_proc.stdout:
                    if line.startswith("out_time_ms="):
                        try:
                            ms = int(line.split("=")[1].strip())
                            if duration > 0:
                                pct = min(99, int(ms / 1000 / duration * 100))
                                self.repairProgress.emit(pct)
                        except Exception:
                            pass
                _, stderr = self._repair_proc.communicate()
                self._repair_proc = None
                self.repairProgress.emit(100)
                self._finish_repair(p, out_path, "Transcode — H.264 re-encode (CRF 18)", stderr)
            except Exception as e:
                self._repair_proc = None
                self.testError.emit(f"Repair failed: {e}")

    def _finish_repair(self, src: Path, out_path: Path, mode_label: str, stderr: str):
        success = out_path.exists() and out_path.stat().st_size > 0
        header = (
            f"Source:  {src.name}\n"
            f"Mode:    {mode_label}\n"
            f"Output:  {out_path.name}\n"
            f"Folder:  {src.parent}\n"
            f"{'─' * 45}"
        )
        if success:
            body = f"\u2713 Complete — {_fmt_size(out_path.stat().st_size)}"
        else:
            errors = [ln for ln in stderr.splitlines()
                      if any(k in ln for k in ("Error", "error", "Invalid", "failed"))]
            body = "\u2717 Failed\n" + "\n".join(errors[-10:])

        self.statusMessage.emit("Repair complete." if success else "Repair failed.")
        self.repairReady.emit(header, body)

    @Slot()
    def cancelRepair(self):
        if self._repair_proc:
            try:
                self._repair_proc.kill()
            except Exception:
                pass
            self.statusMessage.emit("Repair cancelled.")

    # ── File Details ──────────────────────────────────────────────────────────

    @Slot()
    def fileDetails(self):
        """Open file dialog, probe with ffprobe, emit fileDetailsReady."""
        if not self._ffmpeg_exe:
            self.checkFFmpeg()
            if not self._ffmpeg_exe:
                return

        file_path, _ = QFileDialog.getOpenFileName(
            None, "Select Video File", "",
            "Video Files (*.mkv *.mp4 *.avi *.mov *.m4v *.mpg *.mpeg "
            "*.ts *.m2ts *.wmv *.flv *.webm);;All Files (*.*)"
        )
        if not file_path:
            return

        self._details_file = file_path
        self.statusMessage.emit("Probing file…")
        threading.Thread(target=self._do_file_details, args=(file_path,), daemon=True).start()

    def _do_file_details(self, file_path: str):
        import subprocess, json as _json
        ffprobe = str(Path(self._ffmpeg_exe).parent / "ffprobe.exe")
        try:
            r = subprocess.run(
                [ffprobe, "-v", "quiet", "-print_format", "json",
                 "-show_format", "-show_streams", "-show_chapters", file_path],
                capture_output=True, text=True, timeout=30
            )
            data = _json.loads(r.stdout)
            header, body = _format_file_details(data, file_path)
            self.statusMessage.emit("Details ready.")
            self.fileDetailsReady.emit(header, body)
        except Exception as e:
            self.testError.emit(f"File details failed: {e}")

    @Slot(str)
    def saveDetails(self, text: str):
        """Save the details report next to the source file as <stem>_details.txt."""
        if not self._details_file:
            return
        p = Path(self._details_file)
        out_path = p.parent / (p.stem + "_details.txt")
        try:
            out_path.write_text(text, encoding="utf-8")
            self.statusMessage.emit(f"Saved: {out_path.name}")
        except OSError as e:
            self.testError.emit(f"Save failed: {e}")

    # ── Load Saved Report ─────────────────────────────────────────────────────

    @Slot()
    def loadReport(self):
        """Load a previously saved _ffmpeg.txt report into the test panel."""
        txt_path, _ = QFileDialog.getOpenFileName(
            None, "Load FFMPEG Report", "",
            "FFMPEG Reports (*_ffmpeg.txt);;Text Files (*.txt);;All Files (*.*)"
        )
        if not txt_path:
            return

        try:
            text = Path(txt_path).read_text(encoding="utf-8")
        except OSError as e:
            self.testError.emit(f"Cannot read report: {e}")
            return

        # Split at the ─── divider line
        lines     = text.splitlines()
        div_idx   = next(
            (i for i, ln in enumerate(lines) if ln.startswith("\u2500" * 10)),
            len(lines) - 1,
        )
        header = "\n".join(lines[: div_idx + 1])
        body   = "\n".join(lines[div_idx + 1 :]).lstrip("\n")

        # Restore _current_file so Save still works (looks for original video file)
        p = Path(txt_path)
        stem = p.stem  # e.g. "Rocky (1976)_ffmpeg"
        if stem.endswith("_ffmpeg"):
            video_stem = stem[:-7]  # "Rocky (1976)"
            for ext in VIDEO_EXTENSIONS:
                candidate = p.parent / (video_stem + ext)
                if candidate.exists():
                    self._current_file = str(candidate)
                    break
            else:
                self._current_file = txt_path  # fallback: save back to txt
        else:
            self._current_file = txt_path

        self.statusMessage.emit(f"Loaded: {p.name}")
        self.reportReady.emit(header, body)

    # ── Test Folder ───────────────────────────────────────────────────────────

    @Slot(str)
    def testFolder(self, mode: str = "standard"):
        """Open folder dialog, test all video files sequentially, auto-save each report."""
        if not self._ffmpeg_exe:
            self.checkFFmpeg()
            if not self._ffmpeg_exe:
                return

        folder = QFileDialog.getExistingDirectory(None, "Select Folder to Test")
        if not folder:
            return

        files = sorted(
            [f for f in Path(folder).iterdir()
             if f.is_file() and f.suffix.lower() in VIDEO_EXTENSIONS],
            key=lambda f: f.name.lower(),
        )

        if not files:
            self.statusMessage.emit("No video files found in folder.")
            return

        self._folder_cancelled = False
        self.statusMessage.emit(f"Folder test: {len(files)} file(s) found\u2026")
        self.folderTestStarted.emit(len(files))
        threading.Thread(
            target=self._do_folder_test, args=(files, mode, folder), daemon=True
        ).start()

    def _do_folder_test(self, files: list, mode: str, folder: str):
        from error_library import filter_lines

        total = len(files)
        error_files: list[str] = []

        err_flags = ["-err_detect", "+careful"] if mode == "thorough" else []

        for i, fp in enumerate(files):
            if self._folder_cancelled:
                self.statusMessage.emit("Folder test cancelled.")
                self.folderTestComplete.emit("")
                return

            self.folderTestFileStarted.emit(fp.name, i + 1, total)

            # ── Run ffmpeg test (blocking) ─────────────────────────────────────
            cmd = (
                [self._ffmpeg_exe, "-v", "error", "-nostdin"]
                + err_flags
                + ["-i", str(fp), "-map", "0", "-f", "null", "-"]
            )
            import subprocess as _sp
            try:
                result = _sp.run(
                    cmd, capture_output=True, text=True,
                    encoding="utf-8", errors="replace"
                )
                raw_lines = result.stderr.splitlines(keepends=True)
                filtered  = filter_lines(raw_lines)
                body      = "\n".join(filtered) if filtered else "\u2713 No errors detected"
            except Exception as exc:
                body = f"\u2717 Test failed: {exc}"
                filtered = [body]

            had_errors = bool(filtered and filtered[0] != "\u2713 No errors detected")
            if had_errors:
                error_files.append(fp.name)

            # ── Auto-save per-file report ──────────────────────────────────────
            try:
                size_str     = _fmt_size(fp.stat().st_size)
                duration_str = _get_duration_str(str(fp), self._ffmpeg_exe)
            except OSError:
                size_str     = "unknown"
                duration_str = "unknown"

            report_header = (
                f"File:     {fp.name}\n"
                f"Size:     {size_str}\n"
                f"Duration: {duration_str}\n"
                f"Tested:   {datetime.now().strftime('%Y-%m-%d  %H:%M')}\n"
                f"Mode:     {mode.capitalize()}\n"
                f"Part of folder test\n"
                f"{'─' * 45}"
            )
            out_path = fp.parent / (fp.stem + "_ffmpeg.txt")
            try:
                out_path.write_text(
                    report_header + "\n" + body, encoding="utf-8"
                )
            except OSError:
                pass  # don't abort the whole run for a save failure

            self.folderTestFileDone.emit(fp.name, had_errors)
            self.progressChanged.emit(int((i + 1) / total * 100))

        # ── Build and emit summary ─────────────────────────────────────────────
        self.progressChanged.emit(100)
        clean_count = total - len(error_files)
        summary = self._build_folder_summary(
            folder, files, error_files, mode, clean_count
        )

        # Auto-save summary to the tested folder
        ts      = datetime.now().strftime("%Y%m%d_%H%M")
        sum_out = Path(folder) / f"_folder_test_{ts}.txt"
        try:
            sum_out.write_text(summary, encoding="utf-8")
        except OSError:
            pass

        self.statusMessage.emit(
            f"Folder test complete \u2014 {total} files, {len(error_files)} with errors."
        )
        self.folderTestComplete.emit(summary)

    def _build_folder_summary(
        self, folder: str, files: list, error_files: list, mode: str, clean_count: int
    ) -> str:
        total   = len(files)
        divider = "\u2500" * 45
        lines   = [
            "FOLDER TEST REPORT",
            f"Folder:  {folder}",
            f"Tested:  {datetime.now().strftime('%Y-%m-%d  %H:%M')}",
            f"Mode:    {mode.capitalize()}",
            f"Files:   {total} tested",
            f"Clean:   {clean_count}  \u2713",
            f"Errors:  {len(error_files)}  {'✗' if error_files else '✓'}",
            divider,
        ]
        for i, fp in enumerate(files):
            name   = fp.name
            status = "\u2717 errors" if name in error_files else "\u2713 Clean"
            lines.append(f" {i+1:>3}. {name:<55} {status}")

        if error_files:
            lines += ["", divider, "Files with errors:"]
            for name in error_files:
                lines.append(f"  \u2022 {name}")

        return "\n".join(lines)

    @Slot()
    def cancelFolderTest(self):
        self._folder_cancelled = True
        self.statusMessage.emit("Cancelling\u2026")

    @Slot(str)
    def saveFolderSummary(self, text: str):
        """Save the folder summary to the folder (already auto-saved; this is for manual re-save)."""
        if not text:
            return
        # Extract folder from first lines of the summary
        folder = ""
        for line in text.splitlines():
            if line.startswith("Folder:"):
                folder = line.split(":", 1)[1].strip()
                break
        if not folder:
            self.testError.emit("Cannot determine folder from summary.")
            return
        ts      = datetime.now().strftime("%Y%m%d_%H%M")
        out     = Path(folder) / f"_folder_test_{ts}.txt"
        try:
            out.write_text(text, encoding="utf-8")
            self.statusMessage.emit(f"Summary saved: {out.name}")
        except OSError as e:
            self.testError.emit(f"Save failed: {e}")

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


def _get_duration_secs(file_path: str, ffmpeg_exe: str) -> float:
    import subprocess
    ffprobe = str(Path(ffmpeg_exe).parent / "ffprobe.exe")
    try:
        r = subprocess.run(
            [ffprobe, "-v", "quiet", "-show_entries", "format=duration",
             "-of", "csv=p=0", file_path],
            capture_output=True, text=True, timeout=15
        )
        return float(r.stdout.strip())
    except Exception:
        return 0.0


def _get_duration_str(file_path: str, ffmpeg_exe: str) -> str:
    import subprocess
    ffprobe = str(Path(ffmpeg_exe).parent / "ffprobe.exe")
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


# ── ffprobe / compare helpers ─────────────────────────────────────────────────

def _probe_file(ffprobe_exe: str, file_path: str) -> dict:
    """Return a dict of quality-relevant metrics for a video file."""
    import subprocess, json as _json
    r = subprocess.run(
        [ffprobe_exe, "-v", "quiet", "-print_format", "json",
         "-show_streams", "-show_format", file_path],
        capture_output=True, text=True, timeout=30
    )
    data = _json.loads(r.stdout)
    fmt  = data.get("format", {})

    info = {
        "size":             int(fmt.get("size", 0)),
        "duration":         float(fmt.get("duration", 0)),
        "overall_bitrate":  int(fmt.get("bit_rate", 0)),
        "video_codec": "", "width": 0, "height": 0,
        "framerate": 0.0,  "video_bitrate": 0,
        "audio_codec": "", "audio_bitrate": 0,
        "audio_channels": 0,
    }

    for s in data.get("streams", []):
        if s.get("codec_type") == "video" and not info["video_codec"]:
            info["video_codec"]   = s.get("codec_name", "")
            info["width"]         = s.get("width", 0)
            info["height"]        = s.get("height", 0)
            info["video_bitrate"] = int(s.get("bit_rate", 0))
            try:
                num, den = s.get("r_frame_rate", "0/1").split("/")
                info["framerate"] = round(int(num) / max(1, int(den)), 3)
            except Exception:
                info["framerate"] = 0.0

        if s.get("codec_type") == "audio" and not info["audio_codec"]:
            info["audio_codec"]    = s.get("codec_name", "")
            info["audio_bitrate"]  = int(s.get("bit_rate", 0))
            info["audio_channels"] = s.get("channels", 0)

    # Some containers (M2TS) don't expose per-stream bitrate — estimate from overall
    if info["video_bitrate"] == 0 and info["overall_bitrate"] > 0:
        info["video_bitrate"] = max(0, info["overall_bitrate"] - info["audio_bitrate"])

    return info


def _quality_score(info: dict) -> float:
    """
    Score 0-100 based on codec, resolution, effective bitrate, and audio.
    Works regardless of resolution or framerate differences between files.
    """
    import math
    score = 0.0

    # ── Codec (0-25) ──────────────────────────────────────────────────────────
    codec = info["video_codec"].lower()
    if   any(x in codec for x in ("hevc", "h265", "av1")):  score += 25
    elif "vp9"  in codec:                                     score += 21
    elif any(x in codec for x in ("h264", "avc")):           score += 17
    elif any(x in codec for x in ("mpeg2", "vc1", "wmv")):   score += 9
    else:                                                      score += 6

    # ── Resolution (0-30) ─────────────────────────────────────────────────────
    pixels = info["width"] * info["height"]
    if   pixels >= 3840 * 2000: score += 30   # 4K UHD
    elif pixels >= 1920 * 1000: score += 22   # 1080p
    elif pixels >= 1280 *  700: score += 14   # 720p
    elif pixels >= 720  *  500: score += 8    # 576p / 480p
    else:                        score += 3

    # ── Video bitrate — log scale (0-30) ─────────────────────────────────────
    vbr_mbps = info["video_bitrate"] / 1_000_000
    if vbr_mbps > 0:
        score += min(30.0, 30.0 * math.log10(max(1, vbr_mbps)) / math.log10(80))

    # ── Audio (0-15) ──────────────────────────────────────────────────────────
    ac = info["audio_codec"].lower()
    if   any(x in ac for x in ("truehd", "dtshd", "flac", "pcm")): score += 15
    elif any(x in ac for x in ("dts", "ac3", "eac3")):              score += 10
    elif "aac" in ac:                                                 score += 7
    elif "mp3" in ac:                                                 score += 4
    else:                                                              score += 5

    return round(min(100.0, score), 1)


def _fmt_bitrate(bps: int) -> str:
    if bps <= 0:       return "n/a"
    if bps >= 1_000_000: return f"{bps/1_000_000:.1f} Mbps"
    return f"{bps//1000} Kbps"


def _fmt_dur(secs: float) -> str:
    if secs <= 0: return "n/a"
    h = int(secs // 3600)
    m = int((secs % 3600) // 60)
    s = int(secs % 60)
    return f"{h}:{m:02d}:{s:02d}"


def _format_file_details(data: dict, file_path: str) -> tuple:
    """Format full ffprobe JSON into a readable details report. Returns (header, body)."""
    p = Path(file_path)
    fmt      = data.get("format", {})
    streams  = data.get("streams", [])
    chapters = data.get("chapters", [])

    # ── Header ────────────────────────────────────────────────────────────────
    try:
        size_bytes = p.stat().st_size
        size_str   = _fmt_size(size_bytes)
    except OSError:
        size_str   = _fmt_size(int(fmt.get("size", 0)))

    duration    = float(fmt.get("duration", 0))
    overall_br  = int(fmt.get("bit_rate", 0))
    fmt_tags    = fmt.get("tags", {})
    encoded     = fmt_tags.get("creation_time", "").replace("T", " ").split(".")[0]

    header = (
        f"File:     {p.name}\n"
        f"Size:     {size_str}\n"
        f"Duration: {_fmt_dur(duration)}\n"
        f"Probed:   {datetime.now().strftime('%Y-%m-%d  %H:%M')}\n"
        f"{'─' * 45}"
    )

    # ── Body ──────────────────────────────────────────────────────────────────
    _CH = {1: "mono", 2: "stereo", 6: "5.1", 8: "7.1"}
    lines = []

    # Container
    fmt_name = fmt.get("format_long_name") or fmt.get("format_name", "unknown")
    lines += [
        "─── CONTAINER " + "─" * 31,
        f"Format:          {fmt_name}",
        f"Overall Bitrate: {_fmt_bitrate(overall_br)}",
    ]
    if encoded:
        lines.append(f"Encoded:         {encoded}")
    lines.append("")

    # Video streams
    video_streams = [s for s in streams if s.get("codec_type") == "video"]
    for i, s in enumerate(video_streams):
        track_label = "" if len(video_streams) == 1 else f" (Track {i + 1})"
        lines.append(f"─── VIDEO{track_label} " + "─" * (36 - len(track_label)))

        codec_long = s.get("codec_long_name") or s.get("codec_name", "unknown")
        profile    = s.get("profile", "")
        level_raw  = s.get("level", -1)
        level      = f"L{level_raw / 10:.1f}" if isinstance(level_raw, int) and level_raw > 0 else ""
        codec_disp = codec_long
        if profile and level:
            codec_disp += f"  ({profile} {level})"
        elif profile:
            codec_disp += f"  ({profile})"

        try:
            num, den = s.get("r_frame_rate", "0/1").split("/")
            fps = round(int(num) / max(1, int(den)), 3)
        except Exception:
            fps = 0.0

        vbr      = int(s.get("bit_rate", 0))
        pix_fmt  = s.get("pix_fmt", "")
        colorsp  = s.get("color_space", "")

        lines += [
            f"Codec:           {codec_disp}",
            f"Resolution:      {s.get('width', 0)} × {s.get('height', 0)}",
            f"Framerate:       {fps} fps",
        ]
        if vbr:
            lines.append(f"Bitrate:         {_fmt_bitrate(vbr)}")
        if pix_fmt:
            lines.append(f"Pixel Format:    {pix_fmt}")
        if colorsp:
            lines.append(f"Colour Space:    {colorsp}")
        lines.append("")

    # Audio streams
    audio_streams = [s for s in streams if s.get("codec_type") == "audio"]
    for i, s in enumerate(audio_streams):
        track_label = "" if len(audio_streams) == 1 else f" (Track {i + 1})"
        lines.append(f"─── AUDIO{track_label} " + "─" * (36 - len(track_label)))

        codec    = s.get("codec_long_name") or s.get("codec_name", "unknown")
        channels = s.get("channels", 0)
        ch_label = _CH.get(channels, f"{channels}ch")
        abr      = int(s.get("bit_rate", 0))
        sr       = s.get("sample_rate", "")
        tags     = s.get("tags", {})
        lang     = tags.get("language", "")
        title    = tags.get("title", "")

        lines += [
            f"Codec:           {codec}",
            f"Channels:        {channels} ({ch_label})",
        ]
        if sr:
            lines.append(f"Sample Rate:     {sr} Hz")
        if abr:
            lines.append(f"Bitrate:         {_fmt_bitrate(abr)}")
        if lang:
            lines.append(f"Language:        {lang}")
        if title:
            lines.append(f"Title:           {title}")
        lines.append("")

    # Subtitle streams
    sub_streams = [s for s in streams if s.get("codec_type") == "subtitle"]
    if sub_streams:
        lines.append("─── SUBTITLES " + "─" * 31)
        for i, s in enumerate(sub_streams):
            codec = s.get("codec_name", "unknown").upper()
            tags  = s.get("tags", {})
            lang  = tags.get("language", "")
            title = tags.get("title", "")
            entry = f"Track {i + 1}:         {codec}"
            if lang:
                entry += f"  [{lang}]"
            if title:
                entry += f"  {title}"
            lines.append(entry)
        lines.append("")

    # Chapters
    if chapters:
        lines += [
            "─── CHAPTERS " + "─" * 32,
            f"{len(chapters)} chapters",
            "",
        ]

    return header, "\n".join(lines)


def _format_comparison(ia: dict, ib: dict, sa: float, sb: float) -> str:
    """Return a formatted side-by-side spec table with verdict."""
    W = 20   # column width

    def row(label, va, vb):
        return f"{label:<18} {str(va):>{W}}   {str(vb):>{W}}"

    def winner_tag(va, vb, higher=True):
        if va == vb: return ""
        a_wins = (va > vb) if higher else (va < vb)
        return "  ◄ A" if a_wins else "  ◄ B"

    lines = [
        f"{'METRIC':<18} {'FILE A':>{W}}   {'FILE B':>{W}}",
        "─" * (18 + W*2 + 5),
        row("Resolution",
            f"{ia['width']}×{ia['height']}",
            f"{ib['width']}×{ib['height']}") +
            winner_tag(ia['width']*ia['height'], ib['width']*ib['height']),
        row("Video Codec",
            ia['video_codec'].upper() or "n/a",
            ib['video_codec'].upper() or "n/a"),
        row("Framerate",
            f"{ia['framerate']} fps",
            f"{ib['framerate']} fps"),
        row("Video Bitrate",
            _fmt_bitrate(ia['video_bitrate']),
            _fmt_bitrate(ib['video_bitrate'])) +
            winner_tag(ia['video_bitrate'], ib['video_bitrate']),
        row("Audio Codec",
            ia['audio_codec'].upper() or "n/a",
            ib['audio_codec'].upper() or "n/a"),
        row("Audio Bitrate",
            _fmt_bitrate(ia['audio_bitrate']),
            _fmt_bitrate(ib['audio_bitrate'])) +
            winner_tag(ia['audio_bitrate'], ib['audio_bitrate']),
        row("Channels",
            str(ia['audio_channels']),
            str(ib['audio_channels'])),
        row("Duration",
            _fmt_dur(ia['duration']),
            _fmt_dur(ib['duration'])),
        row("File Size",
            _fmt_size(ia['size']),
            _fmt_size(ib['size'])),
        "─" * (18 + W*2 + 5),
        row("QUALITY SCORE", f"{sa} / 100", f"{sb} / 100"),
        "",
    ]

    diff = abs(sa - sb)
    if   sa > sb: lines.append(f"► File A is the better choice  (+{diff:.1f} pts)")
    elif sb > sa: lines.append(f"► File B is the better choice  (+{diff:.1f} pts)")
    else:         lines.append("= Both files score equally")

    if diff < 5:
        lines.append("  Difference is marginal — either file is suitable.")
    elif diff < 15:
        lines.append("  Moderate advantage — the better file is noticeably superior.")
    else:
        lines.append("  Significant advantage — choose the higher-scoring file.")

    return "\n".join(lines)
