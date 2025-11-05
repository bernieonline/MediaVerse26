##############################################################################
# ffmpeg-qthread-converter.py
# --------------------------------------------------------------------------
# A PyQt5-based QThread class that:
# 1. Prompts the user to select an input file.
# 2. Constructs an FFmpeg command similar to the earlier Tkinter example.
# 3. Saves the output to the same location as the input file.
# 4. Emits signals to update a progress bar (progressBarFF) and a QTextEdit
#    (footer) when the conversion begins and ends.
# 5. Demonstrates how to adapt the original functionality into a QThread.
#
# Usage:
#  - Instantiate FFmpegConverter from within your main Qt window class
#    (e.g., getMainWindow).
#  - Pass in references to progressBarFF and footer, which are owned by
#    your main window.
#  - Call .start() to run the conversion in a separate thread.
##############################################################################

import os
import subprocess
from datetime import datetime

from PyQt5.QtCore import QThread, pyqtSignal
from PyQt5.QtWidgets import QFileDialog

class FFmpegConverter(QThread):
    # Signals to be connected by getMainWindow:
    # - progressStarted, progressFinished: can be used to control a QProgressBar
    #   or any other activity indicator in the UI.
    # - conversionMessage: emits strings to display in footer or logs.
    progressStarted = pyqtSignal()
    progressFinished = pyqtSignal()
    conversionMessage = pyqtSignal(str)

    def __init__(
            self,
            progressBarFF,
            footer,
            parent=None,
            # Optional default parameters based on the original code
            output_format="mp4",
            codec="h265",
            crf="20",
            preset="slow",
            audio="auto",
            fps_optimization=True,
            hwaccel="auto"
        ):
        print("      h265,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1")
        """
        :param progressBarFF: A reference to getMainWindow's progress bar (QProgressBar)
        :param footer: A reference to getMainWindow's QTextEdit for logging messages
        :param parent: Optional parent QObject
        :param output_format: Output container format (e.g. "mp4", "mkv", "mov")
        :param codec: Video codec ("h264" or "h265")
        :param crf: CRF value for quality/bitrate
        :param preset: FFmpeg preset (e.g. "slow", "fast", etc.)
        :param audio: Audio quality setting ("auto", "copy lossless", "convert to E-AC3 1024k")
        :param fps_optimization: Whether to add a filter that optimizes framerate
        :param hwaccel: Hardware acceleration setting ("auto", "NVENC (NVIDIA)", "VAAPI (Intel/AMD)", "QSV (Intel)")
        """
        super().__init__(parent)
        print("initialising FFmpegConverter")
        self.progressBarFF = progressBarFF
        self.footer = footer

        # Store these parameters for constructing the FFmpeg command
        self.output_format = output_format
        self.codec = codec
        self.crf = crf
        self.preset = preset
        self.audio = audio
        self.fps_optimization = fps_optimization
        self.hwaccel = hwaccel

        # Prompt user to select input file using a file dialog
        print("opening file dialog for convert")
        self.input_file, _ = QFileDialog.getOpenFileName(
            None, "Select Media File", "", "Media Files (*.mp4 *.mkv *.mov *.avi *.m4v *.wmv);;All Files (*)"
        )

        # If no file selected, set input_file to None so the run step can ignore
        if not self.input_file:
            self.input_file = None
            return

        # Derive output path from the input file
        input_dir = os.path.dirname(self.input_file)
        base_name, _ = os.path.splitext(os.path.basename(self.input_file))
        # Example output filename: "myvideo_converted.mp4"
        self.output_file = os.path.join(input_dir, f"{base_name}_converted.{self.output_format}")


    def run(self):
        """
        Overriding the run method of QThread.
        The actual FFmpeg transcoding process happens here.
        Signals are used for updating the UI in a thread-safe manner.
        """

        print(" FFmpegConverter run function")
        if not self.input_file:
            # No file was chosen, so there's nothing to do.
            return

        # Emit signal indicating the process started
        self.progressStarted.emit()

        # Emit a message to the footer with the time the conversion begins
        start_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.conversionMessage.emit(f"Conversion has begun: {start_time}")
        print("      h265,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,2")
        # Map "h265" -> "libx265" if the user sets codec to "h265"
        final_codec = "libx265" if self.codec.lower() == "h265" else self.codec

        # Build up the ffmpeg command using the logic from the original snippet
        ffmpeg_command = [
            "ffmpeg",
            "-y",            # Overwrite output if exists
            "-i", self.input_file,
            "-c:v", final_codec,
            "-crf", self.crf,
            "-preset", self.preset
        ]

        # If final_codec is libx265, add the tag
        if final_codec == "libx265":
            ffmpeg_command += ["-tag:v", "hvc1"]

        # Hardware acceleration settings
        # The user can override by specifying one of the recognized strings
        if self.hwaccel and self.hwaccel != "auto":
            if "NVENC" in self.hwaccel:
                ffmpeg_command += ["-c:v", "h264_nvenc"]
            elif "VAAPI" in self.hwaccel:
                ffmpeg_command += ["-c:v", "h264_vaapi"]
            elif "QSV" in self.hwaccel:
                ffmpeg_command += ["-c:v", "h264_qsv"]

        # Audio settings
        if self.audio == "copy lossless":
            ffmpeg_command += ["-c:a", "copy"]
        elif self.audio == "convert to E-AC3 1024k":
            ffmpeg_command += ["-c:a", "eac3", "-b:a", "1024k"]

        # Framerate optimization
        if self.fps_optimization:
            # For example, we might use a filter that sets the max input framerate
            ffmpeg_command += ["-vf", "fps=fpsmax"]

        # Output file extension defined by output_format
        ffmpeg_command.append(self.output_file)

        print("ready to begin conversion FFmpegConverter")

        # Run FFmpeg in a blocking subprocess call
        # In a real application, you may wish to monitor progress or stream logs
        try:
            subprocess.run(ffmpeg_command, check=True)
        except subprocess.CalledProcessError as exc:
            # If there is an error, you could emit a failure signal or log
            self.conversionMessage.emit(f"Conversion failed with error: {exc}")
        else:
            # If it completes successfully, note the end time
            end_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            self.conversionMessage.emit(f"Conversion ended: {end_time}")

        # Emit signal indicating the process finished
        self.progressFinished.emit()