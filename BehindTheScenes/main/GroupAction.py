
from PyQt5 import QtWidgets as qtw
import MiscFunctions as msf
from GroupAnalysis import Ui_Form
import SQLiteFunction as sql
from PyQt5 import QtWidgets

class getGroupWindow(qtw.QWidget):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)  # class super subclasses QtWidgets on which the form was based

        # we can then use its show feature to display it
        self.ui = Ui_Form()
        self.ui.setupUi(self)

        #Gui objects here

        self.selectFileButton = self.ui.selectFileButton
        self.selectFileButton.clicked.connect(self.getFile)

        self.loadDataButton = self.ui.loadDataButton
        self.loadDataButton.clicked.connect(self.getData)

        self.fileEdit = self.ui.fileEdit    #filename


        self.filename = None

        self.tableWidget = self.ui.tableWidget



    def getFile(self):
        self.filename = msf.pickFileName()
        self.fileEdit.setText(self.filename)


    def getData(self):
        result = sql.getFileGroup(self.filename)
        print(result)
        self.loadTable(result)

    def loadTable(self, result):
        self.tableWidget.setRowCount(0)

        for row_num, row_data in enumerate(result):
            self.tableWidget.insertRow(row_num)
            for col_num, data in enumerate(row_data):
                self.tableWidget.setItem(row_num, col_num, QtWidgets.QTableWidgetItem(str(data)))



