import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from project_paths import paths

def build_dna_bank():
    source_manifest = paths.get("server_manifest_v2")
    output_json = paths.get("xmldate")

    if not source_manifest or not source_manifest.exists():
        return False

    print("🚀 Rebuilding DNA Bank - Matching Original Record Spec...")
    
    try:
        with open(source_manifest, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        raw_items = data.get("items", [])
        enriched_data = []

        for item in raw_items:
            shared = item.get("shared", {})
            v_str, x_str = shared.get("video"), shared.get("xml")
            
            if v_str and x_str:
                video_path = Path(v_str)
                xml_path = Path(x_str)

                # 1. Year Extraction (Original logic)
                year_match = re.search(r"\((\d{4})\)", video_path.name)
                extracted_year = year_match.group(1) if year_match else ""

                # 2. Replicate the Exact Key Structure (No URLs)
                entry = {
                    "Filename": v_str,
                    "Year": extracted_year,
                    "Genre": "",
                    "Keywords": "",
                    "Actors": [],
                    "Director": "Unknown",
                    "Name": video_path.stem.split(' (')[0],
                    "Series": "",
                    "IMDb ID": "",
                    "Media Sub Type": "Movie",
                    "Season": "",
                    "Episode": "",
                    "TheTVDB Series ID": "",
                    "TheMovieDB Series ID": ""
                }

                # 3. Deep XML Parse to fill the empty keys
                if xml_path.exists():
                    try:
                        tree = ET.parse(xml_path)
                        root = tree.getroot()

                        def get_field(name):
                            node = root.find(f".//Field[@Name='{name}']")
                            return node.text if node is not None and node.text else ""

                        entry.update({
                            "Genre": get_field("Genre"),
                            "Keywords": get_field("Keywords"),
                            "Director": get_field("Director") or "Unknown",
                            "IMDb ID": get_field("IMDb ID"),
                            "Media Sub Type": get_field("Media Sub Type") or "Movie",
                            "Series": get_field("Series"),
                            "Season": get_field("Season"),
                            "Episode": get_field("Episode"),
                            "TheTVDB Series ID": get_field("TheTVDB Series ID"),
                            "TheMovieDB Series ID": get_field("TheMovieDB Series ID")
                        })

                        actors_raw = get_field("Actors")
                        if actors_raw:
                            # Replicate the 5-actor limit from your old code
                            actor_list = [a.strip() for a in actors_raw.split(";") if a.strip()]
                            entry["Actors"] = actor_list[:5]

                    except Exception as e:
                        print(f"⚠️ XML Parse Error for {video_path.name}: {e}")

                enriched_data.append(entry)

        # 4. Save with Indent 4 to exactly match the original file's look
        output_json.parent.mkdir(parents=True, exist_ok=True)
        with open(output_json, 'w', encoding='utf-8') as f:
            json.dump(enriched_data, f, indent=4)
        
        print(f"✅ DNA Bank Replicated: {len(enriched_data)} items saved.")
        return True

    except Exception as e:
        print(f"❌ Replication Error: {e}")
        return False