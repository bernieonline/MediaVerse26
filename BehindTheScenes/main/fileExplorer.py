#!/usr/bin/python

"""
ZetCode PyQt5 tutorial

In this example, we select a file with a
QFileDialog and display its contents
in a QTextEdit.

Author: Jan Bodnar
Website: zetcode.com
"""

from PyQt5.QtWidgets import (QMainWindow, QFileDialog, QApplication, QPushButton, QVBoxLayout, QWidget)
from os.path import expanduser
import sys

class FileWindow(QMainWindow):
    def __init__(self, parent=None):#--------------
        '''
        super(FileWindow, self).__init__(parent)#  |
        self.setWindowTitle("open file dialog")#   |							   |
        btn = QPushButton("Search")#            |---- Just initialization
        layout = QVBoxLayout()#					   |
        layout.addWidget(btn)#                     |
        widget = QWidget()#                        |
        widget.setLayout(layout)#                  |
        self.setCentralWidget(widget)#-------------

        btn.clicked.connect(self.getFolder) # connect clicked to self.open()
        self.show()
        '''
        self.getFolder()

    def open(self):
        # gets full file name
        path = QFileDialog.getOpenFileName(self, 'Open a file', '',
                                        'All Files (*.*)')
        if path != ('', ''):
            print("File path : "+ path[0])

    def openFolder(self):
        # gets selected drive letter
        path = QFileDialog.getExistingDirectory(self, 'Open a folder', '')
        if path != ('', ''):
            print("Folder path : "+ path[0])

    def getFolder(self):

        # path = QFileDialog.getExistingDirectory(self, ("Select Output Folder"), QDir.currentPath());
        path = QFileDialog.getExistingDirectory(None, 'Select a folder:', expanduser("~"))


        if path != ('', ''):
            print("Folder path : " + path)
'''
if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = FileWindow()
    sys.exit(app.exec_())

'''