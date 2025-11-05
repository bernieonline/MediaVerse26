import mysql.connector
from PyQt5.QtWidgets import QApplication, QMainWindow, QMessageBox

class getWindow(QMainWindow):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        # MySQL connection configuration
        self.config = {
            'host': '192.168.1.100',          # MySQL server IP (TrueNAS jail)
            'user': 'root',                   # MySQL username
            'password': 'Ub24MySql!!!',       # MySQL password
            'database': 'mediamanager',       # Database name
            'ssl_ca': r'D:\PythonMusic\pythonProject6\music-new\Certificates\ca-cert.pem',  # Path to the CA certificate
            'ssl_verify_cert': False,         # Disable certificate verification (optional for self-signed certs)
            'connection_timeout': 30,         # Connection timeout in seconds
            'ssl_disabled': False,            # Set to True if you want to disable SSL (not recommended)
        }
        print("Here............1")
        # Test MySQL connection
        self.test_db_connection()

    def test_db_connection(self):
        try:
            print("Here............2")
            # Try to establish the connection
            connection = mysql.connector.connect(**self.config)
            print("Connection successful")
            print("Here............3")
            # Optionally, query the database to test it further
            cur = connection.cursor()
            cur.execute("SELECT DATABASE()")  # Example query to check connection
            result = cur.fetchone()
            print(f"Connected to database: {result[0]}")

            # Close connection
            connection.close()

        except mysql.connector.Error as err:
            # Handle connection errors
            print(f"Error: {err}")
            QMessageBox.critical(self, "Database Connection Error", f"Failed to connect to the database: {err}")

#if __name__ == "__main__":
    #app = QApplication([])  # Create the application instance
    #window = getWindow()     # Create an instance of your window
    #window.show()            # Show the window
    #app.exec_()              # Start the event loop
