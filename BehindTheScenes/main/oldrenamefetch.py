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

        self.parentButtons = [self.parentButton_1, self.parentButton_2, self.parentButton_3, self.parentButton_4,
                              self.parentButton_5, self.parentButton_6, self.parentButton_7, self.parentButton_8,
                              self.parentButton_9, self.parentButton_10]

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

        self.pathlabel = [self.pathlabel_1, self.pathlabel_2, self.pathlabel_3, self.pathlabel_4,
                          self.pathlabel_5, self.pathlabel_6, self.pathlabel_7, self.pathlabel_8,
                          self.pathlabel_9, self.pathlabel_10]

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

        self.namelabel = [self.namelabel_1, self.namelabel_2, self.namelabel_3, self.namelabel_4, self.namelabel_5,
                          self.namelabel_6, self.namelabel_7, self.namelabel_8, self.namelabel_9, self.namelabel_10]

        self.rencheckbox_1 = self.ui.rencheckBox_1
        self.rencheckbox_2 = self.ui.rencheckBox_2
        self.rencheckbox_3 = self.ui.rencheckBox_3
        self.rencheckbox_4 = self.ui.rencheckBox_4
        self.rencheckbox_5 = self.ui.rencheckBox_5
        self.rencheckbox_6 = self.ui.rencheckBox_6
        self.rencheckbox_7 = self.ui.rencheckBox_7
        self.rencheckbox_8 = self.ui.rencheckBox_8
        self.rencheckbox_9 = self.ui.rencheckBox_9
        self.rencheckbox_10 = self.ui.rencheckBox_10

        self.rencheckBox = [self.rencheckbox_1, self.rencheckbox_2, self.rencheckbox_3, self.rencheckbox_4,
                            self.rencheckbox_5, self.rencheckbox_6, self.rencheckbox_7, self.rencheckbox_8,
                            self.rencheckbox_9, self.rencheckbox_10]

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

        self.chlabel = [self.chlabel_1, self.chlabel_2, self.chlabel_3, self.chlabel_4, self.chlabel_5, self.chlabel_6,
                        self.chlabel_7, self.chlabel_8, self.chlabel_9, self.chlabel_10]

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

        self.recordIDLabel = [self.recordIDlabel_1, self.recordIDlabel_2, self.recordIDlabel_3,
                              self.recordIDlabel_4, self.recordIDlabel_5, self.recordIDlabel_6,
                              self.recordIDlabel_7, self.recordIDlabel_8, self.recordIDlabel_9, self.recordIDlabel_10]

        # watch for rename button being pressed
        # clear out text fro master filename

        # search for a particular movie
        self.search = self.ui.searchEdit

        # watch for run button presses
        self.runBtn = self.ui.run_button
        self.runBtn.clicked.connect(self.getWDriveRecord)

        # watch for next button press
        self.nxtBtn = self.ui.nextButton
        self.nxtBtn.clicked.connect(self.getNextRecord)  # clears the display
        self.nxtBtn.clicked.connect(self.getWDriveRecord)  # gets the next list

        # watch for slider changes
        self.levslider.valueChanged.connect(self.changeLevRatio)

        self.getWDriveRecord()

        self.renameBtn = self.ui.renameButton
        # self.renameBtn.clicked.connect(self.updateLibrary)
        self.renameBtn.clicked.connect(self.passinarow)

        # passes in filename for FFMPeg QA check
        self.QAButton = self.ui.QAButton
        self.QAButton.clicked.connect(self.checkFileQA)

        self.chosenWFile = []
        self.chosenCopyFiles = []

        #   self.hideAllDisplay()     this hides all rows in the change file name display panel

    def changeLevRatio(self):

        self.levedit.setText(str(self.levslider.value()))

    def getNextRecord(self):
        self.clearResultsGrid()

    # gets next uncheck file from library on W: drive
    def getWDriveRecord(self):
        print("entering  1")
        # check to see if there is text in the search box

        print("search ", self.ui.searchEdit.text())

        if len(self.ui.searchEdit.text()) < 1:
            searching = False
        else:
            searchx = self.ui.searchEdit.text()
            print("entering  5")
            searching = True

        index = 0
        while index == 0:

            if (searching):
                print("prepping the query")
                self.master_record = sql.getMasterListSearch(searchx)  # returns a list object of the selected file
                print("completed prepping the query ", self.master_record)
            else:
                # get a file detail from W in library
                self.master_record = sql.getMasterList()  # returns a list object of the selected file

            ID = self.master_record[0]
            Drive = self.master_record[1]
            Path = self.master_record[2]
            File = self.master_record[3]
            Type = self.master_record[4]
            print("still getting a ")

            # get all files from library other than thw W file selected above that are yet to be renamed
            library = sql.getOtherNames(ID, File)

            print("still getting b")

            # pass W record above into the function along with a list of all files awaiting renaming
            # the function loops through looking for a match all records being displayed in the function below
            self.result = self.getMatchingRecords(ID, File, library)
            print("still getting c")

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
                if (searching):
                    self.infoCheck("No other files")
                    break

        self.ui.searchEdit.setText("")
        self.displayRecords(self.master_record, self.result)
        print("completed rename display init")

    def getMatchingRecords(self, ID, File, library):
        similarList = []
        index = 0
        levTarget = int(self.levedit.text()) / 100  # get target from text box
        for name in library:  # look for name in 4th col of library master list
            movie_name = name[3]  # catch the name from each record in turn
            partial_score = lev.ratio(movie_name, File)  # compare target name with record name in turn
            # if partial_score > .9:
            # (print("partial ", str(partial_score)))
            if File in name[3] or name[3] in File:  # lev mav miss short titles with missing release year
                partial_score = 1.0
            # print("score ", partial_score)
            if partial_score >= levTarget:
                similarList.append(library[index])  # append file details to a new li
            index = index + 1

        return similarList

    # todo much work on this
    def updateLibrary(self):

        # todo need to establish a list object holding the chosen master record when its not the W file

        # test1 = self.parentDataCheck()  # has a valid parent been selected

        test1 = True

        if test1:
            test2 = self.copyCheck()  # returns true if selection error
            print("error = ", test2)

        print("lib 1")
        # #################################  new section ####################################
        newMasterFile = self.ui.masterFileNameTxt.text()
        print("check master name 1 ", self.masterName.text())
        checkMasterName = len(newMasterFile)
        # #####################################################################################
        if checkMasterName > 0:
            print("check master name 2")
            # there is text in master name box which must be used to rename all files
            self.nameOverride = True
            print("check master name 3")
        else:
            print("master list is empty so no rename overide")

        # self.masterName = self.ui.masterFileNameTxt
        if self.nameOverride:
            newParentName = self.ui.masterFileNameTxt.text()
            # set display filename on row 1 to new name
            # self.ui.namelabel_1.setText(newParentName)
            # set actual file name on W:drive to new name
            nID = self.master_record[0]
            nDrive = self.master_record[1]
            nPath = self.master_record[2]
            nFile = self.master_record[3]
            oFile = self.master_record[3]
            nType = self.master_record[4]
            nFilePath = nDrive + nPath
            nFile = newParentName + nType
            print("pre master parent name to be updated on hdd", nFilePath + oFile + nType, "xx ", nFilePath + nFile)
            # now change file name on hdd nFile is new name, oFile is old name
            ok = self.parentRenameFile(nFilePath + oFile + nType, nFilePath + nFile)
            if ok:
                print("master parent name updated ", nFilePath, nFile, oFile)
            else:
                print("master parent name update Failed ", nFilePath, nFile, oFile)

        else:
            print("no override of parent name required")

        # big block dealing with testing and renaming of similar files
        self.renameFile()
        self.ui.masterFileNameTxt.setText("")
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
        self.List_of_checkedB = []
        if self.ui.rencheckBox_1.isChecked(): self.List_of_checkedB.append(1)
        if self.ui.rencheckBox_2.isChecked(): self.List_of_checkedB.append(2)
        if self.ui.rencheckBox_3.isChecked(): self.List_of_checkedB.append(3)
        if self.ui.rencheckBox_4.isChecked(): self.List_of_checkedB.append(4)
        if self.ui.rencheckBox_5.isChecked(): self.List_of_checkedB.append(5)
        if self.ui.rencheckBox_6.isChecked(): self.List_of_checkedB.append(6)
        if self.ui.rencheckBox_7.isChecked(): self.List_of_checkedB.append(7)
        if self.ui.rencheckBox_8.isChecked(): self.List_of_checkedB.append(8)
        if self.ui.rencheckBox_9.isChecked(): self.List_of_checkedB.append(9)
        if self.ui.rencheckBox_10.isChecked(): self.List_of_checkedB.append(10)

        print(" appended rows are ", self.List_of_checkedB)
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
        self.hideAllDisplay()
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
        self.parentButton_1.show()  # this is item 0 in list
        self.rencheckbox_1.show()
        self.chlabel_1.show()
        self.namelabel_1.show()
        self.pathlabel_1.show()
        self.recordIDlabel_1.show()

        if self.parentButton_1.isHidden():
            print("parent button should not be hidden")
        else:
            print("parent button should is not hidden")

        # next populate the children to be renamed
        # this checks number of rows to be displayed
        numItems = int(len(result))
        count = 1
        # print(" 0 2 ",str(result[0][1]) + str(result[0][2]))
        # childpath = str(result[0][1] + result[0][2])  NOT USED i think
        print("number of items ", numItems)
        # test to display the rows in a loop
        print(" entering block 1")

        index = 0
        if numItems < 1:
            self.infoCheck("No Other Copies")

        # start dispalying on row 2
        # need to modify index when referring to list object than when referring to display object
        # first item dispalys at row 2 but when looking at list first item is 0
        print("result ", result)
        print("numitems ", numItems)  # is 48 children

        while index < numItems and index < 9:  # num items is the number of matching records found 0 to 9
            print(" entering loop 1 index = ", index)
            childid = str(result[index][0])  # index-1 because list positio begins at 0 so ok
            print(" entering loop 1aa index = ", index)
            childpath = str(result[index][1] + result[index][2])
            print(" entering loop 1bb index = ", index)
            childname = str(result[index][3] + result[index][4])
            print(" entering loop 1b index is ", index)

            # ok to here index starts at 0 which is first itm in result list
            # assigmen to objects is wrong
            # the idlabel that we should populate first is '1' in the idlabel list as '0' is taken by row 'w'
            # index + 2 begins at row 2 effectively not populating row 1
            # hiding it as well

            self.recordIDLabel[index + 1].setText(childid)
            print(" entering loop 1b2 index is ", index + 1)  # index = 3

            self.pathlabel[index + 1].setText(childpath)  # index + 1 because we start writing at row 2 on the display
            # self.pathlabel_2.setText(childpath)
            print(" entering loop 1b3 index is ", index + 1)
            self.namelabel[index + 1].setText(childname)
            print(" entering loop 1c")
            # self.ui.namelabel_2.setText(childname)
            self.parentButtons[index + 1].show()
            print(" entering loop 1 cxx index+1 is ", index + 1)
            # self.parentButton_2.show()
            self.rencheckBox[index + 1].show()
            print(" entering loop 1d")
            # self.rencheckbox_1.show()
            self.chlabel[index + 1].show()
            # self.chlabel_2.show()
            self.namelabel[index + 1].show()
            # self.namelabel_2.show()
            self.pathlabel[index + 1].show()
            print(" entering loop e")
            # self.pathlabel_2.show()
            self.recordIDLabel[index + 1].show()
            # self.recordIDlabel_2.show()
            # count = count + 1  # sets next row
            print(" ending loop 1 ", index)
            index = index + 1

        # end of test

    def clearResultsGrid(self):

        for x in self.parentButtons:
            x.setChecked(False)

        for x in self.pathlabel:
            x.setText("")

        for x in self.namelabel:
            x.setText("")

        for x in self.rencheckBox:
            x.setChecked(False)

        for x in self.chlabel:
            x.setText("")

        for x in self.recordIDLabel:
            x.setText("")

        self.showAllRows()

    def showAllRows(self):
        print("p1")

        for x in self.parentButtons:
            x.show()

        for x in self.recordIDLabel:
            x.show()

        for x in self.pathlabel:
            x.show()

        for x in self.namelabel:
            x.show()

        for x in self.rencheckBox:
            x.show()

    def parentRenameFile(self, oldName, newName):

        # os. rename needs to change directory and then use old and new file names
        success = False
        try:
            print("renaming ", oldName, ",", newName)
            os.rename(oldName, newName)
            success = True
            print("now renamed ")

        except FileNotFoundError:
            print("Directory: {0} does not exist".format(newName))
        except NotADirectoryError:
            print("{0} is not a directory".format(newName))
        except PermissionError:
            print("You do not have permissions to change to {0}".format(newName))
        finally:
            return success

    def hideAllDisplay(self):
        '''
        this hides all of the rows in the display RenameSystem GUI
        :return:
        '''

        self.parentButtons
        self.recordIDLabel
        self.pathlabel
        self.namelabel
        self.rencheckBox
        self.chlabel

        for x in range(0, 10):
            self.parentButtons[x].hide()
            self.recordIDLabel[x].hide()
            self.pathlabel[x].hide()
            self.namelabel[x].hide()
            self.rencheckBox[x].hide()
            self.chlabel[x].hide()

    def passinarow(self):
        '''
        this processes each row of the display in a loop leaving parent row to last
        it checks whether its visible if not - ts ignered - and if so
        is it a parent or child
        it gathers the important row data as well as globalRename text if any
        it gather radio and check box data
        it receives back a code from the method() 'processarow' describing the success of each stage of
        row processing which is then displayed
        if each stage gets OK the final spep is to process the parent row
        will not update library TRUE flag unless every step is OK
        but will carry out a global rename and set new name in libary
        flag will be set if this fanal step completes OK and visible signal set to tell user to process the next file
        :return:
        '''
        # first find the parent row ==============================================================
        # self.ui.chlabel_1.setText("")
        counter = 0
        for x in self.parentButtons:
            if x.isChecked():
                parentRow = counter
                parentfilename = self.namelabel[counter].text()
            counter = counter + 1

        print("parent file name is ", parentfilename)

        #   ============================test for global name change and create a list with tha action and name=========
        #   is there a global name change
        # globalaction = False
        nameglobal = self.ui.masterFileNameTxt.text()  # note without file extension
        if len(nameglobal) < 1:
            globalaction = False
        else:
            globalaction = True

        if globalaction:
            print("globalaction true ", nameglobal)
        else:
            print("globalaction false ", nameglobal)

        #    ================================================================================================
        #   examine each row of the display
        #   check if parent >> skip
        #   check if visible >> skip
        #   check if not checked >>
        #   the rest we process one by one sending details tp 'processarow'
        #   ================================================================================================
        counter = 0
        successAllRows = True
        for x in self.recordIDLabel:  # loop through id labels in display
            if not x.isHidden():  # if not hidden
                if counter != parentRow or globalaction:  # if not parent row
                    if self.rencheckBox[counter].isChecked():  # if row is checked for renaming
                        # we have a row that we can process to 'processarow'
                        print("this row can be loaded ", counter)
                        idno = self.recordIDLabel[counter].text()
                        path = self.pathlabel[counter].text()
                        file = self.namelabel[counter].text()
                        result = self.processarow(idno, path, file, globalaction, nameglobal, parentfilename)
                        libUpdate = sql.getLibCheck(idno)
                        if result:
                            self.chlabel[counter].setText("1" + libUpdate)
                            if libUpdate == "0":
                                successAllRows = False
                        else:
                            self.chlabel[counter].setText("0" + libUpdate)
                            successAllRows = False

                        print(idno, path, file, parentfilename, result, globalaction, nameglobal, counter)
            counter = counter + 1
        if successAllRows:
            self.ui.chlabel_1.setText("All actions OK")
        else:
            self.ui.chlabel_1.setText("Some actions failed")

        self.ui.masterFileNameTxt.setText("")

    def processarow(self, idno, path, file, globalaction, nameglobal, parentfilename):
        '''
        this receives row data details from 'passinarow' method()
        as looking to see if global rename is required
        it then updates name on disk and returns a code
        if code ok updates library
        returns a code
        both codes returned to calling method which will process the next row if needed
        :return:
        '''
        success = False
        print('ready to do some work ', idno, globalaction, nameglobal)

        # note globalname and parent name provided without file extensions

        # step 1 need to split filename of parent away from extension
        print(parentfilename)
        parentFileOnly = os.path.splitext(parentfilename)[0]

        # first is there a global rename
        if globalaction:
            parentFileOnly = nameglobal

        childExtension = os.path.splitext(file)[1]
        print("extension child ", childExtension)
        # step 1 Try and change the filename

        oldName = path + file
        newName = path + parentFileOnly + childExtension

        try:
            print("renaming ", oldName, ",", newName)
            os.rename(oldName, newName)
            success = True
            print("now renamed ")
            try:
                conf = sql.updateLibrary(idno)
            except:
                conf = 0

        except OSError as error:
            print(error)
            success = False
        except FileNotFoundError:
            print("Directory: {0} file does not exist - oldname ".format(oldName))
            success = False
        except NotADirectoryError:
            print("{0} is not a directory".format(oldName))
            success = False
        except PermissionError:
            print("You do not have permissions to change to {0}".format(oldName))
            success = False
        finally:
            return success


def checkFileQA(file):

