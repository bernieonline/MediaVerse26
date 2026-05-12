import sys
import os
import logging
import json
import threading
import subprocess
import ctypes
from pathlib import Path
from ai_controller import AIController
from BackupSystem import BackupManager # Add this with your other imports

# ------------------------------------------------------------
# WIN32 HELPER -- find JRiver window regardless of title suffix
# ------------------------------------------------------------
def _find_jriver_hwnd(user32):
    """Return the first top-level HWND whose title contains 'JRiver', or None."""
    import ctypes.wintypes
    result = []

    @ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.wintypes.HWND, ctypes.wintypes.LPARAM)
    def _cb(hwnd, _):
        length = user32.GetWindowTextLengthW(hwnd)
        if length > 0:
            buf = ctypes.create_unicode_buffer(length + 1)
            user32.GetWindowTextW(hwnd, buf, length + 1)
            if "JRiver" in buf.value:
                result.append(hwnd)
        return True

    user32.EnumWindows(_cb, 0)
    return result[0] if result else None

# ------------------------------------------------------------
# PATHS & CONFIG
# ------------------------------------------------------------
this_dir = Path(__file__).resolve().parent 
sandbox_root = this_dir.parent 
sys.path.insert(0, str(sandbox_root)) 

project_root = sandbox_root.parent 
sys.path.append(str(project_root)) 

# Standard PySide6 imports
import PySide6
from PySide6.QtWidgets import QApplication
from PySide6.QtCore import QCoreApplication, QUrl, QLibraryInfo, QTimer
from PySide6.QtQml import QQmlApplicationEngine

from Playback.PlaybackRouter import PlaybackRouter

# Project-specific imports
from project_paths import paths
from XML_Details import GetXMLDetails
from dbMySql.db_utils import getLibraryList, create_db_connection
from xml_controller import XmlController
from FileSystem import FileSystem
from Settings_Manager import SettingsManager
from Manifest_v2_wrapper import ManifestUpdater_v2 as ManifestUpdater
from NotificationManager import notifier
from todo_manager import ToDoManager
from cacheBuilderOnServer_v2 import CacheBuilder_v2
from xml_collections import XMLCollections
from Sandbox.Playback.playback_qml_bridge import PlaybackQmlBridge
from DriveManager import DriveManager
from search_controller import SearchController
from SplashModel import SplashModel
from architect_controller import ArchitectController
from Architect_view import ArchitectView
from splash_layout import generate_splash_layout
from snatcher2_backend import Snatcher2Backend
from landing_view import LandingViewModel
from TV_view import TVViewModel
from ffmpeg_backend import FFmpegBackend
from quality_audit_backend import QualityAuditBackend
from media_manager_backend import MediaManagerBackend

from dotenv import load_dotenv

os.environ["QT_LOGGING_RULES"] = "qt.qpa.fonts=false"
os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"

def main():
    try:
        # Locate the .env file relative to this script
        # Going up two levels from Sandbox/MediaPlayerPy to the root
        env_path = Path(__file__).resolve().parent.parent.parent / "sqlCreds.env"
        load_dotenv(dotenv_path=env_path)
        # --------------------------------------------------------
        # Logging & Splash
        # --------------------------------------------------------
        logging.basicConfig(
            filename=paths["log"],
            level=logging.DEBUG,
            format="%(asctime)s - %(levelname)s - %(message)s",
        )
        splash_model = SplashModel(paths["splash_json"], paths["splash"])

        # --------------------------------------------------------
        # Core Logic Setup
        # --------------------------------------------------------
        myLibrary    = getLibraryList()
        db_connection = create_db_connection()   # persistent -- available for future modules
        fileSystem   = FileSystem()

        # --- Backup System Setup ---
        backup_manager = BackupManager()


        arch_view_instance = ArchitectView()
        snatcher2_backend  = Snatcher2Backend()
        landing_vm         = LandingViewModel()
        tv_vm              = TVViewModel()
        ffmpeg_backend         = FFmpegBackend()
        quality_audit_backend  = QualityAuditBackend()
        media_manager_backend  = MediaManagerBackend()

             # SURGICAL ADDITION: Connect the backup signal to the existing notifier
        # msg is the text, success is the boolean. We use 'not success' because 
        # post_notification(text, is_error) expects True if it's an error.
        backup_manager.backupFinished.connect(
            lambda msg, success: notifier.post_notification(msg, not success)
        )


        settings_manager = SettingsManager(paths["config"], fileSystem)
        settings_manager.load_settings()
        drive_logic = DriveManager()
        
        # Player Auto-Launch (JRiver)
        player_list = settings_manager.get_settings().get("PlayerPaths", {})
        if "JRiver" in player_list:
            jriver_exe = player_list["JRiver"]
            if jriver_exe and os.path.exists(jriver_exe):
                try:
                    check_tasks = subprocess.check_output('tasklist', shell=True).decode()
                    if "Media Center" not in check_tasks:
                        print("[STARTUP] Launching JRiver...")
                        subprocess.Popen(
                            [jriver_exe, "/MediaCenter", "/Min", "/NoSplash"],
                            creationflags=subprocess.DETACHED_PROCESS
                        )
                        # /Min is not always respected -- hide JRiver the moment its window
                        # appears, then keep suppressing it for 5s in case it restores itself.
                        def _suppress_jriver_on_startup():
                            import time
                            _user32 = ctypes.windll.user32
                            deadline = time.time() + 15     # watch for up to 15s
                            suppressing = False
                            suppress_until = 0
                            while time.time() < deadline:
                                hwnd = _find_jriver_hwnd(_user32)
                                if hwnd:
                                    _user32.ShowWindow(hwnd, 7)  # SW_SHOWMINNOACTIVE -- taskbar, no focus steal
                                    if not suppressing:
                                        print("[STARTUP] JRiver minimised to taskbar.")
                                        suppressing = True
                                        suppress_until = time.time() + 5
                                if suppressing and time.time() > suppress_until:
                                    return   # done suppressing
                                time.sleep(0.1)
                        threading.Thread(target=_suppress_jriver_on_startup, daemon=True).start()
                except Exception as e:
                    print(f"[STARTUP] JRiver launch error: {e}")

        # XML & Data Managers
        manifest_updater = ManifestUpdater()
        #build local cache on signal conf server cache completed
        manifest_updater.cacheRebuildFinished.connect(manifest_updater.start_local_cache_sync)

        todo_manager = ToDoManager()
        xml_logic = XMLCollections()
        xml_controller = XmlController()
        xml_provider = GetXMLDetails()

        # When the manifest swaps in a new version, rebuild xml_collection_data.json automatically
        # (XMLCollections.__init__ already handles startup rebuild via mtime check)
        manifest_updater.manifestUpdated.connect(xml_logic.rebuild_after_manifest_change)

        # If W: was not yet accessible when XMLCollections() was instantiated, the mtime
        # check in __init__ was skipped. Re-run it once the server is confirmed reachable
        # so a stale or missing xml_collection_data.json is caught even when the manifest
        # hash hasn't changed (no new movies added).
        manifest_updater.serverCheckPassed.connect(xml_logic.check_and_rebuild_if_stale)

        if myLibrary and "path" in myLibrary[0]:
            fileSystem.update_folders(myLibrary[0]["path"])

        # --------------------------------------------------------
        # Qt Application & Engine Setup
        # --------------------------------------------------------
        app = QApplication(sys.argv)

        # Setup DLLs and Plugins
        pyside_dir = Path(sys.modules["PySide6"].__file__).parent
        QCoreApplication.addLibraryPath(str(pyside_dir / "plugins"))
        if os.name == 'nt':
            os.add_dll_directory(str(pyside_dir))

        engine = QQmlApplicationEngine()

        def handle_qml_error(warnings):
            for warning in warnings:
                print(f"[ERROR] QML ERROR: {warning.toString()}")

        engine.warnings.connect(handle_qml_error)

        ctx = engine.rootContext()
        #playbackManager

        router = PlaybackRouter()
        # Wire the TV watch-progress store into both playback watchdogs so
        # position/duration are recorded when an episode stops, regardless of player.
        router.http_bridge.controller.progress_store     = tv_vm.progress_store
        router.http_bridge.mpcbe_watchdog.progress_store = tv_vm.progress_store
        print("1..........................................")

        #Architect
        #architect_engine = ArchitectController(xml_logic=xml_logic)
        #architect_engine = ArchitectController()
        architect_engine = ArchitectController(file_system=fileSystem) # Critical!

     

        # --- AI ---
        gemini_key = os.getenv("GOOGLE_AI_KEY")

        if not gemini_key:
            print("WARNING: GOOGLE_AI_KEY not found in sqlCreds.env")

        ai_controller = AIController(api_key=gemini_key)
        
        # Determine startup mode from Config.json -> "Tiles" or "Splash"
        _startup_mode = "Tiles"
        try:
            with open(paths["config"], "r", encoding="utf-8") as _f:
                _su = json.load(_f).get("StartUp", {})
            if _su.get("Splash") is True:
                _startup_mode = "Splash"
            elif _su.get("Tiles") is True:
                _startup_mode = "Tiles"
        except Exception:
            pass
        print(f"[STARTUP] Landing mode: {_startup_mode}")

        ctx.setContextProperty("playbackRouter", router)
        ctx.setContextProperty("splashLayout", generate_splash_layout())

        # -- Workbench cinematic backdrop --------------------------------------
        try:
            with open(paths["splash_json"], "r", encoding="utf-8") as _f:
                _wb_entries = json.load(_f)
            _splash_dir = paths["splash_images"]
            for _e in _wb_entries:
                _img = _splash_dir / _e["image"]
                _e["uri"] = _img.as_uri() if _img.exists() else ""
        except Exception as _ex:
            print(f"[WorkbenchSplash] Could not load Splash.json: {_ex}")
            _wb_entries = []
        ctx.setContextProperty("workbenchSplashData", _wb_entries)
        ctx.setContextProperty("architectView", arch_view_instance)
        ctx.setContextProperty("backupManager", backup_manager)
        ctx.setContextProperty("aiController", ai_controller)
        ctx.setContextProperty("landingViewModel", landing_vm)
        ctx.setContextProperty("tvViewModel",     tv_vm)
        ctx.setContextProperty("ffmpegBackend",        ffmpeg_backend)
        ctx.setContextProperty("qualityAuditBackend",  quality_audit_backend)
        ctx.setContextProperty("mediaManagerBackend",  media_manager_backend)
        ctx.setContextProperty("startupMode", _startup_mode)

        # --------------------------------------------------------
        # Menu Data Handling (The Source of Truth)
        # --------------------------------------------------------

        with open(paths["menu"], encoding="utf-8") as f:
            menu_template = json.load(f)

        settings_manager.menu_data = menu_template
        settings_manager.sync_menu_players( ) # Inject players into the menu object


        # --------------------------------------------------------
        # Expose Python Objects to QML
        # --------------------------------------------------------
        ctx.setContextProperty("architectController", architect_engine)
        ctx.setContextProperty("snatcher2Backend",   snatcher2_backend)
        ctx.setContextProperty("splashModel", splash_model)
        ctx.setContextProperty("SettingsManager", settings_manager)
        ctx.setContextProperty("centralMenuData", settings_manager.menu_data) # Point to manager's data

        #playback_bridge = PlaybackQmlBridge()
        playback_bridge = router.http_bridge
        def _on_quit():
            """Shutdown playback + kill JRWeb.exe in a daemon thread."""
            def _cleanup():
                playback_bridge.shutdown()
                try:
                    subprocess.call(
                        ["taskkill", "/F", "/IM", "JRWeb.exe"],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                    )
                except Exception:
                    pass
            threading.Thread(target=_cleanup, daemon=True).start()

        app.aboutToQuit.connect(_on_quit)

        search_controller = SearchController()
        ctx.setContextProperty("playbackBridge", playback_bridge)
        ctx.setContextProperty("driveManager", drive_logic)
        ctx.setContextProperty("searchController", search_controller)
        ctx.setContextProperty("_paths", {k: str(v) for k, v in paths.items()})
        ctx.setContextProperty("collectionLogic", xml_logic)
        ctx.setContextProperty("todoManager", todo_manager)
        ctx.setContextProperty("imagesPath", Path(paths["assets"]).as_uri())
        ctx.setContextProperty("fileSystemManager", fileSystem)
        ctx.setContextProperty("fileSystem", fileSystem)
        ctx.setContextProperty("fontPathFA", paths["fonts"].as_uri())
        ctx.setContextProperty("notificationManager", notifier)
        ctx.setContextProperty("manifestUpdater", manifest_updater)
        ctx.setContextProperty("_xmlController", xml_controller)
        ctx.setContextProperty("xmlDetails", xml_provider)
        ctx.setContextProperty("myLibraryModel", myLibrary)
        ctx.setContextProperty("thumbsPath", paths["thumbs"].as_uri())
        ctx.setContextProperty("displayPath", paths["display"].as_uri())

        print("2..........................................")

        engine.addImportPath(os.path.join(os.path.dirname(PySide6.__file__), "qml"))
        engine.addImportPath(QLibraryInfo.path(QLibraryInfo.LibraryPath.Qml2ImportsPath))

        # --------------------------------------------------------
        # Load & Run
        # --------------------------------------------------------
        engine.load(QUrl.fromLocalFile(str(paths["qml"] / "Framework-1.qml")))

        if not engine.rootObjects():
            return -1
        
        root = engine.rootObjects()[0]
        router.launchMiniPlayer.connect(root.openMiniPlayer)

        # Background Manifest Work -- server check + startup delegated to ManifestUpdater_v2
        def start_manifest_work():
            manifest_updater.retry_server_check()

        QTimer.singleShot(0, start_manifest_work)

        # Replay any notifications that fired before QML was ready
        QTimer.singleShot(500, notifier.flush_pending)

        if not myLibrary:
            notifier.post_notification("Database Connection Failed!", True)
        else:
            notifier.post_notification("Database Connected: MediaVerse is Online", False)

        exit_code = app.exec()

        # Safety timer -- if non-daemon background threads (e.g. MySQL pool) stall
        # Python's normal exit, os._exit() fires after 2 s to force termination.
        # Being daemon, it is killed silently if Python exits normally first.
        _t = threading.Timer(2.0, lambda: os._exit(exit_code))
        _t.daemon = True
        _t.start()

        # JRiver is already minimised on the taskbar (SW_SHOWMINNOACTIVE was used
        # at startup instead of SW_HIDE), so no restore step is needed.
        # Calling GetWindowTextW here would risk blocking the main thread;
        # skipping it entirely removes that risk and the egg-timer delay.
        sys.exit(exit_code)

    except Exception:
        logging.exception("An unhandled exception occurred:")
        return -1

if __name__ == "__main__":
    sys.exit(main())