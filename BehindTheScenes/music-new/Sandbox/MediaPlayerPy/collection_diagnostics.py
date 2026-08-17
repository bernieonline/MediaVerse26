"""
Collection Diagnostics Utility
Traces filtering logic step-by-step to explain why a movie is
included in or excluded from a Quick or Architect collection.
"""

import os
from pathlib import Path
from PySide6.QtCore import QObject, Slot
from json_safe import safe_json_read
from project_paths import paths


class CollectionDiagnostics(QObject):
    """Provides diagnostic slots for the QML SettingsPanel Diagnostics tab."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.master_cache = safe_json_read(paths["xmldate"], schema_type="xml_collection_data")
        self.collections = safe_json_read(paths["movies_coll_v2"], schema_type="collections")

    # ----------------------------------------------------------------
    # Slot 1: collection names for a given type
    # ----------------------------------------------------------------
    @Slot(str, result=list)
    def get_collection_names(self, collection_type):
        self.collections = safe_json_read(paths["movies_coll_v2"], schema_type="collections")
        names = []
        for rec in self.collections:
            if collection_type == "Architect":
                if rec.get("type") == "Architect":
                    names.append(rec.get("name", ""))
            else:  # Quick
                if rec.get("type") != "Architect":
                    names.append(rec.get("name", ""))
        return sorted(set(n for n in names if n))

    # ----------------------------------------------------------------
    # Slot 2: movie name suggestions for autocomplete
    # ----------------------------------------------------------------
    @Slot(str, result=list)
    def get_movie_suggestions(self, partial_text):
        if not partial_text or len(partial_text) < 2:
            return []
        needle = partial_text.lower()
        results = []
        for item in self.master_cache:
            name = item.get("Name", "")
            filename = item.get("Filename", "")
            if needle in name.lower() or needle in filename.lower():
                year = item.get("Year", "")
                label = f"{name} ({year})" if year else name
                if label not in results:
                    results.append(label)
                if len(results) >= 15:
                    break
        return results

    # ----------------------------------------------------------------
    # Slot 3: main diagnostic
    # ----------------------------------------------------------------
    @Slot(str, str, str, str, result=str)
    def diagnose(self, collection_type, collection_name, movie_search, search_mode):
        self.collections = safe_json_read(paths["movies_coll_v2"], schema_type="collections")
        self.master_cache = safe_json_read(paths["xmldate"], schema_type="xml_collection_data")
        lines = []
        lines.append("=" * 60)
        lines.append("COLLECTION DIAGNOSTICS REPORT")
        lines.append("=" * 60)
        lines.append(f"Type:       {collection_type}")
        lines.append(f"Collection: {collection_name}")
        lines.append(f"Movie:      {movie_search}")
        lines.append(f"Mode:       {search_mode}")
        lines.append("")

        # --- Find the movie ---
        movie = self._find_movie(movie_search)
        if not movie:
            lines.append("[!!] Movie NOT FOUND in master cache (xml_collection_data.json)")
            lines.append(f"     Searched for: '{movie_search}'")
            lines.append("")
            lines.append("Possible causes:")
            lines.append("  - Movie name misspelled")
            lines.append("  - Movie not in library / XML data not rebuilt")
            self._append_gotcha_checks(lines, None)
            return "\n".join(lines)

        lines.append("[OK] Movie found in master cache")
        self._append_movie_data(lines, movie)
        lines.append("")

        # --- Find the collection ---
        coll = self._find_collection(collection_type, collection_name)
        if not coll:
            lines.append(f"[!!] Collection '{collection_name}' NOT FOUND (type={collection_type})")
            self._append_gotcha_checks(lines, movie)
            return "\n".join(lines)

        lines.append(f"[OK] Collection '{collection_name}' found")
        lines.append("")

        # --- Run type-specific trace ---
        if collection_type == "Architect":
            self._trace_architect(lines, coll, movie)
        else:
            self._trace_quick(lines, coll, movie)

        # --- Gotcha checks ---
        self._append_gotcha_checks(lines, movie)

        return "\n".join(lines)

    # ================================================================
    # QUICK COLLECTION TRACE
    # ================================================================
    def _trace_quick(self, lines, coll, movie):
        lines.append("-" * 40)
        lines.append("QUICK COLLECTION FILTER TRACE")
        lines.append("-" * 40)

        # TV skip check — only Media Sub Type matters, not Season
        # (Season can be incorrectly set on movies in JRiver metadata)
        sub_type = movie.get("Media Sub Type", "")
        if sub_type.lower() == "tv show":
            lines.append("[EXCLUDED] TV skip triggered:")
            lines.append(f"  Media Sub Type = '{sub_type}'")
            lines.append("  Quick collections skip TV Show records.")
            lines.append("")
            return

        lines.append("[OK] Not a TV Show (passes TV skip)")
        lines.append("")

        criteria = coll.get("rules", {})
        if not isinstance(criteria, dict):
            lines.append("[WARN] Collection rules is not a dict -- cannot trace Quick logic")
            return

        if not criteria:
            lines.append("[INFO] Collection has empty rules -- all movies match")
            return

        all_match = True
        for key, value in criteria.items():
            lines.append(f"  Criterion: {key} = '{value}'")

            if key == "Decade":
                target_prefix = str(value).strip()[:3]
                item_year = str(movie.get("Year") or movie.get("year") or "").strip()
                match = item_year.startswith(target_prefix)
                lines.append(f"    Target prefix: '{target_prefix}x'")
                lines.append(f"    Movie year:    '{item_year}'")
                lines.append(f"    startswith:    {match}")
            else:
                item_val = str(movie.get(key, ""))
                match = str(value).lower() in item_val.lower()
                lines.append(f"    Movie field:   '{item_val}'")
                lines.append(f"    substring in:  {match}")

            status = "MATCH" if match else "MISMATCH"
            lines.append(f"    Result: {status}")
            lines.append("")

            if not match:
                all_match = False

        lines.append("-" * 40)
        if all_match:
            lines.append("VERDICT: Movie MATCHES all criteria -> INCLUDED")
        else:
            lines.append("VERDICT: Movie FAILS one or more criteria -> EXCLUDED")
        lines.append("")

    # ================================================================
    # ARCHITECT COLLECTION TRACE
    # ================================================================
    def _trace_architect(self, lines, coll, movie):
        lines.append("-" * 40)
        lines.append("ARCHITECT COLLECTION PANEL TRACE")
        lines.append("-" * 40)

        rules = coll.get("rules", [])
        if not isinstance(rules, list):
            lines.append("[WARN] Architect rules is not a list")
            return

        movie_basename = os.path.basename(movie.get("Filename", ""))
        lines.append(f"Movie basename: '{movie_basename}'")
        lines.append("")

        sorted_rules = sorted(rules, key=lambda r: r.get("panelIndex", 0))
        working_foundation = []

        for rule in sorted_rules:
            panel_idx = rule.get("panelIndex", 0)
            mode = rule.get("mode", "")
            gate = rule.get("gate", "NONE")
            checked = rule.get("checked", False)

            lines.append(f"  Panel {panel_idx}: mode={mode}, gate={gate}, checked(narrowing)={checked}")

            panel_ids = self._generate_panel_list(rule)
            movie_in_panel = movie_basename in panel_ids

            lines.append(f"    Panel produced {len(panel_ids)} files")
            lines.append(f"    Movie in panel results: {movie_in_panel}")

            # Apply gate logic (mirrors Architect_Summary.apply_logic)
            if panel_idx == 0 or not working_foundation:
                working_foundation = list(set(panel_ids))
            elif gate == "NOT":
                working_foundation = list(set(working_foundation) - set(panel_ids))
            elif checked:  # narrowing = AND/intersection
                working_foundation = list(set(working_foundation) & set(panel_ids))
            else:  # union = OR
                working_foundation = list(set(working_foundation) | set(panel_ids))

            in_foundation = movie_basename in working_foundation
            lines.append(f"    After gate: foundation has {len(working_foundation)} files")
            lines.append(f"    Movie in foundation: {in_foundation}")
            lines.append("")

        lines.append("-" * 40)
        final_in = movie_basename in working_foundation
        if final_in:
            lines.append("VERDICT: Movie survived all panels -> INCLUDED")
        else:
            lines.append("VERDICT: Movie dropped from foundation -> EXCLUDED")
            # Find where it dropped
            self._find_drop_point(lines, sorted_rules, movie_basename)
        lines.append("")

    def _find_drop_point(self, lines, sorted_rules, movie_basename):
        """Identify which panel caused the movie to drop."""
        working = []
        for rule in sorted_rules:
            panel_idx = rule.get("panelIndex", 0)
            gate = rule.get("gate", "NONE")
            checked = rule.get("checked", False)
            panel_ids = self._generate_panel_list(rule)

            was_in = movie_basename in working if working else False

            if panel_idx == 0 or not working:
                working = list(set(panel_ids))
            elif gate == "NOT":
                working = list(set(working) - set(panel_ids))
            elif checked:
                working = list(set(working) & set(panel_ids))
            else:
                working = list(set(working) | set(panel_ids))

            is_in = movie_basename in working
            if was_in and not is_in:
                lines.append(f"  -> Dropped at Panel {panel_idx} (gate={gate}, narrowing={checked})")
                return
            if panel_idx == 0 and not is_in:
                lines.append(f"  -> Never entered foundation (not in Panel 0)")
                return

    def _generate_panel_list(self, rule):
        """Replicate architect_controller._generate_panel_list for diagnostics."""
        mode = rule.get("mode", "")
        data = rule.get("data", {})
        result = []

        if mode == "Folder":
            folder = data.get("folder", "").strip().lower()
            result = [
                os.path.basename(item["Filename"])
                for item in self.master_cache
                if item.get("Filename") and (
                    f"\\{folder}\\" in item["Filename"].lower() or
                    f"/{folder}/" in item["Filename"].lower()
                )
            ]

        elif mode == "Category":
            cat = data.get("category", "")
            val = data.get("value", "")
            val_low = val.lower()
            key_map = {
                "Genres": ["Genre"],
                "Actors": ["Actors"],
                "Directors": ["Director"],
                "Decade": ["Year"],
            }
            search_keys = key_map.get(cat, [cat])

            for item in self.master_cache:
                if item.get("Media Sub Type") == "TV Show":
                    continue
                match_found = False
                for k in search_keys:
                    raw = item.get(k, "")
                    if cat == "Decade":
                        if str(raw).startswith(str(val)[:3]):
                            match_found = True
                    elif isinstance(raw, list):
                        if any(v.strip().lower() == val_low for v in raw):
                            match_found = True
                    elif isinstance(raw, str):
                        if val_low in [p.strip().lower() for p in raw.split(";")]:
                            match_found = True
                    if match_found:
                        break
                if match_found:
                    fpath = item.get("Filename", "")
                    if fpath:
                        result.append(os.path.basename(fpath))

        elif mode == "Files":
            file_list = data.get("files", []) or data.get("list", [])
            result = [os.path.basename(f) for f in file_list if f]

        return result

    # ================================================================
    # HELPERS
    # ================================================================
    def _find_movie(self, movie_search):
        """Find a movie in master_cache by name (with optional year suffix)."""
        # Strip year suffix if present: "Rocky (1976)" -> "Rocky"
        search = movie_search.strip()
        search_name = search
        if search.endswith(")") and "(" in search:
            search_name = search[:search.rfind("(")].strip()

        # Exact name match first
        for item in self.master_cache:
            if item.get("Name", "") == search_name:
                return item

        # Case-insensitive match
        needle = search_name.lower()
        for item in self.master_cache:
            if item.get("Name", "").lower() == needle:
                return item

        # Substring match as fallback
        for item in self.master_cache:
            if needle in item.get("Name", "").lower():
                return item

        return None

    def _find_collection(self, collection_type, collection_name):
        """Find a collection record by type and name."""
        for rec in self.collections:
            if collection_type == "Architect":
                if rec.get("type") == "Architect" and rec.get("name") == collection_name:
                    return rec
            else:
                if rec.get("type") != "Architect" and rec.get("name") == collection_name:
                    return rec
        return None

    def _append_movie_data(self, lines, movie):
        """Show relevant raw data fields for the movie."""
        lines.append("  Raw movie data:")
        for field in ["Name", "Year", "Media Sub Type", "Season", "Genre",
                      "Actors", "Director", "Keywords", "Filename"]:
            val = movie.get(field, "")
            if isinstance(val, list):
                val = "; ".join(val)
            lines.append(f"    {field:16s} = {val}")

    def _append_gotcha_checks(self, lines, movie):
        """Common gotcha checklist -- always shown."""
        lines.append("")
        lines.append("=" * 40)
        lines.append("COMMON GOTCHA CHECKLIST")
        lines.append("=" * 40)

        if movie is None:
            lines.append("  [ ] Movie not in master cache -- cannot run checks")
            return

        sub = movie.get("Media Sub Type", "")
        is_movie = sub == "Movie"
        lines.append(f"  [{'X' if is_movie else ' '}] Media Sub Type is 'Movie' (actual: '{sub}')")

        season = movie.get("Season", "")
        season_empty = not season
        lines.append(f"  [{'X' if season_empty else ' '}] Season field is empty (actual: '{season}')")

        year = str(movie.get("Year", "")).strip()
        year_ok = year.isdigit() and len(year) == 4
        lines.append(f"  [{'X' if year_ok else ' '}] Year is non-empty and numeric (actual: '{year}')")

        fn = movie.get("Filename", "")
        fn_ok = bool(fn)
        lines.append(f"  [{'X' if fn_ok else ' '}] Filename exists and is non-empty")

        lines.append(f"  [X] Movie exists in master cache")
