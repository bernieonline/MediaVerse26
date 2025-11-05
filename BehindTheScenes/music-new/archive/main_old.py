import sys
import mysql.connector
from PyQt5.QtWidgets import QApplication, QLabel, QMainWindow
from getMainWindow_old import getWindow
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QFont
import logging


def main():
    # Configure logging
    logging.basicConfig(
        filename='D:\\PythonMusic\\pythonProject6\\music-new\\application.log',  # Use double backslashes
        level=logging.INFO,           # Set the logging level
        format='%(asctime)s - %(levelname)s - %(message)s'
        

    )

    try:
        # Set application attributes before creating the QApplication instance
        QApplication.setAttribute(Qt.AA_EnableHighDpiScaling)
        QApplication.setAttribute(Qt.AA_UseHighDpiPixmaps)

        # Create the application instance
        app = QApplication(sys.argv)

        # Set default font size for the application
        font = QFont()
        font.setPointSize(12)  # Set the desired font size
        app.setFont(font)

        # Create an instance of your window
        window = getWindow()

        # Show the window
        window.show()

        # Start the event loop
        result = app.exec_()

    except Exception as e:
        logging.error("An error occurred: %s", e)
        sys.exit(1)

    sys.exit(result)

if __name__ == "__main__":
    main()