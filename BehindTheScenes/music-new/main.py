import sys
import mysql.connector
from PyQt5.QtWidgets import QApplication, QLabel, QMainWindow
from getMainWindow import getWindow
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QFont
import logging


def disable_logging():
        logging.getLogger().setLevel(logging.CRITICAL)

def enable_logging(level=logging.INFO):
        logging.getLogger().setLevel(level)



def main():

    # main.py
    __version__ = "1.1.0"


     # Configuration setting to enable or disable logging
    enable_logging = True  # Set to True to enable logging, False to disable

    # Remove existing handlers
    for handler in logging.root.handlers[:]:
        logging.root.removeHandler(handler)

    if enable_logging:
        # Configure logging
        logging.basicConfig(
            filename='D:\\PythonMusic\\pythonProject6\\music-new\\application.log',  # Use double backslashes
            level=logging.INFO,  # Set the logging level
            format='%(asctime)s - %(levelname)s - %(message)s',
            # force=True  # Uncomment if needed to force reconfiguration
        )
    else:
        # Set logging level to CRITICAL to suppress lower-severity messages
        logging.basicConfig(level=logging.CRITICAL)

    # Test message to ensure logging is working
    logging.info("Logging is successfully set up!")

    try:
        
        logging.info("Starting the application")


        # Set application attributes before creating the QApplication instance
        QApplication.setAttribute(Qt.AA_EnableHighDpiScaling)
        QApplication.setAttribute(Qt.AA_UseHighDpiPixmaps)

        # Create the application instance
        app = QApplication(sys.argv)

        # Set default font size for the application
        font = QFont()
        font.setPointSize(12)  # Set the desired font size
        app.setFont(font)

        logging.info("Created QApplication instance")


        # Create an instance of your window
        window = getWindow()
        logging.info("Created QApplication instance")


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