#from db_utils import test_db_connection  #uses mysql functions page
from dbMySql.db_utils import test_mysql_connection  #uses mysql functions page
from PyQt5.QtWidgets import QMessageBox, QTextEdit
from PyQt5.QtCore import QObject, pyqtSignal

class connCheck:

    #connection_status = pyqtSignal(str)  # Signal to emit connection status for database
    def __init__(self, parent=None, Footer=None):
        # Store a reference to the parent window for QMessageBox
        self.parent = parent
        # Store a reference to the Footer QTextEdit object
        self.footer = Footer
        print("inside connCheck")
        
        self.run_connection_test()

        #this class will hold all of the search and data creatin elements when walking through the file system
        #it it progresses it will send messages back to the mainwindow
        #its job is to identify collections and create datbase records for analysis

    def run_connection_test(self):
        """Runs the database connection test and handles the result."""
        print("running test")
        state = test_mysql_connection()
    
        if state:   
            message = "MySql is Connected........."
        else:
            message= "No Mysql Connection........."
           

           
           
        # Display the message in the Footer QTextEdit
        
        if self.footer:
            
            self.footer.setText(message)

    