
from dbMySql.db_utils import get_selected_extensions
from dbMySql.db_utils import get_list_folders
from dbMySql.db_utils import insert_master_record

import os
import time
import logging
import threading
import xxhash  # file hashing for comparisons
import re
from datetime import datetime
from PyQt5.QtCore import QObject, pyqtSignal, QThread, QTimer


from PyQt5.QtWidgets import QMessageBox, QTextEdit
import platform
from srcMedia.collection_check import existing_collection
from PyQt5.QtWidgets import QWidget, QProgressBar

'''this thread is used when creating a collection of Master Records, its a long process
and keeps the system responsive'''

class Worker2(QThread):

    record_counter_signal = pyqtSignal(int)  # Define the signal

    task_complete = pyqtSignal(str)
    start_signal = pyqtSignal()  # Signal to indicate worker has started
    finish_signal = pyqtSignal()  # Signal to indicate worker has finished

    def __init__(self, device_name, start_path, myList, myFolders, media_type, master_type):
        super().__init__()
        self.device_name = device_name
        self.start_path = start_path
        self.myList = myList
        self.myFolders = myFolders
        self.media_type = media_type
        self.master_type = master_type
        logging.info("Initialized Worker2 :%s",self.master_type)
        self.coll_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        #logging.info("self.coll_date:%s ",self.coll_date)


       
    '''this is the method that runs when the thread is activated'''
    def run(self):
        record_counter = 0
        logging.info(f"Worker thread started: {threading.current_thread().name}")

      

         # Emit signal to indicate the worker has started
        self.start_signal.emit()


        try:
            logging.info("Running complete traverse")
            self.complete_traverse()

        except Exception as e:
            logging.error(f"Error during traversal: {e}")

        # Emit signal to indicate the worker has finished
        self.finish_signal.emit()


       
    '''this is the second stage of the os walk process, i have split it into 2 stages
    because I am using progress bars which can not be updated within the thread
    only within the GUI so stage 1 is set up outside of the thread'''
    def complete_traverse(self):

        logging.info("Entering complete traverse")
        
        record_counter=0
        
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
        for dirpath, dirnames, filenames in os.walk(self.start_path):

            # converts sub folder names to lower case to help with name comparison
            dirnames_lower = [d.lower() for d in dirnames]

            #each time we analse a folder we create a list of files to create records from
            #we reset the list for each folder
            media_records = []  # Reset the list for each folde

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
                    device=self.device_name,
                    location=self.start_path
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

                    except (FileNotFoundError, OSError) as e:
                        print(f"Error reading file {full_path} for hashing: {e}")
                        continue

                    # Remove text within parentheses from the filename
                    cleaned_filename = re.sub(r'\s*\(.*?\)\s*', '', filename)

                    file_size_mb = round(os.path.getsize(full_path) / (1024 * 1024), 3)
                    file_creation_date = datetime.fromtimestamp(os.path.getctime(full_path)).strftime('%Y-%m-%d %H:%M:%S')

                    #we only create a media record where media type is as selected
                    #we then set up for using collection type as clone for example using the collection column  
                    #print("collection type: ",self.master_type)
                    
                    master_type_new = f"{self.master_type}:{self.device_name}:{self.start_path}:{self.coll_date}"
                    #logging.info(" re formatted collection is: %s",self.master_type)
                
                    media_record = self.create_media_record(
                    full_path, cleaned_filename, file_ext, file_size_mb, file_creation_date, master_type_new, self.media_type, self.device_name, self.start_path,file_hash ) 
                    all_media_records.append(media_record)
                     # Increment the counter and print the message
                    record_counter += 1
                    print(f"new record AAAA{record_counter}")
                    if record_counter % 10 == 0:
                        print(f"new record BBB {record_counter}")
                        self.record_counter_signal.emit(record_counter)
                        print(f"new record CCC {record_counter}")
                        print(f"new record {record_counter}")
                    #logging.info(f"Created record {record_counter}")
            
        # Insert all collected media records into the database
        if all_media_records:
            logging.info("Inserting media records into the database")
            insert_master_record(all_media_records)

        else:
            logging.info("No media records")

        end_time = time.time()
        time_taken = end_time - start_time

         # Emit a signal when the task is complete
                
        message = f"Traversal complete. Time taken: {time_taken:.2f} seconds. Master records: {len(all_media_records)} found."
        self.task_complete.emit(message)

    def create_media_record(self, file_path, file_name, file_type, file_size, file_creation_date, collection, category, device, location,file_hash ):
        """Creates a tuple with media file details."""
        try:
            #logging.info("Creating media record with the following details:")
            #logging.info(f"file_path: {file_path}, file_name: {file_name}, file_type: {file_type}, file_size: {file_size}")
            #logging.info(f"file_creation_date: {file_creation_date}, collection: {collection}, category: {category}")
            #logging.info(f"device: {device}, location: {location}, file_hash: {file_hash}")

            coll_date = self.coll_date
            record = (
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
                file_hash
            )
            #logging.info("Media record created successfully.")
            return record
        except Exception as e:
            logging.error(f"Error creating media record: {e}")
            raise


   

class SearchMasterLocation(QWidget):
     #connection_status = pyqtSignal(str)  # Signal to emit connection status for database
    def __init__(self, parent=None, Footer = None, master_progress_bar=None, media_type=None, master_type=None, selected_path=None):
        # Store a reference to the parent window for QMessageBox
        self.parent = parent
        super().__init__(parent)
        # Store a reference to the Footer QTextEdit object
        self.footer = Footer
        self.master_progress_bar = master_progress_bar
        self.selected_folder = None
        self.myList = None
        self.myFolders = None
        self.media_type = media_type
        self.master_type = master_type

        
        self.selected_path = selected_path
        #print("...........testing class used is master file search..........................................")


        # Initialize your GUI components, including the progress bar
       
        # Ensure master_progress_bar is not None
        if self.master_progress_bar is None:
            #raise ValueError("master_progress_bar must be provided and cannot be None.")
            print("Progress bar does not exist")

        

         # Create a QTimer to pulse the progress bar
        self.pulse_timer2 = QTimer(self)
        self.pulse_timer2.timeout.connect(self.update_progress_bar)
    
    
    
    def run(self):   
       
        self.selected_folder = self.selected_path

        ("search folder is:"+self.selected_folder)
        if self.selected_folder:
            self.footer.append("search folder is:"+self.selected_folder)
        else:
             self.footer.setText("No Folder Selected")

        #print("step....2       Get a list of media file extensions")
        #folder was selected
        self.myFolders = self.get_folder_list()
        
        self.myList =  self.get_ext_list(self.media_type)
        #print(f"Master type provided: {self.media_type}")  # Print the master_type to check its value
        extensions = get_selected_extensions(self.media_type)  # Call the imported function
        if extensions:        
            #print("Extensions retrieved from database:")  # Print a message indicating extensions were retrieved
                # Extract the first element of each tuple (type) from the list of extensions
            self.myList = [(row[0], row[1]) for row in extensions]
                # Print the contents of self.myList to verify its contents
            #print(f"self.myList contents: {self.myList}")
        
        #print("step....2b       ran the code for a list of media file extensions")
        #this is the method that generates the creation of collections
        self.traverse_folders(self.selected_folder)

         # Connect the worker's finish signal to stop pulsing
        self.worker2.finish_signal.connect(self.stop_pulsing)

    #mofify to limit the list so selected extensions for media
    def get_ext_list(self,master_type):
        """Gets the list of file extensions that define media files but as a master we only want a selected type such as music."""
        #print("entering sl get_ext_list")
        extensions = get_selected_extensions(master_type)  # Call the imported function
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
                
     #this holds the main logic for seraching for and creating media file connections
     #modify to search only for selected media type
    def traverse_folders(self, start_path):
        print("traversing folders")
        #gets name of device that searches for the collection
        device_name = platform.node()
        print(f"Creating master collection on device: {device_name}")
        #we use this in the media file record to show when the record was created
        #print("entering collections check from searchmasterlocation",device_name)
        # Perform the collection check and warn if similar connection exists

        print("device and path", device_name,":",start_path)
        collections, continue_operation = existing_collection(device_name, start_path, self)

        print("past collections check from searchmasterlocation", collections)


        if collections:
            print("entering IF collections block from searchmasterlocation")
            # Debugging output
            print(f"Device Name: {device_name}")
            print(f"Start Path: {start_path}")
            #print("Collections found:")
            #for table, coll_date in collections:
                #print(f"Table: {table}, Collection Date: {coll_date}")

        if not continue_operation:
            # Handle the abort case
            print("Operation aborted by the user.")
            return
        
        # If the user chooses to continue, start the Worker thread
        self.worker2 = Worker2(
        device_name=device_name,
        start_path=start_path,
        myList=self.myList,
        myFolders=self.myFolders,
        media_type = self.media_type,
        master_type = self.master_type,
        
        #hash_index=hash_index  # Add this line to pass the hash_index
        )

        print("instantiated worker2")


          # Connect the worker's start signal to begin pulsing
        self.worker2.start_signal.connect(self.start_pulsing)
        print("Pulsing bar")
        self.worker2.record_counter_signal.connect(self.parent.update_filecount_lcd)  # Connect the signal here
        print("connecting to filecount")

        
        self.worker2.start()
        
        #start_time = time.time()

        #end_time = time.time()
        #time_taken = end_time - start_time
        #self.footer.append(f"Traversal complete. Time taken: {time_taken:.2f} seconds")
        #self.footer.append(f"Media records: {len(self.all_media_records)} found")



    def on_task_complete(self, message):
        # Update the footer or handle the message
        self.footer.append(message)

    def start_pulsing(self):

        # Set the progress bar to be indeterminate (will be pulsing)
        self.master_progress_bar.setRange(0, 0)
        # Start the pulse timer when the worker starts
        self.pulse_timer2.start(100)  # Pulse every 100 ms

    def stop_pulsing(self):
        # Stop the pulse timer when the task is complete
        self.pulse_timer2.stop()    
        self.master_progress_bar.setRange(0, 100)
        self.master_progress_bar.setValue(0)  # Reset the progress bar value

    def update_progress_bar(self):
        current_value = self.master_progress_bar.value()
        # Toggle between 0 and 100 to simulate pulsing effect
        new_value = 100 if current_value == 0 else 0
        self.master_progress_bar.setValue(new_value)
'''
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

            # video_ts files arise in dvds, we dont want to list each .vob file as
            #a media file so we store the name of the dvd folder
            
            
            #error here not defining DVD
            
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

                # Debugging: Print the file extension and check if it's in the known extensions
                #print(f"Checking file: {filename}, Extension: {file_ext}")

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
                    except (FileNotFoundError, OSError) as e:
                        print(f"Error reading file {full_path} for hashing: {e}")
                        continue

                    # Remove text within parentheses from the filename
                    cleaned_filename = re.sub(r'\s*\(.*?\)\s*', '', filename)

                    file_size_mb = round(os.path.getsize(full_path) / (1024 * 1024), 3)
                    file_creation_date = datetime.fromtimestamp(os.path.getctime(full_path)).strftime('%Y-%m-%d %H:%M:%S')

                    media_record = self.create_media_record(
                        full_path, cleaned_filename, file_ext, file_size_mb, file_creation_date, category, device_name, start_path, file_hash
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
            insert_master_record(all_media_records)




    def create_media_record(self, file_path, file_name, file_type, file_size, file_creation_date, category, device, location, file_hash):
        """, the create_media_record function is indeed used as part of the process that adds 
            records to the database in your program. Here's how it fits into the overall workflow:
            Creating Media Records: The create_media_record function is called within the traverse_folders method.
            This method traverses through directories and files, identifying media files based on their extensions and other criteria.."""
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
            file_hash
        )
            '''
    
    

        