from PyQt5.QtWidgets import QWidget, QTextEdit, QTableWidget, QTableWidgetItem, QMessageBox, QMenu
from PyQt5.QtCore import Qt
from dbMySql import db_utils
from dbMySql.db_utils import get_collections_and_cats, count_records_by_collection, remove_records_by_collection, get_location_by_collection, transfer_records_to_master
import os
import subprocess


class UtilClass:
    ''' Gives options to remove data from database collections. It will also transfer collections between tables eg media to master
    It also has options to delete or move actual data sets arranged by opening file explotrer windows
    at the selected locations'''

    
    '''action_type is Remove, Delete,Move, Transfer'''
    ''' Remove removes details of a collection from a table'''
    '''Move and Delete opens a File Explore Window to do it ypurself'''
    '''Transfer moved=s a collection from Table A to Table B Media to Master for example'''
    def __init__(self, utils_page: QWidget,coll_table, action_type: str, footer: QTextEdit):
        self.utils_page = utils_page
        self.coll_table = coll_table
        self.action_type = action_type
        self.footer = footer

        # Initialize any UI components or data structures needed for the actions
        self.setup_ui()

    def setup_ui(self):
       
        # Populate the QTableWidget with collection data from the database - Every OPtion loads this Table auto
        self.populate_table()

        # Enable custom context menu for the table
        self.coll_table.setContextMenuPolicy(Qt.CustomContextMenu)
        self.coll_table.customContextMenuRequested.connect(self.on_table_right_click)

        # Connect the cellClicked signal to a custom slot
        try:
            self.coll_table.cellClicked.disconnect(self.on_table_cell_clicked)
        except TypeError:
            # This exception is raised if the signal was not connected before
            pass

        # Perform initial setup based on the action type
        if self.action_type == "Remove":
            self.setup_remove_action()              #  uses self.coll_table.cellClicked.connect(self.on_table_cell_clicked)  self.handle_selected_data(collection, category, type_)
        elif self.action_type == "Delete":       
            self.setup_delete_action()              # uses  self.coll_table.cellClicked.connect(self.on_table_cell_clicked_for_delete)  self.open_file_explorer(location)
        elif self.action_type == "Move":
            self.setup_move_action()                # uses self.coll_table.cellClicked.connect(self.on_table_cell_clicked_for_delete)  self.open_file_explorer(location)
        elif self.action_type == "Transfer":
            self.setup_transfer_action()            # print("Something")

    def on_table_right_click(self, position):
        # Create a context menu
        menu = QMenu()

        # Add actions to the context menu
        move_to_master_action = menu.addAction("Move to Master")
        move_to_media_action = menu.addAction("Move to Media")

        # Connect actions to methods
        move_to_master_action.triggered.connect(lambda: self.move_to_master(position))
        move_to_media_action.triggered.connect(lambda: self.move_to_media(position))

        # Show the context menu at the cursor position
        menu.exec_(self.coll_table.viewport().mapToGlobal(position))      

    def move_to_media(self, position):
        # Get the row at the clicked position
        row = self.coll_table.rowAt(position.y())

        # Retrieve data from the selected row
        collection_item = self.coll_table.item(row, 0)
        category_item = self.coll_table.item(row, 1)
        type_item = self.coll_table.item(row, 2)

        if collection_item and category_item and type_item:
            collection = collection_item.text()
            category = category_item.text()
            type_ = type_item.text()

            # Call the database utility function to move to media
            # Example: db_utils.move_to_media(collection, category, type_)
            self.footer.append(f"Moved Collection: {collection}, Category: {category}, Type: {type_} to Media")




    def move_to_master(self, position):
        # sql function = transfer_records_to_master(collection_name, category, master_type_name):
        # Get the row at the clicked position
        row = self.coll_table.rowAt(position.y())

        # Retrieve data from the selected row
        collection_item = self.coll_table.item(row, 0)
        category_item = self.coll_table.item(row, 1)
        type_item = self.coll_table.item(row, 2)

        if collection_item and category_item and type_item:
            collection = collection_item.text()
            category = category_item.text()
            type_ = type_item.text()

            # Call the database utility function to move to master
            transfer_records_to_master(collection, category, type_)

            # Example: db_utils.move_to_master(collection, category, type_)
            self.footer.append(f"Moved Collection: {collection}, Category: {category}, Type: {type_} to Master")

    def populate_table(self):
        # Fetch data from the database
        data = get_collections_and_cats()

        # Set the number of rows and columns in the table
        self.coll_table.setRowCount(len(data))
        self.coll_table.setColumnCount(3)  # Assuming two columns: collection and category

        # Set the headers for the table
        self.coll_table.setHorizontalHeaderLabels(["Collection", "Category", "Type"])

         # Set the width of the first column (index 0)
        self.coll_table.setColumnWidth(0, 800)  # Adjust the width value as needed

        # Populate the table with data
        for row_index, (collection, category, type_) in enumerate(data):
            self.coll_table.setItem(row_index, 0, QTableWidgetItem(collection))
            self.coll_table.setItem(row_index, 1, QTableWidgetItem(category))
            self.coll_table.setItem(row_index, 2, QTableWidgetItem(type_))

    def setup_remove_action(self):
        # Setup specific UI elements or logic for the "Remove" action
        self.footer.append("Setting up Remove action...")

         # Connect the cellClicked signal to a custom slot that handles the removal process
        self.coll_table.cellClicked.connect(self.on_table_cell_clicked)

        '''The purpose here is to follow up on the users decision to remove a collection data set from the database. 
        click a row to pass the row details to this function which will then call 2 database functions
        one to inform the number of records affected and the second to remove those records from the databse and update the QTAble being used'''


        # Add more setup logic here

    def setup_delete_action(self):
        # Setup specific UI elements or logic for the "Delete" action
        self.footer.append("Setting up Delete action...")

        # Connect the cellClicked signal to a custom slot that opens the file explorer
        self.coll_table.cellClicked.connect(self.on_table_cell_clicked_for_delete)

        # Add more setup logic here

    def setup_move_action(self):
        # Setup specific UI elements or logic for the "Move" action
        self.footer.append("Setting up Move action...")
        # Add more setup logic here
        # Connect the cellClicked signal to a custom slot that opens the file explorer
        self.coll_table.cellClicked.connect(self.on_table_cell_clicked_for_delete)

    def setup_transfer_action(self):
        print("Something")

        self.setup_remove_action() 


    def perform_action(self):       #not called
        # Execute the action based on the action type
        if self.action_type == "Remove":
            self.perform_remove()
        elif self.action_type == "Delete":
            self.perform_delete()
        elif self.action_type == "Move":
            self.perform_move()
        elif self.action_type == "Transfer":
            self.perform_transfer()

    def perform_remove(self): #not called
        # Logic to perform the "Remove" action
        self.footer.append("Performing Remove action...")
        # Add more logic here

    def perform_delete(self): #not called
        # Logic to perform the "Delete" action
        self.footer.append("Performing Delete action...")
        # Add more logic here

    def perform_move(self): #not called
        # Logic to perform the "Move" action
        self.footer.append("Performing Move action...")

    def perform_transfer(self): #not called
         # Logic to perform the "Move" action
        self.footer.append("Performing Transfer action...")

    def on_table_cell_clicked(self, row, column):
        # Retrieve data from the selected row
        collection_item = self.coll_table.item(row, 0)
        category_item = self.coll_table.item(row, 1)
        type_item = self.coll_table.item(row, 2)

        if collection_item and category_item and type_item:
            collection = collection_item.text()
            category = category_item.text()
            type_ = type_item.text()  # Correctly retrieve the text from the QTableWidgetItem
            self.footer.append(f"Selected Collection: {collection}, Category: {category}, Type: {type_}")

            # Call a function with the selected data
            self.handle_selected_data(collection, category, type_)

    def on_table_cell_clicked_for_delete(self, row, column):
        # Retrieve data from the selected row
        collection_item = self.coll_table.item(row, 0)
        category_item = self.coll_table.item(row, 1)
        type_item = self.coll_table.item(row, 2)

        if collection_item and category_item and type_item:
            collection = collection_item.text()
            category = category_item.text()
            type_ = type_item.text()
            self.footer.append(f"Selected Collection for Delete: {collection}, Category: {category}, Type: {type_}")

            location = get_location_by_collection(collection, category, type_)


            # Open the file explorer at the location associated with the selected collection
            self.open_file_explorer(location)

    def handle_selected_data(self, collection, category, type_):
         # Count the number of records that will be affected
        count = count_records_by_collection(collection, category, type_)
        # Implement the logic to handle the selected data
        self.footer.append(f"Handling data for Collection: {collection}, Category: {category}, Type: {type_}")

        # Create a message box for user confirmation
        msg_box = QMessageBox()
        msg_box.setIcon(QMessageBox.Question)
        msg_box.setWindowTitle("Confirm Removal")
        msg_box.setText(f"Are you sure? {count} records will be affected.")
        msg_box.setStandardButtons(QMessageBox.Yes | QMessageBox.No)
        msg_box.setDefaultButton(QMessageBox.No)

        # Show the message box and get the user's response
        response = msg_box.exec_()
        # Add more logic here
        if response == QMessageBox.Yes:
            # Remove the records from the database
            remove_records_by_collection(collection, category, type_)
            self.footer.append("Records removed successfully.")

            # Refresh the table to reflect changes
            self.populate_table()
        else:
            self.footer.append("Action aborted by the user.")



    def open_file_explorer(self, location):
        """Opens the file explorer at the specified location."""
        if location:
            # Check if the location exists
            if os.path.exists(location):
                try:
                    # Open the file explorer at the specified location
                    if os.name == 'nt':  # Windows
                        os.startfile(location)
                    elif os.name == 'posix':  # macOS or Linux
                        subprocess.run(['open', location] if sys.platform == 'darwin' else ['xdg-open', location])
                except Exception as e:
                    self.footer.append(f"Error opening file explorer: {e}")
            else:
                self.footer.append("The specified location does not exist.")
        else:
            self.footer.append("Location not found for the specified collection.")

    def on_table_cell_clicked_for_move(self, row, column):     #not called because move and delete are the same so we are using delete
        # Retrieve data from the selected row
        collection_item = self.coll_table.item(row, 0)
        category_item = self.coll_table.item(row, 1)
        type_item = self.coll_table.item(row, 2)

        if collection_item and category_item and type_item:
            collection = collection_item.text()
            category = category_item.text()
            type_ = type_item.text()
            self.footer.append(f"Selected Collection for Move: {collection}, Category: {category}, Type: {type_}")

            # Get the location using the collection, category, and type
            location = get_location_by_collection(collection, category, type_)

            if location:
                # Open the file explorer at the determined location
                self.open_file_explorer(location)
