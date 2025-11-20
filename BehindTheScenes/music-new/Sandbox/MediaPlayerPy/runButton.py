from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QCoreApplication, QLibraryInfo, QUrl
import sys, os
from pathlib import Path

app = QApplication(sys.argv)

# Patch DLL and plugin paths
pyside6_dir = Path(sys.modules["PySide6"].__file__).parent
os.add_dll_directory(str(pyside6_dir))
QCoreApplication.addLibraryPath(str(pyside6_dir / "plugins"))

# Patch QML import path
qml_import_path = QLibraryInfo.path(QLibraryInfo.LibraryPath.Qml2ImportsPath)
engine = QQmlApplicationEngine()
engine.addImportPath(qml_import_path)

# Load your test QML
qml_file = Path("D:/PythonMusic/pythonproject2026/BehindTheScenes/music-new/Sandbox/MediaPlayerQML/main.qml")
engine.load(QUrl.fromLocalFile(str(qml_file)))

if not engine.rootObjects():
    print("❌ Failed to load QML")
    sys.exit(-1)

sys.exit(app.exec())