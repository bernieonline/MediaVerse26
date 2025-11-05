import sys

# If VS Code finds this, you have no errors!
from PySide6.QtWidgets import QApplication, QLabel

# This will print the exact location of the library
print(f"PySide6 imported from: {sys.modules['PySide6'].__file__}")