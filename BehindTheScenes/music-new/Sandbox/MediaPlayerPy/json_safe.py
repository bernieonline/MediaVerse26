"""
json_safe.py — Atomic JSON write utility for MediaVerse.

safe_json_write(path, data)
    Writes `data` to `path` atomically via a .tmp file.
    Pre-write backup:
      - All files: copies current file to <filename>.bak before swapping.
      - Movies_Collections_v2.json: keeps a rolling 5-deep backup
        (_bak1 … _bak5), rotated on every save.
    The original file is never touched until the write succeeds.
    Raises ValueError if data is empty, OSError on filesystem failure.
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


def _make_backup(path: Path) -> None:
    """
    Back up `path` before overwriting it.

    - For files listed in _ROLLING_BACKUPS: rotate _bak1…_bakN.
      bak(N-1) → bakN, …, bak1 → bak2, current → bak1
    - For all other files: copy to <name>.bak (single backup).
    """
    if not path.exists():
        return  # Nothing to back up yet (first write)

    depth = _ROLLING_BACKUPS.get(path.stem)

    if depth:
        # Rotate existing backups: oldest slot first to avoid overwriting
        for n in range(depth, 1, -1):
            src = path.with_name(f"{path.stem}_bak{n - 1}{path.suffix}")
            dst = path.with_name(f"{path.stem}_bak{n}{path.suffix}")
            if src.exists():
                shutil.copy2(src, dst)
        # Current file → _bak1
        bak1 = path.with_name(f"{path.stem}_bak1{path.suffix}")
        shutil.copy2(path, bak1)
        log.debug("_make_backup: rotated %d backups for %s", depth, path.name)
    else:
        # Simple single .bak
        bak = path.with_suffix(path.suffix + ".bak")
        shutil.copy2(path, bak)
        log.debug("_make_backup: wrote %s", bak.name)


def safe_json_write(path, data):
    """
    Atomically write `data` as JSON to `path`.

    Steps:
      1. Validate data is a non-empty list or dict.
      2. Back up the current file (rolling 5-deep for collections, .bak for others).
      3. Write to <path>.tmp in the same directory.
      4. os.replace() swaps .tmp → target (atomic on NTFS).
      5. On any failure: delete .tmp, raise exception, original untouched.

    Args:
        path (str | Path): Destination file path.
        data (list | dict): Data to serialise.

    Raises:
        ValueError: If data is empty or not a list/dict.
        OSError:    If the filesystem write or replace fails.
    """
    path = Path(path)
    tmp = path.with_suffix(path.suffix + ".tmp")

    # --- Guard: refuse to write empty or wrong-type data ---
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
        # Ensure parent directory exists (handles first-run on server paths)
        path.parent.mkdir(parents=True, exist_ok=True)

        # Pre-write backup — before touching the target
        _make_backup(path)

        # Write to .tmp
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4, ensure_ascii=False)

        # Atomic swap — on NTFS this is a single metadata operation
        os.replace(tmp, path)

        log.debug("safe_json_write: wrote %d items to %s", len(data), path.name)

    except Exception as exc:
        # Clean up the .tmp so no half-written file is left behind
        try:
            if tmp.exists():
                tmp.unlink()
        except OSError:
            pass
        raise OSError(
            f"safe_json_write failed for {path.name}: {exc}"
        ) from exc
