import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import quote
from project_paths import paths

def build_dna_bank():
    source_manifest = paths.get("server_manifest_v2")
    output_json = paths.get("xmldate")

    if not source_manifest or not source_manifest.exists():
        return False

    print("🚀 Rebuilding DNA Bank using legacy metadata logic...")
    
    try:
        with open(source_manifest, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        raw_items = data.get("items", [])
        enriched_data = []

        for item in raw_items:
            shared = item.get("shared", {})
            cache_info = item.get("cache", {})
            v_str, x_str = shared.get("video"), shared.get("xml")
            
            if v_str and x_str:
                video_path = Path(v_str)
                xml_path = Path(x_str)

                # 1. Year Extraction (Matches your old regex)
                year_match = re.search(r"\((\d{4})\)", video_path.name)
                extracted_year = year_match.group(1) if year_match else ""

                # 2. Image Path Logic (Restoring URL prefixes and encoding)
                rel_thumb = cache_info.get("relative_thumb", "")
                local_img = paths["local_thumb_v2"] / rel_thumb
                server_img = f"file:///W:/MediaVerse/cache/images/thumb/{quote(rel_thumb)}"
                final_thumb = f"file:///{local_img}" if local_img.exists() else server_img

                # 3. Base Structure
                entry = {
                    "Filename": str(video_path),
                    "Year": extracted_year,
                    "Genre": "",
                    "Keywords": "",
                    "Actors": [],
                    "Director": "Unknown",
                    "Name": video_path.stem.split(' (')[0],
                    "Series": "",
                    "Thumb_URL": str(final_thumb).replace("\\", "/"),
                    "Display_URL": str(final_thumb).replace("thumb", "display").replace("\\", "/"),
                    "IMDb ID": "",
                    "Media Sub Type": "Movie",
                    "Season": "",
                    "Episode": "",
                    "TheTVDB Series ID": "",
                    "TheMovieDB Series ID": ""
                }

                # 4. Deep XML Parse
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
                            # Restoring your specific limit of 5 actors
                            actor_list = [a.strip() for a in actors_raw.split(";") if a.strip()]
                            entry["Actors"] = actor_list[:5]

                    except Exception as e:
                        print(f"⚠️ XML Error for {video_path.name}: {e}")

                enriched_data.append(entry)

        # 5. Save with Indent 4 to match original readability
        output_json.parent.mkdir(parents=True, exist_ok=True)
        with open(output_json, 'w', encoding='utf-8') as f:
            json.dump(enriched_data, f, indent=4)
        
        print(f"✅ DNA Bank Created: {len(enriched_data)} items saved.")
        return True

    except Exception as e:
        print(f"❌ Critical Build Error: {e}")
        return False