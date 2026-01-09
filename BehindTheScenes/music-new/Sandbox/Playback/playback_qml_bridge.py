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

    @Slot(str)
    def playVideo(self, absolute_path: str):
        """
        Triggered by the 'Playback Test' button in QML.
        """
        logger.debug(f"Bridge received path: {absolute_path}")
        # Start the threaded playback sequence
        self.controller.play_threaded(absolute_path)