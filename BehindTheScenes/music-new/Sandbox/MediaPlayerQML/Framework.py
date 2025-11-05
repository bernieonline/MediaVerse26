import sys
import os
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtCore import QCoreApplication, QUrl
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QLibraryInfo

if __name__ == "__main__":
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

    engine.load(QUrl("Framework-1.qml"))

    if not engine.rootObjects():
        print("QML FAILED ❌")
        sys.exit(-1)

    sys.exit(app.exec())
