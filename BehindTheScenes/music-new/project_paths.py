#this file is where we define the variables that will represent the relative pathnames of assets like images
#they are critical in order to avoid hard coded locations for eexample we can reference any file inside music-new without hard coding a path name
# we create the variables her
#we import into main.py or its equivalent
#main.py passes the variable pathnames into QML
#The variables can then be used inside QML as a pathname
#such as mypath.images.mylogo.png no drive letter involved
#This means that as long as i keep the file structure below BehindTheScenes I can use the same code in any location

#here is the logic as a reminder for me


# project_paths.py

from pathlib import Path

# Define project root relative to this file
project_root = Path(__file__).resolve().parent
#[1]is 1 level down from BehindTheScenes

# Common paths
assets_path = project_root / "images"
py_path = project_root / "Sandbox" / "MediaPlayerPy"
qml_path = project_root / "Sandbox" / "MediaPlayerQML"
db_path = project_root / "dbMySql"
log_path = project_root / "application.log"
req_path = project_root / "requirements.txt"

# Cache paths
thumb_dir = project_root / "cache" / "thumbnails"
display_dir = project_root / "cache" / "display"






# NEW: JSON categories file path
json_path = project_root / "Assets" / "XMLCategories.json"
menu_json_path = project_root / "Assets" / "MainMenu.json"
config_json = project_root / "Assets" / "Config.json"


#D:\PythonMusic\pythonproject2026\BehindTheScenes\music-new\requirements.txt

#- stead of juggling multiple variables (project_root, assets_path, etc.), you collect them into a single dictionary called paths.
# - Each key ("assets", "qml", etc.) is a label, and each value is the corresponding Path object.

# How to Use It in Python
# print(paths["assets"])   # prints the full path to your images folder


# Optional: expose as dictionary
paths = {
    "project_root": project_root,
    "assets": assets_path,
    "qml": qml_path,
    "db": db_path,
    "log": log_path,
    "req":req_path,
    "json": json_path,
    "menu": menu_json_path,
    "thumbs": thumb_dir,
    "display": display_dir,
    "config" : config_json

    }

server_cache_dir = Path(r"W:\MediaVerse\cache")
manifest_dir = Path(r"W:\MediaVerse\manifest")
paths.update({
    "manifest": manifest_dir,
    "server_cache": server_cache_dir
})




#using this inside main.py
#    from pathlib import Path

# Define project_root relative to this script
#not needed now its in this file
#    project_root = Path(__file__).resolve().parents[1] / "music-new"

# Define image folder path
#not needed now its in this file
# assets_path = project_root / "images"/

# Expose to QML
# engine.rootContext().setContextProperty("imageFolderPath", str(image_folder.as_posix()))

#there is no dot notation in QML but you can use concatenation to refer to a sub folder
#so perhaps set up the higher level folder in main.py then andd a further path like this
#Image {
    #source: imagesPath + "/icons/icons8-movie-liquid-glass-color/play.png"
#}
