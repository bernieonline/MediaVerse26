import sys
import os
import logging
import json
import threading
import subprocess
from pathlib import Path
from ai_controller import AIController
from BackupSystem import BackupManager # Add this with your other imports

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
from search_controller import SearchController
from SplashModel import SplashModel
from architect_controller import ArchitectController

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
        myLibrary = getLibraryList()
        fileSystem = FileSystem()

        # --- Backup System Setup ---
        backup_manager = BackupManager()

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
                        subprocess.Popen([jriver_exe], creationflags=subprocess.DETACHED_PROCESS)
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

        if not paths["xmldate"].exists():
            xml_logic.build_collection_data_json()
        else:
            xml_logic.refresh_master_cache()

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
                print(f"❌ QML ERROR: {warning.toString()}")

        engine.warnings.connect(handle_qml_error)

        ctx = engine.rootContext()
        #playbackManager

        router = PlaybackRouter()
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
        
        ctx.setContextProperty("playbackRouter", router)

        ctx.setContextProperty("backupManager", backup_manager)
   

        ctx.setContextProperty("aiController", ai_controller)

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
        ctx.setContextProperty("architectController", architect_engine)  # <--- ADD THIS LINE
        ctx.setContextProperty("splashModel", splash_model)
        ctx.setContextProperty("SettingsManager", settings_manager)
        ctx.setContextProperty("centralMenuData", settings_manager.menu_data) # Point to manager's data

        #playback_bridge = PlaybackQmlBridge()
        playback_bridge = router.http_bridge

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

        # Background Manifest Work
        def start_manifest_work():
            if not paths["server_manifest_v2"].exists():
                notifier.post_notification("Building manifest...", False)
                manifest_updater.bootstrap_manifest()
            else:
                manifest_updater.update_manifest_background()

        QTimer.singleShot(0, start_manifest_work)

        if not myLibrary:
            notifier.post_notification("Database Connection Failed!", True)
        else:
            notifier.post_notification("Database Connected: MediaVerse is Online", False)

        return app.exec()

    except Exception:
        logging.exception("An unhandled exception occurred:")
        return -1

if __name__ == "__main__":
    sys.exit(main())