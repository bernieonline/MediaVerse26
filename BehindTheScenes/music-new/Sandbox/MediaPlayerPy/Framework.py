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
from Manifest import ManifestUpdater
import threading




def main():
    try:
       
        # Configure logging
        log_file = paths["log"]
        logging.basicConfig(
            filename=log_file,
            level=logging.DEBUG,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )


        config_path = paths["config"]   # relative path to Config.json
        fileSystem = FileSystem()
        settings_manager = SettingsManager(config_path, fileSystem)


      

        print(".........................1")

     



        # ✅ Explicit trigger right after creating the object
        #loads all key value pairs into memory from the cofig file on startup
        settings_manager.load_settings()


        manifest_updater = ManifestUpdater()
        print(".........................2")







        # Build/refresh cache at startup
        update_cache()
        print("✅ Cache updater finished, launching QML engine...")

        # Force Material style before QML loads
        os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"

        app = QApplication(sys.argv)

        # Get media library list
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

        # Add Qt plugin paths
        QCoreApplication.addLibraryPath(str(Path(sys.modules["PySide6"].__file__).parent / "plugins"))
        os.add_dll_directory(str(Path(sys.modules["PySide6"].__file__).parent))

        #Munu paths
        with open(paths["menu"], encoding="utf-8") as f:
            menu_data = json.load(f)


        # Create QML engine
        engine = QQmlApplicationEngine()
        engine.addImportPath(os.path.join(os.path.dirname(PySide6.__file__), "qml"))
        engine.addImportPath(QLibraryInfo.path(QLibraryInfo.LibraryPath.Qml2ImportsPath))
        #engine.rootContext().setContextProperty("imagesPath", str(paths["assets"].as_posix()))
        engine.rootContext().setContextProperty("imagesPath", Path(paths["assets"]).as_uri())
        #engine.rootContext().setContextProperty("menuData", menu_data)
        engine.rootContext().setContextProperty("centralMenuData", menu_data)
        engine.rootContext().setContextProperty("SettingsManager", settings_manager)
        engine.rootContext().setContextProperty("fileSystemManager", fileSystem)
        



        print("Data being passed to QML as menuData:", menu_data)


        # Create persistent Python objects (prevent GC) and expose to QML
        xml_controller = XmlController()
        xml_provider = GetXMLDetails()

        if myLibrary and "path" in myLibrary[0]:
            root_path = myLibrary[0]["path"]
            fileSystem.update_folders(root_path)


        ctx = engine.rootContext()

        ctx.setContextProperty("manifestUpdater", manifest_updater)

        ctx.setContextProperty("fileSystemManager", fileSystem)

        
        ctx.setContextProperty("xmlController", xml_controller)
        ctx.setContextProperty("xmlDetails", xml_provider)
        ctx.setContextProperty("myLibraryModel", myLibrary)

        # Expose cache paths
        ctx.setContextProperty("thumbsPath", paths["thumbs"].as_uri())
        
        
        ctx.setContextProperty("displayPath", paths["display"].as_uri())

        # Load QML
        engine.load(QUrl.fromLocalFile(str(paths["qml"] / "Framework-1.qml")))

        if not engine.rootObjects():
            logging.error("QML FAILED to load")
            return -1
        
        threading.Thread(target=manifest_updater.update_manifest_background, daemon=False).start()
        
        # Explicitly show the root window
        #root = engine.rootObjects()[0]
        #root.show()
        #root.showFullScreen()
        #app.setGeometry(100, 100, 1280, 720)

        print("✅ Framework-1.qml loaded successfully.")
        return app.exec()

    except Exception:
        logging.exception("An unhandled exception occurred:")
        return -1

if __name__ == "__main__":
    sys.exit(main())