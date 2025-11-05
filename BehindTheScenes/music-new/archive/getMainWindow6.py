import mysql.connector
from MediaManager import Ui_MainWindow
from PyQt5 import QtWidgets
#from PyQt5.QtCore import QThread, pyqtSignal
from PyQt5.QtWidgets import QApplication, QMainWindow, QFileDialog, QMessageBox
#import time
#import os
#from PyQt5.QtCore import QTimer


class getWindow(QtWidgets.QMainWindow):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)  # class super subclasses QtWidgets.QMainWindow on which the form is based

        # in the init phase, preceds all new creations with self. to make them accessible from anywhere
        # next 2 actions are critical to setting up the gui that we created

           # Set up the GUI
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)

        self.config = {
        'host': '192.168.1.100',          # MySQL server IP (TrueNAS jail)
        'user': 'root',                   # MySQL username
        'password': 'Ub24MySql!!!',       # MySQL password
        'database': 'mediamanager',       # Database name
        'ssl_ca': 'X:\Python Projects\BehindTheScenes\pythonProject5\music-new\Certificates\ca-cert.pem',  # Path to the CA certificate (Windows-style path)
        'ssl_verify_cert': False,         # Disable certificate verification (optional for self-signed certs)
        'connection_timeout': 30,         # Connection timeout in seconds
        'ssl_disabled': False,            # Set this to True if you want to disable SSL (not recommended)
        # Alternatively, you can use ssl_mode='PREFERRED' to allow self-signed certs
        #'ssl_mode': 'PREFERRED'           # PREFERRED allows using self-signed certs
        }

        print("Connected menu action to doDb Pre") # Debugging statemen
        self.ui.actionSelect_Location.triggered.connect(self.doDb)
        print("Connected menu action to doDb Post") # Debugging statemen


      


    def doDb(self): 

        print("creating connection aaa")
        connection = mysql.connector.connect(**self.config)
        print("creating connection bbb")
        cur = connection.cursor()
        cur.execute("SELECT ext FROM mediatypes")
        for row in cur.fetchall():
            print(row[0])
         # Initialize media_types as an empty dictionary to store media types and extensions
        #self.media_types = {}

        # Database configuration
   

    
        
   


      
       
      







#if __name__ == "__main__":
        #app = QApplication([])  # Create the application instance
        #window = getWindow()     # Create an instance of your window
        #window.show() 
        #print("..................1a")           # Show the window
    # Delay the database connection slightly after window loads
   
    #print("..................2a")  
        #app.exec_()              # Start the event loop

        

