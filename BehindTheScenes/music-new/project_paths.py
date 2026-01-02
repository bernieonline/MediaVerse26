# project_paths.py
# Centralised path definitions for MediaVerse.
# Prevents hard‑coded paths and ensures portability across machines.
# main.py imports this file and exposes selected paths to QML.

from pathlib import Path

# ---------------------------------------------------------
# PROJECT ROOT (relative to this file)
# ---------------------------------------------------------
project_root = Path(__file__).resolve().parent
# This is 1 level down from BehindTheScenes in your structure.

# ---------------------------------------------------------
# COMMON PROJECT PATHS
# ---------------------------------------------------------
assets_path = project_root / "images"
py_path = project_root / "Sandbox" / "MediaPlayerPy"
qml_path = project_root / "Sandbox" / "MediaPlayerQML"
db_path = project_root / "dbMySql"
log_path = project_root / "application.log"
req_path = project_root / "requirements.txt"


# Local cache (old system)
thumb_dir = project_root / "cache" / "thumbnails"
display_dir = project_root / "cache" / "display"

# ---------------------------------------------------------
# FONT AWESOME PATH
# ---------------------------------------------------------
font_path = (
    project_root
    / "Fonts"
    / "fontawesome-free-7.1.0-desktop"
    / "webfonts"
    / "fa-solid-900.ttf"



)

#basic icons 
svg_solid_path = (
    project_root
    / "Fonts"
    / "fontawesome-free-7.1.0-desktop"
    / "svgs"
    / "solid"
)

# ---------------------------------------------------------
# JSON CONFIG FILES
# ---------------------------------------------------------
json_path = project_root / "Assets" / "XMLCategories.json"
menu_json_path = project_root / "Assets" / "MainMenu.json"
config_json = project_root / "Assets" / "Config.json"
coll_data = project_root / "Assets" / "xml_collection_data.json"
coll_json = project_root / "Assets" /"xml_collection.json"

#collections paths
collection_bg = project_root / "Assets" / "Collections.jpg"
movies_coll_v2 = Path(r"W:\MediaVerse\Collections\Movies_Collections_v2.json")
# ---------------------------------------------------------
# SERVER PATHS (MediaVerse V2)
# ---------------------------------------------------------
server_manifest_v2 = Path(r"W:\MediaVerse\manifest\manifest.json")




server_cache_root_v2 = Path(r"W:\MediaVerse\cache\images")
server_cache_thumb_v2 = server_cache_root_v2 / "thumb"
server_cache_display_v2 = server_cache_root_v2 / "display"
server_cache_carousel_v2 = server_cache_root_v2 / "carousel"

# ---------------------------------------------------------
# LOCAL PATHS (MediaVerse V2)
# ---------------------------------------------------------
local_manifest_v2 = project_root / "manifestV2"
local_cache_v2 = project_root / "cacheV2"
local_cache_images_v2 = local_cache_v2 / "images"

local_thumb_v2 = local_cache_images_v2 / "thumb"
local_display_v2 = local_cache_images_v2 / "display"
local_carousel_v2 = local_cache_images_v2 / "carousel"

# ---------------------------------------------------------
# PATH DICTIONARY (exposed to Python + QML)
# ---------------------------------------------------------
paths = {
    "project_root": project_root,
    "assets": assets_path,
    "qml": qml_path,
    "db": db_path,
    "log": log_path,
    "req": req_path,
    "json": json_path,
    "menu": menu_json_path,
    "thumbs": thumb_dir,
    "display": display_dir,
    "config": config_json,
    "fonts": font_path,
   "xmldate" : coll_data,
   "jsoncoll" : coll_json,


    # Server V2
    "server_manifest_v2": server_manifest_v2,
    "server_cache_root_v2": server_cache_root_v2,
    "server_cache_thumb_v2": server_cache_thumb_v2,
    "server_cache_display_v2": server_cache_display_v2,
    "server_cache_carousel_v2": server_cache_carousel_v2,

    # Local V2
    "local_manifest_v2": local_manifest_v2,
    "local_cache_v2": local_cache_v2,
    "local_cache_images_v2": local_cache_images_v2,
    "local_thumb_v2": local_thumb_v2,
    "local_display_v2": local_display_v2,
    "local_carousel_v2": local_carousel_v2,
    "collection_bg": collection_bg,
    "movies_coll_v2": movies_coll_v2,
    "svg_solid": svg_solid_path
    


}