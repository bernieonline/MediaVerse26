import os
import subprocess
import traceback
import json

from PySide6.QtCore import QObject, Slot, Signal
from project_paths import paths

# Existing JRiver HTTP pipeline
from Sandbox.Playback.playback_qml_bridge import PlaybackQmlBridge


class PlaybackRouter(QObject):

    # Signal -> QML MiniPlayer
    launchMiniPlayer = Signal(str)

    def __init__(self):
        super().__init__()

        print("\n==============================")
        print("PlaybackRouter INITIALISING")
        print("==============================")
        print(">>> USING PlaybackRouter FROM:", __file__)

        # ----------------------------------------------------
        # CONFIG PATH
        # ----------------------------------------------------
        self.config_path = paths["config"]
        print("Config file:", self.config_path)

        # ----------------------------------------------------
        # LOAD CONFIG
        # ----------------------------------------------------
        try:
            with open(self.config_path, "r") as f:
                self.config = json.load(f)
            print("Config loaded successfully.")
        except Exception as e:
            print("ERROR loading config:", e)
            self.config = {}

        # ----------------------------------------------------
        # PREFERRED PLAYER
        # ----------------------------------------------------
        pref = self.config.get("Preferred Player", "JRiver")
        if isinstance(pref, int):
            # Legacy integer value -- map to name for backward compatibility
            _legacy_map = {0: "MiniPlayer", 1: "JRiver", 2: "PowerDVD", 3: "vlc"}
            self.preferred_player = _legacy_map.get(pref, "JRiver")
        else:
            self.preferred_player = str(pref)
        print("Preferred player:", self.preferred_player)

        # ----------------------------------------------------
        # PLAYER EXECUTABLE PATHS
        # ----------------------------------------------------
        self.player_paths = self.config.get("PlayerPaths", {})
        self.jriver_exe = self.player_paths.get("JRiver", "")
        self.vlc_exe = self.player_paths.get("vlc", "")
        self.powerdvd_exe = self.player_paths.get("PowerDVD", "")

        print("JRiver EXE path:", self.jriver_exe)
        print("VLC EXE path:", self.vlc_exe)
        print("PowerDVD EXE path:", self.powerdvd_exe)

        # ----------------------------------------------------
        # JRiver HTTP Bridge
        # ----------------------------------------------------
        self.http_bridge = PlaybackQmlBridge()
        print("HTTP Bridge initialised.")

        print("==============================\n")

    # ------------------------------------------------------------
    # PUBLIC ENTRY POINT (QML -> Python)
    # ------------------------------------------------------------
    
    def _play_generic_subprocess(self, exe_path, video_path, extra_args=None):
        """A universal launcher that handles path normalization."""
        # Convert file:///W:/ to W:\
        clean_path = video_path.replace("file:///", "").replace("/", "\\")
        clean_path = os.path.normpath(clean_path)
        
        cmd = [exe_path, clean_path]
        if extra_args:
            cmd.extend(extra_args)
            
        print(f"[>>] Executing: {cmd}")
        try:
            subprocess.Popen(cmd)
        except Exception as e:
            print(f"[ERROR] Failed to launch: {e}")
    
    
    
    @Slot(str, bool)
    def playVideo(self, video_path, is_master):
        # 1. Always reload the latest JSON from Stage 1 & 2
        self.refresh_config()

        # 2. Get the Player Name and Path dynamically
        player_name = str(self.preferred_player).strip()
        player_exe = self.player_paths.get(player_name, "")

        print(f"\n>>> ROUTING REQUEST")
        print(f"Target Player: {player_name}")
        print(f"Target Path: {player_exe}")

        # --------------------------------------------------------
        # INTERNAL PLAYER
        # --------------------------------------------------------
        if player_name == "MiniPlayer":
            self._route_miniplayer(video_path)
            return

        # --------------------------------------------------------
        # EXTERNAL PLAYERS (Dynamic Lookup)
        # --------------------------------------------------------
        if not player_exe or not os.path.exists(player_exe):
            print(f"[ERROR] ERROR: Player '{player_name}' has no valid EXE path.")
            return

        # Use specific logic for JRiver (HTTP vs Subprocess)
        if "JRiver" in player_name:
            self._route_jriver(video_path, is_master)
            
        # MPC-BE: launch with watchdog for progress tracking
        elif "mpc" in player_name.lower():
            self._route_mpcbe(video_path, player_exe)
            
        # Generic fallback for VLC, PowerDVD, or anything else
        else:
            self._play_generic_subprocess(player_exe, video_path)

    # ------------------------------------------------------------
    # MiniPlayer Routing
    # ------------------------------------------------------------
    def _route_miniplayer(self, video_path):
        print("\n>>> ROUTING: MiniPlayer (Internal QML Player)")
        clean_path = video_path.replace("\\", "/")
        print("Emitting launchMiniPlayer with:", clean_path)
        self.launchMiniPlayer.emit(clean_path)

    # ------------------------------------------------------------
    # JRiver Routing
    # ------------------------------------------------------------
    def _route_jriver(self, video_path, is_master):
        if is_master:
            print("\n>>> ROUTING: JRiver HTTP (Library Item)")
            clean_path = video_path.replace("\\", "/")
            self.play_jriver_http(clean_path)
        else:
            print("\n>>> ROUTING: JRiver Subprocess (Freestyle Item)")
            self.play_jriver_subprocess(video_path)

    # ------------------------------------------------------------
    # MPC-BE Routing (with progress watchdog)
    # ------------------------------------------------------------
    def _route_mpcbe(self, video_path, exe_path):
        """Launch MPC-BE and start the HTTP watchdog for position tracking."""
        print("\n>>> ROUTING: MPC-BE with progress watchdog")

        clean_path = video_path.replace("file:///", "").replace("/", "\\")
        clean_path = os.path.normpath(clean_path)

        if not os.path.exists(clean_path):
            print(f"[ERROR] ERROR: File does NOT exist: {clean_path}")
            return
        if not os.path.exists(exe_path):
            print(f"[ERROR] ERROR: MPC-BE EXE not found: {exe_path}")
            return

        port    = int(self.config.get("MpcBePort", "13579"))
        process = subprocess.Popen([exe_path, clean_path, "/play", "/close"])
        self.http_bridge.mpcbe_watchdog.start(clean_path, process, port=port)

    # ------------------------------------------------------------
    # VLC Routing
    # ------------------------------------------------------------
    def _route_vlc(self, video_path):
        print("\n>>> ROUTING: VLC Subprocess (All Items)")
        self.play_vlc_subprocess(video_path)

    # ------------------------------------------------------------
    # PowerDVD Routing
    # ------------------------------------------------------------
    def _route_powerdvd(self, video_path):
        print("\n>>> ROUTING: PowerDVD Subprocess (All Items)")
        self.play_powerdvd_subprocess(video_path)

    # ------------------------------------------------------------
    # JRiver HTTP Playback
    # ------------------------------------------------------------
    def play_jriver_http(self, clean_path):
        print("\n" + "="*80)
        print("JRiver HTTP PLAYBACK")
        print("="*80)
        print("Clean path:", clean_path)

        try:
            self.http_bridge.playVideo(clean_path)
            print("HTTP request sent via PlaybackQmlBridge.")
        except Exception as e:
            print("[ERROR] JRiver HTTP playback failed:", e)
            traceback.print_exc()

    # ------------------------------------------------------------
    # JRiver Subprocess Playback
    # ------------------------------------------------------------
    def play_jriver_subprocess(self, win_path):
        print("\n" + "="*80)
        print("JRiver SUBPROCESS PLAYBACK")
        print("="*80)
        print(f"RAW INPUT PATH FROM QML:\n    {win_path}")

        path = win_path.replace("file:///", "").replace("/", "\\")
        path = os.path.normpath(path)

        print("\nCHECKING FILE EXISTS:", os.path.exists(path))
        print("CHECKING JRiver EXE EXISTS:", os.path.exists(self.jriver_exe))

        if not os.path.exists(path):
            print("[ERROR] ERROR: File does NOT exist:", path)
            return

        if not os.path.exists(self.jriver_exe):
            print("[ERROR] ERROR: JRiver EXE not found:", self.jriver_exe)
            return

        cmd = [self.jriver_exe, "/Play", path]

        print("\n[>>] LAUNCHING JRiver NOW...\n")
        try:
            subprocess.Popen(cmd)
            print("JRiver launched successfully.")
        except Exception as e:
            print("[ERROR] JRiver Subprocess Launch Failed:", e)
            traceback.print_exc()

    # ------------------------------------------------------------
    # VLC Subprocess Playback
    # ------------------------------------------------------------
    def play_vlc_subprocess(self, win_path):
        print("\n" + "="*80)
        print("VLC SUBPROCESS PLAYBACK")
        print("="*80)
        print(f"RAW INPUT PATH FROM QML:\n    {win_path}")

        path = win_path.replace("file:///", "").replace("/", "\\")
        path = os.path.normpath(path)

        print("\nCHECKING FILE EXISTS:", os.path.exists(path))
        print("CHECKING VLC EXE EXISTS:", os.path.exists(self.vlc_exe))

        if not os.path.exists(path):
            print("[ERROR] ERROR: File does NOT exist:", path)
            return

        if not os.path.exists(self.vlc_exe):
            print("[ERROR] ERROR: VLC EXE not found:", self.vlc_exe)
            return

        cmd = [self.vlc_exe, path]

        print("\n[>>] LAUNCHING VLC NOW...\n")
        try:
            subprocess.Popen(cmd)
            print("VLC launched successfully.")
        except Exception as e:
            print("[ERROR] VLC Subprocess Launch Failed:", e)
            traceback.print_exc()

    # ------------------------------------------------------------
    # PowerDVD Subprocess Playback
    # ------------------------------------------------------------
    def play_powerdvd_subprocess(self, win_path):
        print("\n" + "="*80)
        print("POWERDVD SUBPROCESS PLAYBACK")
        print("="*80)
        print(f"RAW INPUT PATH FROM QML:\n    {win_path}")

        path = win_path.replace("file:///", "").replace("/", "\\")
        path = os.path.normpath(path)

        print("\nCHECKING FILE EXISTS:", os.path.exists(path))
        print("CHECKING PowerDVD EXE EXISTS:", os.path.exists(self.powerdvd_exe))

        if not os.path.exists(path):
            print("[ERROR] ERROR: File does NOT exist:", path)
            return

        if not os.path.exists(self.powerdvd_exe):
            print("[ERROR] ERROR: PowerDVD EXE not found:", self.powerdvd_exe)
            return

        cmd = [self.powerdvd_exe, path]

        print("\n[>>] LAUNCHING PowerDVD NOW...\n")
        try:
            subprocess.Popen(cmd)
            print("PowerDVD launched successfully.")
        except Exception as e:
            print("[ERROR] PowerDVD Subprocess Launch Failed:", e)
            traceback.print_exc()

    def refresh_config(self):
        print("\n=== REFRESHING CONFIG ===")

        try:
            with open(self.config_path, "r") as f:
                self.config = json.load(f)
            print("Config refreshed.")
        except Exception as e:
            print("ERROR refreshing config:", e)
            return

        # Update preferred player
        pref = self.config.get("Preferred Player", "JRiver")
        if isinstance(pref, int):
            _legacy_map = {0: "MiniPlayer", 1: "JRiver", 2: "PowerDVD", 3: "vlc"}
            self.preferred_player = _legacy_map.get(pref, "JRiver")
        else:
            self.preferred_player = str(pref)
        print("Updated preferred player:", self.preferred_player)

        # Update player paths
        self.player_paths = self.config.get("PlayerPaths", {})
        self.jriver_exe = self.player_paths.get("JRiver", "")
        self.vlc_exe = self.player_paths.get("vlc", "")
        self.powerdvd_exe = self.player_paths.get("PowerDVD", "")

        print("Updated JRiver EXE:", self.jriver_exe)
        print("Updated VLC EXE:", self.vlc_exe)
        print("Updated PowerDVD EXE:", self.powerdvd_exe)