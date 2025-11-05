from PyQt5.QtWidgets import QTableWidget, QLineEdit, QPushButton, QTableWidgetItem, QApplication
from PyQt5.QtCore import Qt
from dbMySql import db_utils
from dbMySql.db_utils import searchText  # Assuming searchText is defined in db_utils
import sys

class SearchHandler:
    def __init__(self, searchTableWidget,  searchEdit, searchButton):
        self.table_widget = searchTableWidget
        self.searchEdit = searchEdit
        self.search_button = searchButton

       
        
        # Connect the search button click event to the search method
        self.search_button.clicked.connect(self.perform_search)
        
        # Connect the cellClicked signal to the copy_to_clipboard method
        self.table_widget.cellClicked.connect(self.copy_to_clipboard)

        print("searchhandler init")

  
    
    def perform_search(self):
        print("Button clicked, performing search")
        # Get the text from the line edit
        search_query =  self.searchEdit.text()
        
        # Call the searchText function from db_utils
        results = searchText(search_query)
        
        # Populate the QTableWidget with the results
        self.populate_table(results)

    def populate_table(self, results):
        # Assuming results is a list of tuples, where each tuple represents a row
        self.table_widget.setRowCount(len(results))
        self.table_widget.setColumnCount(12)  # Assuming there are 12 fields

        for row_index, row_data in enumerate(results):
            for column_index, data in enumerate(row_data):
                item = QTableWidgetItem(str(data))
                self.table_widget.setItem(row_index, column_index, item)

    def copy_to_clipboard(self, row, column):
        # Get the item at the clicked cell
        item = self.table_widget.item(row, column)
        if item:
            # Copy the item's text to the clipboard
            clipboard = QApplication.clipboard()
            clipboard.setText(item.text(), mode=clipboard.Clipboard)
            print(f"Copied to clipboard: {item.text()}")



