# the purpose of this program is to work its way through the library looking for Movies
# with similar names. the ui provides access to the library records and provides a facility
# to choose a record with the desired name as the 'parent' and select other records from the list
# that are to be given the same filename as the parent
# the similar selected files will be renamed on the drive a flag will be set in the library file to show its been done
# and edited with the chosen name.
# We will initially use the W: drive as a source for the desired file names because the names are designed to
# accurately connect to jriver and imdb
# The whole purpose of this is to use the W: drive (jriver) as a source and to manage and synchronize all
# further copies of the movie file, particularly spelling but also file types and locations
# pyuic5 -o RenameSystem.py RenameSystem.ui
# step 1 Get a list of all filenames from W:

import os
import os.path
from RenameSystem import Ui_MovieFileRename
import SQLiteFunction as sql
import Levenshtein as lev  # used for string comparison
from PyQt5 import QtWidgets as qtw
from PyQt5.QtWidgets import QMessageBox
import MiscFunctions as msf


class getChangeWindow(qtw.QWidget):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)  # class super subclasses QtWidgets on which the form was based

        # we can then use its show feature to display it
        self.ui = Ui_MovieFileRename()
        self.ui.setupUi(self)

        self.masterName = self.ui.masterFileNameTxt
        self.nameOverride = False

        # used to set the comparison percent using Levenshtein
        self.levslider = self.ui.horizontalSlider
        self.levslider.setMinimum(0)
        self.levslider.setMaximum(100)
        self.levslider.setValue(70)
        self.levedit = self.ui.levRatioEdit
        self.levedit.setText("70")
        self.copyError = False

        self.ID = None
        self.drive = None
        self.Path = None
        self.File = None
        self.Type = None
        self.master_record = []
        self.result = []
        self.otherNames = []
        self.similar_list = []
        self.browseList = []
        self.oldfilename = None
        self.newfilename = None

        # alt method of adding checkboxes to a layout from a loop

        # radio buttons used to select the primary movie name as a renamimg source
        self.parentButton_1 = self.ui.parentButton_1
        self.parentButton_2 = self.ui.parentButton_2
        self.parentButton_3 = self.ui.parentButton_3
        self.parentButton_4 = self.ui.parentButton_4
        self.parentButton_5 = self.ui.parentButton_5
        self.parentButton_6 = self.ui.parentButton_6
        self.parentButton_7 = self.ui.parentButton_7
        self.parentButton_8 = self.ui.parentButton_8
        self.parentButton_9 = self.ui.parentButton_9
        self.parentButton_10 = self.ui.parentButton_10

        self.pathlabel_1 = self.ui.pathlabel_1
        self.pathlabel_2 = self.ui.pathlabel_2
        self.pathlabel_3 = self.ui.pathlabel_3
        self.pathlabel_4 = self.ui.pathlabel_4
        self.pathlabel_5 = self.ui.pathlabel_5
        self.pathlabel_6 = self.ui.pathlabel_6
        self.pathlabel_7 = self.ui.pathlabel_7
        self.pathlabel_8 = self.ui.pathlabel_8
        self.pathlabel_9 = self.ui.pathlabel_9
        self.pathlabel_10 = self.ui.pathlabel_10

        self.namelabel_1 = self.ui.namelabel_1
        self.namelabel_2 = self.ui.namelabel_2
        self.namelabel_3 = self.ui.namelabel_3
        self.namelabel_4 = self.ui.namelabel_4
        self.namelabel_5 = self.ui.namelabel_5
        self.namelabel_6 = self.ui.namelabel_6
        self.namelabel_7 = self.ui.namelabel_7
        self.namelabel_8 = self.ui.namelabel_8
        self.namelabel_9 = self.ui.namelabel_9
        self.namelabel_10 = self.ui.namelabel_10

        self.rencheckbox = self.ui.rencheckBox
        self.rencheckbox_2 = self.ui.rencheckBox_2
        self.rencheckbox_3 = self.ui.rencheckBox_3
        self.rencheckbox_4 = self.ui.rencheckBox_4
        self.rencheckbox_5 = self.ui.rencheckBox_5
        self.rencheckbox_6 = self.ui.rencheckBox_6
        self.rencheckbox_7 = self.ui.rencheckBox_7
        self.rencheckbox_8 = self.ui.rencheckBox_8
        self.rencheckbox_9 = self.ui.rencheckBox_9
        self.rencheckbox_10 = self.ui.rencheckBox_10

        self.chlabel_1 = self.ui.chlabel_1
        self.chlabel_2 = self.ui.chlabel_2
        self.chlabel_3 = self.ui.chlabel_3
        self.chlabel_4 = self.ui.chlabel_4
        self.chlabel_5 = self.ui.chlabel_5
        self.chlabel_6 = self.ui.chlabel_6
        self.chlabel_7 = self.ui.chlabel_7
        self.chlabel_8 = self.ui.chlabel_8
        self.chlabel_9 = self.ui.chlabel_9
        self.chlabel_10 = self.ui.chlabel_10

        self.recordIDlabel_1 = self.ui.recordIDlabel_1
        self.recordIDlabel_2 = self.ui.recordIDlabel_2
        self.recordIDlabel_3 = self.ui.recordIDlabel_3
        self.recordIDlabel_4 = self.ui.recordIDlabel_4
        self.recordIDlabel_5 = self.ui.recordIDlabel_5
        self.recordIDlabel_6 = self.ui.recordIDlabel_6
        self.recordIDlabel_7 = self.ui.recordIDlabel_7
        self.recordIDlabel_8 = self.ui.recordIDlabel_8
        self.recordIDlabel_9 = self.ui.recordIDlabel_9
        self.recordIDlabel_10 = self.ui.recordIDlabel_10

        # watch for rename button being pressed
        self.renameBtn = self.ui.renameButton
        self.renameBtn.clicked.connect(self.updateLibrary)

        # watch for run button presses
        self.runBtn = self.ui.run_button
        self.runBtn.clicked.connect(self.getWDriveRecord)

        # watch for next button press
        self.nxtBtn = self.ui.nextButton
        self.nxtBtn.clicked.connect(self.getNextRecord)  # clears the display
        self.nxtBtn.clicked.connect(self.getWDriveRecord)  # gets the next list

        # watch for slider changes
        self.levslider.valueChanged.connect(self.changeLevRatio)

        self.chosenWFile = []
        self.chosenCopyFiles = []

        self.getWDriveRecord()


    def changeLevRatio(self):

        self.levedit.setText(str(self.levslider.value()))

    def getNextRecord(self):
        self.clearResultsGrid()

    # gets next uncheck file from library on W: drive
    def getWDriveRecord(self):



        lastWID = 0

        index = 0
        while index == 0:

            # get a single W record from Library that hasn't been checked
            # message back if no data
            self.master_record = sql.getMasterList(lastWID)  # returns a list object of the selected file

            # prep variables to store selected record details
            ID = self.master_record[0]
            lastWID = ID
            Drive = self.master_record[1]
            Path = self.master_record[2]
            File = self.master_record[3]
            Type = self.master_record[4]

            # get all files from library other than thw W file selected above that are yet to be renamed
            library = sql.getOtherNames(ID, File)
            print("still getting b")

            # pass W record above into the function along with a list of all files awaiting renaming
            # the function loops through looking for a match all records being displayed in the function below
            self.result = self.getMatchingRecords(ID, File, library)    # gets list of similarly named from library

            # check to see if similar file names exist
            # if not index will remain at 0 the library updated and a new W record chosen, repeating until
            # at least one similar file is found
            numRows = len(self.result)
            if numRows > 0:
                index = 1
            else:
                index = 0
                # update library to show  W: record that has been reviewed and passed over bacause there are no
                # similar names
                sql.updateLibrary(ID)

        self.displayRecords(self.master_record, self.result)
        print("still getting d")

    def getMatchingRecords(self, ID, File, library):
        similarList = []
        index = 0
        levTarget = int(self.levedit.text()) / 100  # get target from text box
        for name in library:  # look for name in 4th col of library master list
            movie_name = name[3]  # catch the name from each record in turn
            partial_score = lev.ratio(movie_name, File)  # compare target name with record name in turn
            # if partial_score > .9:
            # (print("partial ", str(partial_score)))
            if File in name[3] or name[3] in File:  # lev may miss short titles with missing release year
                partial_score = 1.0
            # print("score ", partial_score)
            if partial_score >= levTarget:
                similarList.append(library[index])  # append file details to a new li
            index = index + 1
        return similarList      # returns list of similarly named files

    # todo much work on this
    def updateLibrary(self):

        checkMasterName = len(self.masterName.text())
        if checkMasterName > 0:
            print("check master name 2")
            # there is text in master name box which must be used to rename all files
            self.nameOverride = True
        else:
            self.nameOverride = False

        # todo need to establish a list object holding the chosen master record when its not the W file
        # test1 = self.parentDataCheck()  # has a valid parent been selected
        test1 = True
        if test1:
            test2 = self.copyCheck()  # returns true if selection error
            print("error = ", test2)
        print("lib 1")

        # self.masterName = self.ui.masterFileNameTxt
        if self.nameOverride:
            newParentName = self.masterName.text()  # get new name
            # set display filename on row 1 to new name
            print("new overridden name is ", self.ui.namelabel_1.setText(newParentName))
            # set actual file name on W:drive to new name
            nID = self.master_record[0]
            nDrive = self.master_record[1]
            nPath = self.master_record[2]
            nFile = self.master_record[3]
            nType = self.master_record[4]
            nFilePath = nDrive + nPath
            nFile = newParentName + nType
            # now change file name
            ok = self.parentRenameFile(nFilePath, nFile)
            if ok:
                print("master parent name updated ", nFilePath, nFile)
            else:
                print("master parent name update Failed ", nFilePath, nFile)

        else:
            print("no override of parent name required")

        # testing file rename
        self.renameFile()
        print("completed update library")
        # get filename from W
        # get drive, path, filename and ext from copy
        # pass into rename to change and get conf

    # todo import to empty the parent and child lists once rename is completed
    # checks to make sure user selects files to rename and doesnt choose same row as parent
    # also creates masterlist of parent and child LISTS to use as a basis for the rename function.
    def copyCheck(self):

        radioCheck = [(self.parentButton_1.isChecked(), 1), (self.parentButton_2.isChecked(), 2),
                      (self.parentButton_3.isChecked(), 3), (self.parentButton_4.isChecked(), 4),
                      (self.parentButton_5.isChecked(), 5), (self.parentButton_6.isChecked(), 6),
                      (self.parentButton_7.isChecked(), 7), (self.parentButton_8.isChecked(), 8),
                      (self.parentButton_9.isChecked(), 9), (self.parentButton_10.isChecked(), 10)]

        List_of_checked = []

        List_of_unchecked = []

        # locates which radio button is checked
        for i, v in radioCheck:
            if i:
                List_of_checked.append(v)
            else:
                List_of_unchecked.append(v)

        # stores select W in a list at global level for other methods
        self.chosenWFile = List_of_checked
        print("chosen radio ", self.chosenWFile)

        # use checked to record which radio button was checked
        # repeat for checkboxes

        copyCheck = [(self.rencheckbox.isChecked(), 1), (self.rencheckbox_2.isChecked(), 2),
                     (self.rencheckbox_3.isChecked(), 3), (self.rencheckbox_4.isChecked(), 4),
                     (self.rencheckbox_5.isChecked(), 5), (self.rencheckbox_6.isChecked(), 6),
                     (self.rencheckbox_7.isChecked(), 7), (self.rencheckbox_8.isChecked(), 8),
                     (self.rencheckbox_9.isChecked(), 9), (self.rencheckbox_10.isChecked(), 10)]

        self.List_of_checkedB = []

        List_of_uncheckedB = []

        # locates which checkboxes are checked
        # making sure that radio and check are not the same row
        for i, v in copyCheck:
            if i:
                self.List_of_checkedB.append(v)
            else:
                List_of_uncheckedB.append(v)

        # number checked items to copy
        count = len(self.List_of_checkedB)

        # globalised list of files to be renamed
        self.chosenCopyFiles = self.List_of_checkedB
        print("copy these records ", self.chosenCopyFiles)

        # now to see whether same row was checked
        parentRow = List_of_checked[0]
        if count == 0:
            # no parent box has been ticked
            self.infoCheck("You Must Choose A FileName")
            self.copyError = True
        else:
            if parentRow in self.List_of_checkedB:
                self.copyError = True
                # checks to see if rows to copy are same as parent row
                print("ERROR")
                self.infoCheck("Cannot Choose Parent Row")

        print("completed copycheck error status: ", self.copyError)
        return self.copyError

    def infoCheck(self, missing):
        msg = QMessageBox()
        msg.setIcon(QMessageBox.Information)
        msg.setText("Missing Information")
        msg.setInformativeText(missing)
        msg.setWindowTitle("Warning")
        msg.setStandardButtons(QMessageBox.Ok)
        # this displays the message
        x = msg.exec_()

    def displayRecords(self, master_record, result):  # pass data to be displayed

        # first display the parent file from W:Drive
        # master record is the W Drive record to use
        # result is a list of matching records from the database

        # get data and display W drive record
        parentid = str(master_record[0])
        parentpath = master_record[1] + master_record[2]
        parentname = master_record[3] + master_record[4]
        self.ui.recordIDlabel_1.setText(parentid)
        self.ui.pathlabel_1.setText(parentpath)
        self.ui.namelabel_1.setText(parentname)

        # next populate the children to be renamed
        # this checks number of rows to be displayed
        numItems = int(len(result))
        count = 1
        # print(" 0 2 ",str(result[0][1]) + str(result[0][2]))
        # childpath = str(result[0][1] + result[0][2])  NOT USED i think

        if numItems < 1:
            self.infoCheck("No Other Copies")
        else:
            # keep track of which of the child records I am displaying
            # todo what happens if no records returned
            # todo after hiding we need to show them again when NEXT is clicked
            if count == 1:
                childid = str(result[0][0])
                childpath = str(result[0][1] + result[0][2])
                childname = str(result[0][3] + result[0][4])
                self.ui.recordIDlabel_2.setText(childid)
                self.ui.pathlabel_2.setText(childpath)
                self.ui.namelabel_2.setText(childname)
                count = count + 1  # sets next row
            else:
                self.ui.recordIDlabel_2.hide()
                self.ui.pathlabel_2.hide()
                self.ui.namelabel_2.hide()
                self.ui.chlabel_2.hide()
                self.ui.parentButton_2.hide()
                self.ui.rencheckBox_2.hide()

            # compare next row with number of rows needed, when we reach the limit, start hiding
            if count == 2 and count <= numItems:
                childid2 = str(result[1][0])
                childpath2 = str(result[1][1] + result[1][2])
                childname2 = str(result[1][3] + result[1][4])
                self.ui.recordIDlabel_3.setText(childid2)
                self.ui.pathlabel_3.setText(childpath2)
                self.ui.namelabel_3.setText(childname2)
                count = count + 1
            else:
                self.ui.recordIDlabel_3.hide()
                self.ui.pathlabel_3.hide()
                self.ui.namelabel_3.hide()
                self.ui.chlabel_3.hide()
                self.ui.parentButton_3.hide()
                self.ui.rencheckBox_3.hide()

            if count == 3 and count <= numItems:
                childid3 = str(result[2][0])
                childpath3 = str(result[2][1] + result[2][2])
                childname3 = str(result[2][3] + result[2][4])
                self.ui.recordIDlabel_4.setText(childid3)
                self.ui.pathlabel_4.setText(childpath3)
                self.ui.namelabel_4.setText(childname3)
                count = count + 1
            else:
                self.ui.recordIDlabel_4.hide()
                self.ui.pathlabel_4.hide()
                self.ui.namelabel_4.hide()
                self.ui.chlabel_5.hide()
                self.ui.parentButton_4.hide()
                self.ui.rencheckBox_4.hide()

            if count == 4 and count <= numItems:
                childid4 = str(result[3][0])
                childpath4 = str(result[3][1] + result[3][2])
                childname4 = str(result[3][3] + result[3][4])
                self.ui.recordIDlabel_5.setText(childid4)
                self.ui.pathlabel_5.setText(childpath4)
                self.ui.namelabel_5.setText(childname4)
                count = count + 1
            else:
                self.ui.recordIDlabel_5.hide()
                self.ui.pathlabel_5.hide()
                self.ui.namelabel_5.hide()
                self.ui.chlabel_5.hide()
                self.ui.parentButton_5.hide()
                self.ui.rencheckBox_5.hide()

            if count == 5 and count <= numItems:
                childid5 = str(result[4][0])
                childpath5 = str(result[4][1] + result[4][2])
                childname5 = str(result[4][3] + result[4][4])
                self.ui.recordIDlabel_6.setText(childid5)
                self.ui.pathlabel_6.setText(childpath5)
                self.ui.namelabel_6.setText(childname5)
                count = count + 1
            else:
                self.ui.recordIDlabel_6.hide()
                self.ui.pathlabel_6.hide()
                self.ui.namelabel_6.hide()
                self.ui.chlabel_6.hide()
                self.ui.parentButton_6.hide()
                self.ui.rencheckBox_6.hide()

            if count == 6 and count <= numItems:
                childid6 = str(result[5][0])
                childpath6 = str(result[5][1] + result[5][2])
                childname6 = str(result[5][3] + result[5][4])
                self.ui.recordIDlabel_7.setText(childid6)
                self.ui.pathlabel_7.setText(childpath6)
                self.ui.namelabel_7.setText(childname6)
                count = count + 1
            else:
                self.ui.recordIDlabel_7.hide()
                self.ui.pathlabel_7.hide()
                self.ui.namelabel_7.hide()
                self.ui.chlabel_7.hide()
                self.ui.parentButton_7.hide()
                self.ui.rencheckBox_7.hide()

            if count == 7 and count <= numItems:
                childid7 = str(result[6][0])
                childpath7 = str(result[6][1] + result[6][2])
                childname7 = str(result[6][3] + result[6][4])
                self.ui.recordIDlabel_8.setText(childid7)
                self.ui.pathlabel_8.setText(childpath7)
                self.ui.namelabel_8.setText(childname7)
                count = count + 1
            else:
                self.ui.recordIDlabel_8.hide()
                self.ui.pathlabel_8.hide()
                self.ui.namelabel_8.hide()
                self.ui.chlabel_8.hide()
                self.ui.parentButton_8.hide()
                self.ui.rencheckBox_8.hide()

            if count == 8 and count <= numItems:
                childid8 = str(result[7][0])
                childpath8 = str(result[7][1] + result[7][2])
                childname8 = str(result[7][3] + result[7][4])
                self.ui.recordIDlabel_9.setText(childid8)
                self.ui.pathlabel_9.setText(childpath8)
                self.ui.namelabel_9.setText(childname8)
                count = count + 1
            else:
                self.ui.recordIDlabel_9.hide()
                self.ui.pathlabel_9.hide()
                self.ui.namelabel_9.hide()
                self.ui.chlabel_9.hide()
                self.ui.parentButton_9.hide()
                self.ui.rencheckBox_9.hide()

            if count == 9 and count <= numItems:
                childid9 = str(result[8][0])
                childpath9 = str(result[8][1] + result[8][2])
                childname9 = str(result[8][3] + result[8][4])
                self.ui.recordIDlabel_10.setText(childid9)
                self.ui.pathlabel_10.setText(childpath9)
                self.ui.namelabel_10.setText(childname9)
            else:
                self.ui.recordIDlabel_10.hide()
                self.ui.pathlabel_10.hide()
                self.ui.namelabel_10.hide()
                self.ui.chlabel_10.hide()
                self.ui.parentButton_10.hide()
                self.ui.rencheckBox_10.hide()

    def clearResultsGrid(self):

        # todo after clearing grid reset the hidden rows

        self.parentButton_1.setChecked(False)
        self.parentButton_2.setChecked(False)
        self.parentButton_3.setChecked(False)
        self.parentButton_4.setChecked(False)
        self.parentButton_5.setChecked(False)
        self.parentButton_6.setChecked(False)
        self.parentButton_7.setChecked(False)
        self.parentButton_8.setChecked(False)
        self.parentButton_9.setChecked(False)
        self.parentButton_10.setChecked(False)

        self.pathlabel_1.setText("")
        self.pathlabel_2.setText("")
        self.pathlabel_3.setText("")
        self.pathlabel_4.setText("")
        self.pathlabel_5.setText("")
        self.pathlabel_6.setText("")
        self.pathlabel_7.setText("")
        self.pathlabel_8.setText("")
        self.pathlabel_9.setText("")
        self.pathlabel_10.setText("")

        self.namelabel_1.setText("")
        self.namelabel_2.setText("")
        self.namelabel_3.setText("")
        self.namelabel_4.setText("")
        self.namelabel_5.setText("")
        self.namelabel_6.setText("")
        self.namelabel_7.setText("")
        self.namelabel_8.setText("")
        self.namelabel_9.setText("")
        self.namelabel_10.setText("")

        self.rencheckbox.setChecked(False)
        self.rencheckbox_2.setChecked(False)
        self.rencheckbox_3.setChecked(False)
        self.rencheckbox_4.setChecked(False)
        self.rencheckbox_5.setChecked(False)
        self.rencheckbox_6.setChecked(False)
        self.rencheckbox_7.setChecked(False)
        self.rencheckbox_8.setChecked(False)
        self.rencheckbox_9.setChecked(False)
        self.rencheckbox_10.setChecked(False)

        self.chlabel_1.setText("")
        self.chlabel_2.setText("")
        self.chlabel_3.setText("")
        self.chlabel_4.setText("")
        self.chlabel_5.setText("")
        self.chlabel_6.setText("")
        self.chlabel_7.setText("")
        self.chlabel_8.setText("")
        self.chlabel_9.setText("")
        self.chlabel_10.setText("")

        self.recordIDlabel_1.setText("")
        self.recordIDlabel_2.setText("")
        self.recordIDlabel_3.setText("")
        self.recordIDlabel_4.setText("")
        self.recordIDlabel_5.setText("")
        self.recordIDlabel_6.setText("")
        self.recordIDlabel_7.setText("")
        self.recordIDlabel_8.setText("")
        self.recordIDlabel_9.setText("")
        self.recordIDlabel_10.setText("")

        self.showAllRows()

    def showAllRows(self):
        # todo method needed to unhide all rows
        self.ui.parentButton_1.show()
        self.ui.parentButton_2.show()
        self.ui.parentButton_3.show()
        self.ui.parentButton_4.show()
        self.ui.parentButton_5.show()
        self.ui.parentButton_6.show()
        self.ui.parentButton_7.show()
        self.ui.parentButton_8.show()
        self.ui.parentButton_9.show()
        self.ui.parentButton_10.show()

        self.ui.recordIDlabel_1.show()
        self.ui.recordIDlabel_2.show()
        self.ui.recordIDlabel_3.show()
        self.ui.recordIDlabel_4.show()
        self.ui.recordIDlabel_5.show()
        self.ui.recordIDlabel_6.show()
        self.ui.recordIDlabel_7.show()
        self.ui.recordIDlabel_8.show()
        self.ui.recordIDlabel_9.show()
        self.ui.recordIDlabel_10.show()

        self.ui.pathlabel_1.show()
        self.ui.pathlabel_2.show()
        self.ui.pathlabel_3.show()
        self.ui.pathlabel_4.show()
        self.ui.pathlabel_5.show()
        self.ui.pathlabel_6.show()
        self.ui.pathlabel_7.show()
        self.ui.pathlabel_8.show()
        self.ui.pathlabel_9.show()
        self.ui.pathlabel_10.show()

        self.ui.namelabel_1.show()
        self.ui.namelabel_2.show()
        self.ui.namelabel_3.show()
        self.ui.namelabel_4.show()
        self.ui.namelabel_5.show()
        self.ui.namelabel_6.show()
        self.ui.namelabel_7.show()
        self.ui.namelabel_8.show()
        self.ui.namelabel_9.show()
        self.ui.namelabel_10.show()

        self.ui.rencheckBox.show()
        self.ui.rencheckBox_2.show()
        self.ui.rencheckBox_3.show()
        self.ui.rencheckBox_4.show()
        self.ui.rencheckBox_5.show()
        self.ui.rencheckBox_6.show()
        self.ui.rencheckBox_7.show()
        self.ui.rencheckBox_8.show()
        self.ui.rencheckBox_9.show()
        self.ui.rencheckBox_10.show()

    # todo once renaming is completed make sure that the lists are cleared out ready for the next action
    # def renameFile(dir, path, oldfile, newfile, ext):
    def renameFile(self):
        '''
        the method looks at the Ui for renaming files. It looks at the radio button to make sure that one is selected
        it looks at the checkboxes to make sure something has been checked. Then the row data is gathered as either
        Parent Data which is the selected filename to be used in the library, and it gathers data of the selected
        :return:
        '''
        # reset
        newMasterFile = None
        print("running renamefile()")
        self.nameOverride = False

        # used to pass current renaming data to renaming function
        currentParentID = None
        currentParentPath = None
        currentParentFile = None
        currentChildID = None
        currentChildPath = None
        currentChildFile = None

        newMasterFile = self.masterName.text()
        print("check master name 1 ", self.masterName.text())
        checkMasterName = len(self.masterName.text())
        if checkMasterName > 0:
            print("check master name 2")
            # there is text in master name box which must be used to rename all files
            self.nameOverride = True
            print("check master name 3")
        else:
            print("master list is empty")
            self.nameOverride = False

        # list of the row number of parent
        for x in self.chosenWFile:
            # print("parent row is ",x)
            parentRow = x  # assume 1
        # this is the row 1 result from W: drive
        # print("w file = ", File)
        # ==================================================================================================
        # list of row number of files to be renamed
        # if 1 then look at other list else copyfiles -1

        if parentRow == 1:  # ie W option
            ID = self.master_record[0]
            Drive = self.master_record[1]
            Path = self.master_record[2]
            File = self.master_record[3]
            Type = self.master_record[4]

            #  **************   if user stick with W: as parent  ****************************parent*************
            checkMasterName = len(self.masterName.text())
            if checkMasterName > 0:
                print("check master name 2")
                # there is text in master name box which must be used to rename all files
                self.nameOverride = True
            else:
                self.nameOverride = False

            if self.nameOverride:
                File = newMasterFile
            fullFileName = File + Type
            print("its Parent row 1 full path is ", Drive + Path)
            print("its Parent row 1 full filename is ", fullFileName)
            currentParentID = ID
            currentParentFile = fullFileName
            print("end of parent W setup")
            # ***************************************************************************************************
        else:  # assume its row 3
            print("parentrow ", parentRow)  # its now 3
            parentRow = parentRow - 2  # changed val to 2
            # print(parentRow)
            # must have chosen a non W file as the parent so get it from the
            # list -2 to accnt for start pos of 0 not 1

            index = 0
            for y in self.result:  # this is a list of the children
                print("y is ", y)  # a list
                if index == parentRow:  # starts at 0 parent row is 1
                    # print("PARENT IS ",index)
                    ID = self.result[index][0]  # get file details from library
                    Drive = self.result[index][1]
                    Path = self.result[index][2]
                    File = self.result[index][3]
                    Type = self.result[index][4]
                    # ***************   so this is the parent if W not selected    ***********************parent****
                    print("parent pathname is ", Drive + Path)
                    print("parent file is ", File + Type)
                    fullFileName = File + Type
                    currentParentID = ID
                    currentParentFile = fullFileName
                    # **********************************************************************************************
                index = index + 1

        # now put the variable together to create a  filename
        # print(" these are the list items ", self.chosenCopyFiles)   # 1 and 3
        if 1 in self.chosenCopyFiles:  # this is the w drive item
            # print("yup 1 in here")
            None

        # print("chosencopyfiles ", self.chosenCopyFiles)

        # *************** this loops through selected child files outputting the path and filename
        for x in self.chosenCopyFiles:  # list holds row numbers eg 1 and 2
            if x == 1:  # if row is 1 ie select W file as a child *********************
                ID = self.master_record[0]
                Drive = self.master_record[1]
                Path = self.master_record[2]
                File = self.master_record[3]
                Type = self.master_record[4]
                # ******************************** details of the child file on Row 1 the W file*****************
                fullFileName = File + Type
                print("child full path is ", Drive + Path)
                print("child full filename is ", fullFileName)
                currentChildID = ID
                currentChildPath = Drive + Path
                currentChildFile = fullFileName

                # each child file gets modified using parent details
                success = self.finalRenameFile(currentParentID, currentParentFile, currentChildFile, currentChildPath,
                                               currentChildID)
                # if renaming a success confirm back to libary
                if success:
                    sql.updateLibrary(currentParentID)
                    sql.updateLibrary(currentChildID)
                    fName = msf.getStopPosition(currentParentFile)
                    # currentParentFile = currentChildFile[0:(fName-1)]  # modify name to drop file type
                    print("modified parent filename is ", fName)
                    sql.updateLibraryFile(currentChildID, fName)
                # ************************************************************************************************
                # rename me
            else:
                print("00000000000000", x)
                # x is a number not row 1 on the dispaly
                ID = self.result[x - 2][0]
                Drive = self.result[x - 2][1]
                Path = self.result[x - 2][2]
                File = self.result[x - 2][3]
                Type = self.result[x - 2][4]
                # *************otherwise these are the other selected files whose names are to be changed************
                fullFileName = File + Type
                print("child full path is ", Drive + Path)
                print("child full filename is ", fullFileName, "result row is ", x - 1)
                currentChildID = ID
                currentChildPath = Drive + Path
                currentChildFile = fullFileName

                success = self.finalRenameFile(currentParentID, currentParentFile, currentChildFile, currentChildPath,
                                               currentChildID)

                # todo if a non W file is selected as the parent there is no facility below to rename it in the library

                if success:
                    print("success")
                    sql.updateLibrary(currentParentID)
                    sql.updateLibrary(currentChildID)
                    fName = msf.getStopPosition(currentParentFile)
                    # currentParentFile = currentChildFile[0:(fName-1)]    # modify name to drop file type
                    print("modified parent filename is ", fName)
                    sql.updateLibraryFile(currentChildID, fName)
                else:
                    print("failed to rename")

                # **********************************************************************************
                # reset
                self.nameOverride = False

    def finalRenameFile(self, currentParentID, currentParentFile, currentChildFile, currentChildPath, currentChildID):
        '''
        Takes path of child name and new parent name and renames the child name to the parent name
        using OS methods to rename
        if it all works ok it returns a true value for feedback
        '''
        success = False
        print("success ok about to try ", currentChildFile)

        # test this
        # check if there is a master name set
        # change display
        # change library
        # change filename on W
        # chdir to parent directory
        # change filename
        # then update the file name in library
        # when to do this?
        # or right at the beginning before it starts

        try:

            # print("Current working directory: {0}".format(os.getcwd()))
            os.chdir(currentChildPath)
            # print("ok  A......Current working directory for renaming: {0}".format(os.getcwd()))
            # first test to see if the file that I'm renaming exists
            if os.path.isfile(currentChildFile):
                None
                print("child to rename exists ", currentChildFile)
            else:
                print("child to rename doesnt exist ", currentChildFile)
                self.infoCheck("No such file here ")

            # now to make sure that the new file name doesnt exist
            # problem when the duplicate copy has the exact same name
            # i shall just ignore it
            if not os.path.isfile(currentParentFile):
                # now to rename
                # print("child is ", parentName)
                # print("Current working directory for renaming: {0}".format(os.getcwd()))
                # parent is new name
                os.rename(currentChildFile, currentParentFile)

                print("no risk of duplicate file name")
                success = True

            else:
                print("looks like there is already a file of that name so cant rename this one there ")
                comment = "Duplicate File Error " + currentParentFile
                # self.infoCheck(comment)
                success = True

        except FileNotFoundError:
            print("Directory: {0} does not exist".format(currentChildPath))
        except NotADirectoryError:
            print("{0} is not a directory".format(currentChildPath))
        except PermissionError:
            print("You do not have permissions to change to {0}".format(currentChildPath))
        finally:
            return success  # or otherwise True/False

    def parentRenameFile(self, newParentPath, newParentFile):
        success = False
        try:
            os.rename(newParentPath, newParentFile)
            success = True

        except FileNotFoundError:
            print("Directory: {0} does not exist".format(newParentPath))
        except NotADirectoryError:
            print("{0} is not a directory".format(newParentPath))
        except PermissionError:
            print("You do not have permissions to change to {0}".format(newParentPath))
        finally:
            return success

