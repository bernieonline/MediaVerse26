import os
from pathlib import Path
from datetime import datetime
import subprocess
import ffmpegFunc
from ffmpegFunc import checkError
#from dbMySql import db_utils
from dbMySql.db_utils import getAPath




def main():

    file_path_raw = getAPath()
    
    print("got a path: ",  file_path_raw)
    file_path = 'W:\\Collection\\1960s 70s 80s\\City Heat (1984).mp4'
    result = checkError(file_path)

    log_file_path = "D:\\filexx.log"
    if result == "Success":
        with open(log_file_path, 'r') as log_file:
            log_content = log_file.read()
            if not log_content.strip():
                print("No errors found", "The video file has no errors.")
            else:
                print("output recordsd")
                os.startfile(log_file_path)

if __name__ == "__main__":
    main()