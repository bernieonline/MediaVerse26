from __future__ import unicode_literals, print_function
import sys
import os
import threading
from datetime import datetime
from pathlib import Path
from errorLibrary import errorLibrary as errLib
import MiscFunctions as msf

def background(f):
    '''
    a threading decorator
    use @background above the function you want to run in the background
    '''
    def bg_f(*a, **kw):
        threading.Thread(target=f, args=a, kwargs=kw).start()
    return bg_f


# converts format - not used yet
def convFile():
    ffConf = ['b:\\movie_test\\Hornblower.m2ts', 'b:\\movie_test\\City.m2ts', 'b:\\movie_test\\Genghis.m2ts']
    p = 0
    for input in ffConf:
        # need to strip extwnsio from input to create a base filename then add type to convert to
        # cmd = 'ffmpeg -i ' + input + '-qscale 0 ' + input - ext +mp4 '
        #os.system(cmd)
        p = p + 1

#must make sure that background function is listed ahead of the function to be used

def checkError(file):
    now = datetime.now()
    print("entering check error..for full file path...", file,"...",now)
    '''
    the decorator allows this method to run in the backgroundd
    it builds a command that is placed in an os.system call
    :param mid:
    :param file:
    :return:
    '''

    filename = Path(file).stem
    print("filename is ", filename)
    cmd = 'ffmpeg -v error -i "'+file+'" -map 0:1 -f null - 2>b:\\filexx.log -hide_banner'

    try:
        print("here....................")
        os.system(cmd)
    except OSError as error:
        print(error)
        f = open("db:\\filexx.log", "w")
        f.write("FFMPEG Failed")
        f.close()
        msf.warningMessagePopUp("FFMEG Failed",filename)



    print("here 2 ..............")
    conf = trimErrorLog(filename)
    print("checkError complete :", now)

    return(conf)

# remove errors from the results report that are unimportant
def trimErrorLog(filename):

    # get list of errors to be tested against
    myLog = errLib()
    myLib = myLog.createFinalList()

    # progarm FAILS here
    # file is not created

    tempFile = "B:\\"+filename+".txt"


    print("create tempfile in trim section ", tempFile)

    result = "Fail"

    writepath = tempFile  
    mode = 'a' if os.path.exists(writepath) else 'w'
   
    with open("B:\\filexx.log", 'r') as read_obj, open(tempFile, mode) as write_obj:
        # read each line
        for line in read_obj:
            message = line
            # strip blank spaces fore and aft
            message = message.strip()
            # ignore the [] brackets and everything inside them
            lineStrip = myLog.truncString(message)
            # remove blanks again
            lineStrip = lineStrip.strip()

            # check to see if the stripped line of text is in our list of errors to be ignored
            if lineStrip in myLib:
                print("skipping...",line)
            else:
                # I had trouble filtering out this line of text so put it in here and worked OK
                if "Last message repeated" in line:
                    None
                else:
                    write_obj.write(line)

        read_obj.close()
        write_obj.close()

        if os.path.exists(writepath):
            result = "Success"
        else:
            result = "Fail"

        print ("created output file for sql ", result)


    ##os.remove("B:\\filexx.log")
    return(result)

# not really used now with Mediainfo replacing it
def getMeta(input):
    # gets limited FFMPEG meta data better using mediaInfo- not used now
    cmd = 'ffmpeg -i "' + input + ' "-f ffmetadata 2> b:\meta2file.log -hide_banner'
    os.system(cmd)

# plays movie for visual inspection
def playMovie(input):
    '''
    used to play a movie for a visual test'''
    # MPC Player
    cmd = "mpc-hc64.exe " + '"'+(input)+'" /play'
    os.chdir('C:\\Program Files\\MPC-HC\\')
    os.system(cmd)

# displays mediainfo of a file
def mediaInfoRun(input):
    cmd = "MediaInfo.exe " + '"' + (input) + '"'
    os.chdir('C:\\Program Files\\MediaInfo\\')
    os.system(cmd)



