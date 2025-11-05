import mysql.connector
from MediaManager import Ui_MainWindow       # MainWindow is the file created by pyuic, Ui_M.. is a class in that file
from PyQt5 import QtWidgets
from PyQt5.QtWidgets import QMainWindow, QMessageBox, QApplication


class getWindow(QtWidgets.QMainWindow):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)  # Initialize QMainWindow
        
        # Set up the GUI
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)
        
        # Database configuration
        self.config = {
            'host': '192.168.1.100',          # MySQL server IP (TrueNAS jail)
            'user': 'root',                   # MySQL username
            'password': 'Ub24MySql!!!',       # MySQL password
            'database': 'mediamanager',       # Database name
            'ssl_ca': r'X:\Python Projects\BehindTheScenes\pythonProject5\music-new\Certificates\ca-cert.pem',  # Path to the CA certificate
            'ssl_verify_cert': False,         # Disable certificate verification (for self-signed certs)
            'connection_timeout': 30          # Connection timeout in seconds
        }
        
        print("GUI initialized")

    def connect_to_db(self):
        try:
            print("Attempting connection to database...")
            self.connection = mysql.connector.connect(**self.config)
            
            if self.connection.is_connected():
                print("Connection established successfully!")
            else:
                print("Connection failed without exception.")
        
        except mysql.connector.Error as err:
            print(f"Connection Failed: {err}")
            self.show_no_connection_message()
        
        except Exception as e:
            print(f"Unexpected error: {e}")
    
    def show_no_connection_message(self):
        # Display a message box if connection fails
        QMessageBox.critical(self, "Connection Error", "Failed to connect to the database.")

if __name__ == "__main__":
    app = QApplication([])  # Create the application instance
    window = getWindow()     # Create an instance of your window
    window.show()            # Show the window
    window.connect_to_db()   # Attempt to connect to the database after the window is shown
    app.exec_()

