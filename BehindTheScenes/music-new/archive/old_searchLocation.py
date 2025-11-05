#from db_utils import test_db_connection  #uses mysql functions page
from dbMySql.db_utils import get_list_extensions
from dbMySql.db_utils import get_list_folders
from PyQt5.QtWidgets import QMessageBox, QTextEdit
from PyQt5.QtCore import QObject, pyqtSignal
import tkinter as tk
from tkinter import filedialog
import os
import time
import platform

class SearchLocation:

    #connection_status = pyqtSignal(str)  # Signal to emit connection status for database
    def __init__(self, parent=None, Footer = None):
        # Store a reference to the parent window for QMessageBox
        self.parent = parent
        # Store a reference to the Footer QTextEdit object
        self.footer = Footer
        self.selected_folder = None
        self.myList = None
        self.myFolders = None

        
        #self.run_connection_test()

        #this class will hold all of the search and data creatin elements when walking through the file system
        #it it progresses it will send messages back to the mainwindow
        #its job is to identify collections and create datbase records for analysis
        
    def run(self):   
        #print("step....1       Get a file explorer box and select a folder to search returning folder name")
        self.selected_folder =self.getSearchLocation()
        if self.selected_folder:
            self.footer.append("search folder is:"+self.selected_folder)
        else:
             self.footer.setText("No Folder Selected")

        #print("step....2       Get a list of media file extensions")
        #folder was selected
        self.myFolders = self.get_folder_list()
        
        self.myList =  self.get_ext_list()
        #print("step....2b       ran the code for a list of media file extensions")

        self.traverse_folders(self.selected_folder)


    def getSearchLocation(self):
       
        def select_folder():
            # Create a root window and hide it
            root = tk.Tk()
            root.withdraw()  # Hide the root window

            # Open a file dialog to select a directory
            folder_path = filedialog.askdirectory(title="Select a Folder")

            # Destroy the root window after selection
            root.destroy()
            return folder_path

            # Return the selected folder path
        return select_folder()

    
    def get_ext_list(self):
        """Gets the list of file extensions that define media files."""
        #print("entering sl get_ext_list")
        extensions = get_list_extensions()  # Call the imported function
        if extensions:
            #print("we have an extension list")
            # Extract the first element of each tuple (type) from the list of extensions
            self.myList = [(row[0], row[1]) for row in extensions]
            # Append the formatted string to the footer
            # Format the output for the footer
            formatted_extensions = [f"{type_}: {ext}" for type_, ext in self.myList]
            self.footer.append("Extensions retrieved: " + ", ".join(formatted_extensions))
        else:
            # Append a failure message to the footer if no extensions were retrieved
            self.footer.append("Failed to retrieve extensions.")

        # Return the list of types for use in run method
        return self.myList
        
    def get_folder_list(self):
        """Gets the list of exempt folders."""
        # Fetch the list of folders using the imported function
        folders = get_list_folders()
        if folders:
            # Assign the fetched folder list to the instance variable
            self.myFolders = folders
            # Format the folder names for display
            formatted_folders = [f"{folder_name}" for folder_name in self.myFolders]
            # Append the formatted folder names to the footer
            self.footer.append("Folders retrieved: " + ", ".join(formatted_folders))
        else:
            # Append a failure message to the footer if no folders were retrieved
            self.footer.append("Failed to retrieve folders.")
        
        # Return the list of folders for use in the run method
        return self.myFolders
                
   

    print("step....4       use os.walk to move to the first folder")
    print("step....5       check if folder holds media and is not an exempt name, if name is exempt break to next folder across, if no media skip")

    def traverse_folders(self, start_path):
        device_name = platform.node()
    
        # Log or store the device name
        print(f"Creating media collection on device: {device_name}")
        start_time = time.time()
        media_extensions = {ext.lower().strip() for _, ext in self.myList}
        exempt_folders = set(self.myFolders)
        media_folders = []  # New list to store paths of folders containing 'video_ts'

        for dirpath, dirnames, filenames in os.walk(start_path):
            # Convert dirnames to lowercase for case-insensitive comparison
            dirnames_lower = [d.lower() for d in dirnames]

            # Check for 'video_ts' folder in a case-insensitive manner
            if 'video_ts' in dirnames_lower:
                # Append the path up to the parent directory of 'video_ts'
                media_folders.append(dirpath)
                # Prevent os.walk from traversing into 'video_ts'
                dirnames.clear()
                continue

            # Skip processing if the current directory is 'video_ts'
            if os.path.basename(dirpath).lower() == 'video_ts':
                continue

            if os.path.basename(dirpath) in exempt_folders:
                dirnames.clear()
                continue

            for filename in filenames:
                full_path = os.path.join(dirpath, filename)
                file_ext = os.path.splitext(filename)[1].lower().strip()

                # Check if the file extension is in the media extensions set
                if file_ext in media_extensions:
                    # Exclude image files below 500KB
                    if file_ext in {'.jpg', '.jpeg', '.png', '.gif', '.bmp'}:
                        try:
                            if os.path.getsize(full_path) < 500 * 1024:  # 500KB
                                continue
                        except FileNotFoundError:
                            print(f"File not found: {full_path}")
                            continue
                        except OSError as e:
                            print(f"Error accessing file {full_path}: {e}")
                            continue

                    print(f"Media file: {full_path}")

        end_time = time.time()
        time_taken = end_time - start_time
        self.footer.append(f"Traversal complete. Time taken: {time_taken:.2f} seconds")
        self.footer.append(f"Media folders: {', '.join(media_folders)}")

        print("Media folders:")
        for folder in media_folders:
            print(folder)
   
    print("step....6       if folder contains valid media grab device,path,filename,ext,date checked, date created, then create extra data item making a name for the collection ")

    print("step....7       once a file has been processed add it to a list of files detail until eof then insert records into database")

    print("step....8       loop through all folders until completeand send completed message to Footer ")
        
