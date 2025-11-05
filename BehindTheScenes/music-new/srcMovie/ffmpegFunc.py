from __future__ import unicode_literals, print_function
import sys
import os
import threading
from datetime import datetime
from pathlib import Path
from srcMovie.errorLibrary import errorLibrary as errLib
import subprocess
import select
from PyQt5.QtCore import pyqtSignal, QObject, QThread
from PyQt5.QtWidgets import QTextEdit, QProgressBar
from PyQt5.QtCore import QCoreApplication
from PyQt5.QtWidgets import QFileDialog
#the pymediainfo package is installed
from pymediainfo import MediaInfo
# import MiscFunctions as msf


'''Decorator Definition: The background function is defined to take a function f as an argument. This is typical for decorators, which are functions that modify the behavior of other functions.
Inner Function bg_f: Inside background, there's another function bg_f defined. This function takes any number of positional (*a) and keyword arguments (**kw), which it will pass to the function f.
Thread Creation: Within bg_f, a new thread is created using threading.Thread. The target parameter is set to the function f, and the args and kwargs are set to the arguments passed to bg_f.
Thread Start: The thread is started immediately with the start() method, which means the function f will run concurrently in the background.
Return bg_f: The background function returns the bg_f function, effectively replacing the original function f with bg_f when the decorator is applied
By using the @background decorator above a function, you can execute that function asynchronously, allowing the main program to continue running without waiting for the function to complete.
This is useful for tasks that can run independently, such as I/O operations or long computations.'''

class FFmpegWorker(QThread):
    ''' runs ffmpeg check error and trim program'''
    output_signal = pyqtSignal(str)
    finished_signal = pyqtSignal()

    def __init__(self, file):
        super().__init__()
        self.file = file

    def run(self):
        now = datetime.now()
        print("Entering check error for full file path:", "...", now)
        
        filename = Path(self.file).stem
        print("Filename is:", filename)

        # 1. Emit and log the full path/filename at the very beginning.
        final_log_path = Path(self.file).with_name(f"{filename}.txt")
        self.output_signal.emit(f"Processing file: {self.file}")
        with open(final_log_path, "a", encoding="utf-8") as final_log:
            final_log.write(f"Processing file: {self.file}\n")


        cmd = ['ffmpeg', '-v', 'error', '-nostdin', '-i', self.file, '-map', '0:1', '-f', 'null', '-']
        print("Command is:", ' '.join(cmd))


        output_file_path = f"D:/filexx.txt"
        with open(output_file_path, 'w') as output_file:

            try:
                print("Beginning process command:")
                process = subprocess.Popen(cmd, stderr=subprocess.PIPE, text=True, bufsize=1, universal_newlines=True)
                print("past process command:")

                # Read the output line by line
                while True:
                    line = process.stderr.readline()
                    if line:
                        self.output_signal.emit(line.strip())  # Emit signal to update QTextEdit
                        print(line.strip(), flush=True)
                        output_file.write(line)  # Write to file
                    else:
                        break
                print("end of while print  command:")

                process.stderr.close()
                process.wait()

                if process.returncode != 0:
                    print("failed ffmpeg :")
                    self.output_signal.emit("FFMPEG Failed")
                    print("FFmpeg failed with return code:", process.returncode)
                    output_file.write(f"FFmpeg failed with return code: {process.returncode}\n")

            except Exception as e:
                print("An error occurred:", e)
                self.output_signal.emit(f"Error: {e}")
                output_file.write(f"Error: {e}\n")

            # Signal that the process has finished
            self.finished_signal.emit()
        
        print("beginning trimerror:", filename)

        #conf = trimErrorLog(filename)
        input_path = Path(self.file)
        conf = trimErrorLog(input_path)


        print("trimerror complete:", now)

        # Append MediaInfo data
        try:
            media_info = MediaInfo.parse(self.file)
            self.output_signal.emit("MediaInfo data:")
            with open(final_log_path, "a", encoding="utf-8") as final_log:
                final_log.write("\n=== MediaInfo Results ===\n")

                for track in media_info.tracks:
                    # Build a list of details, then join them
                    details = []

                    if track.track_type == "General":
                        details.append("General:")
                        # Basic fields
                        if getattr(track, "format", None):
                            details.append(f"Format={track.format}")
                        if getattr(track, "duration", None):
                            details.append(f"Duration={track.duration}ms")
                        if getattr(track, "file_size", None):
                            details.append(f"Size={track.file_size} bytes")

                    elif track.track_type == "Video":
                        details.append("Video:")
                        # Basic fields
                        if getattr(track, "format", None):
                            details.append(f"Codec={track.format}")
                        if getattr(track, "width", None):
                            details.append(f"Width={track.width}")
                        if getattr(track, "height", None):
                            details.append(f"Height={track.height}")
                        if getattr(track, "duration", None):
                            details.append(f"Duration={track.duration}ms")

                        # Optional fields
                        if getattr(track, "frame_rate", None):
                            details.append(f"FrameRate={track.frame_rate}")
                        if getattr(track, "bit_rate", None):
                            details.append(f"BitRate={track.bit_rate}")
                        if getattr(track, "display_aspect_ratio", None):
                            details.append(f"DisplayAspectRatio={track.display_aspect_ratio}")
                        if getattr(track, "bit_depth", None):
                            details.append(f"BitDepth={track.bit_depth}")
                        if getattr(track, "scan_type", None):
                            details.append(f"ScanType={track.scan_type}")

                    elif track.track_type == "Audio":
                        details.append("Audio:")
                        if getattr(track, "format", None):
                            details.append(f"Codec={track.format}")
                        if getattr(track, "channel_s", None):
                            details.append(f"Channels={track.channel_s}")
                        if getattr(track, "sampling_rate", None):
                            details.append(f"SampleRate={track.sampling_rate}Hz")

                    else:
                        # For other track types
                        details.append(f"Other track: {track.track_type}")

                    # Final joined string
                    detail_str = ", ".join(details)
                    self.output_signal.emit(detail_str)
                    final_log.write(detail_str + "\n")

        except Exception as e:
            err_message = f"Failed to parse MediaInfo: {e}"
            self.output_signal.emit(err_message)

        # Signal completion
        self.finished_signal.emit()

        

        #return conf

def viewError(escaped_file_path, error_textpane):
    """
    Reads the content of an error and media info file and displays it in the provided text pane.

    :param escaped_file_path: The path to the text file to be displayed.
    :param error_textpane: The QTextEdit widget where the file content will be displayed.
    """
    print("Entering view method")
    try:
        # Open the file in read mode
        with open(escaped_file_path, 'r') as file:
            # Read the entire content of the file
            content = file.read()
        
        # Set the content to the text pane
        error_textpane.setPlainText(content)
        print(f"Content of {escaped_file_path} displayed in text pane.")

    except FileNotFoundError:
        error_textpane.setPlainText("Error: File not found.")
        print(f"Error: {escaped_file_path} not found.")

    except Exception as e:
        error_textpane.setPlainText(f"An error occurred: {e}")
        print(f"An error occurred while reading {escaped_file_path}: {e}")

def background(f):
    '''
    a threading decorator
    use @background above the function you want to run in the background
    '''
    def bg_f(*a, **kw):
        threading.Thread(target=f, args=a, kwargs=kw).start()
    return bg_f


# converts format - not used yet
def convFile(file):
   print("converting file")



def checkError(file, error_textpane):
    print("into checkerror")
    worker = FFmpegWorker(file)
    print("initiated thread")

    # Connect the output signal to update the text pane
    worker.output_signal.connect(error_textpane.append)
    print("signal to footer established")
    return worker

# remove errors from the results report that are unimportant
def trimErrorLog(file):
    input_path = Path(file)
    print("trimerror input_path: Create tempfile in trim section", input_path)
    filename = Path(file).stem      #name only
    myLog = errLib()
    myLib = myLog.createFinalList()

    logfile = input_path.with_name(f"{filename}.txt")
    print("trimerror : Create logfile in trim section", logfile)

    result = "Fail"
    writepath = logfile
    mode = 'a' if os.path.exists(writepath) else 'w'
    print("ready to process file")
    try:
        with open("D:\\filexx.txt", 'r') as read_obj, open(logfile, mode) as write_obj:
            for line in read_obj:
                message = line.strip()
                lineStrip = myLog.truncString(message).strip()

                if lineStrip in myLib:
                    print("Skipping...", line)
                elif "Last message repeated" not in line:
                    write_obj.write(line)

        if os.path.exists(writepath):
            print("All seems to be ok")
            result = "Success"
        else:
            print("All seems to be  NOT ok")
            result = "Fail"

        print("Created output file for trimerror sql", result)

    except Exception as e:
        print(f"An error occurred while trimming the error log: {e}")

    return result

# not really used now with Mediainfo replacing it
def getMeta(input):
    # gets limited FFMPEG meta data better using mediaInfo- not used now
    cmd = 'ffmpeg -i "' + input + ' "-f ffmetadata 2> b:\meta2file.log -hide_banner'
    os.system(cmd)



def playMovieWithPowerDVD(filename):
    """
    Plays a video file using CyberLink PowerDVD.
    
    :param filename: The path to the video file to be played.
    """
    # Path to the PowerDVD executable
    powerdvd_path = r"C:\Program Files\CyberLink\PowerDVD20\PowerDVD.exe"
    
    # Ensure the file exists
    if not os.path.isfile(filename):
        raise FileNotFoundError(f"The file {filename} does not exist.")
    
    # Command to open the video file with PowerDVD
    cmd = [powerdvd_path, filename]
    
    # Execute the command
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while trying to play the video: {e}")

# Example usage
# playMovieWithPowerDVD("C:\\path\\to\\your\\video.mp4")

# displays mediainfo of a file
def mediaInfoRun(input):
    cmd = "MediaInfo.exe " + '"' + (input) + '"'
    os.chdir('C:\\Program Files\\MediaInfo\\')
    os.system(cmd)





def repairError(filename, footer):
    '''To repair a file using FFmpeg, you can use the basic command ffmpeg -i "input_file" -c copy "output_file"
    which essentially rewrites the file's container structure, often fixing issues with playback by copying the
    video and audio streams without re-encoding them, effectively "remuxing" the file to a new container format;
    important to note that this method only works if the corruption is related to the container structure and 
    not missing data within the file; you can try different output container formats (like MP4, MKV)
    depending on the original file type to see if it helps with playback issues.
                
    Basic command: ffmpeg -i "input_file" -c copy "output_file" 
                
    Try converting the file to a different container format (like MP4, MKV) to see if that resolves playback issues. 
    Use Repair Command: Use a command like this: ffmpeg -i corrupted.mp4 -c copy fixed.mp4
        
    If you need to fix only the video or audio stream, use -c:v copy or -c:a copy respectively. 

    Re-encoding for severe corruption:
    For heavily corrupted files, you might need to re-encode the video and audio streams with appropriate codecs using different
    options like -c:v libx264 or -c:a aac. 
                       
    '''
    file = filename
   
    now = datetime.now()
    footer.append(f"Conversion commenced at {now}")
    QCoreApplication.processEvents()  
    print("Entering file repair for full file path:", "...", now)
 
    # Create the output file name with '_repair.mp4'
    filename_path = Path(filename)
    output_file = filename_path.with_name(filename_path.stem + '_repair.mp4')
    
    print("Filename is:", filename_path.stem)
    print("Output Filename is:", output_file)

 

    cmd = ['ffmpeg', '-i', str(filename_path), '-c', 'copy', str(output_file)]
    print("Command is:", ' '.join(cmd))

    try:
        print("Beginning process command:")
        process = subprocess.Popen(cmd, stderr=subprocess.PIPE, text=True, bufsize=1, universal_newlines=True)
        stdout, stderr = process.communicate()
        if process.returncode != 0:
            print("FFmpeg error:", stderr)
            footer.append(f"Error during conversion: {stderr}")
        else:
            print("File repaired successfully.")
            completion_time = datetime.now()
            footer.append(f"Conversion complete. New file: {output_file} at {completion_time}")

    except Exception as e:
        print("An error occurred:", e)
        footer.append(f"Error: {e}")

        # Signal that the process has finished
   
class RepairWorker(QThread): 
    update_footer = pyqtSignal(str)
    start_progress = pyqtSignal()
    stop_progress = pyqtSignal()  
    def __init__(self, filename, footer, progress_bar):
        super().__init__()
        self.filename = filename
        self.footer = footer
        self.progress_bar = progress_bar

   

    def run(self):
        now = datetime.now()
        self.update_footer.emit(f"Conversion commenced at {now}")
        QCoreApplication.processEvents()

        filename_path = Path(self.filename)
        output_file = filename_path.with_name(filename_path.stem + '_repair.mp4')

        cmd = ['ffmpeg', '-i', str(filename_path), '-c', 'copy', str(output_file)]

        self.start_progress.emit()  # Start progress bar pulsing

        try:
            process = subprocess.Popen(cmd, stderr=subprocess.PIPE, text=True, bufsize=1, universal_newlines=True)
            stdout, stderr = process.communicate()
            if process.returncode != 0:
                self.update_footer.emit(f"Error during conversion: {stderr}")
            else:
                completion_time = datetime.now()
                self.update_footer.emit(f"Conversion complete. New file: {output_file} at {completion_time}")

        except Exception as e:
            self.update_footer.emit(f"Error: {e}")

        finally:
            self.stop_progress.emit()  # Stop progress bar pulsing
































