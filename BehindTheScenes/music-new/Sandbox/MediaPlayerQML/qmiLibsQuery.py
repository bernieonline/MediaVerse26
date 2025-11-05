import sys
from PySide6.QtCore import QCoreApplication
from PySide6.QtQml import QQmlEngine

# Create an application instance FIRST
app = QCoreApplication(sys.argv)

engine = QQmlEngine()

print("\nQML Import Paths:")
for path in engine.importPathList():
    print("  ", path)
