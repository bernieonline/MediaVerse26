
from dbMySql import db_utils
from dbMySql.db_utils import fetch_master_hashes_from_db
from dbMySql.db_utils import get_list_extensions
from dbMySql.db_utils import get_list_folders
from tkinter import filedialog
from datetime import datetime
from dbMySql.db_utils import insert_record
from srcMedia.collection_check import existing_collection
from PyQt5.QtWidgets import QMessageBox, QWidget,  QProgressBar
from PyQt5.QtCore import QObject, pyqtSignal, QThread, QTimer
from concurrent.futures import ThreadPoolExecutor, as_completed



import tkinter as tk
import os
import time
import platform
import re
import xxhash  # Add this import at the top of your file
import threading
import logging



class Worker(QThread):
    ''' This threads main action is to run the os.walk searching for media content 
    records are created in the database and the GUI updated with progress
    its important to update the GUI in a specific way when a thread is running'''
    #sIGNALS BACK TO MAIN gui

    #signal emits every 10 files that are created to update LCDNumber widget in GUI
    record_counter_signal = pyqtSignal(int)  # Define the signal

    task_complete = pyqtSignal(str)
    start_signal = pyqtSignal()  # Signal to indicate worker has started
    finish_signal = pyqtSignal()  # Signal to indicate worker has finished
    
    
    def __init__(self, device_name, start_path, myList, myFolders, hash_index):
        super().__init__()
        self.device_name = device_name
        self.start_path = start_path
        self.myList = myList
        self.myFolders = myFolders
        self.hash_index = hash_index    # distinct list of hash refernces that can be used to check for existing content and flag as a dupicate
        self.duplicate=False

        self.coll_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        logging.info("self.coll_date:%s ",self.coll_date)
       

    def run(self):
        record_counter = 0
        logging.info(f"Worker thread started: {threading.current_thread().name}")
         # Emit signal to indicate the worker has started
        self.start_signal.emit()

        try:
            '''This is the long running process that needs a thread'''
            self.complete_traverse()
        except Exception as e:
            logging.info(f"Error during traversal: {e}")

        # Emit signal to indicate the worker has finished
        self.finish_signal.emit()
       

    def complete_traverse(self):
        #progress_interval = 10  # Emit progress every 10 directories
        #folder_counter = 0  # Initialize a folder counter
        record_counter=0
        logging.info(f"Device Name: {self.device_name}")  # Debugging line
        logging.info(f"Starting Task 1 on device: {self.device_name}")
        start_time = time.time()
        collection = ""
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

        '''os.walk() Function:
            os.walk() is a generator that yields a tuple of three values for each directory it visits in the directory tree rooted at self.start_path.
            The three values are:
            dirpath: A string representing the path to the current directory.
            dirnames: A list of the names of the subdirectories in dirpath.
            ilenames: A list of the names of the non-directory files in dirpath.'''


        #this begins the loop for the os.walk iterating through folders, sub folders and files
        for dirpath, dirnames, filenames in os.walk(self.start_path):

            # converts sub folder names to lower case to help with name comparison
            dirnames_lower = [d.lower() for d in dirnames]
            #each time we analyse a folder we create a list of files to create records from
            #we reset the list for each folder (not sure if that actually happens all all records are added to database in one go
            
            media_records = []  # Reset the list for each folde

            
            ### DEALING WITH DVDS #####
            # video_ts files arise in dvds, we dont want to list each .vob file as
            #a media file so we store the name of the dvd folder
            #if 'video_ts' in dirnames_lower:
            if 'video_ts' in dirnames_lower or any(filename.lower().endswith('.vob') for filename in filenames):
                #self.makeDVDFolder(dirpath, )

                # Get the parent folder name
                parent_folder_name = os.path.basename(dirpath)
            
                # Calculate the size of the parent folder
                folder_size_bytes = sum(
                    os.path.getsize(os.path.join(dp, f))
                    for dp, dn, fn in os.walk(dirpath)
                    for f in fn
                )
                
                folder_size_mb = folder_size_bytes / (1024 * 1024)
               

               # Create a media record for the DVD
                print("...........testing folder creation date..........................................")
                folder_creation_timestamp = os.path.getctime(dirpath)
                folder_creation_date = datetime.fromtimestamp(folder_creation_timestamp).strftime('%Y-%m-%d %H:%M:%S')
                logging.info("folder_creation_date: %s ",folder_creation_date)
                # Construct the collection field before calling create_media_record
                collection=f"{self.device_name}:{self.start_path}:{self.coll_date}"

                
                # Create a media record for the DVD
                #media_record is a TUPLE that holds the data about a media file or folder to be created in the database
                media_record = self.create_media_record(
                    file_path=dirpath,
                    file_name=parent_folder_name,
                    file_type='DVD',
                    file_size=folder_size_mb,
                    file_creation_date=folder_creation_date,
                    collection = collection,
                    category='Video',
                    device=self.device_name,
                    location=self.start_path,
                    coll_date=self.coll_date,
                    file_hash = "None Calculated",
                    duplicate = "X"
                )
            
                # Add the media record to the list
                 #media_record is a TUPLE that holds the data about a media file or folder to be created in the database

              
                #all_media_records.append(media_record)
            
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

                    # Check if the file is an image and apply size filtering 500 kB
                    if category == 'Images':
                        try:
                            if os.path.getsize(full_path) < 500 * 1024:
                                continue
                        except (FileNotFoundError, OSError) as e:
                            print(f"Error accessing file {full_path}: {e}")
                            continue   
                    
                    if category == 'Video':
                        file_hash = 'None Calculated'
                        self.duplicate = 'X'

                    else:
                        #file_hash = 'None Calculated'
                        self.duplicate = 'X'
                        
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
                    #print("starting os search proper................1G")
                    cleaned_filename = re.sub(r'\s*\(.*?\)\s*', '', filename)
                    #print("starting os search proper................2")

                    file_size_mb = round(os.path.getsize(full_path) / (1024 * 1024), 3)
                    file_creation_date = datetime.fromtimestamp(os.path.getctime(full_path)).strftime('%Y-%m-%d %H:%M:%S')
                    logging.info("file_creation_date :%s ",file_creation_date)
                    #print("starting os search proper................3")
                    
                    collection=f"{self.device_name}:{self.start_path}:{self.coll_date}"

                    
                    #print(f"Device Name: {self.device_name}")
                    #print(f"Start Path: {self.start_path}")
                    #print(f"datetime:{self.coll_date}")

                    #print(f"Collection: {collection}")

                    #print("starting os search proper................4")

                    #media_record is a TUPLE that holds the data about a media file or folder to be created in the database
                    media_record = self.create_media_record(
                        full_path, cleaned_filename, file_ext, file_size_mb, file_creation_date, collection, category, self.device_name, self.start_path, self.coll_date, file_hash, self.duplicate
                    )
                    #print("Arguments being passed to create_media_record:")
                    #print(full_path, cleaned_filename, file_ext, file_size_mb, file_creation_date, collection, category, self.device_name, self.start_path, self.coll_date, file_hash, self.duplicate)
                    media_records.append(media_record)
                     # Increment the counter and print the message
                    record_counter += 1
                    if record_counter % 10 == 0:
                        self.record_counter_signal.emit(record_counter)
                        #print(f"new record {record_counter}")

            # Add the media records of the current directory to the overall list
            all_media_records.extend(media_records)

            # Print the tuples after processing each folder
            #if media_records:
                #print(f"Printing Tuples for folder: {dirpath}")
                #for record in media_records:
                    #print(record)

        # Insert all collected media records into the database
        if all_media_records:
            #print(f"Printing Tuples for folder: all media records")
            insert_record(all_media_records)

        #print("starting os search proper................A")
                    
        end_time = time.time()
        #print("starting os search proper................B")
                    
        time_taken = end_time - start_time

        #print("starting os search proper................C")
                    
  

        # Emit a signal when the task is complete
        
        
        message = f"Traversal complete. Time taken: {time_taken:.2f} seconds. Media records: {len(all_media_records)} found."
        #print("starting os search proper................D")
                    
        self.task_complete.emit(message)
        #print("starting os search proper................E")
                    


    def create_media_record(self, file_path, file_name, file_type, file_size, file_creation_date, collection,category, device, location,coll_date, file_hash, duplicate):
        """Creates a tuple with media file details."""
        
        coll_date=self.coll_date


        return (
            file_path,
            file_name,
            file_type,
            file_size,
            file_creation_date,
            collection,
            category,
            device,
            location,
            coll_date,
            file_hash,
            duplicate
        )
    

   
                    
    
 

   


class SearchLocation(QWidget):
    #show_message_box = pyqtSignal(str, str)  # Signal to show a message box with title and message need due to threads not allowing a gui to be created within it, gui must run from Main thread
    #connection_status = pyqtSignal(str)  # Signal to emit connection status for database
    def __init__(self, getWin=None, Footer=None, media_type=None, master_type=None, selected_path=None, media_progress_bar=None):
        # Store a reference to the parent window for QMessageBox
        self.getWin = getWin
        super().__init__(self.getWin)  # Initialize the QWidget with the parent
        
        # Store a reference to the Footer QTextEdit object
        self.footer = Footer
        self.selected_folder = None
        self.myList = None
        self.myFolders = None
        self.hash_index = set()

        # Initialize your GUI components, including the progress bar
        self.media_progress_bar = media_progress_bar
       
         # Create a QTimer to pulse the progress bar
        self.pulse_timer = QTimer(self)
        self.pulse_timer.timeout.connect(self.update_progress_bar)

        for hash_value in fetch_master_hashes_from_db():
            #creates a python set from the hashes that can be used to quickly look up a hash to see if its in the list
            self.hash_index.add(hash_value)


        #this class will hold all of the search and data creatin elements when walking through the file system
        #it it progresses it will send messages back to the mainwindow
        #its job is to identify collections and create datbase records for analysis


    # this method is called from getMainWindow Menu option to search for collections 
    # check ok       
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

        # Connect the worker's finish signal to stop pulsing
        self.worker.finish_signal.connect(self.stop_pulsing)
      


    #user selectas a folder to begin searching from
    #check ok 
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

    #check ok 
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
    #check ok  
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
                
   


    #this holds the main gui work prior to os.walk for seraching for and creating media file connections 
    #os.walk now running in a thread worker
    def traverse_folders(self, start_path):
        #gets name of device that searches for the collection

        self.device_name = platform.node()
        logging.info(f"Creating media collection on device: {self.device_name}")
        #we use this in the media file record to show when the record was created

        # Perform the collection check to see if a similar collecion already exists at that location
        collections, continue_operation = existing_collection(self.device_name, start_path, self)

        if not continue_operation:
            logging.info("Operation aborted by the user.")
            return
        
        self.getWorker(start_path,self.device_name)
        

    def getWorker(self, start_path, device_name):

        # If the user chooses to continue, start the Worker thread
        self.worker = Worker(
        device_name=device_name,
        start_path=start_path,
        myList=self.myList,
        myFolders=self.myFolders,
        hash_index=self.hash_index  # Add this line to pass the hash_index
        )
        
        self.getWin.setStartTime()

        # Connect the worker's start signal to begin pulsing
        self.worker.start_signal.connect(self.start_pulsing)
       
        # Start the worker thread
        self.worker.start()
        print("preparing to set end time")
        #self.getWin.setEndTime()

    def on_task_complete(self, message):
        # Update the footer or handle the message
        self.footer.append(message)

    def start_pulsing(self):

        # Set the progress bar to be indeterminate (will be pulsing)
        self.media_progress_bar.setRange(0, 0)
        # Start the pulse timer when the worker starts
        self.pulse_timer.start(100)  # Pulse every 100 ms

    def stop_pulsing(self):
        # Stop the pulse timer when the task is complete
        self.pulse_timer.stop()    
        self.media_progress_bar.setRange(0, 100)
        self.media_progress_bar.setValue(0)  # Reset the progress bar value
        self.getWin.setEndTime()

    def update_progress_bar(self):
        current_value = self.media_progress_bar.value()
        # Toggle between 0 and 100 to simulate pulsing effect
        new_value = 100 if current_value == 0 else 0
        self.media_progress_bar.setValue(new_value)
        

