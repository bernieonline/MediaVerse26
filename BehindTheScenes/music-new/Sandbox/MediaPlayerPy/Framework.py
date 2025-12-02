import sys
import os
import logging
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

# Configure logging
log_file = paths["log"]
logging.basicConfig(
    filename=log_file,
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def main():
    try:
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

        # Create QML engine
        engine = QQmlApplicationEngine()
        engine.addImportPath(os.path.join(os.path.dirname(PySide6.__file__), "qml"))
        engine.addImportPath(QLibraryInfo.path(QLibraryInfo.LibraryPath.Qml2ImportsPath))

        # Create persistent Python objects (prevent GC) and expose to QML
        file_system = FileSystem()
        xml_controller = XmlController()
        xml_provider = GetXMLDetails()

        ctx = engine.rootContext()
        ctx.setContextProperty("fileSystemManager", file_system)
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