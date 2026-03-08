"""
json_safe.py — Atomic JSON write utility for MediaVerse.

safe_json_write(path, data)
    Writes `data` to `path` atomically via a .tmp file.
    The original file is never touched until the write succeeds.
    Raises ValueError if data is empty, OSError on filesystem failure.
"""

import json
import os
import logging
from pathlib import Path

log = logging.getLogger(__name__)


def safe_json_write(path, data):
    """
    Atomically write `data` as JSON to `path`.

    Steps:
      1. Validate data is a non-empty list or dict.
      2. Write to <path>.tmp in the same directory.
      3. os.replace() swaps .tmp → target (atomic on NTFS).
      4. On any failure: delete .tmp, raise exception, original untouched.

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
