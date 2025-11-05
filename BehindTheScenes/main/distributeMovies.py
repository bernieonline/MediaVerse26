import os
import os.path
from moveNewFiles import Ui_Form
import SQLiteFunction as sql
from PyQt5 import QtWidgets as qtw
import MiscFunctions as msf
from fileExplorer import FileWindow
import shutil


class getDistWindow(qtw.QWidget):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)  # class super subclasses QtWidgets on which the form was based

        # we can then use its show feature to display it
        self.ui = Ui_Form()
        self.ui.setupUi(self)

        # file explorer button to find source filename
        self.masterButton = self.ui.masterButton
        self.masterButton.clicked.connect(self.openExplorer)

        # filename of source file
        self.sourceEdit = self.ui.sourceEdit

        chLocButton_1 = self.ui.chLocButton_1
        chLocButton_1.clicked.connect(self.browseFolders)
        chLocButton_2 = self.ui.chLocButton_2
        chLocButton_2.clicked.connect(self.browseFolders)
        chLocButton_3 = self.ui.chLocButton_3
        chLocButton_3.clicked.connect(self.browseFolders)
        chLocButton_4 = self.ui.chLocButton_4
        chLocButton_4.clicked.connect(self.browseFolders)
        chLocButton_5 = self.ui.chLocButton_5
        chLocButton_5.clicked.connect(self.browseFolders)


        # displays selected folder names for distribution
        self.chLocText_a = self.ui.chLocText_a
        self.chLocText_b = self.ui.chLocText_b
        self.chLocText_c = self.ui.chLocText_c
        self.chLocText_d = self.ui.chLocText_d
        self.chLocText_e = self.ui.chLocText_e

        self.clearButton1 = self.ui.clearButton1
        self.clearButton1.clicked.connect(self.clearRow)
        self.clearButton2 = self.ui.clearButton2
        self.clearButton2.clicked.connect(self.clearRow)
        self.clearButton3 = self.ui.clearButton3
        self.clearButton3.clicked.connect(self.clearRow)
        self.clearButton4 = self.ui.clearButton4
        self.clearButton4.clicked.connect(self.clearRow)
        self.clearButton5 = self.ui.clearButton5
        self.clearButton5.clicked.connect(self.clearRow)

        self.clearAllButton = self.ui.clearAllButton
        self.clearAllButton.clicked.connect(self.clearAll)

        self.moveButton = self.ui.moveButton
        self.moveButton.clicked.connect(self.copyFiles)

        self.destinationList = []

        self.textBrowser = self.ui.textBrowser



    def openExplorer(self):
        '''
        allows user to browse for a folder name to be used to collect all file in a folder for batch processing
        :return:
        '''
        myFile = msf.pickFileName()
        print(myFile)
        self.sourceEdit.setText(myFile)

    def browseFolders(self):
        '''
        allows user to browse for a file name to be used to collect list of files for batch processing
        :return:
        '''
        # use of sender allows the method to share between multiple buttons
        sender = self.sender()
        print(sender.text() + ' was pressed')

        if sender.text() == 'Choose Location 1':
            myFile = msf.pickFolderName()
            self.chLocText_a.setText(myFile)

        if sender.text() == 'Choose Location 2':
            myFile = msf.pickFolderName()
            self.chLocText_b.setText(myFile)

        if sender.text() == 'Choose Location 3':
            myFile = msf.pickFolderName()
            self.chLocText_c.setText(myFile)

        if sender.text() == 'Choose Location 4':
            myFile = msf.pickFolderName()
            self.chLocText_d.setText(myFile)

        if sender.text() == 'Choose Location 5':
            myFile = msf.pickFolderName()
            self.chLocText_e.setText(myFile)

    def clearRow(self):
        sender = self.sender()
        print(sender.text() + ' was pressed')

        if sender.text() == 'Clear Row 1':
            self.chLocText_a.setText("")

        if sender.text() == 'Clear Row 2':
            self.chLocText_b.setText("")

        if sender.text() == 'Clear Row 3':
            self.chLocText_c.setText("")

        if sender.text() == 'Clear Row 4':
            self.chLocText_d.setText("")

        if sender.text() == 'Clear Row 5':
            self.chLocText_e.setText("")

    def clearAll(self):
        self.chLocText_a.setText("")
        self.chLocText_b.setText("")
        self.chLocText_c.setText("")
        self.chLocText_d.setText("")
        self.chLocText_e.setText("")

    def copyFiles(self):

        source = self.sourceEdit.text()
        print("source is ", source)
        test1 = len(source)
        if test1 > 0:
            doesItExist = msf.checkExists(source)       # True or False
        else:
            msf.warningMessagePopUp("You Must Choose a Source File ", "System Exit")

        if doesItExist:
            # need a list of destination folders to work through
            # need to make destination filenames
            baseName = msf.getBaseName(source)
            print("basenames is ", baseName)
            # self.textBrowser.setText("basenames is " + baseName)

            dest1 = self.chLocText_a.text()
            testa = len(dest1)
            print(testa)
            dest1 = dest1 + "/" + baseName
            print(dest1)
            if testa > 0:
                self.destinationList.append(dest1)
                ()

            dest2 = self.chLocText_b.text()
            testb = len(dest2)
            print(testb)
            dest2 = dest2 + "/" + baseName
            if testb > 0:
                self.destinationList.append(dest2)
                ()

            dest3 = self.chLocText_c.text()
            testc = len(dest3)
            dest3 = dest3 + "/" + baseName
            if testc > 0:
                self.destinationList.append(dest3)


            dest4 = self.chLocText_d.text()
            testd = len(dest4)
            dest4 = dest4 + "/" + baseName
            if testd > 0:
                self.destinationList.append(dest4)


            dest5 = self.chLocText_e.text()
            teste = len(dest5)
            dest5 = dest5 + "/" + baseName
            if teste > 0:
                self.destinationList.append(dest5)


            print(self.destinationList)


            #loop through the destinatio list passing source and destination to a copy file function
            for each in self.destinationList:
                source = source
                print("src ", source)
                print("des ", each)
                dest = each
                msf.copyFile(source, dest)

        else:
            msf.warningMessagePopUp("No Such Source File ", "System Exit")

        print("Copy list Complete")
