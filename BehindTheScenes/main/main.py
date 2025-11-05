
#project pythonProject4

#this file calls the main GUI window and displays it
#the GUI has buttons and other menus and tools for various purposes
# Version 1.0.0
# Date 27/01/2021


from PyQt5.QtWidgets import *
from getMainWindow import getWindow
import sys


def main():
    app = QApplication(sys.argv)

    # derived from getMainWindow which is a file that incorprates all of the functionality
    # of the Main Window including classes and methods etc
    mywin = getWindow()
    mywin.showMaximized()

    app.exec_()


if __name__ == '__main__':
    main()