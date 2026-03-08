from project_paths import paths
import json
from json_safe import safe_json_write

CONFIG_PATH = paths["menu"]  # You can choose menu_json_path or a separate config.json

# Load the preferred player
def load_config():
    if CONFIG_PATH.exists():
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"PreferredPlayer": 0}  # default to first option

def save_config(config):
    safe_json_write(CONFIG_PATH, config)
