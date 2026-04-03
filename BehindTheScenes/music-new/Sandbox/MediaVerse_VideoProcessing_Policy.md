# MediaVerse — Video Processing Policy
_Version 1.0 | April 2026_

---

## Purpose

This document defines the rules, workflows and quality expectations for processing video
files within the MediaVerse Workbench module. It covers file testing, comparison, repair,
conversion and AI upscaling, with specific guidance for each source type in the library.

---

## 1. Guiding Principles

**1.1** — Always work on a copy. Never process the original source file destructively.
The original DVD, Blu-ray disc or source rip is the master and must be preserved.

**1.2** — Process in sequence. Each stage produces the best possible input for the next.
Skipping stages (e.g. upscaling a file with unfixed artefacts) magnifies problems
rather than resolving them.

**1.3** — Understand the ceiling. Processing cannot recover detail that was never captured.
A DVD upscaled with AI is still a DVD source — it will look better but will never
match a native HD master. Manage expectations accordingly.

**1.4** — Container format does not equal quality. Changing a file from `.avi` to `.mkv`
or from `.mp4` to `.m2ts` changes nothing visible. What matters is the codec,
bitrate, resolution and the integrity of the encoded frames.

**1.5** — Upscaling resolution in software without a neural network achieves nothing.
A DVD rip re-encoded at 1080p by a conventional media program is still DVD-quality
content — the extra pixels were interpolated, not real. Do not confuse file
resolution with source quality.

---

## 2. The Processing Pipeline

The correct sequence for any file is:

```
1. TEST          Identify what problems exist, if any
2. COMPARE       If two versions exist, determine which is technically superior
3. REPAIR        Fix container and stream issues on the chosen file
4. CONVERT       Prepare a clean encode optimised for the output display
5. AI UPSCALE    Apply neural network upscaling (VideoProc) where worthwhile
```

Never proceed to a later stage if an earlier stage reveals a blocking problem.
Always re-test after repair before converting.

---

## 3. Test File — Rules

**3.1** — Run Test File on every file before any other processing.

**3.2** — Use Standard mode for a quick health check. Use Thorough mode when Standard
reports errors, or for files that will be processed through VideoProc.

**3.3** — Interpreting results:

| ffmpeg reports | What it means | Action |
|---------------|---------------|--------|
| No errors | Container and stream are clean | Proceed to Compare or Convert |
| Timestamp / sync errors | Container problem, frames likely fine | Repair → Remux |
| Missing reference frames | Frame data is damaged | Repair → Transcode |
| moov atom / index error | Container is broken | Repair → Remux first |
| Truncated file | Incomplete recording or copy | Repair → Remux, accept partial loss |

**3.4** — A clean Test File result does not guarantee good visual quality.
ffmpeg measures technical integrity, not perceptual quality. Use Compare Files
for a quality assessment between two versions.

**3.5** — A file showing errors is not necessarily unwatchable. Modern players
(JRiver, VLC, MPC-BE) have error concealment that handles many issues silently.
The test identifies risk, not necessarily a current playback problem.

---

## 4. Compare Files — Rules

**4.1** — When two versions of the same title exist, always use Compare Files before
deciding which to keep or process further.

**4.2** — The Compare tool uses ffprobe metadata only. It reads both files in seconds
and works regardless of resolution or framerate differences between them.

**4.3** — Quality Score breakdown (max 100 points):

| Factor | Weight | What it rewards |
|--------|--------|----------------|
| Video Codec | 25 pts | HEVC / AV1 over H.264 over MPEG-2 |
| Resolution | 30 pts | 4K > 1080p > 720p > 576p |
| Video Bitrate | 30 pts | More bits per second = more preserved detail |
| Audio Quality | 15 pts | Lossless (TrueHD, DTS-MA) > Dolby/DTS > AAC > MP3 |

**4.4** — Score gap interpretation:

| Gap | Meaning |
|-----|---------|
| Under 5 points | Marginal — either file is suitable |
| 5 to 15 points | Moderate advantage — the higher-scoring file is noticeably superior |
| Over 15 points | Significant — always choose the higher-scoring file |

**4.5** — The Compare score is a technical measure, not a guarantee of visual preference.
A file with a higher score may still have worse visible quality if its frames are
damaged. Always cross-reference with Test File results.

**4.6** — VMAF (pixel-level comparison) is not used. It requires matching resolution
and framerate and is inappropriate for comparing different versions of the same title.

---

## 5. Repair File — Rules

**5.1** — Always attempt Remux before Transcode. Remux is lossless and takes seconds.
Only escalate to Transcode if Test File still reports errors after remuxing.

**5.2** — Remux (lossless stream copy):

- Rebuilds the container without touching any video or audio frame
- Output is bit-for-bit identical quality to the source
- Fixes: broken index, wrong timestamps, sync drift, truncated headers
- Does NOT fix: corrupted frame data, missing reference frames, damaged audio
- Output: `<filename>_repair<original extension>`

**5.3** — Transcode (full re-encode):

- Every frame is decoded and re-encoded as H.264 (CRF 18, high quality)
- Corrupted frames are replaced by the encoder's best reconstruction
- Audio is copied unchanged — no quality loss on audio
- A small re-encode quality penalty applies — the output is excellent but not lossless
- Output: `<filename>_repair.mkv`
- Use only when Remux does not resolve the errors

**5.4** — After any repair, re-run Test File on the repaired output before proceeding.

**5.5** — Do not delete the original file until the repaired version has been tested
and visually verified.

---

## 6. Convert — Rules and Source Guidance

The Convert module serves three distinct purposes. Select the appropriate workflow
for the source type.

### 6.1 — Crop Black Bars

**When to use:** Any file (from any source) that does not fill the display, has
letterbox bars (top/bottom) or pillarbox bars (sides) baked into the video frame.

**Process:**
1. ffmpeg `cropdetect` samples the file and identifies the exact crop values
2. Crop is applied and the file is re-encoded at CRF 18 H.264
3. Result fills the display without stretching or distorting aspect ratio

**Rule:** Never stretch to fill. Always crop. Stretching distorts faces and shapes.
If the content is genuinely 4:3, pillarbox bars are correct and should be left alone
unless display filling is specifically required.

---

### 6.2 — DVD Folder → MKV

**When to use:** Original DVD disc rips in `VIDEO_TS` folder format containing
`.VOB`, `.IFO` and `.BUP` files.

**Source characteristics:**
- MPEG-2 video, 720×576 (PAL) or 720×480 (NTSC)
- Always interlaced — this is the most important issue to resolve
- AC3 audio, usually 192kbps stereo or 5.1
- Menu structure and multiple titles in IFO files

**Process:**
1. Identify main title VOB chain (largest sequential set)
2. Apply `yadif` deinterlace — **mandatory**, interlacing is severe on large displays
3. Apply `cropdetect` — DVD authoring often includes slight overscan borders
4. Encode H.264 CRF 18 at native 576p resolution — do not upscale in ffmpeg
5. Copy audio unchanged
6. Output: single clean `.mkv`

**Rule:** Always deinterlace. Never skip this step for DVD content.
Always output at native resolution — upscaling is VideoProc's job, not ffmpeg's.

**Limitation:** Heavily multi-angle or poorly authored DVDs may not parse correctly.
For these, HandBrake provides more reliable DVD navigation handling.

---

### 6.3 — Blu-ray Folder → MKV

**When to use:** Blu-ray disc rips in `BDMV` folder format.

**Source characteristics:**
- H.264 or HEVC video, typically 1080p or 4K — already high quality
- Audio: TrueHD, DTS-MA, DTS, AC3 — often lossless
- Main feature is almost always the largest `.m2ts` file in `BDMV/STREAM/`

**Process:**
1. Identify main feature by largest `.m2ts` file size
2. **Remux to MKV** — lossless, no re-encode required, takes seconds
3. Preserves TrueHD / DTS-MA audio intact

**Rule:** Do not re-encode Blu-ray content. The source is already high quality H.264
or HEVC — remuxing to MKV is all that is needed for clean playback.
Only transcode if storage capacity is a specific constraint.

---

## 7. AI Upscaling (VideoProc) — Rules

**7.1** — AI upscaling is the final stage. Never apply it to a file that has not been
tested, repaired if necessary, and converted to a clean encode.

**7.2** — A clean file fed to VideoProc produces dramatically better results than
processing a raw rip with artefacts. The neural network sharpens what it finds —
including macroblocking and noise if those are present.

**7.3** — VideoProc benefit by source type:

| Source | Upscale benefit | Notes |
|--------|----------------|-------|
| Original DVD rip (native 576p, deinterlaced) | High | Best use case — clean analogue master, strong model training match |
| Pre-2000 analogue Sky capture (clean) | High | Organic noise responds well to neural reconstruction |
| 720p conventional upscale from DVD | Moderate | Model has good source to work with |
| 1080p conventional upscale from DVD | Low–Moderate | Source detail ceiling is still the original DVD |
| Digital Sky broadcast (post-2002) | Low–Moderate | MPEG-2 broadcast compression limits the ceiling |
| Good native 1080p H.264 | Low | Source is already near the display quality ceiling |
| Native 4K | None | No benefit |

**7.4** — For files that were previously upscaled to 1080p using conventional (non-AI)
software: if the original DVD or source rip is still available, always process from
the original rather than the upscaled version. The neural network works better
from original pixels than from previously interpolated ones.

**7.5** — After VideoProc processing, run Compare Files between the VideoProc output
and the pre-upscale Convert output to verify the score has improved and the
processing has not introduced artefacts.

---

## 8. Source-Specific Pipelines

### 8.1 — Original DVD (disc available)

```
Rip disc → DVD → MKV (deinterlace + crop) → VideoProc upscale → Test result
```

This is the gold standard pipeline. Working from the disc gives the cleanest
possible input at every stage.

---

### 8.2 — Existing DVD Rip (good quality, no errors)

```
Test File → Compare (if multiple versions) → DVD → MKV → VideoProc
```

---

### 8.3 — Existing DVD Rip (errors present)

```
Test File → Repair (Remux first, Transcode if needed) → Test again → DVD → MKV → VideoProc
```

---

### 8.4 — Previously Upscaled DVD (720p, no original rip)

```
Test File → Repair if needed → VideoProc (720p → 4K)
```

Do not re-process through DVD → MKV workflow. The file is not a DVD structure.

---

### 8.5 — Previously Upscaled DVD (1080p, no original rip)

```
Test File → Repair if needed → Compare against any other available version
→ VideoProc only if source quality justifies the processing time
```

Be realistic about the ceiling. If the original disc is available, re-rip instead.

---

### 8.6 — Blu-ray Folder

```
Blu-ray → MKV (remux) → Test result → store
```

VideoProc is not needed for native 1080p or 4K Blu-ray content.

---

### 8.7 — Pre-2000 Analogue Sky Recordings

```
Test File → Repair (Remux for container issues, common in .ts rips)
→ Convert (yadif deinterlace + light noise filter + crop) → VideoProc
```

These files are irreplaceable. Apply the most careful pipeline.
Assess the visual quality of the Convert output before committing to VideoProc —
some captures will be too degraded to justify the processing time.

**Noise filter note:** Apply a light `hqdn3d` noise filter during Convert for these
files. Analogue capture noise and MPEG-2 mosquito noise, if left in, will be
sharpened rather than removed by the neural upscaler.

---

### 8.8 — Digital Sky Recordings (post-2002, MPEG-2 .ts files)

```
Test File → Repair → Convert (yadif + crop + light noise filter) → VideoProc (optional)
```

Manage expectations. MPEG-2 broadcast compression is the limiting factor.
VideoProc will improve these but the ceiling is lower than DVD source content.

---

## 9. What Reformatting Cannot Achieve

The following are common misconceptions that this policy explicitly rejects:

| Belief | Reality |
|--------|---------|
| Changing container improves quality | False — container is a wrapper, not quality |
| Upscaling resolution adds detail | False — interpolation invents pixels, it does not recover them |
| Higher file size means better quality | Not necessarily — inefficient encoding wastes space |
| Re-encoding at a higher bitrate improves a poor source | False — re-encoding can only preserve or reduce quality, never add it |
| AI upscaling recovers lost detail | Partially true — it reconstructs plausible detail, it does not recover what was never captured |

---

## 10. Storage Decisions

**10.1** — After a successful full pipeline (Test → Repair → Convert → VideoProc),
keep both the repaired source MKV and the VideoProc output until the VideoProc
result has been watched and verified. Then archive or delete the intermediate files.

**10.2** — Original disc rips should be retained regardless of processing status.
They are the master copies and the starting point if any stage needs to be repeated.

**10.3** — Repair outputs (`_repair` files) are working files. Once the repaired
file has been converted and verified, the repair intermediate can be removed.

---

_This document will be updated as the MediaVerse Workbench module develops._
_Current module status: Test File, Compare Files and Repair File are operational._
_Convert module and Re Format button are in design._
