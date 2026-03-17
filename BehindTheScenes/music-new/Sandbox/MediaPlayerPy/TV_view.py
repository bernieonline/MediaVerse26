"""
TV_view.py
TV series data backend — exposed to QML as context property "tvViewModel".

Hierarchy built at load time:
    series_name → season_num → [episode_dict, ...]

Each episode dict:
    ep_num, ep_end, ep_name, image_uri, video_path,
    xml_path, last_played, progress_pct
"""

from __future__ import annotations

import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

from PySide6.QtCore import QObject, Slot

from project_paths import (
    server_manifest_v2,
    local_display_v2,
    coll_data as xml_collection_data,
)

# ── Title parsing ────────────────────────────────────────────────────────────

# Range episode (checked first — most specific):
# "Series.S03E01-3.Title" — one file covering merged episodes
_RANGE_RE = re.compile(
    r'^(.+?)\.S(\d{1,2})E(\d{2,3})-(\d+)(?:\.(.*))?$', re.IGNORECASE
)

# Primary: "Series.S01E01.Episode_Name"
_PRIMARY_RE = re.compile(
    r'^(.+?)\.S(\d{2})E(\d{2,3})(?:\.(.*))?$', re.IGNORECASE
)

# Extended patterns tried in order when primary fails
_EXTENDED = [
    re.compile(r'^(.+?)\s+S(\d{2})E(\d{2,3})(?:\s+(.*))?$', re.IGNORECASE),  # space sep
    re.compile(r'^(.+?)\.S(\d{1})E(\d{2,3})(?:\.(.*))?$',   re.IGNORECASE),  # single-digit season
]


_APOSTROPHE_RE = re.compile(r"'([A-Z])")   # fix title() artefact: 's → 's


def _normalise_series(raw: str) -> str:
    """Dots→spaces, collapse whitespace, title-case, fix post-apostrophe caps."""
    name = " ".join(raw.replace(".", " ").split())   # collapse multiple spaces
    name = name.title()
    name = _APOSTROPHE_RE.sub(lambda m: "'" + m.group(1).lower(), name)
    return name


def _parse_title(title: str) -> dict | None:
    """Parse a manifest title into series/season/episode components.
    Returns None for any title that does not match — caller skips it silently."""
    # Strip video extension if present so regex anchors work cleanly
    stem = title
    for ext in (".mp4", ".mkv", ".avi", ".m4v"):
        if stem.lower().endswith(ext):
            stem = stem[: -len(ext)]
            break

    # Range episode — check first
    m = _RANGE_RE.match(stem)
    if m:
        series_raw, s_num, e_start, e_end, ep_name = m.groups()
        return {
            "series":  _normalise_series(series_raw),
            "season":  int(s_num),
            "episode": int(e_start),       # sort key — start of range
            "ep_end":  int(e_end),         # end of range for display "Ep 1–3"
            "ep_name": (ep_name or "").replace(".", " ").strip(),
        }

    # Single episode — primary then extended
    m = _PRIMARY_RE.match(stem)
    if not m:
        for pat in _EXTENDED:
            m = pat.match(stem)
            if m:
                break
    if not m:
        return None

    series_raw, s_num, e_num, ep_name = m.groups()
    return {
        "series":  _normalise_series(series_raw),
        "season":  int(s_num),
        "episode": int(e_num),
        "ep_end":  None,
        "ep_name": (ep_name or "").replace(".", " ").strip(),
    }


# ── XML sidecar reader ───────────────────────────────────────────────────────

def _read_sidecar(xml_path: str) -> dict:
    """Extract last_played and progress_pct from a JRiver XML sidecar.
    Best-effort — returns empty dict on any failure."""
    if not xml_path:
        return {}
    try:
        tree = ET.parse(xml_path)
        fields = {
            f.get("Name", ""): (f.text or "")
            for f in tree.getroot().iter("Field")
        }
        last_played = fields.get("Date Last Played", "")
        num_plays   = int(fields.get("Number Plays", 0) or 0)
        duration    = float(fields.get("Duration", 0) or 0)
        position    = float(fields.get("Current Position", 0) or 0)

        if duration > 0 and position > 0:
            progress_pct = min(100, round(position / duration * 100))
        elif num_plays > 0:
            progress_pct = 100
        else:
            progress_pct = 0

        return {"last_played": last_played, "progress_pct": progress_pct}
    except Exception:
        return {}


# ── ViewModel ────────────────────────────────────────────────────────────────

class TVViewModel(QObject):
    """
    QML context property: "tvViewModel"

    Typical QML usage:
        var series  = JSON.parse(tvViewModel.get_series_list())
        var seasons = JSON.parse(tvViewModel.get_seasons("Yellowstone"))
        var eps     = JSON.parse(tvViewModel.get_episodes("Yellowstone", 1))
    """

    def __init__(self, parent=None):
        super().__init__(parent)
        # _hierarchy[series_name][season_num] = [episode_dict, ...]
        self._hierarchy: dict[str, dict[int, list[dict]]] = {}
        # xml_collection_data keyed by video-path stem for fast lookup
        self._xml_coll: dict[str, dict] = {}
        # preloaded XML cache: series_name → { xml_path: {description, actors} }
        self._series_xml_cache: dict[str, dict] = {}
        self._load()

    # ── Startup loading ──────────────────────────────────────────────────────

    def _load(self) -> None:
        self._load_xml_collection()
        self._build_hierarchy()

    def _load_xml_collection(self) -> None:
        """Index xml_collection_data.json by filename stem for O(1) lookup."""
        path = Path(xml_collection_data)
        if not path.exists():
            print(f"⚠️  [TV] xml_collection_data not found: {path}")
            return
        try:
            with open(path, "r", encoding="utf-8") as fh:
                items = json.load(fh)
            for item in items:
                fn = item.get("Filename", "")
                if fn:
                    self._xml_coll[Path(fn).stem] = item
            print(f"✅ [TV] xml_collection_data: {len(self._xml_coll)} records indexed")
        except Exception as exc:
            print(f"❌ [TV] xml_collection_data load error: {exc}")

    def _build_hierarchy(self) -> None:
        """Read manifest → parse TV titles → build series/season/episode tree."""
        manifest_path = Path(server_manifest_v2)
        if not manifest_path.exists():
            print(f"⚠️  [TV] Manifest not found: {manifest_path}")
            return
        try:
            with open(manifest_path, "r", encoding="utf-8") as fh:
                raw = json.load(fh)
        except Exception as exc:
            print(f"❌ [TV] Manifest load error: {exc}")
            return

        records      = raw if isinstance(raw, list) else raw.get("items", [])
        display_root = Path(local_display_v2)
        parsed_n     = 0
        skipped_n    = 0

        for rec in records:
            if rec.get("metadata", {}).get("type") != "tv":
                continue

            title  = rec.get("title", "")
            parsed = _parse_title(title)
            if not parsed:
                skipped_n += 1
                continue

            # Resolve display image — flat cache folder, filename only
            cache     = rec.get("cache", {})
            shared    = rec.get("shared", {})
            rel_disp  = cache.get("display") or cache.get("relative_display") or ""
            disp_name = Path(rel_disp).name if rel_disp else (Path(title).stem + ".jpg")
            img_path  = display_root / disp_name
            if not img_path.exists():
                img_path = display_root / (Path(title).stem + ".jpg")
            image_uri = img_path.as_uri() if img_path.exists() else ""

            episode = {
                "ep_num":      parsed["episode"],
                "ep_end":      parsed["ep_end"],
                "ep_name":     parsed["ep_name"],
                "image_uri":   image_uri,
                "video_path":  shared.get("video", ""),
                "xml_path":    shared.get("xml", ""),
                # Playback data fetched live in get_episodes() from sidecar
                "last_played":   "",
                "progress_pct":  0,
            }

            series = parsed["series"]
            season = parsed["season"]
            self._hierarchy.setdefault(series, {}).setdefault(season, []).append(episode)
            parsed_n += 1

        # Sort episodes within each season by episode start number
        for series_data in self._hierarchy.values():
            for season_eps in series_data.values():
                season_eps.sort(key=lambda e: e["ep_num"])

        print(
            f"✅ [TV] {len(self._hierarchy)} series | "
            f"{parsed_n} episodes parsed | {skipped_n} skipped"
        )

    # ── Image helpers ────────────────────────────────────────────────────────

    def _season_image(self, series: str, season: int) -> str:
        """Image URI of the first (lowest-numbered) episode in the season."""
        eps = self._hierarchy.get(series, {}).get(season, [])
        return eps[0]["image_uri"] if eps else ""

    def _series_image(self, series: str) -> str:
        """Image URI of S01E01 (or lowest available season/episode)."""
        seasons = self._hierarchy.get(series, {})
        if not seasons:
            return ""
        return self._season_image(series, min(seasons.keys()))

    # ── QML slots ────────────────────────────────────────────────────────────

    @Slot(result=str)
    def get_series_list(self) -> str:
        """Returns JSON array: [{name, image_uri, season_count, episode_count}, ...]
        Sorted alphabetically by series name."""
        result = []
        for name, seasons in sorted(self._hierarchy.items()):
            ep_count = sum(len(eps) for eps in seasons.values())
            result.append({
                "name":          name,
                "image_uri":     self._series_image(name),
                "season_count":  len(seasons),
                "episode_count": ep_count,
            })
        return json.dumps(result)

    @Slot(str, result=str)
    def get_seasons(self, series_name: str) -> str:
        """Returns JSON array: [{season_num, image_uri, episode_count}, ...]
        Sorted by season number."""
        seasons = self._hierarchy.get(series_name, {})
        result = [
            {
                "season_num":    sn,
                "image_uri":     self._season_image(series_name, sn),
                "episode_count": len(seasons[sn]),
            }
            for sn in sorted(seasons.keys())
        ]
        return json.dumps(result)

    @Slot(str, int, result=str)
    def get_episodes(self, series_name: str, season: int) -> str:
        """Returns JSON array sorted by ep_num:
        [{ep_num, ep_end, ep_name, image_uri, video_path,
          xml_path, last_played, progress_pct}, ...]
        Reads XML sidecar live for up-to-date playback data."""
        eps = self._hierarchy.get(series_name, {}).get(season, [])
        result = []
        for ep in eps:
            sidecar = _read_sidecar(ep["xml_path"])
            result.append({
                "ep_num":       ep["ep_num"],
                "ep_end":       ep["ep_end"],
                "ep_name":      ep["ep_name"],
                "image_uri":    ep["image_uri"],
                "video_path":   ep["video_path"],
                "xml_path":     ep["xml_path"],
                "last_played":  sidecar.get("last_played", ""),
                "progress_pct": sidecar.get("progress_pct", 0),
            })
        return json.dumps(result)

    @Slot(str, result=str)
    def get_episode_detail(self, xml_path: str) -> str:
        """Returns JSON: {description, actors, director, genre, year, keywords}
        Reads XML sidecar directly — xml_collection_data does not hold Description."""
        if not xml_path:
            return json.dumps({})
        try:
            tree   = ET.parse(xml_path)
            fields = {
                f.get("Name", ""): (f.text or "")
                for f in tree.getroot().iter("Field")
            }
            return json.dumps({
                "description": fields.get("Description", "") or fields.get("Plot", ""),
                "actors":      [a.strip() for a in fields.get("Actors", "").split(";") if a.strip()],
                "director":    fields.get("Director", ""),
                "genre":       fields.get("Genre", ""),
                "year":        fields.get("Year", ""),
                "keywords":    fields.get("Keywords", ""),
            })
        except Exception:
            return json.dumps({})

    @Slot(str, result=str)
    def preload_series_xml(self, series_name: str) -> str:
        """Pre-read all XML sidecars for every episode in a series.
        Returns JSON: { xml_path: { description: str, actors: [str, ...] }, ... }
        Result is cached so repeated calls for the same series are instant."""
        if series_name in self._series_xml_cache:
            return json.dumps(self._series_xml_cache[series_name])

        seasons = self._hierarchy.get(series_name, {})
        cache: dict[str, dict] = {}

        for eps in seasons.values():
            for ep in eps:
                xml_path = ep.get("xml_path", "")
                if not xml_path or xml_path in cache:
                    continue
                try:
                    tree = ET.parse(xml_path)
                    fields = {
                        f.get("Name", ""): (f.text or "")
                        for f in tree.getroot().iter("Field")
                    }
                    actors_raw = fields.get("Actors", "")
                    cache[xml_path] = {
                        "description": fields.get("Description", "") or fields.get("Plot", ""),
                        "actors": [a.strip() for a in actors_raw.split(";") if a.strip()],
                    }
                except Exception:
                    cache[xml_path] = {"description": "", "actors": []}

        self._series_xml_cache[series_name] = cache
        print(f"✅ [TV] XML preloaded: {len(cache)} episodes for '{series_name}'")
        return json.dumps(cache)
