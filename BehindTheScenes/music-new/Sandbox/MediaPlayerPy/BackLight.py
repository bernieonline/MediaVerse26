import sys
import os
import logging
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtCore import QCoreApplication, QUrl
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QLibraryInfo

# Configure logging
log_file = Path(__file__).parent.parent.parent / "application.log"
logging.basicConfig(filename=log_file, level=logging.DEBUG, 
                    format='%(asctime)s - %(levelname)s - %(message)s')

if __name__ == "__main__":
    try:
        app = QGuiApplication(sys.argv)

        QCoreApplication.addLibraryPath(str(Path(sys.modules["PySide6"].__file__).parent / "plugins"))

        # Add the PySide6 package directory to the DLL search path.
        # This is required on Windows for QML to find its dependent Qt DLLs.
        pyside6_dir = Path(sys.modules["PySide6"].__file__).parent
        os.add_dll_directory(str(pyside6_dir))

        engine = QQmlApplicationEngine()

        # Use QLibraryInfo to get the built-in QML import path
        qml_import_path = QLibraryInfo.path(QLibraryInfo.LibraryPath.Qml2ImportsPath)
        engine.addImportPath(qml_import_path)

        # Register the FileSystem class with QML
        from FileSystem import FileSystem
        file_system = FileSystem()
        engine.rootContext().setContextProperty("fileSystemManager", file_system)

        engine.load(QUrl.fromLocalFile(str(Path(__file__).parent.parent / "MediaPlayerQML" / "BackLight.qml")))

        if not engine.rootObjects():
            logging.error("QML FAILED to load")
            sys.exit(-1)

        sys.exit(app.exec())

    except Exception as e:
        logging.exception("An unhandled exception occurred:")
        sys.exit(-1)
