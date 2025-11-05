import platform #get_os_type
import tkinter as tk #getSourcePath
from tkinter import filedialog #getSourcePath
import os #getSourcePath
import hashlib

#This function returns the name of the OS - Windows, Linux or Darwin for Mac
#tested on Linux and works OK
def get_os_type():
    os_name = platform.system()
    if os_name == 'Windows':
        return 'Windows'
    elif os_name == 'Darwin':  # macOS is identified as 'Darwin'
        return 'macOS'
    elif os_name == 'Linux':
        return 'Linux'
    else:
        return 'Unknown'



def getSourcePath():
    root = tk.Tk()
    root.withdraw()  # Hide the root window
    folder_selected = filedialog.askdirectory()
    if folder_selected:
        return folder_selected
    return 





def calculate_md5(source, chunk_size=8192):
    """
    Calculate the MD5 checksum of a file in chunks.

    :param source: Path to the file for which the checksum is calculated.
    :param chunk_size: Size of each chunk to read from the file (default: 8192 bytes).
    :return: MD5 checksum as a hexadecimal string.
    """
    md5_hash = hashlib.md5()
    print("Opening source for checksum calculation:", source)
    
    try:
        with open(source, "rb") as a_file:
            while chunk := a_file.read(chunk_size):
                md5_hash.update(chunk)
    except (FileNotFoundError, OSError) as e:
        print(f"Error reading file {source}: {e}")
        return None

    digest = md5_hash.hexdigest()
    return digest
'''
if __name__ == "__main__":
    # Example usage
    source_file = "path/to/your/large/file"
    checksum = calculate_md5(source_file)
    if checksum:
        print(f"MD5 checksum: {checksum}")
    else:
        print("Failed to calculate checksum.")

# Example usage
if __name__ == "__main__":
        #get os type
        #operatingSys = get_os_type()
        #print("OS is:", operatingSys)


        #get chosen source
        folder_path = getSourcePath()
        if folder_path:
            print("Selected folder:", folder_path)
        else:
            print("No folder selected.")
'''