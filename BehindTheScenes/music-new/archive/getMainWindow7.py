import mysql.connector
from MediaManager import Ui_MainWindow
from PyQt5.QtWidgets import QApplication, QMainWindow, QMessageBox

class getWindow(QMainWindow):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        # Set up the GUI
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)

        # MySQL connection configuration
        self.config = {
            'host': '192.168.1.100',          # MySQL server IP (TrueNAS jail)
            'user': 'root',                   # MySQL username
            'password': 'Ub24MySql!!!',       # MySQL password
            'database': 'mediamanager',       # Database name
            #'ssl_ca': r'D:\PythonMusic\pythonProject6\music-new\Certificates\ca-cert.pem',  # Path to the CA certificate
            #'ssl_verify_cert': False,         # Disable certificate verification (optional for self-signed certs)
            'connection_timeout': 30,         # Connection timeout in seconds
            #'ssl_disabled': False,            # Set to True if you want to disable SSL (not recommended)
            'port' : 3306
        }

        # Connect the menu action to the database function
        self.ui.actionSelect_Location.triggered.connect(self.doDb)

    def doDb(self):
        print("Attempting to connect to the database...")  # Debug line
        try:

            # MySQL connection configuration
            config = {
            'host': '192.168.1.100',          # MySQL server IP (TrueNAS jail)
            'user': 'root',                   # MySQL username
            'password': 'Ub24MySql!!!',       # MySQL password
            'database': 'mediamanager',       # Database name
            'ssl_ca': r'D:\PythonMusic\pythonProject6\music-new\Certificates\ca-cert.pem',  # Path to the CA certificate
            'ssl_verify_cert': False,         # Disable certificate verification (optional for self-signed certs)
            'connection_timeout': 30,         # Connection timeout in seconds
            'ssl_disabled': False,            # Set to True if you want to disable SSL (not recommended)
            'port' : 3306
        }
            # Try to establish the connection
            
            connection = mysql.connector.connect(**self.config)
            print("Connection successful")

            # Optionally, query the database to test it further
            cur = connection.cursor()
            cur.execute("SELECT ext FROM mediatypes")  # Example query
            for row in cur.fetchall():
                print(row[0])  # Print the result from the query

            # Close the connection after query
            connection.close()
        except mysql.connector.Error as err:
            print(f"Error: {err}")  # Print the actual error
            QMessageBox.critical(self, "Database Connection Error", f"Failed to connect to the database: {err}")
        except Exception as ex:
            print(f"Unexpected error: {ex}")  # Catch any unexpected exceptions
            QMessageBox.critical(self, "Unexpected Error", f"An unexpected error occurred: {ex}")

if __name__ == "__main__":
    app = QApplication([])  # Create the application instance
    window = getWindow()     # Create an instance of your window
    window.show()            # Show the window
    app.exec_()              # Start the event loop
