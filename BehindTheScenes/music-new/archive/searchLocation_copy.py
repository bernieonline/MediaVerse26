from dbMySql.db_utils import fetch_master_hashes_from_db
from dbMySql.db_utils import get_list_extensions
from dbMySql.db_utils import get_list_folders
from PyQt5.QtWidgets import QMessageBox, QTextEdit
from PyQt5.QtCore import QObject, pyqtSignal
import tkinter as tk
from tkinter import filedialog
import os
import time
import platform
from datetime import datetime
import re
from dbMySql.db_utils import insert_record
import xxhash  # Add this import at the top of your file
#import collection_check
from srcMedia.collection_check import existing_collection
from PyQt5.QtWidgets import QWidget
from PyQt5.QtCore import pyqtSignal





class SearchLocation(QWidget):
    #show_message_box = pyqtSignal(str, str)  # Signal to show a message box with title and message need due to threads not allowing a gui to be created within it, gui must run from Main thread
    #connection_status = pyqtSignal(str)  # Signal to emit connection status for database
    def __init__(self, parent=None, Footer=None, media_type=None, master_type=None, selected_path=None):
        # Store a reference to the parent window for QMessageBox
        super().__init__(parent)  # Initialize the QWidget with the parent
        # Store a reference to the Footer QTextEdit object
        #self.footer = Footer
        self.selected_folder = None
        self.myList = None
        self.myFolders = None
        self.hash_index = set()
        self.duplicate=False

        for hash_value in fetch_master_hashes_from_db():
            #creates a python set from the hashes that can be used to quickly look up a hash to see if its in the list
            self.hash_index.add(hash_value)

        
        #self.run_connection_test()

        #this class will hold all of the search and data creatin elements when walking through the file system
        #it it progresses it will send messages back to the mainwindow
        #its job is to identify collections and create datbase records for analysis


    # this method is called from getMainWindow Menu option to search for collections        
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
        #this is the method that generates the creation of collections
        
        
        
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

    #this holds the main logic for seraching for and creating media file connections
    def traverse_folders(self, start_path):
        #gets name of device that searches for the collection


        device_name = platform.node()
        print(f"Creating media collection on device: {device_name}")
        #we use this in the media file record to show when the record was created

        # Perform the collection check
        collections, continue_operation = existing_collection(device_name, start_path, self)

        print("past collections check from searchmasterlocation")


        '''this worked before changes
        
        if collections:
            messages = []
            print("entering IF collections block from searchmasterlocation")
            # Debugging output
            print(f"Device Name: {device_name}")
            print(f"Start Path: {start_path}")
            print("Collections found:")
            for table, coll_date in collections:
                print(f"Table: {table}, Collection Date: {coll_date}")

        if not continue_operation:
            # Handle the abort case
            print("Operation aborted by the user.")
            return
            '''
        
        if collections:
            messages = []
            for table, coll_date in collections:
                messages.append(f"This collection already exists in the `{table}` table.\n"
                                f"Collection was created on {coll_date}")

            full_message = "\n\n".join(messages) + "\n\nDo you want to continue?"

            # Emit the signal to show the message box
            self.show_message_box.emit("Collection Already Exists", full_message)

            # Wait for the user's response (you might need to handle this differently)
            # For now, assume the operation continues
            continue_operation = True  # Or handle the response appropriately

        if not continue_operation:
            print("Operation aborted by the user.")
            return



        start_time = time.time()

        # Create a dictionary to map extensions to their types
        #converts to lower case and removes any possible white space
        #used to determine if a file in os.walk is a media file
        #it is if the ext is in extension_to_type, we can then lookup an extension
        #to see what type it is video, image etc
        extension_to_type = {ext.lower().strip(): type_ for type_, ext in self.myList}
        
        #this gets a list of folder names that should not feature in any search path
        exempt_folders = set(self.myFolders)


        #this initializes an empty array that will hold the records ready for insertion to the database
        all_media_records = []  # Collect all media records for database insertion

        #this begins the loop for the os.walk iterating through folders, sub folders and files
        for dirpath, dirnames, filenames in os.walk(start_path):
            # converts sub folder names to lower case to help with name comparison
            dirnames_lower = [d.lower() for d in dirnames]
            #each time we analse a folder we create a list of files to create records from
            #we reset the list for each folder
            media_records = []  # Reset the list for each folder





             #error here not defining DVD

            # video_ts files arise in dvds, we dont want to list each .vob file as
            #a media file so we store the name of the dvd folder
            if 'video_ts' in dirnames_lower:
                # Get the parent folder name
                parent_folder_name = os.path.basename(dirpath)
            
                # Calculate the size of the parent folder
                folder_size_bytes = sum(
                    os.path.getsize(os.path.join(dp, f))
                    for dp, dn, fn in os.walk(dirpath)
                    for f in fn
                )
                folder_size_mb = folder_size_bytes / (1024 * 1024)

            





            
                # Get the creation date of the parent folder
                folder_creation_timestamp = os.path.getctime(dirpath)
                folder_creation_date = datetime.fromtimestamp(folder_creation_timestamp).strftime('%Y-%m-%d %H:%M:%S')
            
                # Create a media record for the DVD
                media_record = self.create_media_record(
                    file_path=dirpath,
                    file_name=parent_folder_name,
                    file_type='DVD',
                    file_size=folder_size_mb,
                    file_creation_date=folder_creation_date,
                    category='Video',
                    device=device_name,
                    location=start_path
                )
            
                # Add the media record to the list
                all_media_records.append(media_record)
            
                # Clear dirnames to stop os.walk from descending into subdirectories
                dirnames.clear()
                continue

            if os.path.basename(dirpath).lower() == 'video_ts':
                continue

            if os.path.basename(dirpath) in exempt_folders:
                dirnames.clear()
                continue

            for filename in filenames:
                full_path = os.path.join(dirpath, filename)
                file_ext = os.path.splitext(filename)[1].lower().strip()

                # Check if the file extension is in the list of known extensions
                if file_ext in extension_to_type:
                    # Get the category/type of the file based on its extension
                    category = extension_to_type[file_ext]

                    # Check if the file is an image and apply size filtering
                    if category == 'Images':
                        try:
                            if os.path.getsize(full_path) < 500 * 1024:
                                continue
                        except (FileNotFoundError, OSError) as e:
                            print(f"Error accessing file {full_path}: {e}")
                            continue

                    # Calculate the hash of the file
                    #this hash is used to identify the file even though it may have a slightly different file name
                    #i can use it when looking for duplications
                    try:
                        with open(full_path, 'rb') as f:
                            file_hash = xxhash.xxh64(f.read()).hexdigest()
                            # Print the file hash
                            #print(f"Hash for {filename}: {file_hash}")
                            #now use the hash to check if the file exists in a master file
                            #by looking up in the hash list
                            #duplicate=checkHashLookup(file_hash)
                            if file_hash in self.hash_index:
                                self.duplicate = True
                            else: self.duplicate = False


                    except (FileNotFoundError, OSError) as e:
                        print(f"Error reading file {full_path} for hashing: {e}")
                        continue

                    # Remove text within parentheses from the filename
                    cleaned_filename = re.sub(r'\s*\(.*?\)\s*', '', filename)

                    file_size_mb = round(os.path.getsize(full_path) / (1024 * 1024), 3)
                    file_creation_date = datetime.fromtimestamp(os.path.getctime(full_path)).strftime('%Y-%m-%d %H:%M:%S')

                    media_record = self.create_media_record(
                        full_path, cleaned_filename, file_ext, file_size_mb, file_creation_date, category, device_name, start_path, file_hash, self.duplicate
                    )
                    media_records.append(media_record)

            # Add the media records of the current directory to the overall list
            all_media_records.extend(media_records)

            # Print the tuples after processing each folder
            #if media_records:
                #print(f"Printing Tuples for folder: {dirpath}")
                #for record in media_records:
                    #print(record)

        # Insert all collected media records into the database
        if all_media_records:
            print(f"Printing Tuples for folder: all media records")
            insert_record(all_media_records)

        end_time = time.time()
        time_taken = end_time - start_time
        self.footer.append(f"Traversal complete. Time taken: {time_taken:.2f} seconds")
        self.footer.append(f"Media records: {len(all_media_records)} found")

    def create_media_record(self, file_path, file_name, file_type, file_size, file_creation_date, category, device, location, file_hash, duplicate):
        """Creates a tuple with media file details."""
        coll_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        return (
            file_path,
            file_name,
            file_type,
            file_size,
            file_creation_date,
            category,
            device,
            location,
            coll_date,
            file_hash,
            duplicate
        )
    
    #def checkHashLookup(file_hash):
    def fetch_master_hashes_from_db():
        '''gets a list of music master library hashes for comparison with media file to find duplicates'''
        hashes = fetch_master_hashes_from_db()
        return hashes
   
    print("step....6       if folder contains valid media grab device,path,filename,ext,date checked, date created, then create extra data item making a name for the collection ")

    print("step....7       once a file has been processed add it to a list of files detail until eof then insert records into database")

    print("step....8       loop through all folders until completeand send completed message to Footer ")
        