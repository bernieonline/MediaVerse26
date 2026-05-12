"""
landing_view.py
Mosaic tile landing view -- scrolling grid of movie poster tiles.

Tile sizes are computed dynamically from the viewport dimensions so the
mosaic always fills the full display area:
  U_H = viewport_height / 2    (2 rows of small tiles)
  U_W = U_H * (2/3)            (portrait 2:3 ratio)
  Hero = 2×U_W × 2×U_H        (occupies 1 full column × full strip height)

Three recipe strips vary the hero position across cycles.

Batch behaviour:
  - BATCH_SIZE films are selected per scroll cycle (100 images, ~10 min at 1080p).
  - _used_ids prevents any film from repeating in the immediately following batch.
  - The next batch is pre-built while the current one is still scrolling so the
    cycle transition (a brief fade to black) uses a cached JSON payload and is
    essentially instantaneous.
"""

from __future__ import annotations

import json
import random
from pathlib import Path

from PySide6.QtCore import QObject, Slot, Signal, Property

from project_paths import server_manifest_v2, local_thumb_v2, local_display_v2

# px/sec -- determines how long one full canvas scroll takes
SCROLL_SPEED_PPS: float = 48.0

# Target number of films per scroll batch.
# 5 tiles per recipe -> 100 films  20 recipes  10 min scroll at 1920×1080.
BATCH_SIZE: int = 100

# Recipe definitions -- coordinates in grid units (col, row).
# All recipes are exactly 2 rows tall.  Hero occupies 2 cols × 2 rows.
#
#  Strip A (4 cols):  [Hero 2×2 | S S]
#                     [         | S S]
#
#  Strip B (4 cols):  [S S | Hero 2×2]
#                     [S S |         ]
#
#  Strip C (4 cols):  [S | Hero 2×2 | S]
#                     [S |          | S]

_RECIPE_DEFS = [
    {
        "cols": 4,
        "tiles": [
            ("hero",  0, 0),
            ("small", 2, 0), ("small", 2, 1),
            ("small", 3, 0), ("small", 3, 1),
        ],
    },
    {
        "cols": 4,
        "tiles": [
            ("small", 0, 0), ("small", 0, 1),
            ("small", 1, 0), ("small", 1, 1),
            ("hero",  2, 0),
        ],
    },
    {
        "cols": 4,
        "tiles": [
            ("small", 0, 0), ("small", 0, 1),
            ("hero",  1, 0),
            ("small", 3, 0), ("small", 3, 1),
        ],
    },
]


class LandingViewModel(QObject):
    """
    Exposed to QML as the context property "landingViewModel".

    Typical QML usage::

        Component.onCompleted: {
            var raw  = landingViewModel.build_tile_model(width, height)
            tileModel = JSON.parse(raw)
        }

    Pre-build the next batch while still scrolling::

        // at ~75% of canvas:
        landingViewModel.prebuild_next_model(width, height)

    Then call build_tile_model() again at cycle end -- it returns the
    pre-built payload instantly.
    """

    tileModelChanged = Signal()
    scrollDurationChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._film_pool: dict[str, dict] = {}
        self._hero_slot_index: int = 0
        self._current_tiles: list[dict] = []
        self._shuffled_ids: list[str] = []
        self._shuffle_cursor: int = 0
        self._scroll_duration_ms: int = 60_000
        # Anti-repeat: IDs used in the most recently built batch
        self._used_ids: set[str] = set()
        # Pre-built next batch (JSON string + duration)
        self._next_model_json: str = ""
        self._next_scroll_ms: int = 0
        self._load_film_pool()

    # -- Data loading -----------------------------------------------------------

    def _load_film_pool(self) -> None:
        """
        Read the server manifest, filter to movies that have a local display
        image, and populate self._film_pool keyed by title stem.

        Follows the same image-resolution logic as splash_layout.py:
          1. cache["display"]  -- e.g. "Cache/display/Rocky (1976).jpg"
          2. cache["relative_display"] as fallback
          3. Stem + ".jpg" direct lookup as last resort
        """
        display_root  = Path(local_display_v2)
        thumb_root    = Path(local_thumb_v2)
        manifest_path = Path(server_manifest_v2)

        if not manifest_path.exists():
            print(f"[WARN] [LANDING] Manifest not found: {manifest_path}")
            return

        try:
            with open(manifest_path, "r", encoding="utf-8") as fh:
                raw = json.load(fh)
        except Exception as exc:
            print(f"[ERROR] [LANDING] Manifest read error: {exc}")
            return

        records = raw if isinstance(raw, list) else raw.get("items", [])
        loaded = 0

        for record in records:
            meta = record.get("metadata", {})
            if meta.get("type") != "movie":
                continue

            title = record.get("title", "")
            if not title:
                continue

            film_id = Path(title).stem   # strip .mp4 / .mkv if present

            cache  = record.get("cache", {})
            shared = record.get("shared", {})

            # -- Resolve display image (flat folder, filename only) -------------
            rel_display = (
                cache.get("display") or
                cache.get("relative_display") or
                ""
            )
            disp_name    = Path(rel_display).name if rel_display else (film_id + ".jpg")
            display_path = display_root / disp_name
            if not display_path.exists():
                display_path = display_root / (film_id + ".jpg")
                if not display_path.exists():
                    display_path = None

            # -- Resolve thumbnail as fallback ---------------------------------
            rel_thumb  = cache.get("relative_thumb", "")
            thumb_name = Path(rel_thumb).name if rel_thumb else (film_id + ".jpg")
            thumb_path = thumb_root / thumb_name
            if not thumb_path.exists():
                thumb_path = None

            poster_path = display_path or thumb_path
            if not poster_path:
                continue   # no local image -> skip

            self._film_pool[film_id] = {
                "display_path": str(display_path) if display_path else "",
                "thumb_path":   str(thumb_path)   if thumb_path   else "",
                "poster_path":  str(poster_path),
                "video_path":   shared.get("video", ""),
                "xml_path":     shared.get("xml", ""),
                "title":        film_id,
                "year":         str(meta.get("year", "")),
                "is_hidden_gem": meta.get("id") is None,
            }
            loaded += 1

        print(f"[OK] [LANDING] Film pool: {loaded} movies with local images")

    # -- Film shuffling ---------------------------------------------------------

    def _shuffle_films(self) -> None:
        """Shuffle available films, excluding IDs used in the previous batch."""
        available = [fid for fid in self._film_pool if fid not in self._used_ids]
        if len(available) < 20:
            # Pool nearly exhausted -- reset and use all films
            self._used_ids.clear()
            available = list(self._film_pool.keys())
        random.shuffle(available)
        self._shuffled_ids = available
        self._shuffle_cursor = 0

    def _next_film_id(self) -> str | None:
        if not self._shuffled_ids or self._shuffle_cursor >= len(self._shuffled_ids):
            self._shuffle_films()
        if not self._shuffled_ids:
            return None
        fid = self._shuffled_ids[self._shuffle_cursor]
        self._shuffle_cursor += 1
        return fid

    # -- Internal layout engine -------------------------------------------------

    def _do_build(self, viewport_width: float, viewport_height: float) -> tuple[str, int]:
        """
        Build a fresh batch of tiles.

        Returns (json_tiles_str, scroll_duration_ms).
        Side effects: updates _used_ids, _current_tiles, advances _hero_slot_index.
        """
        if not self._film_pool:
            print("[WARN] [LANDING] _do_build: film pool empty")
            return json.dumps([]), 60_000

        # -- Dynamic sizing so tiles fill the full display area -----------------
        U_H: float = viewport_height / 2.0          # 2 rows fills full height
        U_W: float = U_H * (2.0 / 3.0)             # portrait 2:3 ratio
        HERO_W: float = U_W * 2
        HERO_H: float = U_H * 2                    # = viewport_height

        # -- Rotate recipe order each batch -------------------------------------
        n = len(_RECIPE_DEFS)
        self._hero_slot_index = (self._hero_slot_index + 1) % n
        recipe_order = [(self._hero_slot_index + i) % n for i in range(n)]

        recipes: list[dict] = []
        for rdef in _RECIPE_DEFS:
            pixel_tiles = []
            for species, col, row in rdef["tiles"]:
                pixel_tiles.append((species, col * U_W, row * U_H))
            recipes.append({
                "width": rdef["cols"] * U_W,
                "tiles": pixel_tiles,
            })

        # -- Shuffle films for this batch (excludes _used_ids) ------------------
        self._shuffle_films()
        batch_size = min(BATCH_SIZE, len(self._film_pool))

        tiles: list[dict] = []
        x_cursor: float   = 0.0
        cycle_pos: int    = 0
        films_placed: int = 0

        while films_placed < batch_size:
            recipe = recipes[recipe_order[cycle_pos % n]]
            cycle_pos += 1

            for species, rx, ry in recipe["tiles"]:
                if films_placed >= batch_size:
                    break

                film_id = self._next_film_id()
                if film_id is None:
                    break

                if species == "hero":
                    w, h  = HERO_W, HERO_H
                    layer = 0   # back layer
                else:
                    w, h  = U_W, U_H
                    layer = 1   # front layer

                film    = self._film_pool[film_id]
                display = film["display_path"] or film["poster_path"]

                tiles.append({
                    "film_id":       film_id,
                    "species":       species,
                    "x":             x_cursor + rx,
                    "y":             ry,
                    "w":             w,
                    "h":             h,
                    "layer":         layer,
                    "poster_uri":    Path(display).as_uri() if display else "",
                    "image_uri":     Path(display).as_uri() if display else "",
                    "xml_path":      film["xml_path"],
                    "movie_path":    film["video_path"],
                    "title":         film["title"],
                    "year":          film["year"],
                    "is_hidden_gem": film["is_hidden_gem"],
                    "stagger_index": 0,
                })
                films_placed += 1

            x_cursor += recipe["width"]

        # -- Assign stagger indices left-to-right -------------------------------
        for i, t in enumerate(sorted(tiles, key=lambda t: t["x"])):
            t["stagger_index"] = i

        # -- Record used IDs so next batch excludes them ------------------------
        self._used_ids = {t["film_id"] for t in tiles}
        self._current_tiles = tiles

        actual_w = max((t["x"] + t["w"] for t in tiles), default=viewport_width * 2)
        duration_ms = max(10_000, int(actual_w / SCROLL_SPEED_PPS * 1000))

        print(
            f"[OK] [LANDING] {len(tiles)} tiles | "
            f"U_W={U_W:.0f} U_H={U_H:.0f} | "
            f"canvas={actual_w:.0f}px | "
            f"scroll={duration_ms / 1000:.0f}s"
        )
        return json.dumps(tiles), duration_ms

    # -- Public slots -----------------------------------------------------------

    @Slot(float, float, result=str)
    def build_tile_model(self, viewport_width: float, viewport_height: float) -> str:
        """
        Return JSON tile array for the current batch.
        Uses pre-built payload if prebuild_next_model() was called earlier,
        otherwise builds fresh (first load or missed prebuild window).
        """
        if self._next_model_json:
            result = self._next_model_json
            self._scroll_duration_ms = self._next_scroll_ms
            self.scrollDurationChanged.emit()
            self._next_model_json = ""
            self._next_scroll_ms  = 0
            # Restore _current_tiles for hit_test
            self._current_tiles = json.loads(result)
            return result

        json_str, dur = self._do_build(viewport_width, viewport_height)
        self._scroll_duration_ms = dur
        self.scrollDurationChanged.emit()
        return json_str

    @Slot(float, float)
    def prebuild_next_model(self, viewport_width: float, viewport_height: float) -> None:
        """
        Pre-compute the next batch in the background while the current canvas
        is still scrolling.  Call this from QML at ~75% scroll progress.
        The result is cached and returned instantly by the next build_tile_model().
        """
        if not self._next_model_json:
            json_str, dur = self._do_build(viewport_width, viewport_height)
            self._next_model_json = json_str
            self._next_scroll_ms  = dur

    @Slot(float, float, float, result="QVariant")
    def hit_test(self, click_x: float, click_y: float, scroll_offset: float) -> dict:
        """Return detail-view data for the tile at (click_x, click_y)."""
        for tile in self._current_tiles:
            adj_x = tile["x"] - scroll_offset
            if (adj_x <= click_x <= adj_x + tile["w"]
                    and tile["y"] <= click_y <= tile["y"] + tile["h"]):
                film = self._film_pool.get(tile["film_id"])
                if film:
                    display = film["display_path"] or film["poster_path"]
                    return {
                        "imagePath":  Path(display).as_uri() if display else "",
                        "xmlPath":    film["xml_path"],
                        "moviePath":  film["video_path"],
                    }
        return {}

    @Slot()
    def on_cycle_complete(self) -> None:
        # Hero slot rotation is now handled inside _do_build; kept as a no-op
        # so existing QML call sites don't break.
        pass

    # -- QML property -----------------------------------------------------------

    @Property(int, notify=scrollDurationChanged)
    def scroll_duration_ms(self) -> int:
        return self._scroll_duration_ms
