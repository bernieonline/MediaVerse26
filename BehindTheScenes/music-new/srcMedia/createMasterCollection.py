'''
the purpose of this file is to provide the user with a pop up window
that allows the selection of a local or network folder in order to 
use os.walk and create a collection much like the searchLocation program
In this case we will be selecting a location that will be searched and the results stored as
 a master record location
Prior to the search the user will have on the po up window the option to choose the file types
eg Video,Audio or Photo. There will be a second combobox that allows the user to choose the
 type of master
record to create eg Master, Clone or Secondary
The location will be scanned and the results stored in a mysql database table named masterfiledetail
 which will be cloned from 
the table named mediafiledetail and the results stored in that location ----- The logic here is to 
maintain a separate database table of the masterfiles and when non master locations are identified a
 comparison
can be made between the collection and the master data set. One important objective here is to identif
y files that may not be in the master set that should be
It will then be possible to decide what to do with those collections that are duplicates and represent
 no value

before we do this though we need to decide what master sets we needs, what clones and what secondar
y datasets we want to preserve





I would like to create a version of the searchLocation.py
It should cretae a window that will allow the user to select a start location for the os.walk.process the same as searchLocation.py
In addition this window should have 2 additional comboboxes the first should offer the values Video, Audio and Photo and the second the values Master, Clone and Secondary
Once the user selects the start location, the pathname will be returned along with the two combobox selections
The code for this function should be created in a function named createMaster in a file named createMasterCollection.py
'''

from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QPushButton, QComboBox, QLabel, QFileDialog, QProgressBar
from PyQt5.QtGui import QFont
import sys
from srcMedia import SearchMasterLocation
from srcMedia.SearchMasterLocation import SearchMasterLocation
#from SearchMasterLocation import SearchMasterLocation
#from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QPushButton, QComboBox, QLabel, QFileDialog

class createMasterCollection:
    def __init__(self, getWin=None, Footer=None, master_progress_bar=None):
        
        self.getWin = getWin    # getWin was parent nut I can use getWin as a reference back to methods in getWindow or pass it forwatd
        self.footer = Footer
        self.master_progress_bar = master_progress_bar
        if self.master_progress_bar is None:
            print("47 self.master_progress_bar is NONE")
            #raise ValueError("master_progress_bar must be provided and cannot be None.")
        else:
             print("47 self.master_progress_bar is OK")
        self.app = QApplication(sys.argv)
        self.window = QWidget()
        self.window.setWindowTitle('Create Master Collection')
        self.layout = QVBoxLayout()

        # Set the background color of the window to blue and text color to white
        self.window.setStyleSheet("background-color: blue; color: white;")

        # Define a larger font
        large_font = QFont()
        large_font.setPointSize(12)  # Adjust the size as needed

        # Label and button for selecting the start location
        self.start_location_label = QLabel('Select Start Location:')
        self.start_location_label.setFont(large_font)
        self.layout.addWidget(self.start_location_label)
        
        self.start_location_button = QPushButton('Browse...')
        self.start_location_button.setFont(large_font)
        self.start_location_button.setStyleSheet("color: black; background-color: white;")
        self.start_location_button.clicked.connect(self.select_start_location) 
        self.layout.addWidget(self.start_location_button)
        
        # Combobox for selecting media type
        self.media_type_label = QLabel('Select Media Type:')
        self.media_type_label.setFont(large_font)
        self.layout.addWidget(self.media_type_label)
        
        self.media_type_combobox = QComboBox()
        self.media_type_combobox.setFont(large_font)

        

        self.media_type_combobox.addItems(['Video', 'Music', 'Photo'])



        self.media_type_combobox.setStyleSheet("color: black; background-color: white;")
        self.layout.addWidget(self.media_type_combobox)
        
        # Combobox for selecting collection type
        self.collection_type_label = QLabel('Select Collection Type:')
        self.collection_type_label.setFont(large_font)
        self.layout.addWidget(self.collection_type_label)
        
        self.collection_type_combobox = QComboBox()
        self.collection_type_combobox.setFont(large_font)

        self.collection_type_combobox.addItems(['Master', 'Clone', 'Secondary'])

        self.collection_type_combobox.setStyleSheet("color: black; background-color: white;")
        self.layout.addWidget(self.collection_type_combobox)
        
        # Button to confirm selection
        self.confirm_button = QPushButton('Confirm Selection')
        self.confirm_button.setFont(large_font)
        self.confirm_button.setStyleSheet("color: black; background-color: white;")
        self.confirm_button.clicked.connect(self.create_master)
        self.layout.addWidget(self.confirm_button)

        self.window.setLayout(self.layout)


    def create_master(self):
        # Ensure master_progress_bar is not None before passing it
        if self.master_progress_bar is None:
            print("103 self.master_progress_bar is NONE")
            #raise ValueError("master_progress_bar must be provided and cannot be None.")
        else:
             print("103 self.master_progress_bar is OK")

        self.window.close()
        selected_media_type = self.media_type_combobox.currentText()
        selected_collection_type = self.collection_type_combobox.currentText()
        print(f'Selected Path: {getattr(self, "selected_path", "None")}')
        print(f'Selected Media Type: {selected_media_type}')
        print(f'Selected Collection Type: {selected_collection_type}')
        # Here you can add logic to handle the selections, such as storing them in a database
        print("inside create_master")

        self.getWin.setStartTime()

        # Initialize SearchMasterLocation instance
        # modify to pass in selected media and master details
        #self.search_master_instance = SearchMasterLocation(parent=self, Footer=self.footer, media_type=selected_media_type, master_type=selected_collection_type, start_location=self.selected_path)
        # replace  parent=self.window, with getWin=self.getWin mainining a connection back to getMainWindow
        self.search_master_instance = SearchMasterLocation(
            getWin=self.getWin,
            Footer=self.footer,
            master_progress_bar = self.master_progress_bar,
            media_type=selected_media_type,
            master_type=selected_collection_type,
            selected_path=self.selected_path  # Use 'selected_path' instead of 'start_location'
        )
        
        
        
        result = None
        # in the code below we instantiared search_instance from the imported DearchLocation class.
        #run() is a method in that class so we can refer to it as search_instance.run()
        #The run method manages the whole media collection/media creation process
        result = self.search_master_instance.run()

    def select_start_location(self):
        folder_path = QFileDialog.getExistingDirectory(self.window, "Select Start Location")
        if folder_path:
            self.start_location_label.setText(f'Selected Start Location: {folder_path}')
            self.selected_path = folder_path

    def confirm_selection(self):
        selected_media_type = self.media_type_combobox.currentText()
        selected_collection_type = self.collection_type_combobox.currentText()
        print(f'Selected Path: {getattr(self, "selected_path", "None")}')
        print(f'Selected Media Type: {selected_media_type}')
        print(f'Selected Collection Type: {selected_collection_type}')
        # Here you can add logic to handle the selections, such as storing them in a database

    def run(self):
        print(" inside createMasterCollection run()")
        self.window.show()
        #sys.exit(self.app.exec_())

#if __name__ == '__main__':
#    creator = MasterCollectionCreator()
#    creator.run()