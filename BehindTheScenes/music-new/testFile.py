from PyQt5.QtWidgets import QApplication, QPushButton, QFileDialog, QVBoxLayout, QWidget

class TestApp(QWidget):
    def __init__(self):
        super().__init__()
        self.init_ui()

    def init_ui(self):
        self.fileDialogOpen = False
        self.button = QPushButton("Open File Dialog", self)
        self.button.clicked.connect(self.on_viewFFFileButton_clicked)

        layout = QVBoxLayout()
        layout.addWidget(self.button)
        self.setLayout(layout)

    def on_viewFFFileButton_clicked(self):
        if self.fileDialogOpen:
            print("File dialog is already open.")
            return

        self.fileDialogOpen = True
        try:
            print("Opening file dialog...")
            file_path, _ = QFileDialog.getOpenFileName(self, "Select a File", "W:\\Collection", "Text Files (*.txt)")
            if file_path:
                print(f"Selected file: {file_path}")
            else:
                print("No file selected.")
        finally:
            self.fileDialogOpen = False

if __name__ == "__main__":
    import sys
    app = QApplication(sys.argv)
    mainWin = TestApp()
    mainWin.show()
    sys.exit(app.exec_())
