import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from project_paths import paths
from json_safe import safe_json_write, safe_json_read


def build_dna_bank() -> dict:
    """
    Build xml_collection_data.json from manifest.json sidecar XMLs.

    Pipeline:
      1. Read manifest, count expected movie records
      2. Parse each XML sidecar into enriched records (written to staging file)
      3. Validate staging file:
           - JSON parses cleanly
           - Record count matches manifest movie count
           - At least 80% of previous record count (protects against server-down blank builds)
           - Metadata quality: <10% of records have all-blank Genre+Actors+Director
      4. If all tests pass: atomic replace live file via safe_json_write
      5. Return a result dict with counts and pass/fail flags

    Returns dict with keys:
      success (bool), accepted (int), manifest_movie_count (int),
      previous_count (int), blank_metadata_count (int), error (str or None)
    """
    source_manifest = paths.get("server_manifest_v2")
    output_json     = paths.get("xmldate")
    staging_json    = paths.get("xmldate_b")

    result = {
        "success":             False,
        "accepted":            0,
        "manifest_movie_count": 0,
        "previous_count":      0,
        "blank_metadata_count": 0,
        "xml_parse_errors":    0,
        "error":               None,
    }

    if not source_manifest or not source_manifest.exists():
        result["error"] = "Manifest not found"
        print(f"❌ [XMLCollectionBuilder] {result['error']}: {source_manifest}")
        return result

    # --- 1. Read manifest -------------------------------------------------
    try:
        manifest = safe_json_read(source_manifest, "manifest")
        raw_items = manifest.get("items", [])
    except Exception as e:
        result["error"] = f"Manifest read failed: {e}"
        print(f"❌ [XMLCollectionBuilder] {result['error']}")
        return result

    # DVD items have type=="movie" but video==null — excluded from DNA bank by design
    movie_items = [
        i for i in raw_items
        if i.get("metadata", {}).get("type") == "movie"
        and i.get("shared", {}).get("video")
    ]
    result["manifest_movie_count"] = len(movie_items)

    # --- 2. Record previous live file count (for 80% guard) ---------------
    if output_json and output_json.exists():
        try:
            prev = safe_json_read(output_json, "xml_collection_data")
            result["previous_count"] = len(prev)
        except Exception:
            result["previous_count"] = 0

    print(f"🚀 Rebuilding xml_collection_data DNA Bank - Matching Original Record Spec...")

    # --- 3. Build enriched records ----------------------------------------
    enriched_data = []
    xml_parse_errors = 0

    for item in movie_items:
        shared = item.get("shared", {})
        v_str, x_str = shared.get("video"), shared.get("xml")

        if not v_str:
            continue

        video_path = Path(v_str)
        year_match = re.search(r"\((\d{4})\)", video_path.name)

        entry = {
            "Filename":           v_str,
            "Year":               year_match.group(1) if year_match else "",
            "Genre":              "",
            "Keywords":           "",
            "Actors":             [],
            "Director":           "Unknown",
            "Name":               video_path.stem.split(" (")[0],
            "Series":             "",
            "IMDb ID":            "",
            "Media Sub Type":     "Movie",
            "Season":             "",
            "Episode":            "",
            "TheTVDB Series ID":  "",
            "TheMovieDB Series ID": "",
        }

        if x_str:
            xml_path = Path(x_str)
            if xml_path.exists():
                try:
                    tree = ET.parse(xml_path)
                    root = tree.getroot()

                    def get_field(name):
                        node = root.find(f".//Field[@Name='{name}']")
                        return node.text if node is not None and node.text else ""

                    entry.update({
                        "Genre":              get_field("Genre"),
                        "Keywords":           get_field("Keywords"),
                        "Director":           get_field("Director") or "Unknown",
                        "IMDb ID":            get_field("IMDb ID"),
                        "Media Sub Type":     get_field("Media Sub Type") or "Movie",
                        "Series":             get_field("Series"),
                        "Season":             get_field("Season"),
                        "Episode":            get_field("Episode"),
                        "TheTVDB Series ID":  get_field("TheTVDB Series ID"),
                        "TheMovieDB Series ID": get_field("TheMovieDB Series ID"),
                    })

                    actors_raw = get_field("Actors")
                    if actors_raw:
                        entry["Actors"] = [a.strip() for a in actors_raw.split(";") if a.strip()][:5]

                except Exception as e:
                    xml_parse_errors += 1
                    print(f"⚠️ XML Parse Error for {video_path.name}: {e}")

        enriched_data.append(entry)

    result["xml_parse_errors"] = xml_parse_errors
    result["accepted"] = len(enriched_data)

    # --- 4. Write to staging file -----------------------------------------
    try:
        staging_json.parent.mkdir(parents=True, exist_ok=True)
        safe_json_write(staging_json, enriched_data)
    except Exception as e:
        result["error"] = f"Staging write failed: {e}"
        print(f"❌ [XMLCollectionBuilder] {result['error']}")
        return result

    # --- 5. Validate staging file -----------------------------------------

    # 5a. JSON integrity — re-read what was written
    try:
        validated = safe_json_read(staging_json, "xml_collection_data")
        if not isinstance(validated, list):
            raise ValueError("Staging file is not a list")
    except Exception as e:
        result["error"] = f"Staging JSON validation failed: {e}"
        print(f"❌ [XMLCollectionBuilder] {result['error']}")
        return result

    staged_count = len(validated)

    # 5b. Record count must match manifest movie count exactly
    if staged_count != result["manifest_movie_count"]:
        result["error"] = (
            f"Record count mismatch: staged {staged_count} "
            f"vs manifest movie count {result['manifest_movie_count']}"
        )
        print(f"❌ [XMLCollectionBuilder] {result['error']}")
        return result

    # 5c. 80% guard vs previous live file
    prev = result["previous_count"]
    if prev > 0 and staged_count < prev * 0.8:
        result["error"] = (
            f"80% guard: staged {staged_count} records "
            f"vs previous {prev} (less than 80%). Build refused."
        )
        print(f"❌ [XMLCollectionBuilder] {result['error']}")
        return result

    # 5d. Metadata quality — count records with all-blank Genre+Actors+Director
    blank_count = sum(
        1 for r in validated
        if not r.get("Genre") and not r.get("Actors") and r.get("Director") in ("Unknown", "", None)
    )
    result["blank_metadata_count"] = blank_count
    blank_pct = (blank_count / staged_count * 100) if staged_count else 0
    if blank_pct > 10:
        print(
            f"⚠️ [XMLCollectionBuilder] Metadata quality warning: "
            f"{blank_count}/{staged_count} records ({blank_pct:.1f}%) have blank Genre+Actors+Director. "
            f"XML files may be inaccessible. Build proceeding but review recommended."
        )

    # --- 6. All tests passed — atomic replace live file -------------------
    try:
        safe_json_write(output_json, validated)
    except Exception as e:
        result["error"] = f"Live file replace failed: {e}"
        print(f"❌ [XMLCollectionBuilder] {result['error']}")
        return result

    result["success"] = True
    print(
        f"✅ DNA Bank Replicated: {staged_count} items saved. "
        f"({xml_parse_errors} XML parse errors, {blank_count} blank metadata records)"
    )
    return result
