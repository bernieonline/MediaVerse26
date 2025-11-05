import mysql.connector
from MediaManager import Ui_MainWindow
from PyQt5 import QtWidgets
from PyQt5.QtCore import QThread, pyqtSignal
from PyQt5.QtWidgets import QApplication, QMainWindow, QFileDialog, QMessageBox
import os
import time

class DatabaseConnectionThread(QThread):
    connection_success = pyqtSignal()
    connection_failed = pyqtSignal(str)

    def __init__(self, config):
        super().__init__()
        self.config = config

    def run(self):
        try:
            connection = mysql.connector.connect(**self.config)
            if connection.is_connected():
                self.connection_success.emit()
            else:
                self.connection_failed.emit("Connection failed without exception.")
        except mysql.connector.Error as err:
            self.connection_failed.emit(f"Connection Failed: {err}")
        except Exception as e:
            self.connection_failed.emit(f"Unexpected error: {e}")

class getWindow(QtWidgets.QMainWindow):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)  # Subclassing QMainWindow

        # Set up the GUI
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)

        

        print("GUI initialized")

        # Connect the "Choose Location" action to the method
        self.ui.actionSelect_Location.triggered.connect(self.choose_location)

        # To store media types and extensions
        self.media_types = {}

    def connect_to_db(self):
        # Set up the thread and signals for database connection
        self.db_thread =  connection = mysql.connector.connect(
        host='192.168.1.100',  # TrueNAS server host
        user='root',           # Username
        password='Ub24MySql!!!',  # Password
        database='MediaManager'   # Database name
        )
        self.db_thread.connection_success.connect(self.on_connection_success)
        self.db_thread.connection_failed.connect(self.on_connection_failed)
        self.db_thread.start()

    def on_connection_success(self):
        print("Connection established successfully!")
        self.load_media_types()

    def on_connection_failed(self, error_message):
        print(error_message)
        self.show_no_connection_message()

    def show_no_connection_message(self):
        # Display a message box if connection fails
        QMessageBox.critical(self, "Connection Error", "Failed to connect to the database.")

    def load_media_types(self):
        # Query the database for media types and extensions
        try:
            connection = mysql.connector.connect(**self.config)
            cursor = connection.cursor()
            cursor.execute("SELECT Type, Ext FROM meditypes")
            result = cursor.fetchall()
            for type_, ext in result:
                if type_ not in self.media_types:
                    self.media_types[type_] = []
                self.media_types[type_].append(ext.lower())
            cursor.close()
            connection.close()
            print(f"Loaded media types: {self.media_types}")
        except mysql.connector.Error as err:
            print(f"Database error: {err}")

    def choose_location(self):
        # This method opens the folder selection dialog when the action is triggered
        options = QFileDialog.Options()
        folder_name = QFileDialog.getExistingDirectory(self, "Select Folder", "", options=options)
        
        if folder_name:
            print(f"Selected location: {folder_name}")
            # After the user selects the folder, you can call another function to process files in that location
            self.process_files_in_location(folder_name)
        else:
            print("No location selected.")

    def process_files_in_location(self, folder_path):
        # This method is called once a folder is selected; it uses os.walk to search for media files
        print(f"Processing files in: {folder_path}")
        for root, dirs, files in os.walk(folder_path):
            # Check if the folder contains any media files
            folder_contains_media = False
            for file in files:
                if self.is_media_file(file):
                    folder_contains_media = True
                    break  # If at least one file matches, break out of the loop

            if folder_contains_media:
                # Process the folder if it contains media files
                print(f"Processing media in folder: {root}")
                self.process_media_files(root, files)

    def is_media_file(self, file_name):
        # Check if the file extension matches any known media types
        ext = os.path.splitext(file_name)[1].lower()
        for media_type, extensions in self.media_types.items():
            if ext in extensions:
                return True
        return False

    def process_media_files(self, folder_path, files):
        # This method processes media files in a folder
        for file in files:
            if self.is_media_file(file):
                print(f"Found media file: {os.path.join(folder_path, file)}")
                self.insert_media_file_details(folder_path, file)

    def insert_media_file_details(self, folder_path, file_name):
        # Collect file details
        file_path = os.path.join(folder_path, file_name)
        file_type = self.get_file_type(file_name)
        file_size = os.stat(file_path).st_size  # Get file size in bytes
        file_creation_time = os.path.getctime(file_path)
        file_creation_date = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(file_creation_time))

        # Insert file details into the database
        try:
            connection = mysql.connector.connect(**self.config)
            cursor = connection.cursor()
            cursor.execute("""
                INSERT INTO MediaFileDetail (file_path, file_name, file_type, file_size, file_creation_date, collection, category)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (file_path, file_name, file_type, file_size, file_creation_date, '', ''))  # Empty collection and category for now
            connection.commit()
            print(f"Inserted {file_name} details into the database.")
            cursor.close()
            connection.close()
        except mysql.connector.Error as err:
            print(f"Database error: {err}")

    def get_file_type(self, file_name):
        # Derive file type based on file extension
        ext = os.path.splitext(file_name)[1].lower()
        for media_type, extensions in self.media_types.items():
            if ext in extensions:
                return media_type
        return 'Unknown'

if __name__ == "__main__":
    app = QApplication([])  # Create the application instance
    window = getWindow()     # Create an instance of your window
    window.show()            # Show the window
    window.connect_to_db()   # Attempt to connect to the database after the window is shown
    app.exec_()              # Start the event loop
