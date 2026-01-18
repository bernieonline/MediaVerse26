import json
import subprocess
import os
from PySide6.QtCore import QObject, Slot, Signal

class SettingsManager(QObject):
    # Signals QML can connect to
    settingsChanged = Signal()
    videoLaunchRequested = Signal(str)

    def __init__(self, config_path, fileSystem, parent=None):
        super().__init__(parent)
        self.config_path = config_path
        self.fileSystem = fileSystem
        self._settings = {}
        # Assumes menu.json is in the same folder as config.json
        self.menu_path = os.path.join(os.path.dirname(self.config_path), "menu.json")
        self.load_settings(emit_signal=False)

    def load_settings(self, emit_signal=True):
        """Load settings from JSON file into memory."""
        try:
            if os.path.exists(self.config_path):
                with open(self.config_path, "r", encoding="utf-8") as f:
                    self._settings = json.load(f)
                print("[INFO] Settings loaded successfully")
            else:
                self._settings = {"PlayerPaths": {}, "Preferred Player": 0}
            
            if emit_signal:
                self.settingsChanged.emit()
        except Exception as e:
            print(f"[ERROR] Could not load config: {e}")
            self._settings = {"PlayerPaths": {}, "Preferred Player": 0}

    @Slot(result="QVariant")
    def get_settings(self):
        """Expose settings dictionary to QML."""
        return self._settings

    @Slot(str, "QVariant")
    def update_setting(self, key, value):
        """Update a setting dynamically and persist to JSON."""
        try:
            self._settings[key] = value
            with open(self.config_path, "w", encoding="utf-8") as f:
                json.dump(self._settings, f, indent=2)
            print(f"[INFO] Updated {key} to {value}")
            self.settingsChanged.emit()
        except Exception as e:
            print(f"[ERROR] Could not update config: {e}")

    @Slot(str)
    def add_new_player(self, file_path):
        """Adds a new player EXE, updates config and menu JSONs, and refreshes UI."""
        print(f"[DEBUG] Raw path received from QML: {file_path}")

        # 1. Normalize the Windows path
        clean_path = file_path.replace("file:///", "").replace("/", "\\")
        if clean_path[1:2] != ":":  
            clean_path = clean_path.lstrip("\\").lstrip("/")
        
        display_name = os.path.splitext(os.path.basename(clean_path))[0]

        # 2. Update Config Dictionary
        if "PlayerPaths" not in self._settings:
            self._settings["PlayerPaths"] = {}
        self._settings["PlayerPaths"][display_name] = clean_path
        
        try:
            with open(self.config_path, "w", encoding="utf-8") as f:
                json.dump(self._settings, f, indent=2)
        except Exception as e:
            print(f"[ERROR] Failed to save config.json: {e}")

        # 3. Update Menu JSON (Atomic Update)
        try:
            with open(self.menu_path, "r", encoding="utf-8") as f:
                menu_data = json.load(f)

            updated = False
            # We look for "Media Player" list inside "Settings"
            for top_item in menu_data.get("menu", []):
                if top_item["label"] == "Settings":
                    for sub_item in top_item.get("items", []):
                        # Support both labels in case you renamed it
                        if sub_item["label"] in ["Media Player", "Media Apps"]:
                            if not any(i["label"] == display_name for i in sub_item.get("items", [])):
                                if "items" not in sub_item:
                                    sub_item["items"] = []
                                sub_item["items"].append({"label": display_name})
                                updated = True
            
            if updated:
                with open(self.menu_path, "w", encoding="utf-8") as f:
                    json.dump(menu_data, f, indent=2)
                print(f"[INFO] Menu updated with {display_name}")

        except Exception as e:
            print(f"[ERROR] Failed to update menu.json: {e}")

        # 4. Final Refresh (Trigger signal once)
        self.load_settings(emit_signal=False)
        self.settingsChanged.emit()
        print(f"[SUCCESS] {display_name} added and UI notified.")

    @Slot(str)
    def delete_player(self, player_name):
        """Removes a player from config and menu."""
        if "PlayerPaths" in self._settings and player_name in self._settings["PlayerPaths"]:
            del self._settings["PlayerPaths"][player_name]
            with open(self.config_path, "w", encoding="utf-8") as f:
                json.dump(self._settings, f, indent=2)

        try:
            with open(self.menu_path, "r", encoding="utf-8") as f:
                menu_data = json.load(f)

            for top_item in menu_data.get("menu", []):
                if top_item["label"] == "Settings":
                    for sub_item in top_item.get("items", []):
                        if sub_item["label"] in ["Media Player", "Media Apps"]:
                            sub_item["items"] = [i for i in sub_item.get("items", []) if i["label"] != player_name]
            
            with open(self.menu_path, "w", encoding="utf-8") as f:
                json.dump(menu_data, f, indent=2)
        except Exception as e:
            print(f"[ERROR] Delete from menu failed: {e}")

        self.load_settings(emit_signal=True)

    @Slot(str)
    def launch_video_with_preferred_player(self, video_path: str):
        if not video_path:
            return
        
        # Using the fileSystem normalization logic if available
        if hasattr(self.fileSystem, 'normalize_path'):
            video_path = self.fileSystem.normalize_path(video_path)
            
        preferred_index = self._settings.get("Preferred Player", 0)
        player_paths = self._settings.get("PlayerPaths", {})
        players = list(player_paths.keys())

        if 0 <= preferred_index < len(players):
            player_name = players[preferred_index]
            player_exe = player_paths[player_name]
            
            if player_name == "MiniPlayer" or not player_exe:
                self.videoLaunchRequested.emit(video_path)
            else:
                try:
                    subprocess.Popen([player_exe, video_path])
                    print(f"[INFO] Launched with {player_name}")
                except Exception as e:
                    print(f"[ERROR] Could not launch {player_name}: {e}")