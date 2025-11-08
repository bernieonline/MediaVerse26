import os


print("✅ myPyForQMLFunctions.py loaded")

def get_subfolder_names(base_path):
    """
    Returns a list of tuples, where each tuple contains
    the folder name and its full path.
    """
    if not os.path.isdir(base_path):
        print(f"❌ Error: Path '{base_path}' is not a valid directory.")
        return []
    try:
        subfolders = [
            (entry, os.path.join(base_path, entry))
            for entry in os.listdir(base_path)
            if os.path.isdir(os.path.join(base_path, entry))
        ]
        print(f"✅ Found {len(subfolders)} folders in {base_path}")
        return subfolders
    except Exception as e:
        print(f"❌ Error accessing {base_path}: {e}")
        return []

def get_subfolder_names_test(folder_path="W:\\Collection"):
    """
    Returns a tuple of folder names inside the given path for testing.
    Defaults to W:\Collection if no path is provided.
    """
    try:
        folder_names = tuple(
            entry for entry in os.listdir(folder_path)
            if os.path.isdir(os.path.join(folder_path, entry))
        )
        print(f"✅ Folders in {folder_path}: {folder_names}")
        return folder_names
    except Exception as e:
        print(f"❌ Error accessing {folder_path}: {e}")
        return ()