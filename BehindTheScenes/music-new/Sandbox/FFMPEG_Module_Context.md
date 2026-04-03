# Workbench Module — Build Context
_Last updated: 2026-04-03 | Branch: MediaVerseL5_

---

## Progress Log

| Date       | Item                              | Status |
|------------|-----------------------------------|--------|
| 2026-04-02 | Phase 1: UI switching             | ✅ COMPLETE |
| 2026-04-02 | Test File (Button 1)              | ✅ COMPLETE |
| 2026-04-02 | Analyse + AI feedback             | ✅ COMPLETE |
| 2026-04-03 | Compare Files (Button 2)          | ✅ COMPLETE |
| 2026-04-03 | Repair File (Button 3)            | ✅ COMPLETE |
| 2026-04-03 | Video Proc (Button 7)             | ✅ COMPLETE |
|            | Re Format (Button 4)              | TODO |
|            | Test Folder (Button 5)            | TODO |
| 2026-04-03 | File Details (Button 6)           | ✅ COMPLETE |

---

## Phase 1 — UI Switching (COMPLETE)

- `SlidePanel.qml` — scissors → Workbench (green `#39FF14`); spare slot → MediaVerse (⬡ `#2566c2`)
- `WorkButtons.qml` — new button row, neon green, 6 buttons with signals
- `Framework-1.qml`:
  - `RowButton { id: rowButtons }` replaced with `Loader { id: buttonLoader; source: "RowButton.qml" }`
  - Two separate Connections blocks (RowButton / WorkButtons) — guarded by `indexOf` to avoid signal mismatch warnings
  - SlidePanel `onWorkbenchClicked` / `onMediaverseClicked` swap `buttonLoader.source`
  - `contentContainer` radius set to `0` (square corners for all modules)
  - `workbenchMode` property added (shared with WorkbenchView mode toggle)

---

## Phase 2 — Test File Workflow (COMPLETE)

### Files Created
| File | Purpose |
|------|---------|
| `Sandbox/MediaPlayerPy/error_library.py` | Noise filter + severity classifier |
| `Sandbox/MediaPlayerPy/ffmpeg_worker.py` | QThread — ffprobe then ffmpeg, real % progress |
| `Sandbox/MediaPlayerPy/ffmpeg_backend.py` | FFmpegBackend QObject — all workbench Python logic |
| `Sandbox/MediaPlayerQML/WorkbenchView.qml` | Right-panel report view |
| `Sandbox/MediaPlayerQML/WorkbenchActionButton.qml` | Compact glossy button component |

### Modified Files
- `Framework.py` — imports FFmpegBackend, registers `ffmpegBackend` context property
- `Framework-1.qml` — wires TestFile/TestFolder buttons; forwards `ffmpegAskAI` to `aiController`

### Test File Flow
1. Click Test File → `contentLoader.setSource("WorkbenchView.qml")` then `ffmpegBackend.testFile(mode)`
2. `checkFFmpeg()` — checks `shutil.which("ffmpeg")` + local `tools/ffmpeg/ffmpeg.exe`
3. If missing → `ffmpegMissing` → install dialog in WorkbenchView
4. `QFileDialog` opens (native Windows picker, video files filter)
5. ffprobe gets duration → real % progress; falls back to pulsing bar if absent
6. Panel slides in immediately on `statusMessage("Running test…")`
7. Report auto-header: filename, size, duration, date, mode
8. Body editable — user adds notes
9. Save → `<stem>_ffmpeg.txt` written next to source file → panel closes

### Test Commands
- **Standard**: `ffmpeg -v error -nostdin -i <file> -map 0 -f null -`
- **Thorough**: adds `-err_detect +careful`
- **Progress**: `-progress pipe:1 -nostats` — parse `out_time` vs ffprobe duration

### FFMPEG Install / Download
- Download URL: `https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip`
- Extracts to `project_root / "tools" / "ffmpeg" / "ffmpeg.exe"`

---

## Analyse Workflow (COMPLETE)

### Flow
1. Click Analyse → `ffmpegBackend.analyseReport(filename, error_text)`
2. `classify_errors()` runs locally (instant) → `analysisDone(verdict, summary)` emitted
3. Summary appended to bodyArea below `─── Analysis ───` divider
4. If major/critical → `ffmpegAskAI(filename, prompt)` emitted
5. Framework-1.qml Connections forwards to `aiController.ask(filename, prompt)`
6. WorkbenchView `aiController.onAnswerReady` replaces "Asking AI…" with response
7. Full report (errors + analysis + AI) saved by Save button

### Severity Classifier (`error_library.classify_errors`)
| Tier | Examples | Count adjustment |
|------|----------|-----------------|
| Critical | moov atom not found, invalid data, truncation | Always critical |
| Major | missing reference picture, concealing, no picture | < 5 → minor; > 100 → critical |
| Minor | timestamp issues, bitrate anomalies | Always minor |

Returns `(verdict, summary)` — verdict: `"none"` / `"minor"` / `"major"` / `"critical"`

### AI Integration
- Reuses `aiController` (Gemini, same as Detail_View_v2)
- `ffmpegBackend.ffmpegAskAI` signal forwarded in Framework-1.qml
- Only called for major/critical — no API cost for clean files
- Prompt includes: filename, error list, asks for cause / playback impact / repair advice

---

## Phase 3 — Compare Files (COMPLETE)

### Important Design Note
VMAF was considered and rejected — it requires matching resolution and framerate, making it
unsuitable for comparing two versions of the same movie (e.g. `.mkv` vs `.m2ts`).
The implemented approach uses ffprobe metadata only: no decoding, completes in seconds,
works regardless of resolution or framerate differences.

### Files Created
| File | Purpose |
|------|---------|
| `Sandbox/MediaPlayerQML/CompareView.qml` | Dual-score comparison panel with info overlay |

### Files Modified
- `WorkButtons.qml` — added `compareFilesClicked` signal + "Compare / Files" button (position 2)
- `ffmpeg_backend.py` — added `compareReady(str,str,float,float)`, `compareFiles()`, `_do_compare()`; module-level helpers `_probe_file()`, `_quality_score()`, `_format_comparison()`
- `Framework-1.qml` — wired `onCompareFilesClicked` → load `CompareView.qml` + call `compareFiles()`

### Compare Flow
1. Click Compare Files → two file dialogs open (File A, then File B)
2. `ffprobe` reads both files (JSON output, no decoding) — ~2 seconds total
3. `_quality_score()` calculates 0–100 score for each file
4. `compareReady(header, body, scoreA, scoreB)` emitted
5. Panel slides in — side-by-side score tiles, winner highlighted at full brightness, loser dimmed

### Quality Score Breakdown (max 100)
| Factor | Max | Scoring logic |
|--------|-----|---------------|
| Video Codec | 25 | HEVC/AV1=25, VP9=21, H.264=17, MPEG-2/VC-1=9 |
| Resolution | 30 | 4K=30, 1080p=22, 720p=14, 576p=8 |
| Video Bitrate | 30 | Log scale — 80 Mbps = full 30 pts |
| Audio | 15 | TrueHD/PCM=15, DTS/AC3=10, AAC=7, MP3=4 |

- Video bitrate fallback: if stream `bit_rate` is 0 (e.g. M2TS container), estimated as `overall_bitrate − audio_bitrate`
- ffprobe path uses `Path(ffmpeg_exe).parent / "ffprobe.exe"` throughout (not fragile string replace)

### Score Colour Bands
| Range | Colour | Label |
|-------|--------|-------|
| 80–100 | `#39FF14` neon green | Excellent |
| 60–79  | `#FFB300` amber | Good |
| 40–59  | `#FF6600` orange | Fair |
| 0–39   | `#FF3333` red | Poor |

### Body — formatted comparison table
Side-by-side spec table: Resolution, Codec, Framerate, Video Bitrate, Audio Codec,
Audio Bitrate, Channels, Duration, File Size, Quality Score.
Winner column marked with `◄ A` or `◄ B`. Verdict + gap interpretation appended below.

### `i` Info Overlay
Explains: ffprobe-based approach (no decoding), four scoring factors, score colour bands,
how to interpret a gap (< 5 pts marginal, 5–15 moderate, > 15 significant).

---

## Phase 4 — Repair File (COMPLETE)

### Design Rationale
Two distinct repair strategies are offered, selectable before the file dialog opens.
The user chooses mode first (with guidance from the `i` overlay), then clicks Start Repair.

### Files Created
| File | Purpose |
|------|---------|
| `Sandbox/MediaPlayerQML/RepairView.qml` | Repair panel — mode toggle, progress, result, info overlay |

### Files Modified
- `ffmpeg_backend.py` — added `repairReady(str,str)`, `repairProgress(int)`, `repairFile(mode)`, `_do_repair()`, `_finish_repair()`, `cancelRepair()`, `_get_duration_secs()` helper
- `Framework-1.qml` — wired `onRepairFileClicked` → load `RepairView.qml` + `checkFFmpeg()`

### Repair Flow
1. Click Repair File → `RepairView.qml` loads (panel immediately visible — user chooses mode first)
2. User optionally reads `i` overlay, selects Remux or Transcode, clicks Start Repair
3. File dialog opens; repair runs in background thread
4. Progress: pulsing bar for remux (seconds); real % parsed from `-progress pipe:1` for transcode
5. `repairReady(header, body)` emitted on completion
6. Result shows source name, mode, output filename, folder, file size
7. Save Log / New Repair / Cancel buttons appear contextually

### Remux Mode
- Command: `ffmpeg -y -i <input> -c copy <stem>_repair<original_ext>`
- Lossless — no frame decoded or re-encoded
- Fixes: broken container index, wrong timestamps, sync drift, truncated headers
- Does NOT fix: corrupted frame data, missing reference frames

### Transcode Mode
- Command: `ffmpeg -y -i <input> -c:v libx264 -crf 18 -preset medium -c:a copy -progress pipe:1 -nostats <stem>_repair.mkv`
- Re-encodes every frame; corrupted frames replaced by encoder reconstruction
- Audio copied unchanged; output always `.mkv`
- Fixes: corrupted frame data and anything remux cannot resolve

### Output Naming
| Mode | Output filename |
|------|----------------|
| Remux | `<stem>_repair<original extension>` |
| Transcode | `<stem>_repair.mkv` |

Both written to the same folder as the source file.

### Recommended Workflow
1. Run **Test File** to identify error type
2. Try **Remux** first — instant, lossless
3. Run **Test File** again on the repaired output
4. If errors persist → run **Transcode**

---

## Re Format (Button 4) — Decisions Pending

### Context
Re Format is for deliberately changing a file's container or codec — distinct from repair.
User selects a target format; ffmpeg transcodes. Discussion needed on:
- Format list: `mp4`, `mkv`, `avi`, `mov`, `m4v` (confirmed candidates)
- Codec choice per format (copy streams where possible vs force re-encode)
- Quality setting for re-encode (CRF or bitrate target)
- Whether to offer resolution scaling as part of reformat

---

## Video Proc (Button 7) — COMPLETE

### Decision
Trimming TV recordings will be done in VideoProc, not in the Workbench.
VideoProc's visual scrubber (Lossless Cut mode) is better suited than timecode entry.
The Workbench VideoProc button launches the configured executable directly.
Path configured under `ToolPaths.VideoProc` in Config.json, browseable via Settings → Tools tab.

### Trim use case — VideoProc preferred over ffmpeg because:
- Visual timeline scrubber — no need to find timecodes in a separate player first
- Lossless Cut mode = stream copy, same quality as ffmpeg `-c copy`
- Keyframe snap limitation is identical in both tools
- Batch trimming not required — always single file

---

## Remaining Buttons

### Test Folder (Button 5)
- Single folder, non-recursive (user confirmed)
- Slot stub exists in `ffmpeg_backend.py` — iterate video files, run FFmpegWorker sequentially
- Show per-file progress + cumulative summary

### File Details (Button 6) — COMPLETE
- ffprobe JSON → formatted text report (not MediaInfo — no extra tool required)
- Sections: Container, Video (per stream), Audio (per stream), Subtitles, Chapters
- `FileDetailsView.qml` — slide-in panel, scrollable Consolas body, Save + New File buttons
- Save writes `<stem>_details.txt` next to the source file
- Signal: `fileDetailsReady(str, str)` / Slots: `fileDetails()`, `saveDetails(text)`

---

## Known Issues / Watch Points
- `String.repeat()` used in WorkbenchView QML (ES6) — verify on target Qt 5.15 build
- Save button in WorkbenchView concatenates `headerArea.text + "\n" + bodyArea.text` — header
  may be reproduced in the body after `reportReady`; may need to save `bodyArea` only
- Test File result showed clean file with errors and inferior file with none — confirmed expected:
  ffmpeg error reporting reflects container/stream integrity, not perceptual quality.
  Compare Files (ffprobe scoring) is the correct tool for quality comparison.

---

## ffmpeg_backend.py — Signal Reference

```python
# Test / report
reportReady      = Signal(str, str)          # (header, body)
progressChanged  = Signal(int)               # 0–100
statusMessage    = Signal(str)               # status bar text
testError        = Signal(str)               # error string

# Analysis
analysisDone     = Signal(str, str)          # (verdict, summary)
ffmpegAskAI      = Signal(str, str)          # (filename, prompt) → forwarded to aiController

# Install / download
ffmpegMissing    = Signal()
downloadProgress = Signal(int)               # 0–100
downloadComplete = Signal()
downloadFailed   = Signal(str)

# Compare
compareReady     = Signal(str, str, float, float)  # (header, body, scoreA, scoreB)

# Repair
repairReady      = Signal(str, str)          # (header, body)
repairProgress   = Signal(int)               # 0–100
```

## QML Views — Summary

| View | Loaded by | Panel |
|------|-----------|-------|
| `WorkbenchView.qml` | Test File button | Right 38%, slides in on test start |
| `CompareView.qml` | Compare Files button | Right 38%, slides in on result |
| `RepairView.qml` | Repair File button | Right 38%, always visible (mode selection first) |

## Context Properties
```python
ctx.setContextProperty("ffmpegBackend", ffmpeg_backend)   # added session 1
ctx.setContextProperty("aiController",  ai_controller)     # pre-existing, reused
```

## Original Source Reference (music-new — DO NOT COPY)
- `music-new/srcMovie/ffmpegFunc.py` — original worker logic
- `music-new/srcMovie/errorLibrary.py` — original noise filter list
