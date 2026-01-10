# playback_qml_bridge.py
from PySide6.QtCore import QObject, Slot, Signal
import logging
from Sandbox.Playback.playback_controller import PlaybackController

logger = logging.getLogger(__name__)

class PlaybackQmlBridge(QObject):
    # This signal is caught by QML to bring Mediaverse back to focus
    playbackFinished = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        # We pass 'self' so the controller can shout back to this bridge
        self.controller = PlaybackController(self)
        print("Mediaverse Playback Bridge Initialized")

        # ADD THIS LINE:
        # This tells the bridge: "When the controller says playback is finished, 
        # run the window focus method."
        self.playbackFinished.connect(self._force_window_to_front)

    @Slot(str)
    def playVideo(self, absolute_path: str):
        """
        Triggered by the 'Playback Test' button in QML.
        """
        logger.debug(f"Bridge received path: {absolute_path}")
        # Start the threaded playback sequence

        self.controller.play_threaded(absolute_path)





    def _force_window_to_front(self):
        try:
            import ctypes
            import time
            user32 = ctypes.windll.user32
            
            # Find the windows
            hwnd_jriver = user32.FindWindowW(None, "JRiver Media Center 34")
            hwnd_mv = user32.FindWindowW(None, "Mediaverse")

            if hwnd_jriver:
                # SW_HIDE (0) removes it from the screen entirely for a split second
                # This prevents JRiver from 'grabbing' the focus back
                user32.ShowWindow(hwnd_jriver, 0) 
            
            time.sleep(0.2)

            if hwnd_mv:
                # Bring Mediaverse to the absolute top
                user32.ShowWindow(hwnd_mv, 9) # Restore
                user32.SetForegroundWindow(hwnd_mv)
                logger.info("Mediaverse forced to front.")

            time.sleep(0.3)

            if hwnd_jriver:
                # Now bring JRiver back, but ONLY as a minimized icon in the taskbar
                user32.ShowWindow(hwnd_jriver, 6) # SW_MINIMIZE
                logger.info("JRiver tucked away in taskbar.")
                
        except Exception as e:
            logger.error(f"Surgical focus failed: {e}")

    @Slot()
    def stopPlayback(self):
        """Stops JRiver via HTTP and immediately reclaims the screen."""
        try:
            # 1. Tell JRiver to STOP
            # Command 10002 is the MCC code for Stop
            stop_url = f"{self.controller.url}/Control/MCC?Command=10002"
            import requests
            requests.get(stop_url, timeout=5)
            logger.info("Sent STOP command to JRiver.")

            # 2. Immediately Run the Window Swap
            self._force_window_to_front()
            
        except Exception as e:
            logger.error(f"Manual stop failed: {e}")

    @Slot()
    def stopPlayback(self):
        # This is just a placeholder so the QML button doesn't error out
        print("UI TEST: Stop button clicked in QML!")
        # We will add the JRiver/Focus logic here AFTER we see the button works