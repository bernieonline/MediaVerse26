import sys
import os
import logging
from pathlib import Path
from myPyForQMLFunctions import get_subfolder_names_test
import PySide6
from PySide6.QtWidgets import QApplication, QMessageBox
from PySide6.QtCore import QCoreApplication, QUrl
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QLibraryInfo
from PySide6.QtCore import QUrl

#Import os



from XML_Details import GetXMLDetails

#db_path = Path("D:/PythonMusic/pythonproject2026/BehindTheScenes/music-new")
#sys.path.append(str(db_path))

# Dynamically resolve the absolute path to music-new
project_root = Path(__file__).resolve().parents[2] / "music-new"
sys.path.append(str(project_root))

print("✅ Added to sys.path:", project_root)

# Add the parent folder of dbMySql to sys.path
sys.path.append(str(Path(__file__).resolve().parent.parent.parent))


from dbMySql.db_utils import getLibraryList 

#import sys
from pathlib import Path
from xml_controller import XmlController

# Ensure the current script's folder is in sys.path
sys.path.append(str(Path(__file__).resolve().parent))



# Configure logging
log_file = Path(__file__).parent.parent.parent / "application.log"
logging.basicConfig(filename=log_file, level=logging.DEBUG, 
                    format='%(asctime)s - %(levelname)s - %(message)s')

if __name__ == "__main__":
    try:
        app = QApplication(sys.argv)

        #pass list of medial library object back to Framework-1.qml for display taken from query function
        myLibrary = getLibraryList()
        if not myLibrary:
            error_message = "Server not running or no libraries found."
            logging.error(error_message)
            msg_box = QMessageBox()
            msg_box.setIcon(QMessageBox.Icon.Critical)
            msg_box.setText(error_message)
            msg_box.setWindowTitle("Database Connection Error")
            msg_box.exec()
            sys.exit(-1)

        # ADDED FOR DEBUGGING: Print the data being sent to QML
        print("Data being passed to QML as myLibraryModel:", myLibrary)


        QCoreApplication.addLibraryPath(str(Path(sys.modules["PySide6"].__file__).parent / "plugins"))

        # Add the PySide6 package directory to the DLL search path.
        # This is required on Windows for QML to find its dependent Qt DLLs.
        pyside6_dir = Path(sys.modules["PySide6"].__file__).parent
        os.add_dll_directory(str(pyside6_dir))

        engine = QQmlApplicationEngine()

        pyside_qml_path = os.path.join(os.path.dirname(PySide6.__file__), "qml")
        engine.addImportPath(pyside_qml_path)

        # Verify it worked (optional, for debugging)
        print("QML Import Paths inc effects:")
        for path in engine.importPathList():
            print(f"  {path}")

        # Use QLibraryInfo to get the built-in QML import path
        qml_import_path = QLibraryInfo.path(QLibraryInfo.LibraryPath.Qml2ImportsPath)
        engine.addImportPath(qml_import_path)

        # Force Material style
        os.environ["QT_QUICK_CONTROLS_STYLE"] = "Material"




        #xml processing
        # Create controller instance
        xmlController = XmlController()
        # Expose to QML
        engine.rootContext().setContextProperty("xmlController", xmlController)

        # Register the FileSystem class with QML
        from FileSystem import FileSystem
        file_system = FileSystem()
        #makes fileSystemManager directly accessible from QML
        engine.rootContext().setContextProperty("fileSystemManager", file_system)

        engine.rootContext().setContextProperty("myLibraryModel", myLibrary)


        #these expose the xml deta in the detail view after clicking an image
        xml_provider = GetXMLDetails()
        engine.rootContext().setContextProperty("xmlDetails", xml_provider)

        engine.load(QUrl.fromLocalFile(str(Path(__file__).parent.parent / "MediaPlayerQML" / "Framework-1.qml")))

        root_objs = engine.rootObjects()
        if root_objs:
            root = root_objs[0]
            root.setProperty("xmlDetails", xml_provider)
    

        if not engine.rootObjects():
            logging.error("QML FAILED to load")
            sys.exit(-1)
         
        #print("getting folders from path")
        #get_subfolder_names_test()

        sys.exit(app.exec())

    except Exception as e:
        logging.exception("An unhandled exception occurred:")
        sys.exit(-1)