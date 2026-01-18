import sys
import os
import logging
import json
import threading
from pathlib import Path

# ------------------------------------------------------------
# PATHS
# ------------------------------------------------------------
this_dir = Path(__file__).resolve().parent         # MediaPlayerPy
sandbox_root = this_dir.parent                    # Sandbox
sys.path.insert(0, str(sandbox_root))             # Ensure Sandbox is found first

project_root = sandbox_root.parent                # BehindTheScenes
sys.path.append(str(project_root))                # Optional: higher-level modules

# Silences the font warning messages in the terminal
os.environ["QT_LOGGING_RULES"] = "qt.qpa.fonts=false"

# ------------------------------------------------------------
# Playback import
# ------------------------------------------------------------
from Playback.playback_qml_bridge import PlaybackQmlBridge

from search_controller import SearchController
from SplashModel import SplashModel

# ------------------------------------------------------------
# Standard PySide6 imports
# ------------------------------------------------------------
import PySide6
from PySide6.QtWidgets import QApplication
from PySide6.QtCore import QCoreApplication, QUrl, QLibraryInfo, QTimer
from PySide6.QtQml import QQmlApplicationEngine

# ------------------------------------------------------------
# Project-specific imports
# ------------------------------------------------------------
from project_paths import paths
from XML_Details import GetXMLDetails
from dbMySql.db_utils import getLibraryList
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

import subprocess
import os


# ------------------------------------------------------------
# MAIN
# ------------------------------------------------------------
def main():
    try:
        # --------------------------------------------------------
        # Logging
        # --------------------------------------------------------
        log_file = paths["log"]
        logging.basicConfig(
            filename=log_file,
            level=logging.DEBUG,
            format="%(asctime)s - %(levelname)s - %(message)s",
        )

        # --------------------------------------------------------
        # Splash model
        # --------------------------------------------------------
        splash_model = SplashModel(paths["splash_json"], paths["splash"])

        # --------------------------------------------------------
        # Database connection
        # --------------------------------------------------------
        myLibrary = getLibraryList()

        # --------------------------------------------------------
        # Settings + filesystem
        # --------------------------------------------------------
        config_path = paths["config"]
        fileSystem = FileSystem()
        settings_manager = SettingsManager(config_path, fileSystem)
        font_url = paths["fonts"].as_uri()
        settings_manager.load_settings()
        print(">>> Framework: settings loaded")
        drive_logic = DriveManager()


        #start jriver
        #1. Access the "Garage" (PlayerPaths)
        settings = settings_manager.get_settings()
        player_list = settings.get("PlayerPaths", {})

        # 2. Only proceed if 'JRiver' is actually a registered player
        if "JRiver" in player_list:
            jriver_exe = player_list["JRiver"]
            
            # 3. Check if the path actually exists on your hard drive
            if jriver_exe and os.path.exists(jriver_exe):
                try:
                    # Check if it's already running to avoid "Already Running" popups
                    check_tasks = subprocess.check_output('tasklist', shell=True).decode()
                    if "Media Center" not in check_tasks:
                        print(f"[STARTUP] JRiver found in players list. Launching...")
                        subprocess.Popen([jriver_exe], creationflags=subprocess.DETACHED_PROCESS)
                    else:
                        print("[STARTUP] JRiver is already active.")
                except Exception as e:
                    print(f"[STARTUP] Error checking/launching JRiver: {e}")
            else:
                print("[STARTUP] JRiver path in config is invalid or empty.")
        else:
            print("[STARTUP] JRiver is not in the player list. Skipping auto-launch.")

        ###################################################################


        # --------------------------------------------------------
        # Manifest updater and ToDo manager
        # --------------------------------------------------------
        manifest_updater = ManifestUpdater()
        todo_manager = ToDoManager()

        # --------------------------------------------------------
        # XML logic - Collections
        # --------------------------------------------------------
        xml_logic = XMLCollections()
        xml_controller = XmlController()
        xml_provider = GetXMLDetails()

        # --------------------------------------------------------
        # Bootstrap / First run
        # --------------------------------------------------------
        if not paths["xmldate"].exists():
            print("🚀 FIRST RUN: xml_collection_data.json not found. Building metadata...")
            xml_logic.build_collection_data_json()
        else:
            print("📡 Metadata found. Loading master cache...")
            xml_logic.refresh_master_cache()

        if myLibrary and "path" in myLibrary[0]:
            root_path = myLibrary[0]["path"]
            fileSystem.update_folders(root_path)

        # --------------------------------------------------------
        # Qt setup
        # --------------------------------------------------------
        os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"
        app = QApplication(sys.argv)

        QCoreApplication.addLibraryPath(
            str(Path(sys.modules["PySide6"].__file__).parent / "plugins")
        )
        os.add_dll_directory(str(Path(sys.modules["PySide6"].__file__).parent))

        # Convert paths to strings for QML
        paths_stringified = {k: str(v) for k, v in paths.items()}

        # --------------------------------------------------------
        # Load menu data
        # --------------------------------------------------------
        with open(paths["menu"], encoding="utf-8") as f:
            menu_data = json.load(f)

        # --- ADD THIS BLOCK RIGHT HERE ---
        # Get the keys from the PlayerPaths dictionary we loaded earlier
        actual_player_names = list(player_list.keys()) 

        for top_item in menu_data.get("menu", []):
            if top_item.get("label") == "Settings":
                for sub_item in top_item.get("items", []):
                    if sub_item.get("label") == "Media Player":
                        # This fills the empty [] we just created in menu.json
                        sub_item["items"] = [{"label": name} for name in actual_player_names]
                        print(f">>> Menu Injection: Added {actual_player_names}")
# ----------------------------------











        # --------------------------------------------------------
        # QML engine setup
        # --------------------------------------------------------
        engine = QQmlApplicationEngine()
        ctx = engine.rootContext()

        # --------------------------------------------------------
        # IMPORTANT: expose splashModel BEFORE ANYTHING ELSE touches QML
        # --------------------------------------------------------
        ctx.setContextProperty("splashModel", splash_model)

        # --------------------------------------------------------
        # Expose other Python objects
        # --------------------------------------------------------
        playback_bridge = PlaybackQmlBridge()
        ctx.setContextProperty("playbackBridge", playback_bridge)

        ctx.setContextProperty("driveManager", drive_logic)

        search_controller = SearchController()
        ctx.setContextProperty("searchController", search_controller)

        engine.addImportPath(os.path.join(os.path.dirname(PySide6.__file__), "qml"))
        engine.addImportPath(QLibraryInfo.path(QLibraryInfo.LibraryPath.Qml2ImportsPath))

        ctx.setContextProperty("_paths", paths_stringified)
        ctx.setContextProperty("collectionLogic", xml_logic)
        ctx.setContextProperty("todoManager", todo_manager)
        ctx.setContextProperty("imagesPath", Path(paths["assets"]).as_uri())
        ctx.setContextProperty("centralMenuData", menu_data)
        ctx.setContextProperty("SettingsManager", settings_manager)
        ctx.setContextProperty("fileSystemManager", fileSystem)
        ctx.setContextProperty("fontPathFA", font_url)
        ctx.setContextProperty("notificationManager", notifier)
        ctx.setContextProperty("manifestUpdater", manifest_updater)
        ctx.setContextProperty("_xmlController", xml_controller)
        ctx.setContextProperty("xmlDetails", xml_provider)
        ctx.setContextProperty("myLibraryModel", myLibrary)
        ctx.setContextProperty("thumbsPath", paths["thumbs"].as_uri())
        ctx.setContextProperty("displayPath", paths["display"].as_uri())

        # --------------------------------------------------------
        # Load main QML
        # --------------------------------------------------------
        engine.load(QUrl.fromLocalFile(str(paths["qml"] / "Framework-1.qml")))

        if not engine.rootObjects():
            logging.error("QML FAILED TO LOAD")
            return -1

        print(">>> Framework: QML loaded successfully")

        # --------------------------------------------------------
        # Start manifest work after Qt event loop
        # --------------------------------------------------------
        server_manifest_path = paths["server_manifest_v2"]

        def start_manifest_work():
            if not server_manifest_path.exists():
                notifier.post_notification("Building manifest for the first time…", False)
                manifest_updater.bootstrap_manifest()
            else:
                print("Manifest exists — updating in background")
                manifest_updater.update_manifest_background()

        QTimer.singleShot(0, start_manifest_work)

        # --------------------------------------------------------
        # Check library connection
        # --------------------------------------------------------
        if not myLibrary:
            notifier.post_notification("Database Connection Failed!", True)
            logging.error("No libraries found.")
            return -1
        else:
            notifier.post_notification("Database Connected: MediaVerse is Online", False)

        return app.exec()

    except Exception:
        logging.exception("An unhandled exception occurred:")
        return -1


if __name__ == "__main__":
    sys.exit(main())