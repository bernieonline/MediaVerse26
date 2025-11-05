
from PyQt5 import QtWidgets
from dbMySql.db_utils import addNewExtension
from dbMySql import db_utils
from dbMySql.db_utils import get_list_extension_types, get_list_folders, get_list_master_types, getExtList, add_media_type, delete_media_type
from dbMySql.db_utils import add_excluded_folder, delete_excluded_folder, add_master_type,  delete_master_type, addNewExtension, delete_extension_and_type


class EditPanelManager:
    def __init__(self, edit_panel_widget,footer):
        '''edit_panel_widget is the page on which the edit actions are carried out
        and incorporates the many GUI elements we need to interact with Purpose is to allow the user to set standard lists such as excluded folders and extensions other
        than the default options'''
        self.edit_panel_widget = edit_panel_widget
        self.footer = footer
        self.setup_ui()

    def setup_ui(self):
        # Access and manipulate widgets within the EditPanel page

        #MediaType Changes Video, Musid etc
        self.mediaTypeEdit = self.edit_panel_widget.findChild(QtWidgets.QLineEdit, "mediaTypeEdit")
        self.addMediaTypeButton = self.edit_panel_widget.findChild(QtWidgets.QPushButton, "addMediaTypeButton")
        self.removeMediaTypeCombo = self.edit_panel_widget.findChild(QtWidgets.QComboBox, "removeMediaTypeCombo")
        self.removeMediaTypeButton = self.edit_panel_widget.findChild(QtWidgets.QPushButton, "removeMediaTypeButton")

        #Excluded Folders
        self.excludeFoldersEdit = self.edit_panel_widget.findChild(QtWidgets.QLineEdit, "excludeFoldersEdit")
        self.addFoldersButton = self.edit_panel_widget.findChild(QtWidgets.QPushButton, "addFoldersButton")
        self.removeFoldersCombo = self.edit_panel_widget.findChild(QtWidgets.QComboBox, "removeFoldersCombo")
        self.removeFoldersButton = self.edit_panel_widget.findChild(QtWidgets.QPushButton, "removeFoldersButton")

        #Master Collection Types eg Master Clone Secondary
        self.addMasterTypeEdit = self.edit_panel_widget.findChild(QtWidgets.QLineEdit, "addMasterTypeEdit")
        self.addMasterTypeButton = self.edit_panel_widget.findChild(QtWidgets.QPushButton, "addMasterTypeButton")
        self.removeMasterTypeCombo = self.edit_panel_widget.findChild(QtWidgets.QComboBox, "removeMasterTypeCombo")
        self.removeMasterTypeButton = self.edit_panel_widget.findChild(QtWidgets.QPushButton, "removeMasterTypeButton")

        # Edit File Extension list
        self.addFileExtEdit = self.edit_panel_widget.findChild(QtWidgets.QLineEdit, "addFileExtEdit")
        self.selectMediaTypeCombo = self.edit_panel_widget.findChild(QtWidgets.QComboBox, "selectMediaTypeCombo")
        self.addExtButton = self.edit_panel_widget.findChild(QtWidgets.QPushButton, "addExtButton")
        self.removeExtCombo = self.edit_panel_widget.findChild(QtWidgets.QComboBox, "removeExtCombo")
        self.removeExtButton = self.edit_panel_widget.findChild(QtWidgets.QPushButton, "removeExtButton")
        
        '''
        # Connect signals to slots
        self.addMediaTypeButton.clicked.connect(self.add_media_type)
        self.removeMediaTypeButton.clicked.connect(self.remove_media_type)
        self.addFoldersButton.clicked.connect(self.add_folder)
        self.removeFoldersButton.clicked.connect(self.remove_folder)
        self.addMasterTypeButton.clicked.connect(self.add_master_type)
        self.removeMasterTypeButton.clicked.connect(self.remove_master_type)
        self.addExtButton.clicked.connect(self.addExt)
        self.removeExtButton.clicked.connect(self.remove_ext)

        '''

        #Methods to run from Button clicks
        self.addMediaTypeButton.clicked.connect(self.addMediaType)
        self.removeMediaTypeButton.clicked.connect(self.removeMediaType)
        self.addFoldersButton.clicked.connect(self.addFolder)
        self.removeFoldersButton.clicked.connect(self.removeFolder)
        self.addMasterTypeButton.clicked.connect(self.addMasterType)
        self.removeMasterTypeButton.clicked.connect(self.removeMasterType)
        self.addExtButton.clicked.connect(self.addNewExt)
        self.removeExtButton.clicked.connect(self.removeExt)

        
        
        self.loadCombos()

    def addMediaType(self):
        item = self.mediaTypeEdit.text().strip()
        print(item)
        self.mediaTypeEdit.clear()

        if not item:
            self.footer.append("No media type entered. Please enter a valid media type.")
            return

        result = add_media_type(item)

        if result:
            self.footer.append(f"New Type Added: {item}")
        else:
            self.footer.append("New Type failed to create a record.")

        self.loadCombos()

    def removeMediaType(self):
        item = self.removeMediaTypeCombo.currentText()
        print(item)
        self.removeMediaTypeCombo.setCurrentIndex(0)

        if not item:
            self.footer.append("No media type entered for removal. Please enter a valid media type.")
            return

        result = delete_media_type(item)

        if result:
            self.footer.append(f" Type Removed: {item}")
        else:
            self.footer.append("New Type failed to remove.")

        self.loadCombos()
    
    def addFolder2(self):
        print("inside edit function")


    def addFolder(self):
        item = self.excludeFoldersEdit.text()
        print(item)
        
        self.excludeFoldersEdit.clear()

        if not item:
            self.footer.append("No folder name  entered. Please enter a valid folder name.")
            return
        
        result = add_excluded_folder(item)

        if result:
            self.footer.append(f"New Folder Added: {item}")
        else:
            self.footer.append("New Folder failed to create a record.")

        self.loadCombos()


    def removeFolder(self):
        item = self.removeFoldersCombo.currentText()
        print("removing folder ",item)
        self.removeFoldersCombo.setCurrentIndex(0)

        if not item:
            self.footer.append("No folder entered for removal. Please enter a valid folder name.")
            return
        
        result = delete_excluded_folder(item)

        if result:
            self.footer.append(f" Folder Removed: {item}")
        else:
            self.footer.append(" Folder failed to remove.")

        self.loadCombos()


    def addMasterType(self):
        item = self.addMasterTypeEdit.text()
        print(item)
        self.addMasterTypeEdit.clear()

        if not item:
            self.footer.append("No master type  entered. Please enter a valid type name.")
            return
        
        result = add_master_type(item)

        if result:
            self.footer.append(f"New master Type Added: {item}")
        else:
            self.footer.append("New Master Type failed to create a record.")

        self.loadCombos()

    def removeMasterType(self):
        item = self.removeMasterTypeCombo.currentText()
        print(item)
        self.removeMasterTypeCombo.setCurrentIndex(0)

        if not item:
            self.footer.append("No master type entered for removal. Please enter a valid type name.")
            return
        
        result = delete_master_type(item)

        if result:
            self.footer.append(f" Master Type Removed: {item}")
        else:
            self.footer.append(" Master Type failed to remove.")

        self.loadCombos()


    def addNewExt(self): 
        itemA = self.addFileExtEdit.text()
        print(itemA)
        self.addFileExtEdit.clear()

        itemB = self.selectMediaTypeCombo.currentText()
        print(itemB)
        self.selectMediaTypeCombo.setCurrentIndex(0)

        if not itemA:
            self.footer.append("No extension type  entered. Please enter a valid extension name.")
            return
        
        result = addNewExtension(itemB, itemA)

        if result:
            self.footer.append(f"New extension  Added: {itemA}")
        else:
            self.footer.append("New Extension failed to create a record.")

        self.loadCombos()





    def removeExt(self):
        item = self.removeExtCombo.currentText()
        print(item)
        self.removeExtCombo.setCurrentIndex(0)


        if not item:
            self.footer.append("No extension type entered for removal. Please enter a valid extension name.")
            return
        print("about to run delete_extension_and_type")
        result = delete_extension_and_type(item)

        if result:
            self.footer.append(f" Extension and Type Removed: {item}")
        else:
            self.footer.append(" Extension and Type failed to remove.")

        self.loadCombos()





    def loadCombos(self):

        print("loading combos")

        #combo box remove Media Type
        selectMediaTypeComboList = get_list_extension_types()   #returns distinct list of media types
        self.removeMediaTypeCombo.clear()                       #clear the list
        for media_type in selectMediaTypeComboList:             #iterate through adding item sto combo
            self.removeMediaTypeCombo.addItem(media_type)

        
        self.selectMediaTypeCombo.clear()                       #clear the list
        for media_type in selectMediaTypeComboList:             #iterate through adding item sto combo
            self.selectMediaTypeCombo.addItem(media_type)
 

        #remove Excluded Folder Combo
        selectFolderComboList = get_list_folders()
        self.removeFoldersCombo.clear()
        for folder in selectFolderComboList:
            self.removeFoldersCombo.addItem(folder)

        #remove master type eg Master, Clone. Secondary
        selectMasterComboList = get_list_master_types()
        self.removeMasterTypeCombo.clear()
        for master in selectMasterComboList:
            self.removeMasterTypeCombo.addItem(master)

        #remove extension type
        selectedExtTypes = getExtList()
        self.removeExtCombo.clear()
        for ext in selectedExtTypes:
            self.removeExtCombo.addItem(ext)


    # Button Click Methods
    def addExt(self):
        new_extension = self.addFileExtEdit.text()
         # Get the text from the QLineEdit and strip any whitespacedesigner
        new_extension = self.addFileExtEdit.text().strip()

         # Ensure the first character is a dot
        if not new_extension.startswith('.'):
            new_extension = '.' + new_extension
        
        type_ = self.selectMediaTypeCombo.currentText()

        addExtRecord = addNewExtension(type_,new_extension)

        if addExtRecord:
            self.footer.append(f"The database action completed successfully for {new_extension}.")
        else:
            self.footer.append(f"The database action did not complete for {new_extension}.")

    def remove_ext(self):
        ext = self.removeExtCombo.currentText()

    def add_master_type(self):
        #Master Clone Secondary
        master_type = self.addMasterTypeEdit.text()

    def remove_master_type(self):
         #Master Clone Secondary
        master_type =  self.removeExtCombo.currentText()

    def add_folder(self):
        folder_name = self.excludeFoldersEdit.text()

    def remove_folder(self):
        folder_name = self.removeFoldersCombo.currentText()

    def add_media_type(self):
        # Logic to add a media type video. music etc
        media_type = self.mediaTypeEdit.text()
        print(f"Adding media type: {media_type}")

    def remove_media_type(self):
        # Logic to remove a media type video. music etc
        media_type = self.removeMediaTypeCombo.currentText()
        print(f"Removing media type: {media_type}")
