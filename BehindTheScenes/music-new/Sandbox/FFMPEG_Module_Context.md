# FFMPEG Utilities Module - Build Context

## Project Goal
Rebuild the FFMPEG utilities from `music-new` as a standalone PySide6/QML module
for the **Mediaverse** project. This is a clean rebuild — not a port — using
modern PySide6 + QML architecture.

---

## Module 1: FFMPEG Utilities (this document)

### Functions to Implement

| Button (old name)     | Action                                         | Status      |
|-----------------------|------------------------------------------------|-------------|
| `testFFFileButton`    | Test a single file — run ffmpeg error check, save `.txt` report next to the file | TODO |
| `testFFFolderButton`  | Test all video files in a folder — same report per file | TODO |
| `repairFFButton`      | Select a file, attempt ffmpeg repair (remux: `-c copy`) | TODO |
| `convertFFButton`     | Convert selected file to a format chosen from a list | TODO |
| `playFFButton`        | Play a file using MPC-HC (or configurable player) | TODO |
| `viewFFFileButton`    | Select a `.txt` report file and display it on screen | TODO |

---

## Source Code Reference (music-new — DO NOT COPY, use as reference only)

### Key files
- `music-new/MediaManager.py` — PyQt5 UI definition (auto-generated from .ui)
- `music-new/getMainWindow.py` — Button connections and FFMPEG handler methods
- `music-new/srcMovie/ffmpegFunc.py` — FFMPEG logic (worker thread, checkError, repairError, viewError, trimErrorLog)
- `music-new/srcMovie/errorLibrary.py` — List of ignorable ffmpeg error strings

### Existing Logic Summary

#### Test File (`checkError` / `FFmpegWorker`)
- Opens file dialog to select any video file
- Runs: `ffmpeg -v error -nostdin -i <file> -map 0:1 -f null -`
- Captures stderr line by line via `QThread` + `pyqtSignal`
- Writes raw output to a temp file (`D:/filexx.txt`)
- After completion, calls `trimErrorLog` which:
  - Filters out noise lines using `errorLibrary` (e.g. `non-existing PPS 0 referenced`, `decode_slice_header error`, `no frame!`)
  - Strips lines containing `Last message repeated`
  - Writes cleaned report to `<source_filename>.txt` in the same folder as the input file
- A pulsing `QProgressBar` shows activity during the run

#### View File (`viewError`)
- Opens file dialog filtered to `.txt`
- Reads the selected file and displays in a `QTextEdit`

#### Repair File (`repairError`)
- Opens file dialog (any file type)
- Currently a stub — the command should be: `ffmpeg -i <input> -c copy <output>`
- Output file should be the same name with `_repaired` suffix, same folder

#### Convert File (`convFile`)
- Currently a stub — needs format selection combo box
- Command pattern: `ffmpeg -i <input> -qscale 0 <output>.<ext>`

#### Play File (`playMovie`)
- Calls MPC-HC: `mpc-hc64.exe "<file>" /play`
- Player path is hardcoded — should be configurable

#### View File Details (MediaInfo)
- Calls: `MediaInfo.exe "<file>"`
- Hardcoded path `C:\Program Files\MediaInfo\` — should be configurable

---

## New Architecture: PySide6 + QML

### Design Decisions
- [ ] QML for all UI layout and styling
- [ ] Python backend (PySide6) exposes a `FFmpegBackend` QObject to QML
- [ ] Worker thread uses `QThread` + `Signal` (PySide6 equivalent)
- [ ] Report text area is a QML `TextArea` or `ScrollView > TextArea`
- [ ] File dialogs via `QFileDialog` from Python backend (or QML `FileDialog`)
- [ ] Progress bar: QML `ProgressBar` in indeterminate mode during processing
- [ ] Error library (noise filter) is a plain Python class — reuse the concept

### Proposed Module Structure
```
mediaverse/
  modules/
    ffmpeg/
      FFmpegModule.qml         # Main QML view for the FFMPEG panel
      FFmpegBackend.py         # PySide6 QObject exposed to QML
      FFmpegWorker.py          # QThread worker for running ffmpeg subprocess
      ErrorLibrary.py          # Ignorable-error filter (rewritten clean)
      ffmpeg_config.py         # Configurable paths (ffmpeg, MPC-HC, MediaInfo)
```

### QML Panel Layout (proposed)
```
+-------------------------------------------------------+
|  FFMPEG Utilities                          [progress] |
+-------------------------------------------------------+
|  [Test File] [Test Folder] [Repair] [Convert] [Play] [View Details] |
+-------------------------------------------------------+
|                                                       |
|  Output / Report text area (scrollable)               |
|                                                       |
+-------------------------------------------------------+
```

---

## Open Questions / Decisions Needed

1. **Target folder for Mediaverse project** — does it already exist, or are we creating it?
2. **File dialog** — use Python `QFileDialog` called from backend, or QML `FileDialog`?
3. **Convert formats** — what formats should be offered in the conversion list?
4. **Player** — MPC-HC only, or make the player path configurable via settings?
5. **MediaInfo** — use command-line `MediaInfo.exe` call, or use the `pymediainfo` Python library for richer in-app display?
6. **Report location** — always save `.txt` report next to the source file, or offer a choice?
7. **Test Folder** — should it be recursive (all subfolders) or single folder only?

---

## Progress Log

| Date       | Item                              | Notes |
|------------|-----------------------------------|-------|
| 2026-04-02 | Context file created              | Initial review of music-new source complete |
|            | FFmpegBackend.py                  | |
|            | FFmpegWorker.py                   | |
|            | ErrorLibrary.py                   | |
|            | FFmpegModule.qml                  | |
|            | Test File working                 | |
|            | Test Folder working               | |
|            | Repair working                    | |
|            | Convert working                   | |
|            | Play working                      | |
|            | View Details working              | |

---

## Notes / Decisions Made During Build
_(update this section as we go)_

