"""
json_safe.py — Atomic JSON write + validated read utility for MediaVerse.

safe_json_write(path, data)
    Writes `data` to `path` atomically via a .tmp file.
    Pre-write backup:
      - All files: copies current file to <filename>.bak before swapping.
      - Movies_Collections_v2.json: keeps a rolling 5-deep backup
        (_bak1 … _bak5), rotated on every save.
    The original file is never touched until the write succeeds.
    Raises ValueError if data is empty, OSError on filesystem failure.

safe_json_read(path, schema_type=None)
    Loads JSON from `path` with automatic backup fallback and structure
    validation. Returns a safe empty default if all sources fail.
    schema_type: "collections" | "xml_collection_data" | "config" |
                 "manifest" | None (no validation)
"""

import json
import os
import shutil
import logging
from pathlib import Path

log = logging.getLogger(__name__)

# Files that get a rolling multi-depth backup (stem → depth)
_ROLLING_BACKUPS = {
    "Movies_Collections_v2": 5,
}

# Safe empty defaults per schema type
_DEFAULTS = {
    "collections":        [],
    "xml_collection_data": [],
    "config":             {"PreferredPlayer": 0},
    "manifest":           {"items": []},
}


# ── Validation ────────────────────────────────────────────────────────────────

def _validate(data, schema_type):
    """Return True if data passes minimum structure check for schema_type."""
    if schema_type is None:
        return True

    if schema_type == "collections":
        if not isinstance(data, list):
            return False
        if len(data) == 0:
            return True  # Empty list is valid (no collections yet)
        return all(isinstance(r, dict) and "name" in r for r in data[:5])

    if schema_type == "xml_collection_data":
        if not isinstance(data, list):
            return False
        if len(data) == 0:
            return True
        return all(isinstance(r, dict) and "Filename" in r for r in data[:5])

    if schema_type == "config":
        return isinstance(data, dict) and "PreferredPlayer" in data

    if schema_type == "manifest":
        return isinstance(data, dict) and "items" in data

    return True


def _notify(message, urgent=False):
    """Post a notification — silently skipped if NotificationManager unavailable."""
    try:
        from NotificationManager import notifier
        notifier.post_notification(message, urgent)
    except Exception:
        pass


# ── Backup helpers ────────────────────────────────────────────────────────────

def _make_backup(path: Path) -> None:
    """
    Back up `path` before overwriting it.

    - Rolling N-deep for files listed in _ROLLING_BACKUPS.
    - Single .bak for all other files.
    """
    if not path.exists():
        return

    depth = _ROLLING_BACKUPS.get(path.stem)

    if depth:
        # Rotate: shift bak(N-1)→bakN, …, bak1→bak2, current→bak1
        for n in range(depth, 1, -1):
            src = path.with_name(f"{path.stem}_bak{n - 1}{path.suffix}")
            dst = path.with_name(f"{path.stem}_bak{n}{path.suffix}")
            if src.exists():
                shutil.copy2(src, dst)
        bak1 = path.with_name(f"{path.stem}_bak1{path.suffix}")
        shutil.copy2(path, bak1)
        log.debug("_make_backup: rotated %d backups for %s", depth, path.name)
    else:
        bak = path.with_suffix(path.suffix + ".bak")
        shutil.copy2(path, bak)
        log.debug("_make_backup: wrote %s", bak.name)


def _backup_candidates(path: Path):
    """Return ordered list of backup paths to try after main file fails."""
    depth = _ROLLING_BACKUPS.get(path.stem)
    if depth:
        return [
            path.with_name(f"{path.stem}_bak{n}{path.suffix}")
            for n in range(1, depth + 1)
        ]
    bak = path.with_suffix(path.suffix + ".bak")
    return [bak]


# ── Public API ────────────────────────────────────────────────────────────────

def safe_json_write(path, data):
    """
    Atomically write `data` as JSON to `path`.

    Steps:
      1. Validate data is a non-empty list or dict.
      2. Back up the current file (rolling 5-deep for collections, .bak for others).
      3. Write to <path>.tmp in the same directory.
      4. os.replace() swaps .tmp → target (atomic on NTFS).
      5. On any failure: delete .tmp, raise exception, original untouched.

    Raises:
        ValueError: If data is empty or not a list/dict.
        OSError:    If the filesystem write or replace fails.
    """
    path = Path(path)
    tmp = path.with_suffix(path.suffix + ".tmp")

    if not isinstance(data, (list, dict)):
        raise ValueError(
            f"safe_json_write: data must be a list or dict, got {type(data).__name__} "
            f"for {path.name}"
        )
    if len(data) == 0:
        raise ValueError(
            f"safe_json_write: refusing to write empty data to {path.name}"
        )

    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        _make_backup(path)

        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4, ensure_ascii=False)

        os.replace(tmp, path)
        log.debug("safe_json_write: wrote %d items to %s", len(data), path.name)

    except Exception as exc:
        try:
            if tmp.exists():
                tmp.unlink()
        except OSError:
            pass
        raise OSError(
            f"safe_json_write failed for {path.name}: {exc}"
        ) from exc


def safe_json_read(path, schema_type=None):
    """
    Safely load and validate JSON from `path`, falling back to backups on failure.

    - Tries main file first, then backup files in order.
    - Validates structure against schema_type if provided.
    - Posts a notification if a backup was used.
    - Returns a safe empty default if all sources fail.

    Args:
        path (str | Path): File to read.
        schema_type (str | None): One of "collections", "xml_collection_data",
                                  "config", "manifest", or None.

    Returns:
        Parsed data (list or dict), or the schema default on total failure.
    """
    path = Path(path)
    default = _DEFAULTS.get(schema_type, {})
    candidates = [path] + _backup_candidates(path)

    for candidate in candidates:
        if not candidate.exists():
            continue
        try:
            with open(candidate, "r", encoding="utf-8") as f:
                data = json.load(f)

            if not _validate(data, schema_type):
                log.warning("safe_json_read: validation failed for %s", candidate.name)
                continue

            if candidate != path:
                msg = (f"⚠️ '{path.name}' was damaged — "
                       f"data restored from {candidate.name}")
                log.warning(msg)
                _notify(msg, urgent=True)

            return data

        except (json.JSONDecodeError, OSError) as exc:
            log.warning("safe_json_read: failed to load %s: %s", candidate.name, exc)
            continue

    # All sources exhausted
    msg = f"❌ All sources failed for '{path.name}' — using empty default"
    log.error(msg)
    _notify(msg, urgent=True)
    return default
