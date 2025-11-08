import os


print("✅ myPyForQMLFunctions.py loaded")
#this function will receive input from qml when user selects a library folder
#  and will return a list of folders inside the library
def get_subfolder_names_test(path):
    """
    Returns a tuple of folder names inside W:\Collection for testing.
    """
    print("trying to get image files........")
    test_path = "W:\\Collection"
    try:
       
        folder_names = tuple(
            entry for entry in os.listdir(test_path)
            if os.path.isdir(os.path.join(test_path, entry))
        )
        print(f"✅ Folders in {test_path}: {folder_names}")
        return folder_names
    except Exception as e:
        print(f"❌ Error accessing {test_path}: {e}")
        return ()