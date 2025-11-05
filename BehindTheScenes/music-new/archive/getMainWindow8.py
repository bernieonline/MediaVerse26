import mysql.connector
from MediaManager import Ui_MainWindow
from PyQt5.QtWidgets import QApplication, QMainWindow, QMessageBox

class getWindow(QMainWindow):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        # Set up the GUI
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)

     

        # Connect the menu action to the database function
        #self.ui.actionSelect_Location.triggered.connect(self.doDb)
        self.ui.actionChoose_Local_Drive.triggered.connect(self.doDb)

    def doDb(self):
        print("Attempting to connect to the database...")  # Debug line
        
        connection = mysql.connector.connect(
        host='192.168.1.100',  # TrueNAS server host
        user='root',           # Username
        password='Ub24MySql!!!',  # Password
        database='MediaManager'   # Database name
        )
        try:
            if connection.is_connected():
                print("Connected to the MySQL database BG")

                # Example query to ensure connection is working
                cursor = connection.cursor()
                cursor.execute("SELECT DATABASE();")
                print("Connected to database:", cursor.fetchone())
                cur = connection.cursor()
                cur.execute("SELECT ext FROM mediatypes")  # Example query
                for row in cur.fetchall():
                    print(row[0])  # Print the result from the query

        except mysql.connector.Error as err:
            print(f"Error: {err}")  # Print the actual error
            QMessageBox.critical(self, "Database Connection Error", f"Failed to connect to the database: {err}")
        except Exception as ex:
            print(f"Unexpected error: {ex}")  # Catch any unexpected exceptions
            QMessageBox.critical(self, "Unexpected Error", f"An unexpected error occurred: {ex}")

#if __name__ == "__main__":
    #app = QApplication([])  # Create the application instance
    #window = getWindow()     # Create an instance of your window
    #window.show()            # Show the window
    #app.exec_()              # Start the event loop
