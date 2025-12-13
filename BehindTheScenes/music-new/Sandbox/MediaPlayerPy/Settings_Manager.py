# settings_manager.py
import json
from PySide6.QtCore import QObject, Slot

class SettingsManager(QObject):
    def __init__(self, config_path):
        super().__init__()
        self.config_path = config_path
        self._settings = {}
        self.load_settings()


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

#read the config files and store results in memory and use them to set settings preferences
#both on startup and on changing a setting
    def load_settings(self):
        try:
            with open(self.config_path, "r", encoding="utf-8") as f:
                self._settings = json.load(f)
            print("settings now loaded")
            #these prints demonstrate that config settings are being read on startup and stored in memory
            for key, value in self._settings.items():
                print(f" - {key}: {value}")



        except Exception as e:
            print(f"[ERROR] Could not load config: {e}")
            self._settings = {}

    @Slot(result="QVariant")
    def get_settings(self):
        """Return all settings as a dict for QML"""
        return self._settings



    # Settings_Manager.py
import json
from PySide6.QtCore import QObject, Slot, Signal

class SettingsManager(QObject):
    # ✅ Define a Qt signal that QML can listen for.
    # Whenever settings are changed, we emit this so QML knows to refresh.
    settingsChanged = Signal()

    def __init__(self, config_path):
        super().__init__()
        self.config_path = config_path   # path to Config.json file
        self._settings = {}              # in‑memory dictionary of settings
        self.load_settings()             # preload settings at startup

    def load_settings(self):
        """
        Load all settings from the JSON file into memory.
        This ensures self._settings always reflects the latest file contents.
        """
        try:
            with open(self.config_path, "r", encoding="utf-8") as f:
                # Read the entire JSON file into a Python dictionary
                self._settings = json.load(f)

            # Debug output so you can see what was loaded
            print("settings now loaded")
            for key, value in self._settings.items():
                print(f" - {key}: {value}")

            # Notify QML that settings have been refreshed
            self.settingsChanged.emit()

        except Exception as e:
            print(f"[ERROR] Could not load config: {e}")
            self._settings = {}

    @Slot(result="QVariant")
    def get_settings(self):
        """
        Expose the entire settings dictionary to QML.
        QML can call this to get all key–value pairs at once.
        """
        return self._settings

    @Slot(str, "QVariant")
    def update_setting(self, key, value):
        """
        This dynamically manages the changes made to settings without
        the need for methods for every settings option. It maintains the settings in
        memory, auto updates the config file as needed and handles the link to QML update
        Generic update method:
        - key: the name of the setting to update (string)
        - value: the new value to assign (can be int, str, bool, etc.)
        """
        try:
            # Step 1: Read the current JSON file into a dictionary
            with open(self.config_path, "r", encoding="utf-8") as f:
                config = json.load(f)

            # Step 2: Update the dictionary dynamically
            # This works for ANY key present in the JSON file
            config[key] = value

            # Step 3: Write the updated dictionary back to the JSON file
            with open(self.config_path, "w", encoding="utf-8") as f:
                json.dump(config, f, indent=2)  # indent=2 for readability

            # Step 4: Print a debug message so you know what changed
            print(f"[INFO] Updated {key} to {value}")

            # Step 5: Reload settings into memory so self._settings is fresh
            self.load_settings()

            # Step 6: Emit the signal so QML knows to refresh its bindings
            self.settingsChanged.emit()

        except Exception as e:
            print(f"[ERROR] Could not update config: {e}")