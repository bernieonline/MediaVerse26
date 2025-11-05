import sys
from PyQt5.QtWidgets import QApplication, QWidget, QLabel, QVBoxLayout

class MyPanel(QWidget):
    def __init__(self):
        super().__init__()
        self.initUI()

    def initUI(self):
        self.setWindowTitle('My PyQt5 Panel')
        self.setGeometry(100, 100, 400, 300)

        layout = QVBoxLayout()

        label = QLabel('This is my PyQt5 panel', self)
        layout.addWidget(label)

        self.setLayout(layout)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    panel = MyPanel()
    panel.show()
    sys.exit(app.exec_())

