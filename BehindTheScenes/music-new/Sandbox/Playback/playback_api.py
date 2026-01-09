# Playback/playback_api.py

from .playback_controller import PlaybackController
import logging

logger = logging.getLogger(__name__)

def play_video_from_qml(absolute_path: str) -> str:
    logger.debug(f"[playback_api] Request to play: {absolute_path!r}")
    return PlaybackController.play(absolute_path)
