from project_paths import paths
from json_safe import safe_json_write, safe_json_read

CONFIG_PATH = paths["menu"]  # You can choose menu_json_path or a separate config.json

# Load the preferred player
def load_config():
    return safe_json_read(CONFIG_PATH, "config")

def save_config(config):
    safe_json_write(CONFIG_PATH, config)
