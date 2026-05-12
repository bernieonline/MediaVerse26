#!/usr/bin/env python3
"""
Video Quality Audit
===================
Scans a directory of video files and generates an HTML report identifying
files that may have been degraded through re-encoding, frame interpolation,
excessive compression, or audio downgrade.

Uses MediaInfo CLI (JSON output) for metadata extraction.

Usage:
    python video_quality_audit.py [directory] [--threshold N] [--output report.html] [--no-open]

Examples:
    python video_quality_audit.py
    python video_quality_audit.py "W:\\Collection" --threshold 30
    python video_quality_audit.py "D:\\Films" -t 20 -o audit.html --no-open
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import webbrowser
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from pathlib import Path

# ------------------------------------------------------------------------------
# Configuration -- edit these defaults to suit your setup
# ------------------------------------------------------------------------------

MEDIAINFO_EXE       = r"C:\Program Files\MediaInfo\MediaInfo.exe"
DEFAULT_SCAN_DIR    = r"W:\Collection"
DEFAULT_THRESHOLD   = 25          # minimum score to flag a file
DEFAULT_OUTPUT      = "video_quality_audit.html"
MAX_WORKERS         = 6           # parallel MediaInfo processes

VIDEO_EXTENSIONS = {".mkv", ".mp4", ".avi", ".m2ts", ".ts", ".mov", ".wmv"}

# Bitrate thresholds (Mbps) -- codec-aware, since HEVC is ~2× more efficient
BITRATE_THRESHOLDS = {
    "AVC":     {"low": 10.0, "very_low": 6.0},
    "HEVC":    {"low":  6.0, "very_low": 3.5},
    "default": {"low": 10.0, "very_low": 6.0},
}

# CRF thresholds -- higher CRF = more lossy
CRF_THRESHOLDS = {
    "AVC":     20,   # x264 CRF >= 20 is notably lossy for 1080p
    "HEVC":    24,   # x265 CRF >= 24 is notably lossy for 1080p
    "default": 20,
}

# bits per pixel per frame: bpppf = bitrate_bps / (width × height × fps)
# A genuine Blu-ray at 25 Mbps / 1080p@24fps  0.50; good encode  0.30
BPPPF_LOW      = 0.12   # flag below this
BPPPF_VERY_LOW = 0.08   # flag more severely below this

# Standard cinema frame rates (fps) -- multiplied to detect interpolation
CINEMA_RATES = {23.976, 24.0, 25.0, 29.97}

# Audio codecs considered lossless
LOSSLESS_AUDIO_FORMATS = {"TrueHD", "DTS-HD MA", "DTS-HD", "FLAC", "PCM"}

# Audio codecs considered poor quality
POOR_AUDIO_FORMATS = {"AAC", "AC-3", "MP3", "MP2", "WMA"}

# ------------------------------------------------------------------------------
# MediaInfo extraction
# ------------------------------------------------------------------------------

def get_mediainfo(filepath: Path) -> dict | None:
    """Run MediaInfo CLI and return parsed JSON, or None on failure."""
    try:
        si = subprocess.STARTUPINFO()
        si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        si.wShowWindow = 0  # SW_HIDE
        result = subprocess.run(
            [MEDIAINFO_EXE, "--Output=JSON", str(filepath)],
            capture_output=True,
            text=True,
            timeout=45,
            encoding="utf-8",
            errors="replace",
            startupinfo=si,
        )
        if result.returncode != 0 or not result.stdout.strip():
            return None
        return json.loads(result.stdout)
    except (subprocess.TimeoutExpired, json.JSONDecodeError, OSError):
        return None


def _first_track(mi_data: dict, track_type: str) -> dict:
    """Return the first MediaInfo track of the given type, or empty dict."""
    for track in mi_data.get("media", {}).get("track", []):
        if track.get("@type") == track_type:
            return track
    return {}


def _all_tracks(mi_data: dict, track_type: str) -> list[dict]:
    """Return all MediaInfo tracks of the given type."""
    return [t for t in mi_data.get("media", {}).get("track", [])
            if t.get("@type") == track_type]


def _float(val, default: float = 0.0) -> float:
    try:
        return float(val)
    except (TypeError, ValueError):
        return default


def _int(val, default: int = 0) -> int:
    try:
        return int(val)
    except (TypeError, ValueError):
        return default


def _extract_crf(settings_str: str) -> float | None:
    """Parse CRF value from MediaInfo Encoded_Library_Settings string."""
    if not settings_str:
        return None
    for part in settings_str.split("/"):
        part = part.strip()
        if part.lower().startswith("crf="):
            try:
                return float(part.split("=", 1)[1])
            except (ValueError, IndexError):
                pass
    return None


def extract_info(filepath: Path, mi_data: dict) -> dict:
    """Flatten MediaInfo JSON into a dict of properties we care about."""
    gen   = _first_track(mi_data, "General")
    video = _first_track(mi_data, "Video")
    audio_tracks = _all_tracks(mi_data, "Audio")
    audio = audio_tracks[0] if audio_tracks else {}

    # -- Video --
    width   = _int(video.get("Width"))
    height  = _int(video.get("Height"))
    fps     = _float(video.get("FrameRate"))
    # FrameRate_Original is preserved by some muxers when the stream was
    # re-timed (e.g. IVTC or frame interpolation); its presence is a strong signal
    fps_original = _float(video.get("FrameRate_Original"))
    codec   = video.get("Format", "").strip()           # "AVC", "HEVC", etc.
    codec_profile = video.get("Format_Profile", "").strip()
    lib     = video.get("Encoded_Library", "").strip()  # e.g. "x264 core 164"
    lib_settings = video.get("Encoded_Library_Settings", "").strip()
    writing_app  = gen.get("Encoded_Application", "").strip()  # e.g. "HandBrake 1.6"
    scan_type    = video.get("ScanType", "").strip()    # "Progressive" / "Interlaced"
    bit_depth    = _int(video.get("BitDepth"), 8)
    colour_space = video.get("ColorSpace", "").strip()

    # -- Bitrates --
    # Prefer video-stream bitrate; fall back to overall
    bit_v   = _float(video.get("BitRate"))      # bits/s
    bit_gen = _float(gen.get("OverallBitRate")) # bits/s
    bitrate_bps  = bit_v if bit_v else bit_gen
    bitrate_mbps = bitrate_bps / 1_000_000

    # -- Duration & file size --
    duration_s      = _float(gen.get("Duration"))
    file_size_bytes = _int(gen.get("FileSize"))
    file_size_gb    = file_size_bytes / (1024 ** 3)

    # -- bpppf --
    bpppf = 0.0
    if width and height and fps:
        bpppf = bitrate_bps / (width * height * fps)

    # -- Audio --
    audio_format      = audio.get("Format", "").strip()
    audio_format_comm = audio.get("Format_Commercial_IfAny", "").strip()
    audio_bitrate_bps = _float(audio.get("BitRate"))
    audio_channels    = _int(audio.get("Channels"))

    # Prefer commercial name (e.g. "DTS-HD Master Audio") over raw format
    audio_display = audio_format_comm if audio_format_comm else audio_format

    # Collect all audio track formats for multi-track files
    all_audio_formats = [
        t.get("Format_Commercial_IfAny") or t.get("Format", "")
        for t in audio_tracks
    ]

    # -- CRF --
    crf = _extract_crf(lib_settings)

    return {
        "path":              filepath,
        "width":             width,
        "height":            height,
        "resolution":        f"{width}×{height}" if width else "unknown",
        "fps":               fps,
        "fps_original":      fps_original,
        "codec":             codec,
        "codec_profile":     codec_profile,
        "bitrate_mbps":      bitrate_mbps,
        "bpppf":             bpppf,
        "lib":               lib,
        "lib_settings":      lib_settings,
        "writing_app":       writing_app,
        "crf":               crf,
        "scan_type":         scan_type,
        "bit_depth":         bit_depth,
        "colour_space":      colour_space,
        "audio_format":      audio_display,
        "all_audio_formats": all_audio_formats,
        "audio_bitrate_kbps": audio_bitrate_bps / 1000 if audio_bitrate_bps else 0,
        "audio_channels":    audio_channels,
        "duration_s":        duration_s,
        "file_size_gb":      file_size_gb,
        "file_size_bytes":   file_size_bytes,
    }


# ------------------------------------------------------------------------------
# Scoring
# ------------------------------------------------------------------------------

def _fps_multiplier_check(fps: float) -> tuple[float | None, float | None]:
    """
    Check if fps is an exact ×2 or ×2.5 multiple of a standard cinema rate.
    Returns (cinema_rate, multiplier) or (None, None).
    """
    for cinema_r in CINEMA_RATES:
        for mult in (2.0, 2.5):
            target = cinema_r * mult
            if abs(fps - target) < 0.15:   # tolerance for rounding
                return cinema_r, mult
    return None, None


def score_file(info: dict) -> tuple[int, list[str]]:
    """
    Evaluate a file's metadata and return (total_score, list_of_issue_strings).
    Higher score = more likely to be a degraded file.
    """
    issues: list[str] = []
    score = 0

    fps      = info["fps"]
    fps_orig = info["fps_original"]
    codec    = info["codec"]

    # -- Frame rate / interpolation analysis ----------------------------------

    if fps_orig and abs(fps_orig - fps) > 0.1:
        # MediaInfo preserved the original rate -- this is definitive proof the
        # frame rate was changed after the source was encoded
        ratio = fps / fps_orig if fps_orig else 0
        issues.append(
            f"CONFIRMED FRAME-RATE CHANGE: source was {fps_orig:.3f} fps, "
            f"stream is {fps:.3f} fps (×{ratio:.2f}) -- almost certainly interpolated"
        )
        score += 50

    elif fps > 30:
        # No FrameRate_Original recorded -- check for suspicious multiplier patterns
        cinema_r, mult = _fps_multiplier_check(fps)
        if cinema_r is not None:
            issues.append(
                f"SUSPECTED INTERPOLATION: {fps:.3f} fps is {mult:.1f}× the cinema "
                f"rate {cinema_r} fps -- likely artificially increased"
            )
            score += 30
        else:
            issues.append(
                f"Elevated frame rate: {fps:.3f} fps (above 30 fps for a 1080p film "
                f"is unusual unless action or sports content)"
            )
            score += 12

    # -- Re-encode detection --------------------------------------------------

    if info["lib"]:
        # Presence of an encode library tag means the video stream was created
        # by a software encoder (not a direct disc remux)
        lib_short = info["lib"].split()[0]  # e.g. "x264" from "x264 core 164 ..."
        issues.append(
            f"Re-encoded source: encoded with {lib_short} "
            f"({'quality depends on CRF and bitrate' if info['crf'] is None else ''})"
        )
        score += 20

    if info["writing_app"]:
        # Writing application can reveal HandBrake, FFmpeg, etc.
        app_lower = info["writing_app"].lower()
        if any(tool in app_lower for tool in ("handbrake", "ffmpeg", "avisynth", "vapoursynth")):
            issues.append(f"Written by transcoding tool: {info['writing_app']}")
            score += 10   # additional signal on top of lib detection

    if info["crf"] is not None:
        crf = info["crf"]
        crf_thresh = CRF_THRESHOLDS.get(codec, CRF_THRESHOLDS["default"])
        if crf >= crf_thresh:
            issues.append(
                f"High CRF={crf:.0f} used during encode "
                f"(threshold for {codec}: {crf_thresh} -- above this is noticeably lossy)"
            )
            score += 20
        else:
            issues.append(
                f"CRF={crf:.0f} (below lossy threshold of {crf_thresh} -- "
                f"moderate quality encode)"
            )
            score += 5

    # -- Bitrate analysis -----------------------------------------------------

    bitrate = info["bitrate_mbps"]
    bt = BITRATE_THRESHOLDS.get(codec, BITRATE_THRESHOLDS["default"])

    if bitrate > 0:
        if bitrate < bt["very_low"]:
            issues.append(
                f"Very low bitrate for {codec or 'video'}: {bitrate:.1f} Mbps "
                f"(below {bt['very_low']} Mbps -- significant compression artefacts likely)"
            )
            score += 25
        elif bitrate < bt["low"]:
            issues.append(
                f"Low bitrate for {codec or 'video'}: {bitrate:.1f} Mbps "
                f"(below {bt['low']} Mbps -- quality may be compromised)"
            )
            score += 10

    # -- Bits per pixel per frame ----------------------------------------------
    # This metric is particularly revealing when combined with high frame rate:
    # a file encoded at 8 Mbps / 48 fps has half the detail per frame of the
    # same file at 24 fps, even if the headline bitrate looks acceptable.

    bpppf = info["bpppf"]
    if bpppf > 0:
        if bpppf < BPPPF_VERY_LOW:
            issues.append(
                f"Very low bits/pixel/frame: {bpppf:.4f} "
                f"(below {BPPPF_VERY_LOW} -- little detail encoded per frame; "
                f"a genuine Blu-ray remux is typically >= 0.30)"
            )
            score += 25
        elif bpppf < BPPPF_LOW:
            issues.append(
                f"Low bits/pixel/frame: {bpppf:.4f} "
                f"(below {BPPPF_LOW} -- detail per frame below expected for 1080p)"
            )
            score += 10

    # -- Audio quality ---------------------------------------------------------

    all_formats = " ".join(info["all_audio_formats"]).lower()
    has_lossless = any(la.lower() in all_formats for la in LOSSLESS_AUDIO_FORMATS)
    has_poor     = any(pa.lower() in all_formats for pa in POOR_AUDIO_FORMATS)

    if not has_lossless:
        if has_poor:
            fmt_list = ", ".join(info["all_audio_formats"]) or info["audio_format"]
            issues.append(
                f"Lossy audio only: {fmt_list} -- lossless track (TrueHD, DTS-HD MA, "
                f"FLAC, PCM) absent, suggesting re-encoded or downgraded audio"
            )
            score += 15
        elif info["audio_format"]:
            issues.append(
                f"No lossless audio track: {info['audio_format']} "
                f"(TrueHD / DTS-HD MA / FLAC / PCM absent)"
            )
            score += 8

    # Suspicious: file claims a high-quality audio format but bitrate is very low
    if has_lossless and info["audio_bitrate_kbps"] > 0:
        if info["audio_bitrate_kbps"] < 500:
            issues.append(
                f"Lossless audio format claimed but bitrate suspiciously low: "
                f"{info['audio_bitrate_kbps']:.0f} kbps "
                f"(genuine TrueHD/DTS-HD MA is typically 1500-5000 kbps)"
            )
            score += 15

    # -- File size vs duration cross-check -------------------------------------
    # If the file size doesn't match what you'd expect from the stated bitrate
    # and duration, the metadata may be unreliable or the file is truncated.

    if info["duration_s"] > 60 and info["file_size_bytes"] > 0 and bitrate > 0:
        expected_bytes = (bitrate * 1_000_000 / 8) * info["duration_s"]
        ratio = info["file_size_bytes"] / expected_bytes
        if ratio < 0.65 or ratio > 1.50:
            issues.append(
                f"File size/bitrate mismatch: actual {info['file_size_gb']:.2f} GB "
                f"vs expected ~{expected_bytes / (1024**3):.2f} GB from stated bitrate "
                f"({ratio:.2f}× ratio -- metadata may be unreliable)"
            )
            score += 10

    return score, issues


# ------------------------------------------------------------------------------
# Directory scan
# ------------------------------------------------------------------------------

def is_1080p(info: dict) -> bool:
    """Accept any file where the height is 1080 (allows for cropped widths)."""
    return info["height"] == 1080


def _process_file(filepath: Path) -> dict | None:
    """Process a single file: call MediaInfo, extract info, score. Returns None to skip."""
    mi_data = get_mediainfo(filepath)
    if not mi_data:
        return None

    info = extract_info(filepath, mi_data)

    if not is_1080p(info):
        return None   # only interested in 1080p files

    score, issues = score_file(info)
    info["score"]  = score
    info["issues"] = issues
    return info


def scan_directory(scan_dir: Path) -> tuple[list[dict], int, list[str]]:
    """
    Recursively scan scan_dir for video files.
    Returns (results, total_video_files_found, errors).
    """
    all_files = [
        p for p in scan_dir.rglob("*")
        if p.is_file() and p.suffix.lower() in VIDEO_EXTENSIONS
    ]

    total = len(all_files)
    results: list[dict] = []
    errors:  list[str]  = []
    done = 0

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {executor.submit(_process_file, f): f for f in all_files}
        for future in as_completed(futures):
            done += 1
            print(f"  Processing {done}/{total}...", flush=True)
            try:
                result = future.result()
                if result is not None:
                    results.append(result)
            except Exception as exc:
                errors.append(f"{futures[future]}: {exc}")

    return results, total, errors


# ------------------------------------------------------------------------------
# HTML report
# ------------------------------------------------------------------------------

def _severity_class(score: int) -> str:
    if score >= 60: return "critical"
    if score >= 35: return "high"
    if score >= 20: return "medium"
    return "low"


def _severity_label(score: int) -> str:
    if score >= 60: return "CRITICAL"
    if score >= 35: return "HIGH"
    if score >= 20: return "MEDIUM"
    return "LOW"


def _format_duration(secs: float) -> str:
    if secs <= 0:
        return "--"
    h = int(secs // 3600)
    m = int((secs % 3600) // 60)
    return f"{h}h {m:02d}m" if h else f"{m}m"


def _table_row(r: dict, highlight: bool = False) -> str:
    sc    = _severity_class(r["score"])
    name  = r["path"].name
    path  = str(r["path"])

    fps_cell = f"{r['fps']:.3f}"
    if r["fps_original"] and abs(r["fps_original"] - r["fps"]) > 0.1:
        fps_cell += f'<br><small style="color:#ff4444">orig: {r["fps_original"]:.3f}</small>'

    issues_html = "".join(
        f'<div class="issue-line">{iss}</div>'
        for iss in r["issues"]
    ) if r["issues"] else "--"

    return (
        f'<tr class="row-{sc}{"  top-row" if highlight else ""}">'
        f'<td class="filename" title="{path}">{name}</td>'
        f'<td class="num">{r["resolution"]}</td>'
        f'<td class="num">{r["bitrate_mbps"]:.1f}</td>'
        f'<td class="num">{fps_cell}</td>'
        f'<td>{r["codec"]}</td>'
        f'<td>{r["audio_format"] or "--"}</td>'
        f'<td class="num">{r["file_size_gb"]:.2f}</td>'
        f'<td class="num">{r["bpppf"]:.4f}</td>'
        f'<td class="score-cell score-{sc}">{r["score"]}<br>'
        f'<small>{_severity_label(r["score"])}</small></td>'
        f'<td class="issues-cell">{issues_html}</td>'
        f'</tr>\n'
    )


def generate_html_report(
    results: list[dict],
    total_scanned: int,
    scan_dir: Path,
    threshold: int,
    output_path: Path,
    errors: list[str],
) -> None:
    flagged = sorted(
        [r for r in results if r["score"] >= threshold],
        key=lambda r: r["score"], reverse=True
    )
    top10 = flagged[:10]
    now   = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # Score band counts
    bands = {"critical": 0, "high": 0, "medium": 0, "low_flagged": 0, "clean": 0}
    for r in results:
        if r["score"] >= 60:   bands["critical"]    += 1
        elif r["score"] >= 35: bands["high"]         += 1
        elif r["score"] >= 20: bands["medium"]       += 1
        elif r["score"] >= threshold: bands["low_flagged"] += 1
        else:                  bands["clean"]         += 1

    total_1080p = len(results)

    def pct(n): return f"{100 * n / max(total_1080p, 1):.1f}"

    top10_rows  = "".join(_table_row(r, highlight=True) for r in top10)
    all_rows    = "".join(_table_row(r) for r in flagged)

    errors_section = ""
    if errors:
        err_items = "".join(f"<li>{e}</li>" for e in errors[:50])
        errors_section = f"""
        <h2>Scan Errors ({len(errors)} files)</h2>
        <ul class="error-list">{err_items}</ul>"""

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Video Quality Audit -- {now}</title>
<style>
:root {{
  --bg:        #0d0d0d;
  --surf:      #191919;
  --surf2:     #222;
  --border:    #2e2e2e;
  --text:      #ddd;
  --muted:     #777;
  --critical:  #e84040;
  --high:      #e07820;
  --medium:    #d4b800;
  --low:       #78b840;
  --clean:     #3ea87a;
  --accent:    #2566c2;
}}
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
body {{
  background: var(--bg);
  color: var(--text);
  font-family: 'Segoe UI', system-ui, sans-serif;
  font-size: 14px;
  line-height: 1.5;
  padding: 28px 32px;
}}
a {{ color: var(--accent); }}
h1 {{ font-size: 28px; color: #fff; margin-bottom: 6px; letter-spacing: -.5px; }}
h2 {{
  font-size: 17px; color: #aaa;
  margin: 36px 0 14px;
  padding-bottom: 8px;
  border-bottom: 1px solid var(--border);
  letter-spacing: .03em;
}}
.meta {{ color: var(--muted); font-size: 13px; margin-bottom: 28px; }}
.meta strong {{ color: #ccc; }}

/* -- Summary cards ------------------------------------------------ */
.cards {{
  display: flex; gap: 14px; flex-wrap: wrap; margin-bottom: 24px;
}}
.card {{
  background: var(--surf);
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 16px 22px;
  min-width: 130px;
}}
.card .lbl  {{ font-size: 11px; color: var(--muted); text-transform: uppercase; letter-spacing: .06em; }}
.card .val  {{ font-size: 30px; font-weight: 700; margin-top: 4px; }}
.card.c-total    .val {{ color: #fff; }}
.card.c-critical .val {{ color: var(--critical); }}
.card.c-high     .val {{ color: var(--high); }}
.card.c-medium   .val {{ color: var(--medium); }}
.card.c-clean    .val {{ color: var(--clean); }}

/* -- Score bar ---------------------------------------------------- */
.score-bar {{
  display: flex; height: 20px; border-radius: 6px;
  overflow: hidden; margin-bottom: 30px;
  border: 1px solid var(--border);
}}
.score-bar div {{
  display: flex; align-items: center; justify-content: center;
  font-size: 11px; font-weight: 700; color: #000; min-width: 0;
  transition: width .3s;
}}
.score-bar .seg-clean {{ color: #fff; }}

/* -- Score legend ------------------------------------------------- */
.legend {{
  display: flex; gap: 18px; flex-wrap: wrap;
  margin-bottom: 14px; font-size: 12px; color: var(--muted);
}}
.legend-dot {{
  display: inline-block; width: 10px; height: 10px;
  border-radius: 50%; margin-right: 5px; vertical-align: middle;
}}

/* -- Filter bar --------------------------------------------------- */
.filter-bar {{
  display: flex; gap: 10px; align-items: center; margin-bottom: 12px;
}}
.filter-bar input {{
  background: var(--surf2);
  border: 1px solid var(--border);
  color: var(--text);
  padding: 7px 14px;
  border-radius: 6px;
  font-size: 13px;
  width: 300px;
  outline: none;
}}
.filter-bar input:focus {{ border-color: var(--accent); }}
.filter-bar label {{ color: var(--muted); font-size: 13px; }}
.filter-bar span  {{ color: var(--muted); font-size: 12px; }}

/* -- Tables ------------------------------------------------------- */
.table-wrap {{
  width: 100%; overflow-x: auto;
  border: 1px solid var(--border);
  border-radius: 10px;
  margin-bottom: 32px;
}}
table {{
  width: 100%; border-collapse: collapse;
  background: var(--surf);
}}
thead th {{
  background: var(--surf2);
  color: var(--muted);
  text-transform: uppercase;
  font-size: 11px;
  letter-spacing: .06em;
  padding: 10px 13px;
  text-align: left;
  cursor: pointer;
  user-select: none;
  white-space: nowrap;
  position: sticky; top: 0;
}}
thead th:hover {{ color: var(--text); }}
thead th[data-sort]::after {{ content: " |"; opacity: .35; }}
td {{
  padding: 9px 13px;
  border-top: 1px solid var(--border);
  vertical-align: top;
}}
tr:hover td {{ background: #1e1e1e; }}

/* severity left-border */
.row-critical td:first-child {{ border-left: 4px solid var(--critical); }}
.row-high     td:first-child {{ border-left: 4px solid var(--high); }}
.row-medium   td:first-child {{ border-left: 4px solid var(--medium); }}
.row-low      td:first-child {{ border-left: 4px solid var(--low); }}
.top-row td {{ background: #1d1d1d; }}

.score-cell {{
  font-size: 20px; font-weight: 700;
  text-align: center; white-space: nowrap;
}}
.score-critical {{ color: var(--critical); }}
.score-high     {{ color: var(--high); }}
.score-medium   {{ color: var(--medium); }}
.score-low      {{ color: var(--low); }}

.filename {{
  max-width: 260px; word-break: break-all;
  font-size: 12px; font-family: 'Consolas', monospace;
}}
.num {{ text-align: right; font-variant-numeric: tabular-nums; }}
.issues-cell {{ min-width: 320px; }}
.issue-line {{
  font-size: 12px; line-height: 1.6; color: #bbb;
  padding: 1px 0;
  border-bottom: 1px solid #2a2a2a;
}}
.issue-line:last-child {{ border-bottom: none; }}
small {{ color: var(--muted); font-size: 11px; }}

/* -- Errors ------------------------------------------------------- */
.error-list {{
  font-size: 12px; color: #aa6644; list-style: none;
  background: var(--surf); border: 1px solid var(--border);
  border-radius: 8px; padding: 14px 18px;
}}
.error-list li {{ padding: 2px 0; }}

/* -- Score guide box ---------------------------------------------- */
.guide {{
  background: var(--surf);
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 18px 22px;
  margin-bottom: 28px;
  font-size: 13px;
}}
.guide h3 {{ color: #aaa; margin-bottom: 10px; font-size: 14px; }}
.guide table {{ background: transparent; }}
.guide td {{ border: none; padding: 3px 14px 3px 0; }}
</style>
</head>
<body>

<h1>Video Quality Audit</h1>
<div class="meta">
  Directory: <strong>{scan_dir}</strong> &ensp;|&ensp;
  Run: <strong>{now}</strong> &ensp;|&ensp;
  Score threshold: <strong>{threshold}</strong> &ensp;|&ensp;
  Tool: MediaInfo + Python
</div>

<!-- -- Summary cards -- -->
<div class="cards">
  <div class="card c-total">   <div class="lbl">Files Scanned</div> <div class="val">{total_scanned}</div></div>
  <div class="card c-total">   <div class="lbl">1080p Files</div>   <div class="val">{total_1080p}</div></div>
  <div class="card c-critical"><div class="lbl">Critical >=60</div>  <div class="val">{bands['critical']}</div></div>
  <div class="card c-high">    <div class="lbl">High 35-59</div>    <div class="val">{bands['high']}</div></div>
  <div class="card c-medium">  <div class="lbl">Medium 20-34</div>  <div class="val">{bands['medium']}</div></div>
  <div class="card c-clean">   <div class="lbl">Clean &lt;{threshold}</div> <div class="val">{bands['clean']}</div></div>
</div>

<!-- -- Distribution bar -- -->
<div class="score-bar">
  <div style="width:{pct(bands['critical'])}%;background:var(--critical)">{bands['critical'] if bands['critical'] else ''}</div>
  <div style="width:{pct(bands['high'])}%;background:var(--high)">{bands['high'] if bands['high'] else ''}</div>
  <div style="width:{pct(bands['medium'])}%;background:var(--medium)">{bands['medium'] if bands['medium'] else ''}</div>
  <div style="width:{pct(bands['low_flagged'])}%;background:var(--low)">{bands['low_flagged'] if bands['low_flagged'] else ''}</div>
  <div class="seg-clean" style="flex:1;background:var(--clean)">{bands['clean'] if bands['clean'] else ''}</div>
</div>

<!-- -- Scoring guide -- -->
<div class="guide">
  <h3>Scoring Guide</h3>
  <table>
    <tr><td><span class="legend-dot" style="background:var(--critical)"></span><strong style="color:var(--critical)">Critical >= 60</strong></td><td>Confirmed interpolation or catastrophic bitrate -- replace immediately</td></tr>
    <tr><td><span class="legend-dot" style="background:var(--high)"></span><strong style="color:var(--high)">High 35-59</strong></td><td>Likely genuinely degraded -- worth re-ripping if disc is available</td></tr>
    <tr><td><span class="legend-dot" style="background:var(--medium)"></span><strong style="color:var(--medium)">Medium 20-34</strong></td><td>One or more real concerns -- investigate before sourcing a replacement</td></tr>
    <tr><td><span class="legend-dot" style="background:var(--low)"></span><strong style="color:var(--low)">Low &lt; 20</strong></td><td>Minor concerns only -- probably acceptable</td></tr>
    <tr><td><span class="legend-dot" style="background:var(--clean)"></span><strong style="color:var(--clean)">Clean</strong></td><td>No significant issues detected at threshold {threshold}</td></tr>
  </table>
</div>

<!-- -- Top 10 -- -->
<h2>Top 10 Priority Files</h2>
<div class="table-wrap">
<table>
  <thead><tr>
    <th>Filename</th><th>Resolution</th><th>Bitrate&nbsp;Mbps</th>
    <th>FPS</th><th>Codec</th><th>Audio</th>
    <th>GB</th><th>bpppf</th><th>Score</th><th>Issues Detected</th>
  </tr></thead>
  <tbody>{top10_rows}</tbody>
</table>
</div>

<!-- -- All flagged -- -->
<h2>All Flagged Files -- {len(flagged)} file(s) with score >= {threshold}</h2>

<div class="legend">
  <span><span class="legend-dot" style="background:var(--critical)"></span>Critical >= 60</span>
  <span><span class="legend-dot" style="background:var(--high)"></span>High 35-59</span>
  <span><span class="legend-dot" style="background:var(--medium)"></span>Medium 20-34</span>
  <span><span class="legend-dot" style="background:var(--low)"></span>Low flagged</span>
</div>

<div class="filter-bar">
  <label for="fi">Filter:</label>
  <input id="fi" type="text" placeholder="filename or issue keyword..." oninput="filterTable()">
  <span id="filter-count"></span>
</div>

<div class="table-wrap">
<table id="main-table">
  <thead><tr>
    <th data-sort onclick="sortTable(0)">Filename</th>
    <th data-sort onclick="sortTable(1)">Resolution</th>
    <th data-sort onclick="sortTable(2)">Bitrate&nbsp;Mbps</th>
    <th data-sort onclick="sortTable(3)">FPS</th>
    <th data-sort onclick="sortTable(4)">Codec</th>
    <th data-sort onclick="sortTable(5)">Audio</th>
    <th data-sort onclick="sortTable(6)">GB</th>
    <th data-sort onclick="sortTable(7)">bpppf</th>
    <th data-sort onclick="sortTable(8)">Score</th>
    <th>Issues Detected</th>
  </tr></thead>
  <tbody id="main-tbody">{all_rows}</tbody>
</table>
</div>

{errors_section}

<script>
// -- Table sort --------------------------------------------------------------
let sortCol = 8, sortAsc = false;  // default: score descending
function sortTable(col) {{
  const tbody = document.getElementById('main-tbody');
  const rows  = Array.from(tbody.querySelectorAll('tr'));
  sortAsc = (sortCol === col) ? !sortAsc : false;
  sortCol = col;
  rows.sort((a, b) => {{
    const va = a.cells[col].innerText.trim().split('\\n')[0];
    const vb = b.cells[col].innerText.trim().split('\\n')[0];
    const na = parseFloat(va), nb = parseFloat(vb);
    const cmp = (!isNaN(na) && !isNaN(nb)) ? na - nb : va.localeCompare(vb);
    return sortAsc ? cmp : -cmp;
  }});
  rows.forEach(r => tbody.appendChild(r));
}}

// -- Filter ------------------------------------------------------------------
function filterTable() {{
  const q    = document.getElementById('fi').value.toLowerCase();
  const rows = document.querySelectorAll('#main-tbody tr');
  let shown  = 0;
  rows.forEach(r => {{
    const match = r.innerText.toLowerCase().includes(q);
    r.style.display = match ? '' : 'none';
    if (match) shown++;
  }});
  document.getElementById('filter-count').textContent =
    q ? `Showing ${{shown}} of ${{rows.length}} files` : '';
}}
</script>
</body>
</html>"""

    output_path.write_text(html, encoding="utf-8")


# ------------------------------------------------------------------------------
# Entry point
# ------------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Scan a video collection for quality issues and generate an HTML report.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "directory", nargs="?", default=DEFAULT_SCAN_DIR,
        help=f"Directory to scan recursively (default: {DEFAULT_SCAN_DIR})",
    )
    parser.add_argument(
        "--threshold", "-t", type=int, default=DEFAULT_THRESHOLD,
        help=f"Minimum score to flag a file (default: {DEFAULT_THRESHOLD})",
    )
    parser.add_argument(
        "--output", "-o", default=DEFAULT_OUTPUT,
        help=f"Output HTML filename (default: {DEFAULT_OUTPUT})",
    )
    parser.add_argument(
        "--no-open", action="store_true",
        help="Do not open the report in a browser when done",
    )
    args = parser.parse_args()

    scan_dir    = Path(args.directory)
    output_path = Path(args.output)
    threshold   = args.threshold

    # Validate prerequisites
    if not scan_dir.exists():
        print(f"ERROR: Directory not found: {scan_dir}", file=sys.stderr)
        sys.exit(1)

    if not Path(MEDIAINFO_EXE).exists():
        print(f"ERROR: MediaInfo not found at: {MEDIAINFO_EXE}", file=sys.stderr)
        print("       Edit MEDIAINFO_EXE at the top of this script.", file=sys.stderr)
        sys.exit(1)

    print(f"Video Quality Audit")
    print(f"{'-' * 50}")
    print(f"  Scan directory : {scan_dir}")
    print(f"  Score threshold: {threshold}")
    print(f"  Output file    : {output_path.resolve()}")
    print(f"  Workers        : {MAX_WORKERS}")
    print()

    results, total_scanned, errors = scan_directory(scan_dir)

    flagged = sorted(
        [r for r in results if r["score"] >= threshold],
        key=lambda r: r["score"], reverse=True,
    )

    # Console summary
    print(f"{'-' * 50}")
    print(f"  Total video files : {total_scanned}")
    print(f"  1080p files       : {len(results)}")
    print(f"  Flagged (>= {threshold:2d})    : {len(flagged)}")
    if errors:
        print(f"  Errors            : {len(errors)}")
    print()

    if flagged:
        print("  Top 10 worst files:")
        for i, r in enumerate(flagged[:10], 1):
            print(f"    {i:2}. [{r['score']:3}] {r['path'].name}")
        print()

    # Generate report
    generate_html_report(results, total_scanned, scan_dir, threshold, output_path, errors)

    abs_path = output_path.resolve()
    print(f"  Report saved: {abs_path}")

    if not args.no_open:
        print("  Opening in browser...")
        webbrowser.open(abs_path.as_uri())


if __name__ == "__main__":
    main()
