#import win32api
#win32api will only work with windows
import os
import os.path
from PyQt5.QtWidgets import QMessageBox
from PyQt5.QtWidgets import QApplication, QWidget, QInputDialog, QLineEdit, QFileDialog
import hashlib
import shutil
import sys
import psutil

# This is my modified file
# I need to test the OS and depending on the result replace the win32 aspect with cross platform alternatives


def drive_list():
    drives = []
    partitions = psutil.disk_partitions(all=True)
    for partition in partitions:
        # Filter out system mounts by checking the mount point
        if partition.fstype and 'loop' not in partition.device and not partition.mountpoint.startswith('/sys') and not partition.mountpoint.startswith('/proc') and not partition.mountpoint.startswith('/dev') and not partition.mountpoint.startswith('/run'):
            drives.append(partition.device)
    return drives

# Example usage
#if __name__ == "__main__":
#    available_drives = drive_list()
 #   print("Available drives:", available_drives)

    
 
#windows original code
#def drive_list():   #replaced by drive_list_all_os
    # The return value is a single string, with each drive letter NULL terminated.
    #drives = win32api.GetLogicalDriveStrings()
    # Use "s.split('\\0')" to split into components.
    #drives = drives.split('\000')[:-1]
    #if len(drives)==0:
    #   warningMessagePopUp("Drive List Error", "No connected drives found")
    #else:
    #   return drives


# this function takes a filename and gets its size bytes
def get_file_size_in_bytes(file_path):
    """ Get size of file at given path in bytes"""
    size = 0
    try:
        size = os.path.getsize(file_path)
    except OSError:
        size = 0

    if size == 0:
        # print("ok size is ", str(size))
        # warningMessagePopUp("File path error", "No size found")
        return 0
    else:
        # print("size is ", str(size))
        return size


def warningMessagePopUp(message_description, further_details):
    msg = QMessageBox()
    msg.setIcon(QMessageBox.Information)
    msg.setText("Warning")
    msg.setInformativeText(message_description)
    msg.setWindowTitle("Warning")
    msg.setDetailedText(further_details)
    msg.setStandardButtons(QMessageBox.Ok)
    # this displays the message
    x = msg.exec_()

# copy file to a destination
def copyFile(source, dest):
    # check available space before moving
    # get checksum before and after

    original = source
    target = dest

    dirname = os.path.dirname(dest)

    total, used, free = shutil.disk_usage(dirname)
    print(total/(1000000000), used/1000000000, free/1000000000)

    size = get_file_size_in_bytes(source)
    print("size is ", size/1000000000)

    print("free space :",free/1000000000 ,"space needed :",size/1000000000)

    if size > free:
        warningMessagePopUp("not enough space", dest)
        sys.exit()
    checkBefore = getCheckSum(source)
    print(checkBefore)
    try:
        shutil.copyfile(original, target)

    except Exception as error:
        print(error)

    checkAfter = getCheckSum(dest)
    print(checkAfter)

    if checkBefore == checkAfter:
        print("md5 ok ")
    else:
        print("md5 not ok ")

# get filename.ext
def checkExists (filePath):
    result = os.path.exists(filePath)
    return result


def getBaseName (filePath):
    basename = os.path.basename(filePath)
    return basename


def getStopPosition(fileName):
    # removes file extension from filename
    name = os.path.splitext(fileName)[0]
    return name


def pickFolderName():
    try:
        path = str(QFileDialog.getExistingDirectory(None, "", 'c:\\', QFileDialog.ShowDirsOnly))
    except Exception as err:
        print(err)

    return path


def pickFileName():
    try:
        path = QFileDialog.getOpenFileName(None, 'Open a file', 'W:\\')
    except Exception as err:
        print(err)

    return path[0]


# clacs MD5 Checksum
def getCheckSum(source):

    # filename = input("Enter the input file name: ")
    md5_hash = hashlib.md5()
    a_file = open(source, "rb")
    content = a_file.read()
    md5_hash.update(content)
    digest = md5_hash.hexdigest()

    return digest


def get_os_name():
    os_name = os.name
    if os_name == 'posix':
        return 'Unix-like OS'
    elif os_name == 'nt':
        return 'Windows OS'
    else:
        return 'Unknown OS'

#print(get_os_name())
