# playback_qml_bridge.py
from PySide6.QtCore import QObject, Slot, Signal
import logging
import requests
from Sandbox.Playback.playback_controller import PlaybackController, _handback_windows

logger = logging.getLogger(__name__)


class PlaybackQmlBridge(QObject):
    # Caught by QML to trigger the cinema fade-in
    playbackFinished = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.controller = PlaybackController(self)
        print("Mediaverse Playback Bridge Initialized")

    @Slot(str)
    def playVideo(self, absolute_path: str):
        logger.debug(f"Bridge received path: {absolute_path}")
        self.controller.play_threaded(absolute_path)

    @Slot()
    def shutdown(self):
        """Called on app exit — stops the watchdog and tells JRiver to stop."""
        self.controller.shutdown()

    @Slot()
    def stopPlayback(self):
        """Stop JRiver via HTTP and immediately reclaim the screen."""
        try:
            stop_url = f"{self.controller.url}/Control/MCC?Command=10002"
            requests.get(stop_url, timeout=5)
            logger.info("Sent STOP command to JRiver.")
            _handback_windows()
            self.playbackFinished.emit()
        except Exception as e:
            logger.error(f"Manual stop failed: {e}")
