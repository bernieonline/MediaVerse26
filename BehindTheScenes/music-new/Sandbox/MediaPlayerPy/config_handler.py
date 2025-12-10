from project_paths import paths
import json

CONFIG_PATH = paths["menu"]  # You can choose menu_json_path or a separate config.json

# Load the preferred player
def load_config():
    if CONFIG_PATH.exists():
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"PreferredPlayer": 0}  # default to first option

def save_config(config):
    with open(CONFIG_PATH, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2)
