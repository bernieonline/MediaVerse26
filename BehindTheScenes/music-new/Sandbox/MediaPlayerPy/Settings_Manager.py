# settings_manager.py
import json
from PySide6.QtCore import QObject, Slot

class SettingsManager(QObject):
    def __init__(self, config_path):
        super().__init__()
        self.config_path = config_path

    @Slot(int)
    def update_preferred_player(self, index):
        """Update Preferred Player in config.json"""
        try:
            # Load existing config
            with open(self.config_path, "r", encoding="utf-8") as f:
                config = json.load(f)

            # Update value
            config["Preferred Player"] = index

            # Save back to file
            with open(self.config_path, "w", encoding="utf-8") as f:
                json.dump(config, f, indent=2)

            print(f"[INFO] Updated Preferred Player to {index} in {self.config_path}")

        except Exception as e:
            print(f"[ERROR] Could not update config: {e}")