

from PyQt5.QtWidgets import QTableView, QVBoxLayout, QApplication, QShortcut
from PyQt5.QtGui import QStandardItemModel, QStandardItem, QKeySequence
from PyQt5.QtCore import Qt
from dbMySql import db_utils
from dbMySql.db_utils import compareCollections



# compare_collections.py
''' this takes the combo box choices from the stacked widget that displays comparison results
and dependin on the choices runs different methods to evaluate and display on a table on the stacked widget page 1(starts at 0)'''
class Compare_Collections:
    def __init__(self, compareA, compareB, compareType,display_frame,comboBox_table1, comboBox_table2):
        self.compareA = compareA
        self.compareB = compareB
        self.compareType = compareType
        self.comboBox_table1=comboBox_table1
        self.comboBox_table2=comboBox_table2
        self.display_frame = display_frame
        self.compareCollections = compareCollections

       

    def run(self):
        # Evaluate the selections and call the appropriate method
        if self.compareType == 'Items in B but Not in A':

            results = self.compareCollections(self.compareA,self.compareB,self.compareType)


        elif self.compareType == 'Items in A but Not in B':
            
             results = self.compareCollections(self.compareA,self.compareB,self.compareType)
        
        
        
        else:
            print("Invalid comparison type selected @@@.")
            return

        # Display the results in a table
        self.display_results(results)

    def compare_b_not_a(self):
        # Logic for comparing items in B but not in A
        print(f"Comparing items in {self.compareB} but not in {self.compareA}")
        # Add your comparison logic here

    def compare_a_not_b(self):
        # Logic for comparing items in A but not in B
        print(f"Comparing items in {self.compareA} but not in {self.compareB}")
        # Add your comparison logic here

    def display_results(self, results):
            # Create a QTableView
            table_view = QTableView()

            # Create a QStandardItemModel
            model = QStandardItemModel()

            # Assuming results is a list of tuples, where each tuple is a row
            if results:
                # Set the number of columns based on the first row
                model.setColumnCount(len(results[0]))

                # Populate the model with data
                for row in results:
                    items = [QStandardItem(str(field)) for field in row]
                    model.appendRow(items)

            # Set the model to the table view
            table_view.setModel(model)

            # Set some properties for better user experience
            table_view.setSelectionBehavior(QTableView.SelectRows)
            table_view.setEditTriggers(QTableView.NoEditTriggers)
            table_view.horizontalHeader().setStretchLastSection(True)

            # Enable copying
            table_view.setSelectionMode(QTableView.ExtendedSelection)
            copy_shortcut = QShortcut(QKeySequence.Copy, table_view)
            copy_shortcut.activated.connect(lambda: self.copy_selection_to_clipboard(table_view))

            # Ensure the display frame has a layout
            if not self.display_frame.layout():
                self.display_frame.setLayout(QVBoxLayout())

            # Clear any existing widgets in the display frame
            for i in reversed(range(self.display_frame.layout().count())):
                widget_to_remove = self.display_frame.layout().itemAt(i).widget()
                self.display_frame.layout().removeWidget(widget_to_remove)
                widget_to_remove.setParent(None)

            # Add the table view to the display frame
            self.display_frame.layout().addWidget(table_view)

    def copy_selection_to_clipboard(self, table_view):
        selection = table_view.selectionModel().selectedIndexes()
        if selection:
            rows = sorted(index.row() for index in selection)
            columns = sorted(index.column() for index in selection)
            row_count = rows[-1] - rows[0] + 1
            column_count = columns[-1] - columns[0] + 1

            table_data = [[''] * column_count for _ in range(row_count)]
            for index in selection:
                row = index.row() - rows[0]
                column = index.column() - columns[0]
                table_data[row][column] = index.data()

            clipboard = QApplication.clipboard()
            clipboard_text = '\n'.join(['\t'.join(row) for row in table_data])
            clipboard.setText(clipboard_text)