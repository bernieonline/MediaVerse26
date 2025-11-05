# File Path: collection_check.py

from PyQt5.QtWidgets import QMessageBox
from dbMySql import db_utils
from dbMySql.db_utils import get_latest_collection

def existing_collection(device_name, start_path, parent=None):
    """
    Checks if a collection already exists for the given device and path.
    
    If a match is found, displays a message box to the user.
    
    Args:
        device_name (str): Name of the device.
        start_path (str): Path being searched.
        parent: Parent widget for the QMessageBox.
    
    Returns:
        bool: True if user wants to continue, False if user wants to abort.
    """
    print("getting collection check details")
    collections = get_latest_collection(device_name, start_path)
    print("got collection check details")

    if collections:
        # Prepare the message text
        messages = []
        for table, coll_date in collections:
            messages.append(f"This collection already exists in the `{table}` table.\n"
                            f"Collection was created on {coll_date}")

        full_message = "\n\n".join(messages) + "\n\nDo you want to continue?"

        # Create and configure the message box
        msg = QMessageBox(parent)
        msg.setIcon(QMessageBox.Warning)
        msg.setWindowTitle("Collection Already Exists")
        msg.setText(full_message)
        msg.setStandardButtons(QMessageBox.Yes | QMessageBox.Abort)
        msg.setDefaultButton(QMessageBox.Abort)

        # Execute the message box and capture the response
        response = msg.exec_()

        if response == QMessageBox.Abort:
            return collections, False  # User chose to abort

    return collections, True