import sys
import os
import logging
import json

from pathlib import Path
import PySide6
from PySide6.QtWidgets import QApplication, QMessageBox
from PySide6.QtCore import QCoreApplication, QUrl, QLibraryInfo
from PySide6.QtQml import QQmlApplicationEngine

from cache_updater import update_cache
from project_paths import paths
from XML_Details import GetXMLDetails
from dbMySql.db_utils import getLibraryList
from xml_controller import XmlController
from FileSystem import FileSystem
from Settings_Manager import SettingsManager

# NEW: use your v2 wrapper exactly as intended
from Manifest_v2_wrapper import ManifestUpdater_v2 as ManifestUpdater

import threading


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
        # Settings + filesystem
        # ------------------------------------------------------------
        config_path = paths["config"]
        fileSystem = FileSystem()
        settings_manager = SettingsManager(config_path, fileSystem)

        print(".........................1")

        # Load settings immediately
        settings_manager.load_settings()

        # ------------------------------------------------------------
        # Manifest updater (v2 wrapper)
        # ------------------------------------------------------------
        manifest_updater = ManifestUpdater()
        print(".........................2")

        # ------------------------------------------------------------
        # Cache updater (your existing system)
        # ------------------------------------------------------------
        update_cache()
        print("✅ Cache updater finished, launching QML engine...")

        # ------------------------------------------------------------
        # Qt setup
        # ------------------------------------------------------------
        os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"
        app = QApplication(sys.argv)

        # ------------------------------------------------------------
        # Database library list
        # ------------------------------------------------------------
        myLibrary = getLibraryList()
        if not myLibrary:
            error_message = "Server not running or no libraries found."
            logging.error(error_message)
            msg_box = QMessageBox()
            msg_box.setIcon(QMessageBox.Icon.Critical)
            msg_box.setText(error_message)
            msg_box.setWindowTitle("Database Connection Error")
            msg_box.exec()
            return -1

        print("Data being passed to QML as myLibraryModel:", myLibrary)

        # ------------------------------------------------------------
        # QML engine setup
        # ------------------------------------------------------------
        QCoreApplication.addLibraryPath(str(Path(sys.modules["PySide6"].__file__).parent / "plugins"))
        os.add_dll_directory(str(Path(sys.modules["PySide6"].__file__).parent))

        with open(paths["menu"], encoding="utf-8") as f:
            menu_data = json.load(f)

        engine = QQmlApplicationEngine()
        engine.addImportPath(os.path.join(os.path.dirname(PySide6.__file__), "qml"))
        engine.addImportPath(QLibraryInfo.path(QLibraryInfo.LibraryPath.Qml2ImportsPath))

        engine.rootContext().setContextProperty("imagesPath", Path(paths["assets"]).as_uri())
        engine.rootContext().setContextProperty("centralMenuData", menu_data)
        engine.rootContext().setContextProperty("SettingsManager", settings_manager)
        engine.rootContext().setContextProperty("fileSystemManager", fileSystem)

        print("Data being passed to QML as menuData:", menu_data)

        # ------------------------------------------------------------
        # XML + filesystem controllers
        # ------------------------------------------------------------
        xml_controller = XmlController()
        xml_provider = GetXMLDetails()

        if myLibrary and "path" in myLibrary[0]:
            root_path = myLibrary[0]["path"]
            fileSystem.update_folders(root_path)

        ctx = engine.rootContext()

        # Expose manifest updater to QML
        ctx.setContextProperty("manifestUpdater", manifest_updater)

        ctx.setContextProperty("fileSystemManager", fileSystem)
        ctx.setContextProperty("xmlController", xml_controller)
        ctx.setContextProperty("xmlDetails", xml_provider)
        ctx.setContextProperty("myLibraryModel", myLibrary)

        # Cache paths
        ctx.setContextProperty("thumbsPath", paths["thumbs"].as_uri())
        ctx.setContextProperty("displayPath", paths["display"].as_uri())

        # ------------------------------------------------------------
        # Load QML
        # ------------------------------------------------------------
        engine.load(QUrl.fromLocalFile(str(paths["qml"] / "Framework-1.qml")))

        if not engine.rootObjects():
            logging.error("QML FAILED to load")
            return -1

        # ------------------------------------------------------------
        # Start manifest build in background
        # ------------------------------------------------------------
        threading.Thread(
            target=manifest_updater.update_manifest_background,
            daemon=False
        ).start()

        print("✅ Framework-1.qml loaded successfully.")
        return app.exec()

    except Exception:
        logging.exception("An unhandled exception occurred:")
        return -1


if __name__ == "__main__":
    sys.exit(main())