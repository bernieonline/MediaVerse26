
# This is the file/class created to access and display the main database creation GUI
# for clarity we have a page on its own to hold all of the interface feature
# initially just the 2 display commands
# recoded for checkboxes 12:28 27th Feb
# Create Masterdatabase is the file created by pyuic5, Ui_Cr.. is a class in that file

#This subclasses the createmasterdatabase ui

from functools import partial
import MiscFunctions
from PyQt5 import QtWidgets as qtw
from PyQt5.QtWidgets import QCheckBox, QMessageBox
import SQLiteFunction as sqf
from CreateMasterdatabase import Ui_CreateMasterdatabase    # from pyuic -o
from createDBTest import makeNewDatabase as mdb

# this class to manage the gui references its QWidget origin
# its main purpose is to display the window and provide the user with a chance to select drives, folders and
# types as well as min file
# size for the creation of the main data table

# we inherit qwidget because this is not a main window
class getDbWindow(qtw.QWidget):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)  # class super subclasses QtWidgets on which the form was based

        # we can then use its show feature to display it
        self.ui = Ui_CreateMasterdatabase()
        self.ui.setupUi(self)

        # included drives stored in this list.  use win32api to get a list of all mapped drives
        self.drive_list = MiscFunctions.drive_list()
        # did this because drive_list gets changed later so I use drive_letters for exception list
        self.drive_letters = MiscFunctions.drive_list()
        print("function drive list holds ", self.drive_list)
        print("function drive letters holds ", self.drive_letters)

        # set list variable to hold grab of path exemptions
        self.listTYpes = []

        # placeholder for size limit taken from combobox
        self.FileLimit = 0

        # set list variable to grab type extensions excluded
        self.TypeExt = []

        # New Table preferred
        self.newTable = "True"

        # need to establish local object references to be used with the UI

        self.box = None

        # calls a method to manage display of checkboxes for adding drive list selection
        self.add_checkboxes(self.drive_list)

        # button signals create new master library without deleting old on
        self.NewTbleBtn = self.ui.NewTableButton
        self.NewTbleBtn.clicked.connect(self.build_New_Table)

        # Display standard movie formats that the program will search drives for
        self.NewMovieTypeButton = self.ui.movieTypeButton
        self.NewMovieTypeButton.clicked.connect(self.viewMovieFileTypes)

    # calls function when button
    # 
    # 
    # 
    # 
    #  clicked to CREATE NEW MASTER LIBRARY
    def build_New_Table(self):
        # get the chosen file limit size from the UI
        self.FileLimit = self.add_size_limit()
        # print("got file limit ", self.FileLimit)

        print("building new table.......1")
        # when using components on the gui to set or get stuff we first create a new reference to it
        # this is the console panel for message display
        self.newConsole = self.ui.consoleA   # console panel

        # this runs a method that gets the data from list of exempt folder names and puts it in a list
        # we then iterate through the list appending text to the console
        self.folders = self.add_folder_exemptions()
        for item in self.folders:
            if item != "":
                self.newConsole.append(item)     # display on console
        # also pass folders into table build query

        # this runs a method that selects the list of exempt file types and appends to console
        self.fTypes = self.add_extension_exeptions()
        for item in self.fTypes:
            self.newConsole.append(item)

        # gets selected minimum file size from combobox via method
        # used when searching drives for files above selected size
        self.minimumSize = self.add_size_limit()
        self.size = str(self.minimumSize)
        self.size = "Minimum File size is: "+self.size
        self.newConsole.append(self.size)     # display on console

        # now create a lists of data items to pass into the next action
        # that creates the database based on the selected criteria
        # exceptionList = [self.drive_list, minimumSize, folders, fTypes]

        # this is a mixed list including other lists
        # I need to break it apart and display contents to console
        # print("building new table.......2")

        p1 = mdb(self.drive_letters, self.folders, self.fTypes, self.FileLimit, self.newTable)
        p1.createMasterRecords(self.drive_letters, self.folders, self.fTypes, self.FileLimit, self.newTable)
        # newDB = cdb.makeNewDatabase()
        # print("in database class")
        # newDB.createMasterRecords(self.drive_list, self.listExt, self.TypeExt, self.FileLimit, self.newTable)
        # run function that creates new table passing in necessary parameters

        # p1 = makeNewTable(self.drive_list, folders, fTypes, self.FileLimit, self.newTable)

    # this function add a list of checkboxes representing drives
    # the user selects the drives to be excluded from the analysis
    # ideally a for loop should do this but couldnt achieve it
    def add_checkboxes(self, drive_list):
        # print("my dr list ", drive_list)
        # This block adds the list of drive checkboxes, add checkboxes to the layout
        layout = self.ui.verticalLayout_2

        # we check how many drives we are going to search, there is a limit of 12
        # we will send a message if more drives are found
        namelist = drive_list
        numDrives = len(namelist)
        if numDrives > 12:      # we run out of display space
            self.showdrivelimitwarning()

        # alt method of adding checkboxes to a layout from a loop
        for i, v in enumerate(namelist):
            # print(namelist[i], i)
            namelist[i] = QCheckBox(v)
            # print("here I am")
            layout.addWidget(namelist[i])
            namelist[i].stateChanged.connect(partial(self.build_drivelist, namelist[i].text()))

    @staticmethod
    def showdrivelimitwarning():
        msg = QMessageBox()
        msg.setIcon(QMessageBox.Information)
        msg.setText("Drive Warning")
        msg.setInformativeText("Drive limit of 12 exceeded")
        msg.setWindowTitle("Warning")
        msg.setDetailedText("you will need to disconnect one or more drives:")
        msg.setStandardButtons(QMessageBox.Ok)
        # this displays the message
        x = msg.exec_()

    # this gets file size chosen on combo and returns it when asked
    def add_size_limit(self):
        # file size limit
        self.FileLimit = self.ui.SizeLimitCombo.currentText()
        print("getting size limit", self.FileLimit)
        return self.FileLimit

    # gets text of folder and paths from textedit box
    # puts the data into a list which is returned when asked
    def add_folder_exemptions(self):
        myText = self.ui.textEdit_3
        myString = myText.toPlainText()
        print(myString)
        myString2 = myString.replace('\n', ',')
        print(myString2)
        listPath = []
        listPath = myString2.split(',')
        print(listPath)
        return listPath
        # i can now iterate through the list to check if any element is contained within the pathname

    # when a checkbox is clicked this method amends the list of drives by removing
    # the checked drive letters from the list leaving drives to be read from
    def build_drivelist(self, n, state):
        if state == 2:
            self.drive_letters.remove(n)
        else:
            self.drive_letters.append(n)


    # gets text from textarea for file types to be excluded
    # also displays it in the console box and returns the list when asked
    def add_extension_exeptions(self):
        myString = self.ui.textEdit_4
        myExString = myString.toPlainText()
        myExString2 = myExString.replace('\n', ',')
        listTYpes = myExString2.split(',')
        return listTYpes

    # we have a button to display standard movie file types that shows them in the console area
    def viewMovieFileTypes(self):
        types = sqf.listMovieTypes()
        myConsole = self.ui.consoleA
        for item2 in types:
            myConsole.append(item2)

    # this copies the movielibrary table without records as a basis for a new master table based on selections
    # its new name begins with current date and time
    @staticmethod
    def createNewLibrary():
        newTableName = sqf.copyMainLibrary()


