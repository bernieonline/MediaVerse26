import json
import subprocess
import os
from PySide6.QtCore import QObject, Slot, Signal

class SettingsManager(QObject):
    # Signals QML can connect to
    settingsChanged = Signal()
    videoLaunchRequested = Signal(str)
    
    # CHANGED: Now using (str) to pass a JSON string to avoid Shiboken/C++ conversion errors
    playerMenuChanged = Signal(str)

    def __init__(self, config_path, fileSystem, parent=None):
        super().__init__(parent)
        self.config_path = config_path
        self.fileSystem = fileSystem
        self._settings = {}
        # Assumes menu.json is in the same folder as config.json
        self.menu_path = os.path.join(os.path.dirname(self.config_path), "menu.json")
        self.menu_data = {} # Will be populated by Framework.py at startup
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
        """Adds a new player EXE, updates config, and triggers a live UI refresh."""
        print(f"[DEBUG] Raw path received from QML: {file_path}")

        # 1. Normalize the Windows path
        clean_path = file_path.replace("file:///", "").replace("/", "\\")
        if clean_path[1:2] != ":":  
            clean_path = clean_path.lstrip("\\").lstrip("/")
        
        display_name = os.path.splitext(os.path.basename(clean_path))[0]

        # 2. Update internal dictionary
        if "PlayerPaths" not in self._settings:
            self._settings["PlayerPaths"] = {}
        
        self._settings["PlayerPaths"][display_name] = clean_path
        
        # 3. Save to config.json
        try:
            with open(self.config_path, "w", encoding="utf-8") as f:
                json.dump(self._settings, f, indent=2)
            print(f"[INFO] Config saved with new player: {display_name}")
        except Exception as e:
            print(f"[ERROR] Failed to save config.json: {e}")
            return

        # 4. Trigger the live menu sync and settings refresh
        self.sync_menu_players() 
        self.settingsChanged.emit()
        
        print(f"[SUCCESS] {display_name} added. Menu refreshed.")

    @Slot(str)
    def delete_player(self, player_name):
        """Removes a player from config and menu."""
        if "PlayerPaths" in self._settings and player_name in self._settings["PlayerPaths"]:
            del self._settings["PlayerPaths"][player_name]
            with open(self.config_path, "w", encoding="utf-8") as f:
                json.dump(self._settings, f, indent=2)

        # Sync the menu data object and emit the change to QML
        self.sync_menu_players()
        self.settingsChanged.emit()

    @Slot(str)
    def launch_video_with_preferred_player(self, video_path: str):
        if not video_path:
            return
        
        # 1. Force reload to catch Stage 2 selection changes
        self.load_settings(emit_signal=False)
        
        preferred = self._settings.get("Preferred Player", "MiniPlayer")
        player_paths = self._settings.get("PlayerPaths", {})

        # --- STAGE 2: RESOLVE THE PLAYER NAME ---
        if isinstance(preferred, int):
            # Handle Legacy Index (0, 1, 2...)
            # We grab the keys from the dictionary you built in Stage 1
            available_players = list(player_paths.keys())
            if 0 <= preferred < len(available_players):
                player_name = available_players[preferred]
            else:
                player_name = "MiniPlayer"
        else:
            # Handle Modern String ("MPC-BE", "VLC")
            player_name = str(preferred).strip()

        # --- STAGE 1: RESOLVE THE PATH ---
        player_exe = player_paths.get(player_name)

        # --- EXECUTION ---
        if player_name == "MiniPlayer" or not player_exe:
            print(f"[INFO] Routing to Internal MiniPlayer for: {video_path}")
            self.videoLaunchRequested.emit(video_path)
        else:
            if os.path.exists(player_exe):
                try:
                    print(f"[SUCCESS] Launching {player_name} -> {player_exe}")
                    # For MPC-BE specifically, we can add the auto-play/close flag
                    if "mpc" in player_name.lower():
                        subprocess.Popen([player_exe, video_path, "/play", "/close"])
                    else:
                        subprocess.Popen([player_exe, video_path])
                except Exception as e:
                    print(f"[ERROR] Failed to execute subprocess: {e}")
            else:
                print(f"[ERROR] Path does not exist: {player_exe}")
    @Slot(str)
    def browse_and_save_tool_path(self, tool_name: str):
        """Open a file dialog, then save the chosen exe under ToolPaths[tool_name]."""
        from PySide6.QtWidgets import QFileDialog
        path, _ = QFileDialog.getOpenFileName(
            None,
            f"Select {tool_name} Executable",
            "",
            "Executables (*.exe);;All Files (*.*)"
        )
        if not path:
            return
        clean = path.replace("file:///", "").replace("/", "\\")
        if "ToolPaths" not in self._settings:
            self._settings["ToolPaths"] = {}
        self._settings["ToolPaths"][tool_name] = clean
        try:
            with open(self.config_path, "w", encoding="utf-8") as f:
                json.dump(self._settings, f, indent=2)
            print(f"[INFO] ToolPaths.{tool_name} saved: {clean}")
        except Exception as e:
            print(f"[ERROR] Could not save tool path: {e}")
            return
        self.settingsChanged.emit()

    @Slot(str, result=bool)
    def is_tool_available(self, tool_name: str) -> bool:
        exe = self._settings.get("ToolPaths", {}).get(tool_name, "")
        return bool(exe and os.path.exists(exe))

    @Slot(str)
    def launch_tool(self, tool_name: str):
        """Launch the external tool registered under ToolPaths[tool_name]."""
        tool_paths = self._settings.get("ToolPaths", {})
        exe = tool_paths.get(tool_name, "")
        if not exe or not os.path.exists(exe):
            print(f"[ERROR] Tool not found or not configured: {tool_name} → '{exe}'")
            return
        try:
            proc = subprocess.Popen([exe])
            print(f"[INFO] Launched {tool_name}: {exe}")
            import threading
            threading.Thread(target=self._bring_to_front, args=(proc.pid,), daemon=True).start()
        except Exception as e:
            print(f"[ERROR] Failed to launch {tool_name}: {e}")

    @staticmethod
    def _bring_to_front(pid: int):
        """Wait for the process to create a visible window, then raise it."""
        import ctypes
        import time
        user32 = ctypes.windll.user32
        WNDENUMPROC = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_size_t, ctypes.c_size_t)
        found = [0]

        def _cb(hwnd, _):
            wid = ctypes.c_ulong()
            user32.GetWindowThreadProcessId(hwnd, ctypes.byref(wid))
            if wid.value == pid and user32.IsWindowVisible(hwnd):
                found[0] = hwnd
                return False
            return True

        cb = WNDENUMPROC(_cb)
        for _ in range(20):          # poll up to ~4 seconds
            time.sleep(0.2)
            user32.EnumWindows(cb, 0)
            if found[0]:
                break

        if found[0]:
            user32.ShowWindow(found[0], 9)       # SW_RESTORE
            user32.SetForegroundWindow(found[0])
            print(f"[INFO] Brought PID {pid} window to foreground")

    def sync_menu_players(self):
        """Refreshes the player list inside the menu data and notifies QML via JSON string."""
        if not self.menu_data:
            print("[WARNING] sync_menu_players called but self.menu_data is empty.")
            return

        # 1. Get the current players
        actual_player_names = list(self._settings.get("PlayerPaths", {}).keys())
        player_items = [{"label": name} for name in actual_player_names]
        
        # 2. Inject into the menu structure
        for top_item in self.menu_data.get("menu", []):
            if top_item.get("label") == "Settings":
                for sub_item in top_item.get("items", []):
                    if sub_item.get("label") == "Media Player":
                        sub_item["items"] = player_items
                        break
        
        # 3. Emit as JSON String to bypass Shiboken errors
        json_payload = json.dumps(self.menu_data)
        self.playerMenuChanged.emit(json_payload)
        print(f">>> SettingsManager: Menu synced with {len(player_items)} players.")


   