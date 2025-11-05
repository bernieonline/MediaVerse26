import datetime
import os
from PyQt5.QtWidgets import QMessageBox
import SQLiteFunction
import MiscFunctions
import MovieClassesDef


class makeNewDatabase:

# despite the filetame....Test this is the program for creating new tables of files based on the master library

    def __init__(self, exdrivers, exfolders, exfiletypes, minSize, rebuild):
        # print(" entering mmdb.makeNewDatabase")
        self.drivers = exdrivers  # drive list with exclusions removed
        self.folders = exfolders  # excluded folder list
        self.filetypes = exfiletypes  # excluded list of filetypes
        self.fsize = minSize  # Megabytes
        self.rebuild = rebuild  # user choice, yes to drop existing master table or name of new table to write to

        self.reject = False  # Flag to indicate a potential record is in the excluded list

        # print(" completed initialization entering mmdb.makeNewDatabase")

        # if self.rebuild == 'Yes':   # instructed to drop the master library - so double check
        #    self.showDBWarningDialog()

    # user chose to drop the current MasterLibrary, this double checks
    def showDBWarningDialog(self):
        msgBox = QMessageBox()
        msgBox.setIcon(QMessageBox.Critical)
        msgBox.setText("Delete The Table???")
        msgBox.setWindowTitle("Are You Sure?")
        msgBox.setStandardButtons(QMessageBox.Ok | QMessageBox.Cancel)
        msgBox.buttonClicked.connect(self.warningDBButtonClick)
        # returnValue = msgBox.exec()
        # if returnValue == QMessageBox.Ok:
        #    # print('OK clicked')

    # user choice actions from drop table warning
    def warningDBButtonClick(self, i):
        # print("Button clicked is:", i.text())
        # i.text = OK or Cancel
        if i.text == "OK":
            pass
            # print('OK clicked')
            # self.dropTable() # we use the masterlist table name
        else:
            # print('Cancel Clicked')
            # bypass drop table
            rebuild = 'No'
            self.getNewTableName()  # we create a new table with the new name that records must be written to

    # main function for program     # delete all records from library ready to rebuild
    @staticmethod
    def dropTable():
        SQLiteFunction.delete_all_from_movielibrarylarge()

    def createMasterRecords(self, drivers, folders, filetypes, fsize, rebuild):
        # logging.basicConfig(filename='createMasterRecordLog.txt', level=# print)
        # datetime object
        dv = datetime.datetime.now()

        countingRecordsCreated = 0

        file_type_list = SQLiteFunction.listMovieTypes()
        print(file_type_list)

        print("Datetime commenced =", dv)

        # print("creating master records 1")
        # print("creating master records 1 rebuild ", rebuild)
        # rebuild is True or false
        # if No we need to create a new table
        if rebuild == 'True':  # pass table name into insert record function
            newTableName = SQLiteFunction.copyMainLibrary()  # creates table and returns table name
            # # print("new table name is ", newTableName)
        else:
            newTableName = "MovieLibraryLarge"
        # Loop through each drive in turn and retrieve file names

        # remember \ is an escape character so to use it I need to use \\
        for x in self.drivers:  # modified list after exclusions
            # add an extra '\' to it
            x = x + "\\"
            print('modified drive letter', x)

            if 'D' in x:  # can be removed as we will have included in exceptions
                pass

            else:
                #   y = os.getcwd()     # @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                # # print('entries from directory cos we have not changed it', y)
                # this returns list of entries in the specified directory that we changed to
                # # print("# printing contents of this directory", x)
                # # print(os.listdir(x))

                count = 0

                # # print("I'm in Directory: ", x)
                # this is where I pick up the first element in the list of drives
                os.chdir(x)  # change to each required drive in turn from the list

                # os.walk traverses a whole drive based on current working directory that I changed to
                for root, dirs, files in os.walk(".", topdown=False):
                    # for each filename split out the file extension using os.path
                    for name in files:
                        self.reject = "False"
                        # print("Join root and name: ", os.path.join(root, name))

                        # unpacking the tuple
                        file_name, file_extension = os.path.splitext(name)

                        # print("Filename: ", file_name)
                        # print("Extension: ", file_extension.lower())
                        # # print("more file type list", (file_type_list))
                        # need to make sure when I'm comparing the file extension with the master list of extensions
                        # that I convert both to lower case
                        # in the query that creates the master list I force it to convert to lower case
                        # if our file extension exists in the master list

                        # create a string for pathname, filename and extension

                        thisFile = root + "\\" + file_name + file_extension

                        # i need to check if filesize is smaller than exceptions
                        # get file size
                        file_size = MiscFunctions.get_file_size_in_bytes(thisFile)
                        # # print("returned ",file_size)
                        # convert to megabytes
                        sizeint = int(self.fsize)

                        if sizeint > (file_size / (1024 * 1024)):
                            # # print("size too small", str((file_size/(1024*1024))))
                            # file_size = int(file_size/(1024*1024))
                            # print("new size is Mb: ", str(file_size))
                            # print("size  is: ",str(file_size), "target ", str(sizeint))
                            self.reject = "True"
                        else:
                            # # print("file size is OK")
                            file_size = (file_size / (1024 * 1024))

                        # print(" onto the dates: ",self.reject)

                        if self.reject == 'False':

                            # check if its a movie and not in exception list
                            # print('deal with extension')
                            if file_extension.lower() in file_type_list:  # its a movie
                                # print("its a movie")
                                if file_extension in filetypes:  # but its in the exception list
                                    self.reject = "True"
                                else:
                                    pass
                                    # print("its not in exception list file type")
                            else:
                                print("its not a movie")
                                self.reject = "True"

                            if self.reject == "False":
                                # date modified - using os.path with file name created above to get date info
                                # print("Date Modified", datetime.datetime.fromtimestamp(os.path.getmtime(thisFile)))
                                date_modified = datetime.datetime.fromtimestamp(os.path.getmtime(thisFile))

                                # Date Created as above
                                # print("Date Created: ", datetime.datetime.fromtimestamp(os.path.getctime(thisFile)))
                                date_created = datetime.datetime.fromtimestamp(os.path.getctime(thisFile))

                                # this tests whether the pathname contains a reference to iocage which is a jail
                                # The jail mounts a file system and makes it appear that files are duplicated
                                # so we need to ignore these filename references

                                # loop through list of excluded foldersto see if this path is valid for inclusion

                                # assign pathname to a string called fullstring
                                # check if each excluded folder exists in the full pathname
                                # if it does set reject flag
                                fullstring = root
                                # print("path is ", fullstring)

                                # set a substring element to what folder we want to exclude such as iocage

                                for folder in self.folders:
                                    # print("folder is ",folder)
                                    if folder in fullstring:
                                        # print("folder is in path ")
                                        # print(folder, " in ",self.folders)
                                        # print("path not valid")
                                        self.reject = "True"
                                    else:
                                        pass
                                        # print("folder is not in path")
                            else:
                                pass
                                # print("This item is rejected")

                        # this is a valid entry into the database
                        # print("reject status is :", self.reject)
                        if self.reject == "False":  # insert a record in the table
                            # only do this if itt isnt an iocage location
                            # x[:-1] strips \ from end of drive letter string root[2:]
                            # root[2:] strips first two chars from the string .\
                            # +\\ adds a single \ to the end of root

                            # instantiate the object
                            # print("creating the record xx")
                            # print((x[:-1], root[2:]+'\\', file_name, file_extension,
                            # file_size, date_created, date_modified))
                            p2 = MovieClassesDef.MyMovies \
                                (x[:-1], root[2:] + '\\', file_name, file_extension,
                                 file_size, date_created, date_modified)

                            # use its method to create the record
                            # returns the id number of the record created
                            recNo = p2.insert_to_large_library(newTableName)

                            countingRecordsCreated = countingRecordsCreated + 1
                            if countingRecordsCreated % 10 == 0:
                                print("Records Created: ", str(countingRecordsCreated))

                                # ###########################################################################
                                # I need something here to conf what the error was and # print it to a logfile
                                # ##################C:\Users########################################################
                                # print("ERROR:")
                        else:
                            # print("continuing=====================================================================")
                            continue

        print("_____________________completed______________________")
        # datetime object
        dt = datetime.datetime.now()

        print("Datetime Completed =", dt)

        print("elapsed time is ", (dt - dv) / 60, " minutes")

    # output completion time and time taken
