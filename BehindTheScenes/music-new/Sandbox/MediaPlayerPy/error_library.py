# -----------------------------------------------------------------------------
#  error_library.py -- FFMPEG noise filter
#
#  Filters out known harmless ffmpeg stderr lines so only genuine errors
#  remain in the report.  Add to IGNORE_PATTERNS to expand coverage.
# -----------------------------------------------------------------------------

IGNORE_PATTERNS = [
    # H.264 decoder chatter -- common in Blu-ray / web-ripped files, harmless
    "non-existing pps 0 referenced",
    "non-existing pps referenced",
    "decode_slice_header error",
    "no frame!",
    "cabac_init_cabac_states",
    "mmco: unref short failure",
    "left block unavailable for requested intra4x4 mode",
    "top block unavailable for requested intra4x4 mode",
    "error while decoding mb",

    # H.265 / HEVC noise
    "dpb: tried to delete unexisting frame",

    # Container / demuxer noise
    "dts < pts",
    "dts discontinuity",
    "pts discontinuity",
    "application provided invalid, non monotonically increasing dts",
    "invalid pts",
    "max_analyze_duration",
    "mismatching reference",

    # AAC / audio noise
    "overread, skip pkt",
    "too many bits for bps",
    "crc error",

    # Generic repetition marker -- always strip
    "last message repeated",
]


# -----------------------------------------------------------------------------
#  Severity classification
#
#  Each rule: (pattern, base_severity, plain_english_description)
#  base_severity: "critical" | "major" | "minor"
#
#  Count thresholds adjust major |:
#    major  < DOWNGRADE_THRESHOLD  ->  minor
#    major  > UPGRADE_THRESHOLD    ->  critical
# -----------------------------------------------------------------------------

DOWNGRADE_THRESHOLD = 5    # major with fewer hits treated as minor
UPGRADE_THRESHOLD   = 100  # major with more hits escalated to critical

SEVERITY_RULES = [
    # -- Always critical -------------------------------------------------------
    ("moov atom not found",
     "critical",
     "Container structure is missing or damaged -- the file may not open at all."),
    ("invalid data found when processing input",
     "critical",
     "Severely corrupted data encountered -- likely to cause major playback failure."),
    ("end of file",
     "critical",
     "The file appears to be truncated or incomplete."),
    ("no such file or directory",
     "critical",
     "The file could not be read."),

    # -- Major -- adjusted by count ---------------------------------------------
    ("missing reference picture",
     "major",
     "Video frames are missing their reference data -- expect visible block "
     "artefacts, particularly in fast-moving or complex scenes."),
    ("concealing",
     "major",
     "The decoder had to conceal corrupt or missing frame data -- "
     "visible as brief block or colour glitches."),
    ("no picture",
     "major",
     "Complete frames are absent from the video stream -- "
     "expect freeze frames or black sections."),
    ("error while decoding",
     "major",
     "A decode failure occurred on one or more video frames."),
    ("sei type",
     "major",
     "Metadata embedded in the stream is corrupted or unreadable."),
    ("header missing",
     "major",
     "Audio frame headers are damaged -- may cause audio drop-outs or noise."),
    ("out of range",
     "major",
     "Stream values are outside valid bounds -- indicates data corruption."),

    # -- Minor -----------------------------------------------------------------
    ("dts",
     "minor",
     "Timestamp ordering irregularity -- usually harmless but can cause "
     "minor sync issues on some players."),
    ("pts",
     "minor",
     "Presentation timestamp issue -- typically invisible to the viewer."),
    ("non monotonically",
     "minor",
     "Stream timing is non-sequential -- unlikely to affect playback."),
    ("bitrate",
     "minor",
     "Bitrate anomaly detected -- may cause buffering on slow hardware."),
]


def classify_errors(text: str) -> tuple:
    """
    Analyse filtered ffmpeg error text and return (verdict, summary).

    verdict : "none" | "minor" | "major" | "critical"
    summary : human-readable string describing findings
    """
    if not text.strip():
        return ("none", "")

    lines = text.splitlines()

    # Count occurrences per rule
    hits = {}   # rule_index -> count
    for i, (pattern, _, _) in enumerate(SEVERITY_RULES):
        count = sum(1 for ln in lines if pattern in ln.lower())
        if count > 0:
            hits[i] = count

    if not hits:
        return ("minor", "Unrecognised error lines present -- review manually.")

    # Determine effective severity per matched rule
    findings = []
    overall = "none"
    severity_rank = {"none": 0, "minor": 1, "major": 2, "critical": 3}

    for i, count in hits.items():
        pattern, base_sev, description = SEVERITY_RULES[i]

        if base_sev == "critical":
            effective = "critical"
        elif base_sev == "major":
            if count < DOWNGRADE_THRESHOLD:
                effective = "minor"
            elif count > UPGRADE_THRESHOLD:
                effective = "critical"
            else:
                effective = "major"
        else:
            effective = "minor"

        if severity_rank[effective] > severity_rank[overall]:
            overall = effective

        label = effective.upper()
        findings.append(f"  [{label}] {description} ({count} occurrence{'s' if count != 1 else ''})")

    summary_lines = [f"Severity: {overall.upper()}", ""] + findings
    return (overall, "\n".join(summary_lines))


def filter_lines(lines: list[str]) -> list[str]:
    """
    Remove known-harmless ffmpeg stderr lines.
    Returns only lines that represent genuine issues.
    Empty result means the file is clean.
    """
    kept = []
    for line in lines:
        lower = line.lower().strip()
        if not lower:
            continue
        if any(pattern in lower for pattern in IGNORE_PATTERNS):
            continue
        kept.append(line.rstrip())
    return kept
