import sys
import logging
from PyQt5.QtWidgets import QWidget, QVBoxLayout, QSizePolicy, QApplication
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
import matplotlib.pyplot as plt
import numpy as np

from dbMySql import db_utils
from dbMySql.db_utils import get_collection_data
from PyQt5 import QtWidgets
from PyQt5.QtWidgets import QFrame, QTableWidget, QTableWidgetItem, QVBoxLayout, QSizePolicy



class pie_collection(QWidget):
    def __init__(self, data, canvas_frame, coll_frame_table, parent=None):
        super().__init__(parent)
        self.data = data
        self.canvas_frame = canvas_frame
        self.canvas = None  # Initialize canvas as None
        self.coll_frame_table = coll_frame_table
        self.table_widget = None  # Initialize QTableWidget
        self.initUI()


    def clear_layout(self, layout):
        """Remove all widgets from a layout."""
        while layout.count():
            item = layout.takeAt(0)
            widget = item.widget()
            if widget is not None:
                widget.deleteLater()
            elif item.layout() is not None:
                self.clear_layout(item.layout())

    def initUI(self):
        logging.info("pie_collection.py : plotting chart")

         # Ensure canvas_frame has an expanding size policy
        #self.canvas_frame.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)

         # Add a QTableWidget inside coll_frame_table dynamically if it's a QFrame
        if isinstance(self.coll_frame_table, QFrame):
            logging.info("pie_collection.py : plotting chart.....isinstance entered")
            # Create a layout for the QFrame if it doesn't have one
            layout = QVBoxLayout(self.coll_frame_table)
            
            # Only create the QTableWidget if it doesn't already exist
            if self.table_widget is None:
                self.table_widget = QTableWidget()  # Create a new QTableWidget
                layout.addWidget(self.table_widget)  # Add the QTableWidget to the layout
            


         # Get the layout of canvas_frame
        canvas_layout = self.canvas_frame.layout()

        if canvas_layout is not None:
            print("canvas layout not none")
            # Clear the layout by removing all widgets
            self.clear_layout(canvas_layout)
        else:
            # Create a new layout if it doesn't exist
            canvas_layout = QVBoxLayout(self.canvas_frame)
            self.canvas_frame.setLayout(canvas_layout)
            canvas_layout.setContentsMargins(0, 0, 0, 0)  # Remove any unnecessary margins



        # Create a new FigureCanvas and add it to the existing layout
        self.canvas = FigureCanvas(Figure())
        self.canvas.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        canvas_layout.addWidget(self.canvas)

        # Create the plot

        self.ax = self.canvas.figure.add_subplot(111)
       
       
        self.plot_bar_chart()

        # Connect the canvas to the pick event for handling bar clicks
        self.canvas.mpl_connect('pick_event', self.on_bar_click)

        print("completed initUI in pie_collection")

        
        self.table_widget.cellClicked.connect(self.copy_cell_content_to_clipboard)
        logging.info("Connected cellClicked signal to copy_cell_content_to_clipboard")




    def copy_cell_content_to_clipboard(self, row, column):
        print(f"Cell clicked at row {row}, column {column}")
        """Copy the content of the clicked cell to the clipboard."""
        item = self.table_widget.item(row, column)
        if item is not None:
            clipboard = QApplication.clipboard()
            clipboard.setText(item.text())
            print(f"Copied to clipboard: {item.text()}")
        else:
            print(f"No item found at row {row}, column {column}")
    
    def clear_table(self):
        """Clears the existing table content and resets it."""
        layout = self.coll_frame_table.layout()
    
        # Clear the table layout (similar to how we clear the canvas layout)
        if layout is not None:
            self.clear_layout(layout)
    
        # Recreate the table and re-add it to the layout
        self.table_widget = QTableWidget()  # Recreate the table widget
        self.coll_frame_table.layout().addWidget(self.table_widget)  # Add the new table to the layout

        # Optional: set the table's size policy if needed
        self.table_widget.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
    
        # Now we will proceed to add the new data to the table
        print("Table has been cleared and reset.")

    
    
    
    
    
    def plot_bar_chart(self):

        logging.info("Plotting bar chart nside pie_collection init")
        locations = [row[0] for row in self.data]
        file_counts = [row[1] for row in self.data]
        #logging.info("locations:", locations)
        #logging.info("counts:", file_counts)

        #clear plot area
        self.ax.clear()

        # Create a new bar chart
        bars = self.ax.barh(locations, file_counts, picker = True)

        # Add text labels to the bars
        for index, (bar, count) in enumerate(zip(bars, file_counts)):
            # Set an attribute to store the index of the bar
            bar.set_label(str(index))  # Store the index as a label

            # Add text labels on the bars
            width = bar.get_width()
            self.ax.text(
                width, bar.get_y() + bar.get_height() / 2,
                f'{count}',
                va='center',
                ha='left',
                fontsize=10
            )
        print("before draw")    

        self.ax.figure.subplots_adjust(left=0.3)

      

        self.canvas.draw()

        print("after draw")

    def on_bar_click(self, event):
        print("clicking on bar")
        # This method will be called when a bar is clicked
        if event.artist:
            # Get the label (location) associated with the bar that was clicked
            bar = event.artist

            # Get the stored index from the bar's label (which we set during plotting)
            index = int(bar.get_label())  # Retrieve the index stored in the bar's label

         

             # Ensure the index is within the bounds of the data list
            if 0 <= index < len(self.data):
                location = self.data[index][0]  # Get the location from data
                print(f"Bar clicked: {location}")

                # Run the database query to get collection data for the clicked location
                query_results = get_collection_data(location)

                # Update the QTableWidget with the query results
                self.display_results_in_table(query_results)

            #location = self.data[bar.get_y() // 1][0]  # Get the location from data (adjust indexing if needed)
            #print(f"Bar clicked: {location}")

            # Run the database query to get collection data for the clicked location
            #query_results = get_collection_data(location)

            # Update the QTableWidget with the query results
            #self.display_results_in_table(query_results)
        self.table_widget.cellClicked.connect(self.copy_cell_content_to_clipboard)
        logging.info("Connected cellClicked signal to copy_cell_content_to_clipboard")



    def display_results_in_table(self, results):
        print("displaying table results")
        """Displays the query results in the QTableWidget."""
        if self.table_widget is None:
            print("Error: QTableWidget not initialized.")
            return
        

         # Check if results are empty
        if not results:
            print("No results to display.")
            return
        
       

         # Clear the existing content and reset the table
        print("clearing table")
        self.clear_table()



         # Set up the table headers and row count
        self.table_widget.setRowCount(len(results))
        self.table_widget.setColumnCount(8)  # Adjust based on query columns
        self.table_widget.setHorizontalHeaderLabels([
            "File Name", "File Type", "File Size", "Creation Date",
            "Collection", "Category", "Device", "Collection Date"
        ])

        # Print the refreshed query results to the terminal for debugging
        print("Refreshed query results:")
        for row in results:
            #print(row)  # Print each row of the results
            continue
        # Print the row count after setting new rows
        
        
        #print(f"Row count after setting rows: {self.table_widget.rowCount()}")




        # Insert query results into the table
        for row_index, row_data in enumerate(results):
            for col_index, col_data in enumerate(row_data):
                self.table_widget.setItem(row_index, col_index, QTableWidgetItem(str(col_data)))
    
    
        # Optionally, ensure that the table view is updated (for better UX)
        self.table_widget.viewport().update()


         # Make sure the table is visible by resizing columns based on content (optional)
        self.table_widget.resizeColumnsToContents()


        # Print the final row count for debugging
        print(f"Final row count: {self.table_widget.rowCount()}")

        self.table_widget.cellClicked.connect(self.copy_cell_content_to_clipboard)
        logging.info("Connected cellClicked signal to copy_cell_content_to_clipboard")
    
    def on_pick(self, event):
        pass

'''
class pie_collection(QWidget):
    def __init__(self, data, canvas_frame, coll_frame_table, parent=None):
        super().__init__(parent)
        self.data = data
        self.canvas_frame = canvas_frame
        self.coll_frame_table = coll_frame_table
        self.initUI()

    def initUI(self):
         # Use the layout of canvas_frame to add the FigureCanvas
        self.canvas = FigureCanvas(Figure())
        self.canvas.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)

        # Assuming canvas_frame already has a layout, add the canvas to it
        canvas_layout = self.canvas_frame.layout()
        if not canvas_layout:
            canvas_layout = QVBoxLayout(self.canvas_frame)
        canvas_layout.addWidget(self.canvas)

        self.ax = self.canvas.figure.add_subplot(111)
        self.plot_bar_chart()

    def plot_bar_chart(self):
        locations = [row[0] for row in self.data]
        file_counts = [row[1] for row in self.data]
        print("locations:", locations)
        print("counts:", file_counts)

        self.ax.clear()
        bars = self.ax.barh(locations, file_counts)

        for bar, count in zip(bars, file_counts):
            width = bar.get_width()
            self.ax.text(
                width, bar.get_y() + bar.get_height() / 2,
                f'{count}',
                va='center',
                ha='left',
                fontsize=10
            )

        self.ax.figure.subplots_adjust(left=0.3)
        self.canvas.draw()

    def on_pick(self, event):
        # This method can be used for handling events if needed
        pass
        

'''