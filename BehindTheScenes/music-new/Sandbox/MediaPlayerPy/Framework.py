import sys
import os
import logging
import json
import threading
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

import PySide6
from PySide6.QtWidgets import QApplication
from PySide6.QtCore import QCoreApplication, QUrl, QLibraryInfo, QTimer
from PySide6.QtQml import QQmlApplicationEngine

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


def main():
    try:
        # ------------------------------------------------------------
        # Logging
        # ------------------------------------------------------------
        log_file = paths["log"]
        logging.basicConfig(
            filename=log_file,
            level=logging.DEBUG,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )

        # ------------------------------------------------------------
        # Database connection
        # ------------------------------------------------------------
        myLibrary = getLibraryList()

        # ------------------------------------------------------------
        # Settings + filesystem
        # ------------------------------------------------------------
        config_path = paths["config"]
        fileSystem = FileSystem()
        settings_manager = SettingsManager(config_path, fileSystem)
        font_url = paths["fonts"].as_uri()
        settings_manager.load_settings()
        print(">>> Framework: settings loaded, continuing startup")

        # ------------------------------------------------------------
        # Manifest updater and ToDo manager
        # ------------------------------------------------------------
        manifest_updater = ManifestUpdater()
        todo_manager = ToDoManager()

        # ------------------------------------------------------------
        # XML logic - Collections
        # ------------------------------------------------------------
        xml_logic = XMLCollections()
        #xml_logic = XMLCollections(paths)
        xml_controller = XmlController()
        xml_provider = GetXMLDetails()

        # --- FIRST RUN / BOOTSTRAP LOGIC ---
        # Check if the enriched metadata file (xml_collection_data.json) exists
        if not paths["xmldate"].exists():
            print("🚀 [Framework] FIRST RUN: xml_collection_data.json not found.")
            print(">>> Building enriched metadata from J.River sidecars...")
            # This triggers the threaded builder we just added
            xml_logic.build_collection_data_json()
        else:
            # Normal startup: Just load the existing file into the master_cache
            print("📡 [Framework] Metadata found. Loading Master Cache...")
            xml_logic.refresh_master_cache()


        if myLibrary and "path" in myLibrary[0]:
            root_path = myLibrary[0]["path"]
            fileSystem.update_folders(root_path)

        # ------------------------------------------------------------
        # Qt setup
        # ------------------------------------------------------------
        os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"
        app = QApplication(sys.argv)

        QCoreApplication.addLibraryPath(
            str(Path(sys.modules["PySide6"].__file__).parent / "plugins")
        )
        os.add_dll_directory(str(Path(sys.modules["PySide6"].__file__).parent))

        # Convert all pathlib objects in your dictionary to strings so QML can read them
        paths_stringified = {k: str(v) for k, v in paths.items()}

        # ------------------------------------------------------------
        # Load menu data
        # ------------------------------------------------------------
        with open(paths["menu"], encoding="utf-8") as f:
            menu_data = json.load(f)

        # ------------------------------------------------------------
        # QML engine setup
        # ------------------------------------------------------------
        engine = QQmlApplicationEngine()
        ctx = engine.rootContext()

        engine.addImportPath(os.path.join(os.path.dirname(PySide6.__file__), "qml"))
        engine.addImportPath(QLibraryInfo.path(QLibraryInfo.LibraryPath.Qml2ImportsPath))

        # ⭐ Add YOUR project’s QML folder
        engine.addImportPath(str(paths["qml"]))


        # Expose Python objects to QML
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

        # ------------------------------------------------------------
        # Load QML
        # ------------------------------------------------------------
        engine.load(QUrl.fromLocalFile(str(paths["qml"] / "Framework-1.qml")))

        if not engine.rootObjects():
            logging.error("QML FAILED to load")
            return -1

        print(">>> Framework: QML loaded successfully")

        # ------------------------------------------------------------
        # Server cache + manifest paths
        # ------------------------------------------------------------
        server_cache_root_v2 = paths["server_cache_root_v2"]
        server_manifest_path = paths["server_manifest_v2"]

        # ------------------------------------------------------------
        # Cache builder worker
        # ------------------------------------------------------------
        def run_server_cache_builder(manifest: dict):
            try:
                print("[CacheBuilder_v2] Initializing server cache builder...")
                builder = CacheBuilder_v2(manifest, server_cache_root_v2)

                builder.cacheStarted.connect(lambda: print("[CacheBuilder_v2] Cache build started"))
                builder.cacheProgress.connect(lambda done, total: None)
                builder.cacheFinished.connect(lambda: print("[CacheBuilder_v2] Cache build finished"))

                builder.run()

            except Exception as e:
                print(f"[CacheBuilder_v2] ERROR during cache build: {e}")
                logging.exception("CacheBuilder_v2 encountered an error.")

        # ------------------------------------------------------------
        # Manifest loaded handler
        # ------------------------------------------------------------
        def on_manifest_loaded(manifest: dict):
            notifier.post_notification("Manifest loaded.", False)

            if manifest.get("content_changed") is True:
                print("[Framework] Launching CacheBuilder_v2 in background...")
                notifier.post_notification("Library changed — rebuilding cache…", False)

                threading.Thread(
                    target=run_server_cache_builder,
                    args=(manifest,),
                    # daemon=True
                ).start()
                return

            print("[Framework] No content_changed flag — skipping rebuild.")

        manifest_updater.manifestLoaded.connect(on_manifest_loaded)

        # ------------------------------------------------------------
        # Defer bootstrap/update until Qt event loop is running
        # ------------------------------------------------------------
        def start_manifest_work():
            if not server_manifest_path.exists():
                notifier.post_notification("Building manifest for the first time…", False)
                manifest_updater.bootstrap_manifest()
            else:
                print("MANIFEST EXISTS — UPDATE IN BACKGROUND (via QTimer)")
                manifest_updater.update_manifest_background()

        QTimer.singleShot(0, start_manifest_work)

        # ------------------------------------------------------------
        # Database status
        # ------------------------------------------------------------
        if not myLibrary:
            notifier.post_notification("Database Connection Failed!", True)
            logging.error("Server not running or no libraries found.")
            return -1
        else:
            notifier.post_notification("Database Connected: MediaVerse is Online", False)

        return app.exec()

    except Exception:
        logging.exception("An unhandled exception occurred:")
        return -1


if __name__ == "__main__":
    sys.exit(main())
