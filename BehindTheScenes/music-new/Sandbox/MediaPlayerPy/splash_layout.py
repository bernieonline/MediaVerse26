"""
splash_layout.py
Builds the scattered-photo layout for the Architect gallery display.

Primary source: the first TopTen Architect collection in movies_coll_v2.
Each movie in the collection rules is looked up in the server manifest by
title stem.  The manifest's cache.display field is resolved to a local
image path using local_display_v2 from project_paths.

Falls back to random images from the local display cache if the manifest
is unavailable or the collection resolves fewer images than requested.

Cards are constrained to the left 75 % of the display width so they do
not intrude into the category navigation column on the right.

Usage (Framework.py):
    from splash_layout import generate_splash_layout
    engine.rootContext().setContextProperty("splashLayout", generate_splash_layout())
"""

import json
import random
from pathlib import Path
from project_paths import paths


# ── Manifest helpers ──────────────────────────────────────────────────────────

def _build_manifest_index() -> dict:
    """
    Load the server manifest and return a dict keyed by title stem.
    e.g. "Rocky (1976)" → { full manifest record }
    """
    manifest_path = paths.get("server_manifest_v2")
    if not manifest_path or not Path(manifest_path).exists():
        print(f"⚠️ [SPLASH LAYOUT] Manifest not found: {manifest_path}")
        return {}

    try:
        with open(manifest_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        print(f"❌ [SPLASH LAYOUT] Manifest read error: {e}")
        return {}

    items = data if isinstance(data, list) else data.get("items", [])
    index = {}
    for record in items:
        raw_title = record.get("title", "")
        if raw_title:
            # Title may be "Rocky (1976)" or "Rocky (1976).mp4" — strip extension.
            stem = Path(raw_title).stem
            index[stem] = record

    print(f"✅ [SPLASH LAYOUT] Manifest indexed: {len(index)} records")
    return index


def _uri_from_record(record: dict, cache_root: Path):
    """
    Given a manifest record, return a file:/// URI for the local display image,
    or None if the file cannot be found on disk.
    """
    display = record.get("cache", {}).get("display", "")
    if not display:
        return None
    # "Cache/display/Rocky (1976).jpg" → "Rocky (1976).jpg"
    filename = Path(display).name
    local = cache_root / filename
    return local.as_uri() if local.exists() else None


# ── Main entry point ──────────────────────────────────────────────────────────

def generate_splash_layout(count: int = 10, seed: int = None) -> list:
    """
    Returns a list of card dicts for the QML context property 'splashLayout'.

    Layout rules
    ────────────
    • Index 0 is always the initial hero.  QML centres it precisely; the
      Python x/y for the hero serve as its scatter-back position once a
      different card takes focus.
    • All cards are constrained to the left 75 % of the display width so
      they never overlap the category navigation column on the right.
    • x, y   — fractions of component width / height respectively.
    • width  — fraction of component width.
    • height — NOT used for QML sizing (QML derives height as width × 1.48
               for a consistent portrait ratio).  Kept in the dict for
               reference only.
    """
    if seed is not None:
        random.seed(seed)

    cache_root       = paths.get("local_display_v2")
    collections_path = paths.get("movies_coll_v2")

    if not cache_root or not Path(cache_root).exists():
        print(f"⚠️ [SPLASH LAYOUT] local_display_v2 not found: {cache_root}")
        return []

    cache_root = Path(cache_root)

    # ── Step 1: resolve TopTen collection images via manifest ─────────────────
    resolved: list[tuple[str, str]] = []   # [(uri, title), …]
    index = _build_manifest_index()

    if index and collections_path and Path(collections_path).exists():
        try:
            with open(collections_path, "r", encoding="utf-8") as f:
                colls = json.load(f)

            top_ten = next(
                (c for c in colls
                 if c.get("type") == "Architect" and c.get("category") == "TopTen"),
                None
            )

            if top_ten:
                print(f"✅ [SPLASH LAYOUT] Using TopTen: '{top_ten.get('name')}'")
                for rule in top_ten.get("rules", []):
                    if rule.get("mode") != "Files":
                        continue
                    for file_path in rule.get("data", {}).get("files", []):
                        stem = Path(file_path).stem          # "Rocky (1976)"
                        record = index.get(stem)
                        if record:
                            uri = _uri_from_record(record, cache_root)
                            if uri:
                                resolved.append((uri, stem))
                            else:
                                print(f"⚠️ [SPLASH LAYOUT] Not in local cache: {stem}")
                        else:
                            print(f"⚠️ [SPLASH LAYOUT] Not in manifest: {stem}")
            else:
                print("⚠️ [SPLASH LAYOUT] No TopTen Architect collection found.")

        except Exception as e:
            print(f"❌ [SPLASH LAYOUT] Collection error: {e}")

    # ── Step 2: pad with random local cache images if needed ─────────────────
    if len(resolved) < count:
        used = {uri for uri, _ in resolved}
        pool = [
            f for f in cache_root.iterdir()
            if f.suffix.lower() in {".jpg", ".jpeg", ".png"}
            and f.as_uri() not in used
        ]
        random.shuffle(pool)
        for f in pool:
            if len(resolved) >= count:
                break
            resolved.append((f.as_uri(), f.stem))

    if not resolved:
        print("❌ [SPLASH LAYOUT] No images resolved — returning empty layout.")
        return []

    pool = resolved[:count]
    random.shuffle(pool)

    # ── Step 3: assign positions ──────────────────────────────────────────────
    # Hero width is fixed so QML can render it consistently.
    HERO_W = 0.28

    layout = []
    total  = len(pool)

    for i, (uri, title) in enumerate(pool):
        is_hero = (i == 0)

        if is_hero:
            # Give the hero a plausible scatter position too (used when it
            # returns to background state after another card takes focus).
            w        = HERO_W
            x        = round(random.uniform(0.26, 0.36), 4)
            y        = round(random.uniform(0.22, 0.36), 4)
            rotation = round(random.uniform(-4.0, 4.0), 2)
            z        = total + 1
        else:
            w = round(random.uniform(0.13, 0.19), 4)
            # Right edge of card must not exceed left-75 % boundary.
            max_x = max(0.01, 0.74 - w)
            x     = round(random.uniform(0.01, max_x), 4)
            y     = round(random.uniform(0.03, 0.65), 4)
            rotation = round(random.uniform(-18.0, 18.0), 2)
            z     = i

        layout.append({
            "x":        x,
            "y":        y,
            "width":    w,
            "height":   round(w * 1.48, 4),   # reference only; QML recalculates
            "rotation": rotation,
            "z":        z,
            "path":     uri,
            "title":    title,
        })

    print(f"✅ [SPLASH LAYOUT] {len(layout)} cards — hero: '{layout[0]['title']}'")
    return layout
