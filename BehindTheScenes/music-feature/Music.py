# this code constructs the window
#QMainWindow is the type of widow we made in the UI
#QApplication is required whenever we run a designer.pyqt5 app
#loadUI
from PyQt5.QtWidgets import QMainWindow, QApplication
from PyQt5.uic import loadUi
import sys
import MiscFunctions as msf


#inherits QMainWindow
class Music(QMainWindow):
    #this runs whenever window is created
    def __init__(self):
        #super is the imported QMainWindow and all content assigned to this class
        super(Music, self).__init__()
        #loadui loads all the class variables from the UI xml
        loadUi("Music.ui", self)

        self.osType=msf.get_os_name()
        

        #during construction we setup the listeners
        # go to the page where you built the window in designer
        # on the right you will see a list of all the actions registered 
        # automatically when we added an item to the menu

        ################### View    #######################################
        self.actionView_Collection.triggered.connect(self.viewCollection)
        self.actionView_Track.triggered.connect(self.viewTrack)
        self.actionView_Artist.triggered.connect(self.viewArtist)
        ################### utilities ######################################
        self.actionRemove_collection.triggered.connect(self.removeCollection)
        self.actionMove_Collection.triggered.connect(self.moveCollection)
        self.actionCompare_Collections.triggered.connect(self.compareCollections)
        self.actionTest_Collections.triggered.connect(self.testCollections)
        ###################  Search   ######################################
        self.actionSelect_a_Drive.triggered.connect(self.selectDrive)
         ###################  Reports   ######################################
        self.actionView_Database.triggered.connect(self.summaryReport)
        self.actionView_Details.triggered.connect(self.detailsReport)
      



    # now we can do slots and signals for each event clicked

    #View Menu Group
    #actionView_Collection resuslts in this function being run
    def viewCollection(self):
        print("View Collection clicked")

    #actionView_Track resuslts in this function being run
    def viewTrack(self):
        print("View Track clicked")
        print(osType)
        

    #actionView_Artist resuslts in this function being run
    def viewArtist(self):
        print("View Artist clicked")

    #Utilities Menu Group

    def removeCollection(self):
        print("Collection Removed")

    def moveCollection(self):
        print("Collection Moved")

    def compareCollections(self):
        print("Collections Compared")

    def testCollections(self):
        print("Collections Tested")

    #Select Menu Group

    def selectDrive(self):
        print("Drive Selected")

    #Reports Menu Group

    def summaryReport(self):
        print("Summary Selected")

    def detailsReport(self):
        print("Details Selected")

    #################   End of Menu Block     #####################################


if __name__ == '__main__':
    app = QApplication(sys.argv) #mandatory
    ui = Music() #this now creates an instance of the music ui class
    ui.show()  #show the window
    sys.exit(app.exec())
