import mysql.connector
from mysql.connector import Error
import os 
from dotenv import load_dotenv
import logging
import subprocess
from datetime import datetime
import tkinter as tk
from tkinter import messagebox

# Load environment variables 
#from .env file load_dotenv()
#use my credentials file as environment variables
#load_dotenv(dotenv_path='sqlCreds.env')




from pathlib import Path
load_dotenv(dotenv_path=Path(__file__).parent.parent / "sqlCreds.env")

#Access environment variables 
host = os.getenv('MYSQL_HOST') 
user = os.getenv('MYSQL_USER') 
password = os.getenv('MYSQL_PASSWORD') 
database = os.getenv('MYSQL_DB')



print("Host from .env:", repr(host))



def test_mysql_connection():
    #print("inside create_mysql_connection")
    connection = None
    try:
        connection=mysql.connector.connect(
            host=host,
            user=user,
            password=password,
            database=database,
            connect_timeout=5
        )
        if connection.is_connected():
            print("connection achieved")
            return True
    except mysql.connector.Error as err:
        print("connection failed")
        print(f"Error: {err}")
        return False
    
    finally:
        #print("inside finally")
        if connection and connection.is_connected():
            connection.close()
            print("Database connection closed.")

def create_db_connection():
    """Establishes a connection to the MySQL database and returns the connection object."""
   
    try:
        # Replace these with your actual database credentials

        connection=mysql.connector.connect(
            host=host,
            user=user,
            password=password,
            database=database,
            connect_timeout=5
        )

        if connection.is_connected():
            print("Connection to MySQL database was successful.")
            return connection
    except Error as e:
        print(f"Error while connecting to MySQL: {e}")
        return None
    


#run bt connection test on startup from searchLocation
def insert_master_record(file_path, media_type, collection_type):
    """Insert a record into the masterfiledetail table."""
    connection = create_db_connection()
    if connection is None:
        print("Failed to connect to the database for inserting record.")
        return
    try:
        cursor = connection.cursor()
        cursor.execute(
            "INSERT INTO masterfiledetail (file_path, media_type, collection_type) VALUES (%s, %s, %s)",
            (file_path, media_type, collection_type)
        )
        connection.commit()
    except Error as e:
        print(f"Error while inserting record: {e}")
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()



def get_list_extensions():
    """Fetches a list of types and extension names from the database."""
    print("entering get_list_extensions method.")

    
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database running get_list_extensions.")
        return []
    try:
        print("entering get_list_extensions method.....got connection.")
        cursor = connection.cursor()
        print("entering get_list_extensions method.....got cursor.")
        # Replace 'your_table_name' and 'type_column', 'extension_column' with actual table and column names
        query = "SELECT type, ext FROM mediatypes"
        cursor.execute(query)
        print("entering get_list_extensions method.....query executed.")
        # Fetch all results from the executed query
        results = cursor.fetchall()
        # Format the results into a list of tuples (type, extension)
        extensions_list = [(row[0], row[1]) for row in results]
        
        
        
        
        return extensions_list
    
    except Error as e:
        print(f"Error while executing query: {e}")
        return []
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()


def get_list_extension_types():
    """Fetches a list of types and extension names from the database."""
    print("entering get_list_extensions method.")

    
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database running get_list_extensions.")
        return []
    try:
        print("entering get_list_extension types method.....got connection.")
        cursor = connection.cursor()
        print("entering get_list_extension types method.....got cursor.")
        # Replace 'your_table_name' and 'type_column', 'extension_column' with actual table and column names
        query = "SELECT distinct media_type FROM mediatypename"
        cursor.execute(query)
        print("entering get_list_extension types method.....query executed.")
        # Fetch all results from the executed query
        results = cursor.fetchall()
        # Format the results into a list of tuples (type, extension)
        extensions_list = [(row[0]) for row in results]

        for media in extensions_list:
            print(media)


        
        return extensions_list
    
    except Error as e:
        print(f"Error while executing query: {e}")
        return []
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

def get_list_master_types():
    """Fetches a list of master types  from the database."""
    print("entering get master type method.")

    
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database running get master type.")
        return []
    try:
        print("entering get master types method.....got connection.")
        cursor = connection.cursor()
        print("entering get master types method.....got cursor.")
       
        query = "SELECT distinct type_ FROM mastertype"
        cursor.execute(query)
        print("entering get_list_extension types method.....query executed.")
        # Fetch all results from the executed query
        results = cursor.fetchall()
        # Format the results into a list of tuples (type, extension)
        master_list = [(row[0]) for row in results]

        for master in master_list:
            print(master)


        
        return master_list
    
    except Error as e:
        print(f"Error while executing query: {e}")
        return []
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()



def get_selected_extensions(ext_type):
    """Fetches a list of types and extension names from the database based on the type selected."""
    print("entering get_list_extensions method.")

    
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database running get_list_extensions.")
        return []
    try:
        print("entering get_list_extensions method.....got connection.")
        cursor = connection.cursor()
        print("entering get_list_extensions method.....got cursor.")
        # Replace 'your_table_name' and 'type_column', 'extension_column' with actual table and column names
        query = "SELECT type, ext FROM mediatypes where type = %s"
        cursor.execute(query, (ext_type,))
        print("entering get_list_extensions method.....query executed.")
        # Fetch all results from the executed query
        results = cursor.fetchall()
        # Format the results into a list of tuples (type, extension)
        extensions_list = [(row[0], row[1]) for row in results]
        return extensions_list
    
    except Error as e:
        print(f"Error while executing query: {e}")
        return []
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

def get_list_folders():
    """Fetches a list of folders exempt from the search from the database."""
    
    connection = create_db_connection()
    if connection is None:
        print("Failed to connect to the database.")
        return []

    try:
        with connection.cursor() as cursor:
            query = "SELECT folder_name FROM excluded_folders"  # Ensure 'folder_name' is the correct column
            cursor.execute(query)
            results = cursor.fetchall()
            folder_list = [row[0] for row in results]
            return folder_list
    except Error as e:
        print(f"Error while executing query: {e}")
        return []
    finally:
        if connection.is_connected():
            connection.close()



import mysql.connector
from mysql.connector import Error
import os
from dotenv import load_dotenv

# Load environment variables from the .env file
load_dotenv(dotenv_path='sqlCreds.env')

# Retrieve database credentials from environment variables
host = os.getenv('MYSQL_HOST')
user = os.getenv('MYSQL_USER')
password = os.getenv('MYSQL_PASSWORD')
database = os.getenv('MYSQL_DB')

def create_db_connection():
    """Establishes a connection to the MySQL database and returns the connection object."""
    try:
        connection = mysql.connector.connect(
            host=host,
            user=user,
            password=password,
            database=database,
            connect_timeout=5
        )

        if connection.is_connected():
            print("Connection to MySQL database was successful.")
            return connection
    except Error as e:
        print(f"Error while connecting to MySQL: {e}")
        return None


def insert_record(records):
    """
    Inserts records into the 'mediafiledetails' table in the MySQL database.

    :param records: A list of tuples, where each tuple represents a record to be inserted.
    """
    logging.info("Trying to insert records")
    connection = create_db_connection()
    if connection is None:
        print("Failed to connect to the database. Records were not inserted.")
        return

    try:
        cursor = connection.cursor()

        # Specify the columns you want to insert values into, including the new 'collection' column
        columns = [
            'file_path', 'file_name', 'file_type', 'file_size',
            'file_creation_date','collection', 'category', 'device', 'location', 
            'coll_date', 'checksum', 'duplicated'
        ]
        placeholders = ', '.join(['%s'] * len(columns))
        columns_formatted = ', '.join(columns)
        insert_query = f"INSERT INTO mediafiledetail ({columns_formatted}) VALUES ({placeholders})"

        # Prepare records with the new 'collection' field
        #records_with_collection = [
           # record + (f"{record[6]}:{record[7]}:{record[8]}",) for record in records
        #]

         # Debugging: Print each record before insertion
        #for record in records_with_collection:
            #print("Inserting record x:", record)

      
        ##cursor.executemany(insert_query, records_with_collection)
        ##connection.commit()
        cursor.executemany(insert_query,records)
        connection.commit()
        print(f"{cursor.rowcount} records inserted successfully into mediafiledetail.")

    except Error as e:
        print(f"Error while inserting records: {e}")
        connection.rollback()

    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()
            print("MySQL connection is closed.")


#def insert_record(file_path, media_type, collection_type, checksum):
#modified this 16/12/24 to insert a collection name adding coll_date to location
def insert_record_old(records):
    """
    Inserts records into the 'mediafiledetails' table in the MySQL database.

    :param records: A list of tuples, where each tuple represents a record to be inserted.
    """
    connection = create_db_connection()
    if connection is None:
        print("Failed to connect to the database. Records were not inserted.")
        return

    try:
        cursor = connection.cursor()

        # Specify the columns you want to insert values into
        columns = [
            'file_path', 'file_name', 'file_type', 'file_size',
            'file_creation_date','collection', 'category', 'device', 'location', 'coll_date', 'checksum', 'duplicated'
        ]
        placeholders = ', '.join(['%s'] * len(columns))
        columns_formatted = ', '.join(columns)
        insert_query = f"INSERT INTO mediafiledetail ({columns_formatted}) VALUES ({placeholders})"

        cursor.executemany(insert_query, records)
        connection.commit()
        print(f"{cursor.rowcount} records inserted successfully into mediafiledetail.")

    except Error as e:
        print(f"Error while inserting records: {e}")
        connection.rollback()

    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()
            print("MySQL connection is closed.")

def insert_master_record(records):
     # Print the records object to see its contents
    #print("Records to be inserted:", records)
    """
    Inserts records into the 'masterfiledetail' table in the MySQL database.

    :param records: A list of tuples, where each tuple represents a record to be inserted.
    """
    connection = create_db_connection()
    if connection is None:
        print("Failed to connect to the database. Records were not inserted.")
        return

    try:
        cursor = connection.cursor()

        # Specify the columns you want to insert values into
        columns = [
            'file_path', 'file_name', 'file_type', 'file_size',
            'file_creation_date', 'collection','category', 'device', 'location', 'coll_date', 'checksum'
        ]
        placeholders = ', '.join(['%s'] * len(columns))
        columns_formatted = ', '.join(columns)
        insert_query = f"INSERT INTO masterfiledetail ({columns_formatted}) VALUES ({placeholders})"
        #print("insert master record",insert_query)
        cursor.executemany(insert_query, records)
        connection.commit()
        print(f"{cursor.rowcount} records inserted successfully into masterfiledetail.")

    except Error as e:
        print(f"Error while inserting records: {e}")
        connection.rollback()

    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()
            print("MySQL connection is closed.")



#changed this for the version that groups by collection name 
#it draws the first chart from the menu using mediafiledetails collections
#  using the collection name to group by
def summary_coll_list_old():
    '''lists all locations showing number of media files and total size'''
    '''this list will feed a pie chart - pick a segment to see the details'''
    connection = create_db_connection()
    if connection is None:
        print("Failed to connect to the database.")
        return []

    try:
        with connection.cursor() as cursor:
            #query = "SELECT folder_name FROM excluded_folders"  # Ensure 'folder_name' is the correct column
            query = f"""
            SELECT location, COUNT(*) AS record_count, SUM(file_size) AS total_file_size
            FROM mediafiledetail
            GROUP BY location
            ORDER BY record_count desc limit 7;
            """    
            cursor.execute(query)
            results = cursor.fetchall()
            collection_list = [(row[0],row[1],row[2]) for row in results]
            return collection_list
    except Error as e:
        print(f"Error while executing query: {e}")
        return []
    finally:
        if connection.is_connected():
            connection.close()
   

#it draws the first chart from the menu using mediafiledetails collections using the collection name to group by
def summary_coll_list():
    '''lists all locations showing number of media files and total size'''
    '''this list will feed a pie chart - pick a segment to see the details'''
    connection = create_db_connection()
    if connection is None:
        print("Failed to connect to the database.")
        return []

    try:
         logging.info("Getting data from summary_coll_list() in db_utils, uses group by collection name")
         with connection.cursor() as cursor:
                #query = "SELECT folder_name FROM excluded_folders"  # Ensure 'folder_name' is the correct column
                query = f"""
                SELECT collection, COUNT(*) AS record_count, SUM(file_size) AS total_file_size
                FROM mediafiledetail
                GROUP BY collection
                ORDER BY record_count desc limit 7;
                """    
                cursor.execute(query)
                results = cursor.fetchall()
                collection_list = [(row[0],row[1],row[2]) for row in results]
                return collection_list
    except Error as e:
            print(f"Error while executing query: {e}")
            return []
    finally:
            if connection.is_connected():
                connection.close()


def get_distinct_values_with_all(option_type, coll_type):
    """
    Fetches a list of distinct values from the specified column in the mediafiledetails table
    and adds an 'all' option at the beginning of the list.
    
    Parameters:
    option_type (str): The type of option to fetch ('device' or 'category').

    Returns:
    list: A list of distinct values with 'all' as the first element.
    """
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database.")
        return ['All']
    
    try:
        cursor = connection.cursor()

        print("gettingcombobox details")
        
        # Determine the table based on the coll_type
        if coll_type == 'master':
            table_name = 'masterfiledetail'
        elif coll_type == 'collection':
            table_name = 'mediafiledetail'
        else:
            print("Invalid coll_type provided.")
            return ['All']
        
        # Determine the query based on the option_type
        if option_type == 'device':
            query = f"SELECT DISTINCT device FROM {table_name} ORDER BY device"
        elif option_type == 'category':
            query = f"SELECT DISTINCT category FROM {table_name} ORDER BY category"
        else:
            print("Invalid option_type provided.")
            return ['All']
        
        cursor.execute(query)
        
        # Fetch all results from the executed query
        results = cursor.fetchall()
        
        # Extract the first element from each tuple in the results
        values_list = [row[0] for row in results]
        
        # Add 'all' at the beginning of the list
        values_list.insert(0, 'All')

        # Print the list to be added to the combo box
        print(f"Values for {option_type} combo box: {values_list}")
        
        return values_list
    
    except Error as e:
        print(f"Error while executing query: {e}")
        return ['all']
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()    

def get_filtered_data(device=None, category=None, selected_radio=None):
    logging.info("getting filtered data: %s : %s : %s", device, category, selected_radio)
    # Treat None or empty device as 'All'
    if not device:
        device = 'All'
    
    # Treat None or empty category as 'All'
    if not category:
        category = 'All'
    
    #print("inside get_filtered data: ", selected_radio)
    #print("device:", device, "category:", category)
    
    """Fetches filtered data based on the selected device and category."""
    connection = create_db_connection()
    if connection is None:
        logging.info("Faied to connect to database")
        return []

    try:
        with connection.cursor() as cursor:
            # Determine the table name based on selected_radio
            if selected_radio == "collection":
                table_name = "mediafiledetail"
            elif selected_radio == "master":
                table_name = "masterfiledetail"
            else:
                print("Invalid selected_radio value.")
                return []
            
            # Build the query conditionally
            query = f"""
            SELECT collection, COUNT(*) AS record_count, SUM(file_size) AS total_file_size
            FROM {table_name}
            """
            
            # Dynamic WHERE clause
            where_conditions = []
            params = []

            if device != 'All':
                where_conditions.append("device = %s")
                params.append(device)
            
            if category != 'All':  # Assuming 'All' should also be ignored for category
                where_conditions.append("category = %s")
                params.append(category)

            if where_conditions:
                query += " WHERE " + " AND ".join(where_conditions)

            query += """
            GROUP BY collection
            ORDER BY record_count DESC
            ;
            """

            # Print the query with parameters for debugging
            formatted_query = query % tuple(map(repr, params))
            #print("Final query to execute:", formatted_query)

            # Execute the query with parameters
            cursor.execute(query, tuple(params))
            print("get filtered data query:", formatted_query)  # For debugging

            # Fetch all results to ensure no unread results remain
            results = cursor.fetchall()
            if not results:
                print("No data found.")
                return []
            return [(row[0], row[1], row[2]) for row in results]
    
    except Error as e:
        print(f"Error while executing query: {e}")
        return []
    
    finally:
        if connection.is_connected():
            connection.close()

def get_filtered_data_WORKS(device=None, category=None, selected_radio=None):
    # Treat None or empty device as 'All'
    if not device:
        device = 'All'
    
    # Treat None or empty category as 'All'
    if not category:
        category = 'All'
    
    print("inside get_filtered data: ", selected_radio)
    print("device:", device, "category:", category)
    
    """Fetches filtered data based on the selected device and category."""
    connection = create_db_connection()
    if connection is None:
        print("Failed to connect to the database.")
        return []

    try:
        with connection.cursor() as cursor:
            # Determine the table name based on selected_radio
            if selected_radio == "collection":
                table_name = "mediafiledetail"
            elif selected_radio == "master":
                table_name = "masterfiledetail"
            else:
                print("Invalid selected_radio value.")
                return []
            
            # Build the query conditionally
            query = f"""
            SELECT location, COUNT(*) AS record_count, SUM(file_size) AS total_file_size
            FROM {table_name}
            """
            
            # Dynamic WHERE clause
            where_conditions = []
            params = []

            if device != 'All':
                where_conditions.append("device = %s")
                params.append(device)
            
            if category != 'All':  # Assuming 'All' should also be ignored for category
                where_conditions.append("category = %s")
                params.append(category)

            if where_conditions:
                query += " WHERE " + " AND ".join(where_conditions)

            query += """
            GROUP BY location
            ORDER BY record_count DESC
            ;
            """

            # Print the query with parameters for debugging
            formatted_query = query % tuple(map(repr, params))
            
            #print("Final query to execute:", formatted_query)

            # Execute the query with parameters
            cursor.execute(query, tuple(params))
            print("get filtered data query:", formatted_query)  # For debugging

            # Fetch all results to ensure no unread results remain
            results = cursor.fetchall()
            if not results:
                print("No data found.")
                return []
            return [(row[0], row[1], row[2]) for row in results]
    
    except Error as e:
        print(f"Error while executing query: {e}")
        return []
    
    finally:
        if connection.is_connected():
            connection.close()

def get_filtered_data_old(device, category, selected_radio):
    print("inside get_filtered data: ",selected_radio)
   
   
   
    print("device :",device," collection: ",category)
    """Fetches filtered data based on the selected device and category."""
    connection = create_db_connection()
    if connection is None:
        print("Failed to connect to the database.")
        return []

    try:
        with connection.cursor() as cursor:
            if selected_radio == "collection":
                table_name = "mediafiledetail"
            elif selected_radio == "master":
                table_name = "masterfiledetail"
            else:
                print("Invalid selected_radio value.")
                return []
            


            query = f"""
        SELECT location, COUNT(*) AS record_count, SUM(file_size) AS total_file_size
        FROM {table_name}
        WHERE (device = %s)
        AND (category = %s)
        GROUP BY location
        ORDER BY record_count DESC LIMIT 7;
            """
            cursor.execute(query, (device, category))
            print("get filtered data query :",query)
            results = cursor.fetchall()
            return [(row[0], row[1], row[2]) for row in results]
    except Error as e:
        print(f"Error while executing query: {e}")
        return []
    finally:
        if connection.is_connected():
            connection.close()


def fetch_master_hashes_from_db():
    connection = create_db_connection()
    if connection is None:
        print("Failed to connect to the database.")
        return []

    try:
        with connection.cursor() as cursor:
            query = "SELECT distinct checksum from masterfiledetail where location = 'H:/ItunesFLAC2 Complete' "  
            cursor.execute(query)
            results = cursor.fetchall()
            hash_list = [row[0] for row in results]
            return hash_list
    except Error as e:
        print(f"Error while executing query: {e}")
        return []
    finally:
        if connection.is_connected():
            connection.close()


'''this looks at the mediafile collection table and the masterfile collection table and extracts the location from both leaving
 a unique list of locations that we have recorded'''
def get_unique_locations():
    """Fetches a list of unique location values from two tables."""
    connection = create_db_connection()
    if connection is None:
        print("Failed to connect to the database.")
        return []

    try:
        with connection.cursor() as cursor:
            query = """
            SELECT DISTINCT collection FROM mediafiledetail
            UNION
            SELECT DISTINCT collection FROM masterfiledetail;
            """
            cursor.execute(query)
            results = cursor.fetchall()
            # Extract the first element from each tuple in the results
            unique_locations = [row[0] for row in results]
            return unique_locations
    except Error as e:
        print(f"Error while executing query: {e}")
        return []
    finally:
        if connection.is_connected():
            connection.close()   

def getAPath():
    """Fetches a list of unique location values from two tables."""
    connection = create_db_connection()
    if connection is None:
        print("Failed to connect to the database.")
        return []

    try:
        with connection.cursor() as cursor:
            query = """
            SELECT file_path FROM masterfiledetail where category = 'video' limit 1
            """
            cursor.execute(query)
            results = cursor.fetchall()
            # Extract the first element from each tuple in the results
            unique_locations = [row[0] for row in results]
            return unique_locations
    except Error as e:
        print(f"Error while executing query: {e}")
        return []
    finally:
        if connection.is_connected():
            connection.close()  

def compareCollections(compareA, compareB, compareType):
    print("Running compareCollections Query")
    """Compare collections based on the specified type and return the results.
    compareA is first collection selected, compareB the second, each is associated with a 
    table in the database  comparison based on two collection names"""
   
   
    print(r"first collection is:", compareA)
    print(r"Second collection is:", compareB)
    print("type of comparison is:", compareType)

    myList = lookUpTables(compareA, compareB)       #see function detail for explanation of table assignments

    #if mylist[1] then table1 = masterfiledetail
    #if mylist[2] then table1 = mediafiledetail
    #if mylist[3] then table2 = masterfiledetail
    #if mylist[4] then table2 = mediafiledetal
    #if mylist[1] and [2] == 0 compareA does not exist so Error
    #if mylist[3] and [4] == 0 compareB does not exist so Error
    selection_error = False

     # Check if compareA exists in either table
    if myList[0] == 0 and myList[1] == 0:
        root = tk.Tk()
        root.withdraw()  # Hide the root window
        messagebox.showerror("Error", "The first comparison object no longer exists.")
        selection_error = True
        return []

    
    # Check if compareB exists in either table
    if myList[2] == 0 and myList[3] == 0:
        root = tk.Tk()
        root.withdraw()  # Hide the root window
        messagebox.showerror("Error", "The second comparison object no longer exists.")
        selection_error = True
        return []
    
    if not selection_error:

        print("table selections are OK")
    
         # Determine table1 based on the first two numbers in myList
        if myList[0] == 1:
            table1 = 'masterfiledetail'
            print("table1 is masterfiledate")
        elif myList[1] == 1:
            table1 = 'mediafiledetail'
            print("table1 is mediafiledate")
        else:
            print("Error: compareA does not exist in either table.")
            return []

        # Determine table2 based on the last two numbers in myList
        if myList[2] == 1:
            table2 = 'masterfiledetail'
            print("table2 is masterfiledata")
        elif myList[3] == 1:
            table2 = 'mediafiledetail'
            print("table2 is mediafiledata")
        else:
            print("Error: compareB does not exist in either table.")
            return []
    
    
   
    
        # Establish a connection to the database
        connection = create_db_connection()

        if connection is None:
            print("Failed to connect to the database.")
            return []

        try:


            print("Got connection, preparing to execute query.")
            cursor = connection.cursor()

            # Different queries depending on compareType

            #step 1 look for existence of the   compareA collection in Master else Media assign table name to table1
            # step 2 look for ex                compareB                                 assign table name to table2

            # Construct the query based on compareType
            if compareType == "Items in A but Not in B":
                print("running irems in A not in B")
                query = f"""
                    SELECT file_path FROM {table1}
                    WHERE collection = %s AND file_path NOT IN (
                        SELECT file_path FROM {table2} WHERE collection = %s
                    )
                """
                params = (compareA, compareB)
            elif compareType == "Items in B but Not in A":
                print("running irems in B not in A")
                query = f"""
                    SELECT file_path FROM {table2}
                    WHERE collection = %s AND file_path NOT IN (
                        SELECT file_path FROM {table1} WHERE collection = %s
                    )
                """
                params = (compareB, compareA)
           
            else:
                print("Invalid comparison type selected.")
                return []
            
            cursor.execute(query, params)
            print("Query executed successfully.")

            # Fetch all results from the executed query
            results = cursor.fetchall()
            return results

        except Error as e:
            print(f"Error while executing query: {e}")
            return []

        finally:
            if connection.is_connected():
                cursor.close()
                connection.close()

    else:
        print("Invalid comparison type selected ----.")
        return []



def lookUpTables(compareA, compareB):

    print("entering lookuptables query")

    ''' this function is a bit complicated to follow. The user is comparing 2 collection sets there names being
    assigned to compareA and compareB. I need to know which tables they appear in There are 4 tests
    is compareA in masterfiledetail    Yes= 1 No = 0
    is compareA in mediafiledetail     Yes= 1 No = 0
    is compareB in masterfiledetail    Yes= 1 No = 0
    is compareB in mediafiledetail     Yes= 1 No = 0
    
    
    the function returns a list of numbers from a which I can deuce which table the collections are in and whether there
    are some logical ommissions somehow with a collection not appearing in either list'''
    connection = create_db_connection()
    if connection is None:
        return []  # Return an empty list if the connection fails

    results = []

    try:
        cursor = connection.cursor()

        # Query for compareA in masterfiledetail
        query = "SELECT EXISTS(SELECT 1 FROM masterfiledetail WHERE collection = %s)"
        cursor.execute(query, (compareA,))
        resultA_master = cursor.fetchone()[0]
        results.append(resultA_master)

        # Query for compareA in mediafiledetail
        query = "SELECT EXISTS(SELECT 1 FROM mediafiledetail WHERE collection = %s)"
        cursor.execute(query, (compareA,))
        resultA_media = cursor.fetchone()[0]
        results.append(resultA_media)

        # Query for compareB in masterfiledetail
        query = "SELECT EXISTS(SELECT 1 FROM masterfiledetail WHERE collection = %s)"
        cursor.execute(query, (compareB,))
        resultB_master = cursor.fetchone()[0]
        results.append(resultB_master)

        # Query for compareB in mediafiledetail
        query = "SELECT EXISTS(SELECT 1 FROM mediafiledetail WHERE collection = %s)"
        cursor.execute(query, (compareB,))
        resultB_media = cursor.fetchone()[0]
        results.append(resultB_media)

    except Error as e:
        print(f"Error while executing queries: {e}")
        return []

    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()
    print("Lookup results:", results)
    return results


def get_latest_collection(device_name, start_path):
    """
    Retrieves the latest collection details from 'mediafiledetail' and 'masterfiledetail' tables.
    
    Args:
        device_name (str): Name of the device.
        start_path (str): Path being searched.
    
    Returns:
        list of tuples: Each tuple contains (table_name, coll_date) for existing collections.
    """
    connection = create_db_connection()
    if connection is None:
        return []  # Return empty list if connection fails

    collections = []
    try:
        cursor = connection.cursor()

        # Define the tables to check
        tables = ['mediafiledetail', 'masterfiledetail']

        for table in tables:
            query = f"""
                SELECT coll_date 
                FROM {table} 
                WHERE device = %s AND location = %s 
                ORDER BY coll_date DESC LIMIT 1
            """
            cursor.execute(query, (device_name, start_path))
            result = cursor.fetchone()

            if result:
                coll_date = result[0]
                collections.append((table, coll_date))

    except Error as e:
        print(f"Error retrieving collection details: {e}")
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

    return collections


  

'''the purpose of this query is to list all of the collections, both master and media as an aid when deciding which
collection or master to make next'''
def fetch_collection_summary():
    # Establish a database connection
    connection = create_db_connection()
    
    if connection is None:
        return []  # Return empty list if connection fails

    cursor = connection.cursor()

    # Execute the combined query
    cursor.execute("""
        SELECT 
            'mediafiledetail' AS table_name,
            device, 
            location, 
            category, 
            DATE(coll_date) AS collection_date,
            SUM(file_size) AS total_file_size
        FROM 
            mediafiledetail
        GROUP BY 
            device, location, category, DATE(coll_date)

        UNION ALL

        SELECT 
            'masterfiledetail' AS table_name,
            device, 
            location, 
            category, 
            DATE(coll_date) AS collection_date,
            SUM(file_size) AS total_file_size
        FROM 
            masterfiledetail
        GROUP BY 
            device, location, category, DATE(coll_date)

        ORDER BY 
            device, location, collection_date;
    """)
    combined_results = cursor.fetchall()

    # Close the cursor and connection
    cursor.close()
    connection.close()

    return combined_results

# Fetch and print the combined data
#data = fetch_combined_data()
#for row in data:
#    print(row)



def get_collection_data(location):
    """Fetches filtered data based on the selected device and category."""
    connection = create_db_connection()
    if connection is None:
        print("Failed to connect to the database.")
        return []

    try:
        print("Received: %s", location)
        with connection.cursor() as cursor:
            # Determine which table to query based on the location prefix
            if location.startswith(('Master', 'Clone', 'Secondary')):
                query = """
                SELECT file_name, file_type, file_size, file_creation_date, collection, category, device, coll_date
                FROM masterfiledetail
                WHERE collection = %s
                ORDER BY coll_date;
                """
            else:
                query = """
                SELECT file_name, file_type, file_size, file_creation_date, collection, category, device, coll_date
                FROM mediafiledetail
                WHERE collection = %s
                ORDER BY coll_date;
                """
            
            cursor.execute(query, (location,))
            results = cursor.fetchall()
            return [tuple(row) for row in results]
    except Error as e:
        print(f"Error while executing query: {e}")
        return []
    finally:
        if connection.is_connected():
            connection.close()

def get_collections_and_cats():
    """
    Fetches distinct collection and category records from both masterfiledetail and mediafiledetail tables.
    Orders the results by masterfiledetail records first, then by collection name and category.
    
    Returns:
    list: A list of tuples containing collection and category.
    """
    connection = create_db_connection()
    if connection is None:
        print("Failed to connect to the database.")
        return []

    try:
        with connection.cursor() as cursor:
            query = """
            SELECT collection, category, 
                   CASE WHEN table_name = 'masterfiledetail' THEN 'Master' ELSE 'Media' END AS source
            FROM (
                SELECT 
                    'masterfiledetail' AS table_name,
                    collection, 
                    category
                FROM masterfiledetail
                UNION
                SELECT 
                    'mediafiledetail' AS table_name,
                    collection, 
                    category
                FROM mediafiledetail
            ) AS combined
            ORDER BY 
                CASE WHEN table_name = 'masterfiledetail' THEN 0 ELSE 1 END,
                collection,
                category;
            """
            cursor.execute(query)
            results = cursor.fetchall()
            return results
    except Error as e:
        print(f"Error while executing query: {e}")
        return []
    finally:
        if connection.is_connected():
            connection.close()

# Example usage
#collections_and_categories = get_combined_collections_and_categories()
#for collection, category in collections_and_categories:
#    print(f"Collection: {collection}, Category: {category}")


def remove_records_by_collection(collection_name, collection_category, collection_type):
    """Removes records from the specified table based on collection name and category
    used in utilclass.py to remove unwanted collections from the databse record"""
    
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database for removing records.")
        return
    
    try:
        cursor = connection.cursor()
        
        # Determine the table to query based on the collection type
        if collection_type.lower() == 'master':
            table_name = 'masterfiledetail'
        elif collection_type.lower() == 'media':
            table_name = 'MediaFileDetail'
        else:
            print("Invalid collection type provided. Must be 'Master' or 'Media'.")
            return
        
        # Prepare the SQL query to delete records
        query = f"DELETE FROM {table_name} WHERE collection = %s AND category = %s"
        
        # Execute the query with the provided parameters
        cursor.execute(query, (collection_name, collection_category))
        
        # Commit the changes to the database
        connection.commit()
        print(f"Records removed from {table_name} where collection = {collection_name} and category = {collection_category}.")
    
    except Error as e:
        print(f"Error while removing records: {e}")
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()


def count_records_by_collection(collection_name, collection_category, collection_type):
    """Counts records in the specified table based on collection name and category
     used in utilclass.py before removing unwanted collections from the databse recor
     it warns the user in advance when a removal action is selected, how many records will be affected
     providing the user with a chance to rethink."""
    
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database for counting records.")
        return 0
    
    try:
        cursor = connection.cursor()
        
        # Determine the table to query based on the collection type
        if collection_type.lower() == 'master':
            table_name = 'masterfiledetail'
        elif collection_type.lower() == 'media':
            table_name = 'MediaFileDetail'
        else:
            print("Invalid collection type provided. Must be 'Master' or 'Media'.")
            return 0
        
        # Prepare the SQL query to count records
        query = f"SELECT COUNT(*) FROM {table_name} WHERE collection = %s AND category = %s"
        
        # Execute the query with the provided parameters
        cursor.execute(query, (collection_name, collection_category))
        
        # Fetch the count result
        count = cursor.fetchone()[0]
        return count
    
    except Error as e:
        print(f"Error while counting records: {e}")
        return 0
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

# Example usage:
# count = count_records_by_collection('collection_name', 'collection_category', 'Master')
# print(f"Number of records: {count}")


def get_location_by_collection(collection_name, collection_category, collection_type):
    """Selects the location from the specified table based on collection name and category.
    This function assumes that there is only one location associated with the given collection.
    """
    
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database for retrieving location.")
        return None
    
    try:
        cursor = connection.cursor()
        
        # Determine the table to query based on the collection type
        if collection_type.lower() == 'master':
            table_name = 'masterfiledetail'
        elif collection_type.lower() == 'media':
            table_name = 'MediaFileDetail'
        else:
            print("Invalid collection type provided. Must be 'Master' or 'Media'.")
            return None
        
        # Prepare the SQL query to select the location
        query = f"SELECT location FROM {table_name} WHERE collection = %s AND category = %s"
        
        # Execute the query with the provided parameters
        cursor.execute(query, (collection_name, collection_category))
        
        # Fetch the location result
        location = cursor.fetchone()

        # Ensure all results are fetched
        cursor.fetchall()  # This will clear any remaining results
        
        # Return the location if found, otherwise return None
        return location[0] if location else None
    
    except Error as e:
        print(f"Error while retrieving location: {e}")
        return None
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

def addNewExtension(type_, new_extension):
    """Inserts a new record into the mediatypes table and returns True if successful, False otherwise."""
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database for adding new extension.")
        return False
    
    try:
        cursor = connection.cursor()
        # Insert the new record into the mediatypes table
        query = "INSERT INTO mediatypes (Type, Ext) VALUES (%s, %s)"
        cursor.execute(query, (type_, new_extension))
        connection.commit()
        return True
    
    except Error as e:
        print(f"Error while inserting new extension: {e}")
        return False
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

def getExtList():
    """gets a list of file extensions"""
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database for adding new extension.")
        return False
    
    try:
        cursor = connection.cursor()
        # select ext
        query = "select ext from mediatypes order by ext"
        cursor.execute(query)

         # Fetch the location result
        extlist = cursor.fetchall()

        # Ensure all results are fetched
        #cursor.fetchall()  # This will clear any remaining results

        return [ext[0] for ext in extlist]  # Extract the first element from each tuple so that I return a list of Strings
        
     
    
    except Error as e:
        print(f"Error while inserting new extension: {e}")
        return False
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()


def add_media_type(item):
    """Adds a new media type to the mediatypename table."""
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database for adding new media type.")
        return False
    
    try:
        cursor = connection.cursor()
        # Insert the new media type
        query = "INSERT INTO mediatypename (media_type) VALUES (%s)"
        cursor.execute(query, (item,))
        connection.commit()
        return True
    
    except Error as e:
        print(f"Error while adding new media type: {e}")
        return False
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

def add_excluded_folder(folder_name):
    """Adds a new folder name to the excluded_folders table."""
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database for adding new folder.")
        return False
    
    try:
        cursor = connection.cursor()
        # Insert the new folder name
        query = "INSERT INTO excluded_folders (folder_name) VALUES (%s)"
        cursor.execute(query, (folder_name,))
        connection.commit()
        return True
    
    except Error as e:
        print(f"Error while adding new folder: {e}")
        return False
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

def add_master_type(type_):
    """Adds a new type to the mastertype table."""
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database for adding new master type.")
        return False
    
    try:
        cursor = connection.cursor()
        # Insert the new type into the mastertype table
        query = "INSERT INTO mastertype (type_) VALUES (%s)"
        cursor.execute(query, (type_,))
        connection.commit()
        return True
    
    except Error as e:
        print(f"Error while adding new master type: {e}")
        return False
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

def add_excluded_folder(item):
    print("adding new folder")
    """Adds a new type to the mastertype table."""
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database for adding new master type.")
        return False
    
    try:
        cursor = connection.cursor()
        # Insert the new type into the mastertype table
        query = "INSERT INTO excluded_folders (folder_name) VALUES (%s)"
        cursor.execute(query, (item,))
        connection.commit()
        return True
    
    except Error as e:
        print(f"Error while adding new folder : {e}")
        return False
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

def add_master_type(item):
    print("adding new master type")
    """Adds a new type to the mastertype table."""
    # Establish a connection to the database
    connection = create_db_connection()

    if connection is None:
        print("Failed to connect to the database for adding new master type.")
        return False

    try:
        cursor = connection.cursor()
        # Insert the new type into the mastertype table
        query = "INSERT INTO mastertype (type_) VALUES (%s)"
        cursor.execute(query, (item,))
        connection.commit()
        return True
    except Error as e:
        print(f"Error while adding new master type : {e}")
        return False
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()


def add_new_extension(type_, ext):
    print("Adding new record to extension list table ",type_,"...",ext)
    """Adds a new record to the mediatypes table with a unique ext value ext and type."""
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database for adding new media type with extension.")
        return False
    
    try:
        cursor = connection.cursor()
        # Insert the new record into the mediatypes table
        query = "INSERT INTO mediatypes (Type, Ext) VALUES (%s, %s)"
        cursor.execute(query, (type_, ext))
        connection.commit()
        return True
    
    except Error as e:
        # Check if the error is due to a duplicate entry for the unique ext value
        if e.errno == mysql.connector.errorcode.ER_DUP_ENTRY:
            print(f"Error: The extension '{ext}' already exists.")
        else:
            print(f"Error while adding new media type with extension: {e}")
        return False
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

def delete_extension_and_type(item):
    print("entering delete ext and type query func")
    """Deletes a record from the extension  table with the matching value."""
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database for deleting master type.")
        return False
    
    try:
        cursor = connection.cursor()
        # Delete the record with the matching value
        query = "DELETE FROM mediatypes WHERE Ext = %s"
        cursor.execute(query, (item,))
        connection.commit()
        
        # Check if any row was deleted
        if cursor.rowcount > 0:
            return True
        else:
            print("No matching record found to delete.")
            return False
    
    except Error as e:
        print(f"Error while deleting master type: {e}")
        return False
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()







def delete_master_type(item):
    """Deletes a record from the master type table with the matching value."""
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database for deleting master type.")
        return False
    
    try:
        cursor = connection.cursor()
        # Delete the record with the matching value
        query = "DELETE FROM mastertype WHERE type_ = %s"
        cursor.execute(query, (item,))
        connection.commit()
        
        # Check if any row was deleted
        if cursor.rowcount > 0:
            return True
        else:
            print("No matching record found to delete.")
            return False
    
    except Error as e:
        print(f"Error while deleting master type: {e}")
        return False
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()


def delete_media_type(item):
    """Deletes a record from the mediatypename table with the matching value."""
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database for deleting media type.")
        return False
    
    try:
        cursor = connection.cursor()
        # Delete the record with the matching value
        query = "DELETE FROM mediatypename WHERE media_type = %s"
        cursor.execute(query, (item,))
        connection.commit()
        
        # Check if any row was deleted
        if cursor.rowcount > 0:
            return True
        else:
            print("No matching record found to delete.")
            return False
    
    except Error as e:
        print(f"Error while deleting media type: {e}")
        return False
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

def delete_excluded_folder(item):
    """Deletes a record from the mediatypename table with the matching value."""
    # Establish a connection to the database
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database for deleting folder .")
        return False
    
    try:
        cursor = connection.cursor()
        # Delete the record with the matching value
        query = "DELETE FROM excluded_folders WHERE folder_name = %s"
        cursor.execute(query, (item,))
        connection.commit()
        
        # Check if any row was deleted
        if cursor.rowcount > 0:
            return True
        else:
            print("No matching record found to delete.")
            return False
    
    except Error as e:
        print(f"Error while deleting folder: {e}")
        return False
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()


def searchText(search_query):
    """Searches for the search_query in the file_path field of both masterfiledetail and mediafiledetail tables."""
    connection = create_db_connection()
    if connection is None:
        print("Failed to connect to the database for searching.")
        return []

    try:
        cursor = connection.cursor()

        # Define the query for both tables
        query = """
        SELECT 'masterfiledetail' AS source_table, masterfiledetail.*, NULL AS duplicated
        FROM masterfiledetail
        WHERE file_path LIKE %s
        UNION ALL
        SELECT 'mediafiledetail' AS source_table, mediafiledetail.*
        FROM mediafiledetail
        WHERE file_path LIKE %s
        ORDER BY source_table, location
        """

        # Execute the query with the search pattern
        search_pattern = f"%{search_query}%"
        cursor.execute(query, (search_pattern, search_pattern))

        # Fetch all results
        results = cursor.fetchall()
        return results

    except Error as e:
        print(f"Error while searching: {e}")
        return []

    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

def transfer_records_to_master(collection_name, category, master_type_name):
    """Transfers records from mediafiledetail to masterfiledetail with modifications.
    uses commit and rollback to ensure that if any phase fails the databse retains the original records"""
    
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database for transferring records.")
        return False
    
    try:
        cursor = connection.cursor()
        
        # Step 1: Select records from mediafiledetail
        select_query = """
            SELECT * FROM mediafiledetail 
            WHERE collection = %s AND category = %s
        """
        cursor.execute(select_query, (collection_name, category))
        records = cursor.fetchall()
        
        # Step 2: Modify collection_name and prepare records for insertion
        modified_records = []
        for record in records:
            # Assuming the collection_name is the seventh field (index 6)
            modified_collection_name = f"{master_type_name}:{record[6]}"
            # Exclude the last field from the record
            modified_record = record[1:6] + (modified_collection_name,) + record[7:-1]
            modified_records.append(modified_record)

        print("Modified Records:")
        for mod_record in modified_records:
            print(mod_record)    
        
        # Step 3: Insert modified records into masterfiledetail
        # Replace 'field2, field3, ...' with actual field names from masterfiledetail
        insert_query = """
            INSERT INTO masterfiledetail (file_path, file_name,file_type, file_size, file_creation_date, collection, category, device, location, coll_date, checksum ) 
            VALUES (%s, %s, %s,  %s, %s, %s, %s, %s, %s, %s, %s)
        """
        cursor.executemany(insert_query, modified_records)
      
        
        # Step 4: Verify the count of inserted records
        if cursor.rowcount != len(records):
            print("Mismatch in the number of records transferred.")
            return False
        
        # Step 5: Delete records from mediafiledetail
        delete_query = """
            DELETE FROM mediafiledetail 
            WHERE collection = %s AND category = %s
        """
        cursor.execute(delete_query, (collection_name, category))

        # Commit the transaction if both operations are successful
        connection.commit()
        

        # Log a success message to the footer
        logging.info(f"Successfully transferred {cursor.rowcount} records from mediafiledetail to masterfiledetail.")
        return True
    
    except Error as e:
        print(f"Error while transferring records: {e}")
        return False
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

def getLibraryList():
    
    connection = create_db_connection()
    
    if connection is None:
        print("Failed to connect to the database for transferring records.")
        return False
    
    try:
        cursor = connection.cursor()
        
        # Step 1: Select records from medialibrarylist
        select_query = """
            SELECT LibraryName, Pathname FROM medialibrarylist 
            order by LibraryName asc
        """
        cursor.execute(select_query, ())

        records = cursor.fetchall()

        return [{"name": row[0], "path": row[1]} for row in records]


    except Error as e:
        print(f"Error while retrirving library records: {e}")
        return False
    
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()