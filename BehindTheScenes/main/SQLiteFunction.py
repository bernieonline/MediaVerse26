import sqlite3
from sqlite3 import Error
from PyQt5.QtCore import QDateTime
from PyQt5.QtWidgets import QMessageBox
import MiscFunctions as msf


# used repeatedly to open a connection to the database passed in
def create_connection(db_file):
    """ create a database connection to a SQLite database """
    try:
        conn = sqlite3.connect(db_file)
        return conn
    except Error as e:
        print(e)


# This function gets a list of file types set up manually in the database
def create_type_list():
    # get a connection to the database
    conn = create_connection(r"B:\OneDrive\dropboxEx\Gaming\My OneDrive Documents\Python\Data\PythonMovieDatabase.db")
    # force query results to lower case
    query = "SELECT LOWER(Type) FROM VideoFormats"
    cur = conn.cursor()
    rows = cur.execute(query)
    # for item in rows:
    #   print(*item, sep="\n")
    # close this connection when you have finished with it

    # create a list called type_list
    type_list = []
    for row in rows:
        # get each item from the result list in turn
        a = row[0]
        # convert to lower case
        b = a.lower()
        # append it to the List
        type_list.append(b)

    return type_list


# delete all records from the movie library in advance of rebuilding it
def delete_all_from_movielibrarylarge():
    conn = create_connection(r"B:\OneDrive\dropboxEx\Gaming\My OneDrive Documents\Python\Data\PythonMovieDatabase.db")
    query = "delete from MovieLibraryLarge"
    cur = conn.cursor()
    cur.execute(query)
    conn.commit()
    ##########################################################
    # it would be useful to get confirmation that it was done or not
    ##########################################################
    conn.close()


# displays movietype in console
def listMovieTypes():
    conn = create_connection(r"B:\OneDrive\dropboxEx\Gaming\My OneDrive Documents\Python\Data\PythonMovieDatabase.db")
    query = "select Type, Name from VideoFormats order by Type"
    cur = conn.cursor()
    cur.execute(query)
    conn.commit()
    print("here 3")
    type_list = []
    for row in cur:
        # get each item from the result list in turn
        a = row[0]
        # convert to lower case
        b = a.lower()
        # append it to the List
        type_list.append(b)
    print("here 4")
    conn.close()
    print("here 5b")
    return type_list


def copyMainLibrary():
    now = QDateTime.currentDateTime()
    nameA = now.toString()
    nameB = "-MovieLibraryLarge"
    newName = nameA+nameB
    conn = create_connection(r"B:\OneDrive\dropboxEx\Gaming\My OneDrive Documents\Python\Data\PythonMovieDatabase.db")
    query = "CREATE TABLE [" + newName + "] AS SELECT * from movielibrarylarge where id<0"
    print(query)
    cur = conn.cursor()
    cur.execute(query)
    conn.commit()
    conn.close()
    return newName


# used by copy feature to select parent W: file
def getMasterListSearch(x):
    conn = create_connection(r"B:\OneDrive\dropboxEx\Gaming\My OneDrive Documents\Python\Data\PythonMovieDatabase.db")
    cur = conn.cursor()
    cur.execute("select ID,Drive,Path,FileName, FileType from MovieLibraryLarge where drive = 'W:\\' and FileName"
                " like ? ", ('%'+x+'%',))
    records = cur.fetchone()

    if records:
        conn.commit()
        conn.close()
        return records  # list object
    else:
        print("aint no records found on W:")
        msf.warningMessagePopUp("No Match", "Try Again")
        records = getMasterList()
        conn.close()
        return records


# get file detail from library where drive is W and not been checked
def getMasterList():
    conn = create_connection(r"B:\OneDrive\dropboxEx\Gaming\My OneDrive Documents\Python\Data\PythonMovieDatabase.db")
    cur = conn.cursor()
    cur.execute("select ID,Drive,Path,FileName, FileType from MovieLibraryLarge where drive = 'W:\\'"
                " and  nameConf is null order by Random()")
    records = cur.fetchone()
    if records:
        conn.commit()
        conn.close()
        return records  # list object
    else:
        conn.close()
        infoCheck("no W data returned from library", "")
        return None


def getSearchMovie(Name):
    conn = create_connection(r"B:\OneDrive\dropboxEx\Gaming\My OneDrive Documents\Python\Data\PythonMovieDatabase.db")
    cur = conn.cursor()

    # gets all file details from the library of every record other that the selected record
    cur.execute("select ID,Drive,Path,FileName, FileType from MovieLibraryLarge where  FileName like '%?%'", (Name,))

    records = cur.fetchall()
    if records:
        conn.commit()
        conn.close()
        return records  # list object
    else:
        infoCheck("no similar names returned from library", "")


def getOtherNames(ID, Name):

    conn = create_connection(r"B:\OneDrive\dropboxEx\Gaming\My OneDrive Documents\Python\Data\PythonMovieDatabase.db")
    cur = conn.cursor()
    # gets all file details from the library of every record other than the selected record
    cur.execute("select ID,Drive,Path,FileName, FileType from MovieLibraryLarge"
                " where nameConf is null and ID != ?", (ID,))

    records = cur.fetchall()
    if records:
        conn.commit()
        conn.close()
        return records  # list object
    else:
        infoCheck("no similar names returned from library", "")


def getLibCheck(ID):
    '''
    get check to update gui showing successful update
    :param ID:
    :return:
    '''
    global x
    conn = create_connection(
        r"B:\OneDrive\dropboxEx\Gaming\My OneDrive Documents\Python\Data\PythonMovieDatabase.db")

    cur = conn.cursor()

    try:
        cur.execute("select nameConf from MovieLibraryLarge where ID = ?", (ID,))
        record = cur.fetchone()
        if record is not None:
            x = "-ok"
        else:
            x = '-not ok'
        conn.commit()
    except Error as e:
        print(e)
    finally:
        print("closing")
        conn.close()

    return x


def updateLibrary(ID):
    conn = create_connection(
        r"B:\OneDrive\dropboxEx\Gaming\My OneDrive Documents\Python\Data\PythonMovieDatabase.db")
    cur = conn.cursor()
    try:
        cur.execute("update MovieLibraryLarge set nameConf = 'True' where ID = ?", (ID,))
    except Error as e:
        print(e)
    conn.commit()
    conn.close()


def updateLibraryFile(currentChildID,currentChildFile):
    ID = currentChildID
    name = currentChildFile
    conn = create_connection(
        r"B:\OneDrive\dropboxEx\Gaming\My OneDrive Documents\Python\Data\PythonMovieDatabase.db")
    cur = conn.cursor()
    try:
        cur.execute("update MovieLibraryLarge set fileName = ? where ID = ?  ", (name, ID))
    except Error as e:
        print(e)

    conn.commit()
    conn.close()


def getFileGroup(filename):
    conn = create_connection(
        r"B:\OneDrive\dropboxEx\Gaming\My OneDrive Documents\Python\Data\PythonMovieDatabase.db")
    cur = conn.cursor()
    try:
        cur.execute("select * from errorLog limit 5")
        records = cur.fetchall()
    except Error as e:
        print(e)

    conn.commit()
    conn.close()
    return records

def infoCheck(self, missing):
    msg = QMessageBox()
    msg.setIcon(QMessageBox.Information)
    msg.setText("Missing Information")
    msg.setInformativeText(missing)
    msg.setWindowTitle("Warning")
    msg.setStandardButtons(QMessageBox.Ok)
    # this displays the message
    x = msg.exec_()


# this is not much use as it just dumps tha table data
def getErrorLog():
    conn = create_connection(
        r"B:\OneDrive\dropboxEx\Gaming\My OneDrive Documents\Python\Data\PythonMovieDatabase.db")
    cur = conn.cursor()
    try:
        cur.execute("select * from errorLog")
        records = cur.fetchall()
        result = 'success'
    except Error as e:
        print("error exception is ", e)
    conn.commit()
    conn.close()
    return records


def insertErrorLog(file, y, checkval, dtnow, file_size):
        result = 'Fail'
        conn = create_connection(
            r"B:\OneDrive\dropboxEx\Gaming\My OneDrive Documents\Python\Data\PythonMovieDatabase.db")
        cur = conn.cursor()
        try:
            cur.execute("INSERT INTO errorLog(filename,errorLog, checksum, timestamp, file_size)"
                        " VALUES (?,?,?,?,?)", (file, y, checkval, dtnow, file_size))
            result = 'success'
        except Error as e:
            print("error is ", e)
        conn.commit()
        conn.close()
        return result


def updateManTest(file, comment):
    '''
    used to update errorLog table with manual result of visual test, passes in the file name and location
    as well as the rating
    :param file:
    :param comment:
    :return:
    '''
    result = 'Fail'
    conn = create_connection(
        r"B:\OneDrive\dropboxEx\Gaming\My OneDrive Documents\Python\Data\PythonMovieDatabase.db")
    cur = conn.cursor()
    try:
        cur.execute("update errorLog set manual_check = ? where filename = ?", (comment, file,))
        result = 'success'
    except Error as e:
        print("error is ", e)
    except sqlite3.Error:
        print(sqlite3.error)

    conn.commit()
    conn.close()
    return result
