# settings_manager.py
import json
import subprocess
import os
from PySide6.QtCore import QObject, Slot, Signal
from FileSystem import normalize_path

class SettingsManager(QObject):
    # Signals QML can connect to
    settingsChanged = Signal()
    videoLaunchRequested = Signal(str)

    def __init__(self, config_path, fileSystem, parent=None):
        super().__init__(parent)
        self.config_path = config_path
        self.fileSystem = fileSystem
        self._settings = {}
        self.load_settings()

    def load_settings(self):
        """Load settings from JSON file into memory."""
        try:
            with open(self.config_path, "r", encoding="utf-8") as f:
                self._settings = json.load(f)
            print("settings now loaded")
            for key, value in self._settings.items():
                print(f" - {key}: {value}")
            self.settingsChanged.emit()
        except Exception as e:
            print(f"[ERROR] Could not load config: {e}")
            self._settings = {}

    @Slot(result="QVariant")
    def get_settings(self):
        """Expose settings dictionary to QML."""
        return self._settings

    @Slot(str, "QVariant")
    def update_setting(self, key, value):
        """Update a setting dynamically and persist to JSON."""
        try:
            with open(self.config_path, "r", encoding="utf-8") as f:
                config = json.load(f)
            config[key] = value
            with open(self.config_path, "w", encoding="utf-8") as f:
                json.dump(config, f, indent=2)
            print(f"[INFO] Updated {key} to {value}")
            self.load_settings()
            self.settingsChanged.emit()
        except Exception as e:
            print(f"[ERROR] Could not update config: {e}")

    @Slot(str)
    def launch_video_with_preferred_player(self, video_path: str):
        if not video_path:
            print(f"[ERROR] No matching video found for {image_filename} in {folder_path}")
            return
        
        video_path = normalize_path(video_path)
        print(f"🎬 Launching video directly: {video_path}")

        preferred_index = self._settings.get("Preferred Player", 0)
        player_paths = self._settings.get("PlayerPaths", {})
        players = list(player_paths.keys())

        if 0 <= preferred_index < len(players):
            player_name = players[preferred_index]
            player_exe = player_paths[player_name]
            if player_name == "MiniPlayer" or not player_exe:
                self.videoLaunchRequested.emit(video_path)
                print(f"[INFO] Emitted videoLaunchRequested for MiniPlayer: {video_path}")
            else:
                try:
                    print(f"[DEBUG] exe='{player_exe}'")
                    print(f"[DEBUG] video='{video_path}'")

                    subprocess.Popen([player_exe, video_path])
                    print(f"[INFO] Launched {video_path} with {player_name}")
                except Exception as e:
                    print(f"[ERROR] Could not launch {player_name}: {e}")