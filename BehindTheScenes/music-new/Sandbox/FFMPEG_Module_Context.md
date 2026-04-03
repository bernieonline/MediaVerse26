# Workbench Module — Build Context
_Last updated: 2026-04-02 | Branch: MediaVerseL5_

---

## Progress Log

| Date       | Item                              | Status |
|------------|-----------------------------------|--------|
| 2026-04-02 | Phase 1: UI switching             | ✅ COMPLETE |
| 2026-04-02 | Test File (Button 1)              | ✅ COMPLETE |
| 2026-04-02 | Analyse + AI feedback             | ✅ COMPLETE |
|            | Test Folder (Button 2)            | TODO |
|            | Repair File (Button 3)            | TODO |
|            | Re Format (Button 4)              | TODO |
|            | File Details (Button 5)           | TODO |

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
| `Sandbox/MediaPlayerPy/ffmpeg_backend.py` | FFmpegBackend QObject |
| `Sandbox/MediaPlayerQML/WorkbenchView.qml` | Right-panel report view |
| `Sandbox/MediaPlayerQML/WorkbenchActionButton.qml` | Compact glossy button |

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

## Remaining Buttons — Decisions Made

### Test Folder (Button 2)
- Single folder, non-recursive (user confirmed)
- Slot stub exists in ffmpeg_backend.py — iterate video files, run FFmpegWorker sequentially
- Show per-file progress + cumulative summary

### Repair File (Button 3)
- Command: `ffmpeg -i <input> -c copy <output_stem>_repaired.<ext>`
- Output in same folder as source

### Re Format (Button 4)
- Format list: `["mp4", "mkv", "avi", "mov", "m4v"]`
- Command: `ffmpeg -i <input> -qscale 0 <output>.<ext>`
- Needs format selection UI in WorkbenchView

### File Details (Button 5)
- Command-line `MediaInfo.exe "<file>"` (configurable path)
- Display output in WorkbenchView body area

---

## Known Issues / Watch Points
- ffprobe path resolution: `ffmpeg_exe.replace("ffmpeg", "ffprobe")` is case-sensitive — works for
  `ffmpeg.EXE` at end of path but fragile. Consider `Path(ffmpeg_exe).parent / "ffprobe.exe"` instead.
- `String.repeat()` used in WorkbenchView QML (ES6) — verify on target Qt 5.15 build
- Save button concatenates `headerArea.text + "\n" + bodyArea.text` — header is already reproduced
  in the body after `reportReady`; may need to save bodyArea only

---

## Context Properties
```python
ctx.setContextProperty("ffmpegBackend", ffmpeg_backend)   # added this session
ctx.setContextProperty("aiController",  ai_controller)     # pre-existing, reused
```

## Original Source Reference (music-new — DO NOT COPY)
- `music-new/srcMovie/ffmpegFunc.py` — original worker logic
- `music-new/srcMovie/errorLibrary.py` — original noise filter list
