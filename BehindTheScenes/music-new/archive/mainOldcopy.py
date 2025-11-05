


#project pythonProject4 Version 2

#this file calls the main GUI window and displays it
#the GUI has buttons and other menus and tools for various purposes
# Version 2.0.0
# Date 06/11/2024


from PyQt5.QtWidgets import *
from getMainWindow5 import getWindow
import sys


def main():
    app = QApplication(sys.argv)

    # derived from getMainWindow which is a file that incorprates all of the functionality
    # of the Main Window including classes and methods etc
    #see aboove fromGetMainWindow import getWindow
    mywin = getWindow()
    mywin.showMaximized()

    app.exec_()


if __name__ == '__main__':
    mainOldCopy()