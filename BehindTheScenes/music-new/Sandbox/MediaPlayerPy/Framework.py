import sys
import os
import logging
from pathlib import Path
from myPyForQMLFunctions import get_subfolder_names_test


from PySide6.QtGui import QGuiApplication
from PySide6.QtCore import QCoreApplication, QUrl
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QLibraryInfo

#db_path = Path("D:/PythonMusic/pythonproject2026/BehindTheScenes/music-new")
#sys.path.append(str(db_path))

# Dynamically resolve the absolute path to music-new
project_root = Path(__file__).resolve().parents[2] / "music-new"
sys.path.append(str(project_root))

print("✅ Added to sys.path:", project_root)

# Add the parent folder of dbMySql to sys.path
sys.path.append(str(Path(__file__).resolve().parent.parent.parent))


from dbMySql.db_utils import getLibraryList 

import sys
from pathlib import Path

# Ensure the current script's folder is in sys.path
sys.path.append(str(Path(__file__).resolve().parent))



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

        #pass list of medial library object back to Framework-1.qml for display taken from query function
        myLibrary = getLibraryList()
        engine.rootContext().setContextProperty("myLibraryModel", myLibrary)

        engine.load(QUrl.fromLocalFile(str(Path(__file__).parent.parent / "MediaPlayerQML" / "Framework-1.qml")))

        if not engine.rootObjects():
            logging.error("QML FAILED to load")
            sys.exit(-1)
        
        
        #print("getting folders from path")
        #get_subfolder_names_test()


        sys.exit(app.exec())


    except Exception as e:
        logging.exception("An unhandled exception occurred:")
        sys.exit(-1)