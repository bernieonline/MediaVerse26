import sys
from PyQt5.QtWidgets import QWidget, QVBoxLayout, QSizePolicy, QTableWidget, QTableWidgetItem, QApplication
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
import matplotlib.pyplot as plt
from dbMySql.db_utils import get_collection_data
import warnings

warnings.filterwarnings("ignore", category=DeprecationWarning)

class pie_collection(QWidget):
    def __init__(self, data, parent=None):
        super().__init__(parent)
        self.data = data
        self.initUI()

    def initUI(self):
        layout = QVBoxLayout(self)
        self.canvas = FigureCanvas(Figure())

        # Set size policy for the canvas
        self.canvas.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)

        layout.addWidget(self.canvas)

        self.ax = self.canvas.figure.add_subplot(111)
        self.plot_bar_chart()

        # Create a QTableWidget for displaying data
        self.coll_frame_table = QTableWidget()
        self.coll_frame_table.setColumnCount(7)  # Adjusted to match the number of columns returned by the query
        self.coll_frame_table.setHorizontalHeaderLabels(['File Name', 'File Type', 'File Size', 'Creation Date', 'Collection', 'Category', 'Device','Collection Date'])
        layout.addWidget(self.coll_frame_table)

    def plot_bar_chart(self):
        locations = [row[0] for row in self.data]
        file_counts = [row[1] for row in self.data]
        print("locations:", locations)
        print("counts:", file_counts)

        # Clear the axes before plotting
        self.ax.clear()

        # Plot horizontal bar chart
        bars = self.ax.barh(locations, file_counts, picker=True)  # Enable picking

        # Annotate each bar with its file_counts value
        for bar, count in zip(bars, file_counts):
            width = bar.get_width()
            self.ax.text(
                width, bar.get_y() + bar.get_height() / 2,  # Position the text
                f'{count}',  # Text to display
                va='center',  # Vertical alignment
                ha='left',    # Horizontal alignment
                fontsize=10   # Font size
            )

        # Adjust the subplot to make room for the labels
        self.ax.figure.subplots_adjust(left=0.3)  # Adjust the left margin

        # Connect the pick event
        self.canvas.mpl_connect('pick_event', self.on_pick)

        # Refresh the canvas
        self.canvas.draw()

    def on_pick(self, event):
        # Check if the artist picked is a bar
        if isinstance(event.artist, plt.Rectangle):
            bar_index = int(event.artist.get_y())  # Corrected index calculation
            location = self.data[bar_index][0]
            print(f"Bar clicked: {location}")

            # Query the database
            results = get_collection_data(location)

            # Populate the table with results
            self.coll_frame_table.setRowCount(len(results))
            for row_idx, row_data in enumerate(results):
                for col_idx, item in enumerate(row_data):
                    self.coll_frame_table.setItem(row_idx, col_idx, QTableWidgetItem(str(item)))

if __name__ == '__main__':
    app = QApplication(sys.argv)
    data = [('Location1', 10), ('Location2', 15)]  # Example data
    window = pie_collection(data)
    window.show()
    sys.exit(app.exec_())