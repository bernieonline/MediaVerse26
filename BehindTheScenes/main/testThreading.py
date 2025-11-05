from FFMpeg import Ui_Form
from PyQt5 import QtWidgets as qtw
import ffmpegFunc as ffunc
import MiscFunctions as msf
import SQLiteFunction as sql
from datetime import datetime
import time
import sys
from pathlib import Path
import os
from PyQt5.QtCore import *


class movieFFMPEG(qtw.QWidget):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)  # class super subclasses QtWidgets on which the form was based
        '''
        this uses the FFMPEG panel to test the running of this part of
         the App in a separate thread to the Main Window'''
        # used to call the thread that we want to use in a class shown below this class
        self.thread = Worker()

        # signal examples used by the thread used
        # todo create finished method
        self.thread.finished.connect(self.updateUi)             # because self.thred is in Worker so is the method name
        # self.thread.terminated.connect(self.updateUi)
        self.thread.output['QRect', 'QImage'].connect(self.addImage)
        # todo link to  a method
        self.startButton.clicked.connect(self.makePicture)

        # todo
        # i just want a message saying completed as well as a progress comment such as cum time running

        # we can then use its show feature to display it
        self.ui = Ui_Form()
        self.ui.setupUi(self)

        # reference text fields
        self.folderEdit = self.ui.folderEdit
        self.fileEdit = self.ui.fileEdit

        # setup button action to browse for folder
        # self.folderButton = self.ui.folderButton
        # self.folderButton.clicked.connect(self.browseFolders)

        # setup play button
        self.playButton = self.ui.playButton
        self.playButton.clicked.connect(self.playMovie)

        # set up button action to browse for files
        self.fileButton = self.ui.fileButton
        self.fileButton.clicked.connect(self.browseFiles)

        # set up button action to select list of files
        self.listButton = self.ui.listButton
        self.listButton.clicked.connect(self.browseFolders)

        # setup run button to process a list of ffmepg tests
        self.runButton = self.ui.runButton
        self.runButton.clicked.connect(self.checkListFileQuality)

        # set up test button
        self.testButton = self.ui.testButton
        self.testButton.clicked.connect(self.StartQualityThread)

        self.thread.finished.connect(self.updateUi)

        # set up media info button
        self.infoButton = self.ui.infoButton
        self.infoButton.clicked.connect(self.getMediaInfo)

        # setup manual test feedback to Library
        self.updateLibButton = self.ui.updateLibButton
        self.updateLibButton.clicked.connect(self.updateManTest)

        self.combobox = self.ui.comboBox

        self.textBrowser = self.ui.textBrowser

        self.movieList = []

    def browseFolders(self):
        '''
        allows user to browse for a file name to be used to collect list of files for batch processing
        :return:
        '''
        myFile = msf.pickFileName()
        self.textBrowser.append(myFile)
        self.movieList.append(myFile)
        print("list of files:", myFile)

    def browseFiles(self):
        '''
        allows user to browse for a folder name to be used to collect all file in a folder for batch processing
        :return:
         '''
        myFile = msf.pickFileName()
        print(myFile)
        self.fileEdit.setText(myFile)

    def StartQualityThread(self):
        self.thread.start()


    def checkFileQuality(self, file):
        '''
        Pass a file name into this function
        FFMPEG will test it and output an error report file to B: drive
        then it calculates MD5 checksum
        then file size
        all results saved to errorLog table
        :param file:
        :return:
        '''

        # carry out ffmpeg test and store results in filexx
        self.testButton.setEnabled(False)           # disable after clicking
        file = self.fileEdit.text()  # get selected file name
        checkLog = ffunc.checkError(file)  # pass to ffmpeg error checker
        source = self.fileEdit.text()
        # now get checksum on same file
        checksum = msf.getCheckSum(source)
        print("completed checksum")

        # now retrieve error result file size in MB and checksum and insert into sql database
        time.sleep(30)
        # create unique file to hold filtered test results based on basename of filepath chosen
        log = Path(file).stem
        print("log is ", log)
        logtxt = "B:\\" + log + ".txt"
        print("logtxt is ", logtxt)

        # read  the resukts of the filtered file
        y = self.getlogText(logtxt)
        print("result from error processing is :", y)

        # get file size
        size = msf.get_file_size_in_bytes(file)
        size = int(size / (1024 * 1024))

        now = datetime.now()

        # pass all data to update errorLog table
        comp = sql.insertErrorLog(file, y, checksum, now, size)

        print("actions all complete", now)

    # gets contents of text file and returns it

    def checkListFileQuality(self, file):
        '''
        Pass a file name into this function
        FFMPEG will test it and output an error report file to B: drive
        then it calculates MD5 checksum
        then file size
        all results saved to errorLog table
        :param file:
        :return:
        '''
        # carry out ffmpeg test and store results in filexx

        for file in self.movieList:
            self.file = file
            checkLog = ffunc.checkError(self.file)  # pass to ffmpeg error checker
            source = self.file
            # now get checksum on same file
            checksum = msf.getCheckSum(source)
            print("completed checksum")

            # now retrieve error result file size in MB and checksum and insert into sql database
            time.sleep(60)
            # create unique file to hold filtered test results based on basename of filepath chosen
            log = Path(file).stem
            print("log is ", log)
            logtxt = "B:\\" + log + ".txt"
            print("log is ", log)

            # read  the results of the filtered file
            y = self.getlogText(logtxt)
            print("result from error processing is :", y)

            # get file size
            size = msf.get_file_size_in_bytes(file)
            size = int(size / (1024 * 1024))

            now = datetime.now()

            # pass all data to update errorLog table
            comp = sql.insertErrorLog(file, y, checksum, now, size)

            # self.movieList.remove(file)

            print("actions complete for the file", now)

        print("All actions complete for the list", now)

    # gets contents of text file and returns it

    def getlogText(self, log):
        '''
        used to pick up the error log text from the log file prior to copying into the errorLog table
        :return:
        '''

        print("opening file getting log text foe sql ", log)

        logtxt = log

        try:
            writepath = logtxt
            # mode = 'a' if os.path.exists(writepath) else 'w'
            mode = 'r'
            with open(writepath, mode) as f:
                mstr = f.read()

            # print("logtxt  ", logtxt)
            # fo = open(logtxt, "r")
        except OSError as error:
            print("Could not open/read file: for sql ", error)
            # sys.exit()
        finally:
            None
            # time.sleep(30)
            # if fo.closed:
            # fo = open(logtxt, "r")

        if len(mstr) > 0:
            print("text file retured for sql ")
            return mstr
        else:
            print("no errors returned to sql ")
            return "No Errors"

        # Close opened file
        fo.close()

    def playMovie(self):
        '''
        uses MPC Player to play a movie for visual evaluation purposes
        :return:
        '''
        file = self.fileEdit.text()
        ffunc.playMovie(file)

    def getMediaInfo(self):
        '''
        runs the mediaInfo App passing in the file details
        :return:
        '''
        file = self.fileEdit.text()
        ffunc.mediaInfoRun(file)

    def updateManTest(self):
        '''
        Takes choice from combo box and updates error log for the file/location
        :return:
        '''
        file = self.fileEdit.text()
        comment = self.combobox.currentText()
        sql.updateManTest(file, comment)

        # The updateUi() slot is called when a thread stops running. Since we usually want to let the user
        # run the thread again, we reset the user interface to enable the start button to be pressed:

    def updateUi(self):
        # self.spinBox.setReadOnly(False)
        self.testButton.setEnabled(True)

class Worker(QThread):
    output = pyqtSignal(QRect, QImage)
    def __init__(self, parent = None):
        None


    def __del__(self):
        self.exiting = True
        self.wait()

    # ignore these instructions
    # For convenience, we define a method to set up the attributes required by the thread before starting it.
    def render(self, size, stars):
        #self.size = size
        #self.stars = stars
        self.start()

    # this is a critical one
    # its where we put our own code
    def run(self):
        # Note: This is never called directly. It is called by Qt once the
        # thread environment has been set up.
        random.seed()
        n = self.stars
        width = self.size.width()
        height = self.size.height()

        # this is how we send information back to the main thres
        self.output.emit(QRect(x - self.outerRadius, y - self.outerRadius, self.outerRadius * 2, self.outerRadius * 2),
                         image)




    # Whenever is star is drawn by the worker thread, it will emit a signal that is connected to the addImage() slot.
    # This slot is called with a QRect value, indicating where the star should be placed in the pixmap held by
    # the viewer label, and an image of the star itself:
    def addImage(self, rect, image):
        pixmap = self.viewer.pixmap()
        painter = QPainter()
        painter.begin(pixmap)
        painter.drawImage(rect, image)
        painter.end()
        self.viewer.update(rect)