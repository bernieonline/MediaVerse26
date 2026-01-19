import os
import subprocess
import traceback
import json

from PySide6.QtCore import QObject, Slot, Signal
from project_paths import paths

# Existing JRiver HTTP pipeline
from Sandbox.Playback.playback_qml_bridge import PlaybackQmlBridge


class PlaybackRouter(QObject):

    # Signal → QML MiniPlayer
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
        pref_index = self.config.get("Preferred Player", 1)
        player_map = {
            0: "MiniPlayer",
            1: "JRiver",
            2: "PowerDVD",
            3: "vlc"
        }
        self.preferred_player = player_map.get(pref_index, "JRiver")
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
    # PUBLIC ENTRY POINT (QML → Python)
    # ------------------------------------------------------------
    @Slot(str, bool)
    def playVideo(self, video_path, is_master):
        print("\n==============================")
        print("Refresh video player")
        print("==============================")

        # ⭐ Always reload config before routing
        self.refresh_config()

        print("\n==============================")
        print("PlaybackRouter.playVideo CALLED")
        print("==============================")
        print("Incoming video path:", video_path)
        print("isMaster:", is_master)
        print("Preferred player:", self.preferred_player)

        # --------------------------------------------------------
        # MINI PLAYER
        # --------------------------------------------------------
        if self.preferred_player == "MiniPlayer":
            self._route_miniplayer(video_path)
            return

        # --------------------------------------------------------
        # JRiver
        # --------------------------------------------------------
        if self.preferred_player == "JRiver":
            self._route_jriver(video_path, is_master)
            return

        # --------------------------------------------------------
        # VLC
        # --------------------------------------------------------
        if self.preferred_player == "vlc":
            self._route_vlc(video_path)
            return

        # --------------------------------------------------------
        # PowerDVD
        # --------------------------------------------------------
        if self.preferred_player == "PowerDVD":
            self._route_powerdvd(video_path)
            return

        print("❌ Unknown player selected.")

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
            print("❌ JRiver HTTP playback failed:", e)
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
            print("❌ ERROR: File does NOT exist:", path)
            return

        if not os.path.exists(self.jriver_exe):
            print("❌ ERROR: JRiver EXE not found:", self.jriver_exe)
            return

        cmd = [self.jriver_exe, "/Play", path]

        print("\n🚀 LAUNCHING JRiver NOW...\n")
        try:
            subprocess.Popen(cmd)
            print("JRiver launched successfully.")
        except Exception as e:
            print("❌ JRiver Subprocess Launch Failed:", e)
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
            print("❌ ERROR: File does NOT exist:", path)
            return

        if not os.path.exists(self.vlc_exe):
            print("❌ ERROR: VLC EXE not found:", self.vlc_exe)
            return

        cmd = [self.vlc_exe, path]

        print("\n🚀 LAUNCHING VLC NOW...\n")
        try:
            subprocess.Popen(cmd)
            print("VLC launched successfully.")
        except Exception as e:
            print("❌ VLC Subprocess Launch Failed:", e)
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
            print("❌ ERROR: File does NOT exist:", path)
            return

        if not os.path.exists(self.powerdvd_exe):
            print("❌ ERROR: PowerDVD EXE not found:", self.powerdvd_exe)
            return

        cmd = [self.powerdvd_exe, path]

        print("\n🚀 LAUNCHING PowerDVD NOW...\n")
        try:
            subprocess.Popen(cmd)
            print("PowerDVD launched successfully.")
        except Exception as e:
            print("❌ PowerDVD Subprocess Launch Failed:", e)
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
        pref_index = self.config.get("Preferred Player", 1)
        player_map = {0: "MiniPlayer", 1: "JRiver", 2: "PowerDVD", 3: "vlc"}
        self.preferred_player = player_map.get(pref_index, "JRiver")
        print("Updated preferred player:", self.preferred_player)

        # Update player paths
        self.player_paths = self.config.get("PlayerPaths", {})
        self.jriver_exe = self.player_paths.get("JRiver", "")
        self.vlc_exe = self.player_paths.get("vlc", "")
        self.powerdvd_exe = self.player_paths.get("PowerDVD", "")

        print("Updated JRiver EXE:", self.jriver_exe)
        print("Updated VLC EXE:", self.vlc_exe)
        print("Updated PowerDVD EXE:", self.powerdvd_exe)