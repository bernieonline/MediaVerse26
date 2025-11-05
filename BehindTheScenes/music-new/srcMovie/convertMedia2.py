import sys
from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QLabel, QComboBox, QPushButton, QTextEdit, QProgressBar
from PyQt5.QtCore import QThread, pyqtSignal, QTimer
import subprocess
from datetime import datetime
from PyQt5.QtWidgets import QFileDialog
import os

class TranscodeWorker(QThread):
    #setup the signals
    print("......................6")
    progress_signal = pyqtSignal(int)
    message_signal = pyqtSignal(str)
    progressStarted = pyqtSignal()
    progressFinished = pyqtSignal()
    conversionMessage = pyqtSignal(str)
    
    def __init__(self, format_selected, codec_selected, crf_selected, preset_selected, audio_selected, fps_optimization, hwaccel_selected, input_filepath, output_filepath, selected_fps):
        super().__init__()
        self.message_signal.emit("FFmpeg transcoding started thread successfully.")
        self.progressStarted.emit()
        self.format_selected = format_selected
        self.codec_selected = codec_selected
        self.crf_selected = crf_selected
        self.preset_selected = preset_selected
        self.audio_selected = audio_selected
        self.fps_optimization = fps_optimization
        self.hwaccel_selected = hwaccel_selected
        self.input_file = input_filepath
        self.output_file = output_filepath
        self.selected_fps = selected_fps

    def run(self):
        
        print("beginning run")
        # Send start message
        start_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.message_signal.emit(f"Beginning Conversion: {start_time}")
        self.progressStarted.emit()

        #print("fps-:", self.fps_optimization)

        #panel = FFmpegControlPanel()
        #panel.show()

        # Build the FFmpeg command using the user's parameters
        if not self.input_file:
            self.message_signal.emit("No input file selected. Aborting transcoding.")
            return

        # Derive final output path with chosen format
        self.output_file = f"{self.output_file}.{self.format_selected}"

        # Mock FFmpeg transcoding command
        ffmpeg_command = [
            'ffmpeg',
            '-i', self.input_file,
            '-c:v', self.codec_selected,
            '-crf', self.crf_selected,
            '-preset', self.preset_selected
        ]

        if self.codec_selected == "h265":
            ffmpeg_command += ['-tag:v', 'hvc1']

        if self.hwaccel_selected != "auto":
            if "NVENC" in self.hwaccel_selected:
                ffmpeg_command += ['-c:v', 'h264_nvenc']
            elif "VAAPI" in self.hwaccel_selected:
                ffmpeg_command += ['-c:v', 'h264_vaapi']
            elif "QSV" in self.hwaccel_selected:
                ffmpeg_command += ['-c:v', 'h264_qsv']

        if self.audio_selected == "copy lossless":
            ffmpeg_command += ['-c:a', 'copy']
        elif self.audio_selected == "convert to E-AC3 1024k":
            ffmpeg_command += ['-c:a', 'eac3', '-b:a', '1024k']

        
            # Use the explicitly selected FPS if fps_optimizif self.fps_optimization:ation is enabled
            #ffmpeg_command += ['-vf', f"minterpolate=fps={self.selected_fps}"]
            '''minterpolate is an attempt to keep variable frame rate but it doesnt help with some files with crazy fps of over 1000'''

            if self.fps_optimization and self.selected_fps != "0": ffmpeg_command += ['-vf', f"minterpolate=fps={self.selected_fps}"]

        #ffmpeg_command.append(f"output.{self.output_file}")
         # Final output path
        ffmpeg_command.append(self.output_file)

        # Print final command to confirm parameters
        final_command_str = " ".join(ffmpeg_command)
        self.message_signal.emit(f"Final FFmpeg Command:\n{final_command_str}")
        
        print("running ffmpeg command ")
        
        try:
            # Run the command, capturing output for logs if desired
            process = subprocess.Popen(
                ffmpeg_command,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True
            )

            # Read stderr line by line to simulate progress
            while True:
                line = process.stderr.readline()
                if not line and process.poll() is not None:
                    break
                if line:
                    # Here you could attempt to parse percentage from FFmpeg logs
                    # For simplicity, just display the line in the message log
                    self.message_signal.emit(line.strip())

            return_code = process.wait()
            if return_code != 0:
                self.message_signal.emit("FFmpeg finished with an error.")
            else:
                self.message_signal.emit("FFmpeg transcoding completed successfully.")
        except Exception as e:
            self.message_signal.emit(f"An error occurred while running FFmpeg: {e}")



        # Simulate progress updates (in real use case, subprocess will be tracked here)
        for progress in range(1, 101):  # Mock progress from 1 to 100
            self.progress_signal.emit(progress)
            self.msleep(50)  # Simulate time delay

        # Send completion message
        end_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.message_signal.emit(f"Conversion Complete: {end_time}")
        # Emit signal indicating the process finished
        self.progressFinished.emit()


    
class FFmpegControlPanel(QWidget):
    #def __init__(self, parent=None):
    def __init__(self, parent=None, progressBarFF=None):
        super().__init__()
       
        self.progressBarFF = progressBarFF


        self.output_format = None
        self.input_filepath = None
        self.output_filepath = None
        self.layout = QVBoxLayout()

        # Output File Format
        self.layout.addWidget(QLabel("Output Format:"))
        self.format_combo = QComboBox()
        self.format_combo.addItems(["mp4", "mkv", "mov"])
        self.layout.addWidget(self.format_combo)

        # Video Codec (H.264 vs H.265)
        self.layout.addWidget(QLabel("Video Codec:"))
        self.codec_combo = QComboBox()
        self.codec_combo.addItems(["h264", "h265"])
        self.layout.addWidget(self.codec_combo)


        '''In FFmpeg (when using certain codecs like x264 or x265), CRF (Constant Rate Factor) is an encoding parameter that controls 
        the output quality of the video in a rate-control mode called CRF mode. Lower CRF values produce higher-quality (and typically larger) 
        files, while higher CRF values produce lower-quality (and typically smaller) files.
        For example, if you set “-crf 18”, you’ll likely get a higher-quality (but larger) file than “-crf 28”. The CRF scale for x264 generally 
        goes up to 51 (where 0 is almost lossless, and values above about 28 start to look considerably compressed). In practice, typical ranges 
        for high-quality content are around 18–24 for x264.'''
        # CRF Value Selection - 
        self.layout.addWidget(QLabel("CRF Value:"))
        self.crf_combo = QComboBox()
        self.crf_combo.addItems([str(i) for i in range(18, 30)])
        self.layout.addWidget(self.crf_combo)

        # Preset Selection
        self.layout.addWidget(QLabel("Preset:"))
        self.preset_combo = QComboBox()
        self.preset_combo.addItems(["ultrafast", "superfast", "veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow"])
        self.layout.addWidget(self.preset_combo)

        # High-Quality Audio Options
        self.layout.addWidget(QLabel("Audio Quality:"))
        self.audio_combo = QComboBox()
        self.audio_combo.addItems(["auto", "copy lossless", "convert to E-AC3 1024k"])
        self.layout.addWidget(self.audio_combo)

        # Framerate Optimization Checkbox
        # i have left this in place but removed the fps limit so this has no effect
        #and takes the input frame rate
        self.layout.addWidget(QLabel("Optimize Framerate:"))
        self.fps_combo = QComboBox()
        self.fps_combo.addItems(["Yes", "No"])
        self.layout.addWidget(self.fps_combo)



        # Hardware Acceleration Selection
        self.layout.addWidget(QLabel("Hardware Acceleration:"))
        self.hwaccel_combo = QComboBox()
        self.hwaccel_combo.addItems(self.detect_hardware_encoders())
        self.layout.addWidget(self.hwaccel_combo)

        # NEW: Explicit FPS Selection
        self.layout.addWidget(QLabel("Select FPS:"))
        self.fps_force_combo = QComboBox()
        self.fps_force_combo.addItems(["0", "23", "24", "25", "26", "27", "28", "29", "30", "50", "60", "100"])
        self.layout.addWidget(self.fps_force_combo)

        # Start Button
        self.start_button = QPushButton("Start Transcoding")
        self.start_button.clicked.connect(self.start_transcoding)
        self.layout.addWidget(self.start_button)

        # Progress Bar
        self.progress_bar = QProgressBar(self)
        self.layout.addWidget(self.progress_bar)

        # Create a QTimer to pulse the progress bar
        self.pulse_timer = QTimer(self)
        self.pulse_timer.timeout.connect(self.pulse_progress_bar)


        # Footer TextEdit
        self.footer2 = QTextEdit(self)
        self.footer2.setReadOnly(True)
        self.layout.addWidget(self.footer2)

        self.setLayout(self.layout)

        self.getFilePaths()

    def getFilePaths(self):

        # Prompt user to select input file using a file dialog
        print("opening file dialog for convert")
        self.input_filepath, _ = QFileDialog.getOpenFileName(
            None, "Select Media File", "", "Media Files (*.mp4 *.mkv *.mov *.avi *.m4v *.m2ts *.m4v *.ts *.wmv);;All Files (*)"
        )
        print("......................2")
        # If no file selected, set input_file to None so the run step can ignore
        if not self.input_filepath:
            self.input_filepath = None
            return

        # Derive output path from the input file
        input_dir = os.path.dirname(self.input_filepath)
        print("......................")
        base_name, _ = os.path.splitext(os.path.basename(self.input_filepath))
        # Example output filename: "myvideo_converted.mp4"
        # meed to add output format later  from selection
        print("......................4")
        self.output_filepath = os.path.join(input_dir, f"{base_name}_converted")
        print("......................5")
        


    def detect_hardware_encoders(self):
        """Detect available hardware encoders (mocked here for simplicity)."""
        return ["auto", "NVENC (NVIDIA)", "VAAPI (Intel/AMD)", "QSV (Intel)"]

    def start_transcoding(self):
        print("started transcoding button click")
        format_selected = self.format_combo.currentText()
        codec_selected = self.codec_combo.currentText()
        crf_selected = self.crf_combo.currentText()
        preset_selected = self.preset_combo.currentText()
        audio_selected = self.audio_combo.currentText()
        fps_optimization = self.fps_combo.currentText() == "Yes"
        hwaccel_selected = self.hwaccel_combo.currentText()

        # Capture the FPS selection from the new combobox
        selected_fps = self.fps_force_combo.currentText()

        # Instantiate and start worker thread


        self.worker = TranscodeWorker(format_selected, codec_selected, crf_selected, preset_selected, audio_selected, fps_optimization, hwaccel_selected, self.input_filepath,self.output_filepath, selected_fps)
        #self.worker.progress_signal.connect(self.update_progress_bar)
        self.worker.progressStarted.connect(self.start_pulsing)
        #self.worker.progressStarted.connect(self.start_pulsing)
        #self.worker.progressStarted.connect(self.pulse_progress_bar)
        
        self.worker.message_signal.connect(self.update_footer2)
        
        self.worker.start()
        #self.worker.progressFinished.connect(self.stop_pulsing)

    #def update_progress_bar(self, value):
        #self.progress_bar.setValue(value)

    def update_footer2(self, message):
        self.footer2.append(message)


    def start_pulsing(self):
        # Set the progress bar to be indeterminate (will be pulsing)
        self.progressBarFF.setRange(0, 0)
        # Start the pulse timer
        self.pulse_timer.start(100)  # Pulse every 100 ms

    def stop_pulsing(self):
        # Stop the pulse timer
        self.pulse_timer.stop()
        # Reset the progress bar to a determinate state
        self.progressBarFF.setRange(0, 100)
        self.progressBarFF.setValue(0)

    
    def pulse_progress_bar(self):
        # This method is called by the timer to simulate pulsing
        current_value = self.progressBarFF.value()
        # Toggle between 0 and 100 to simulate pulsing effect
        new_value = 100 if current_value == 0 else 0
        self.progressBarFF.setValue(new_value)
'''
if __name__ == "__main__":
    app = QApplication(sys.argv)
    panel = FFmpegControlPanel()
    panel.show()
    sys.exit(app.exec_())
'''