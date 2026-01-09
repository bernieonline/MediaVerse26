# Playback/config_loader.py

import json
from project_paths import config_json

def load_config():
    with open(config_json, "r", encoding="utf-8") as f:
        return json.load(f)

_config = load_config()

def get_jriver_port() -> int:
    return int(_config["PlayerPaths"]["JRiverPort"])

def get_jriver_access_key() -> str:
    return "fAeKZS"