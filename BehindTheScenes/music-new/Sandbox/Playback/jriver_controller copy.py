# Playback/jriver_controller.py
# This module communicates with JRiver via HTTPS (MCWS API)

import logging
import requests
import xml.etree.ElementTree as ET
from typing import Optional


#from .config_loader import get_jriver_port
from .config_loader import get_jriver_port, get_jriver_access_key


logger = logging.getLogger(__name__)


class JRiverController:
    """
    Backend adapter for JRiver MCWS playback.
    Handles HTTPS, SSL, XML parsing, and error reporting.
    """

    HOST = "localhost"
    ENDPOINT = "/MCWS/v1/Playback/Play"
    TIMEOUT = 2  # seconds

    @staticmethod
    def play(absolute_path: str) -> str:
        logger.info(f"[JRiverController] play called with: {absolute_path!r}")

        if not absolute_path or not isinstance(absolute_path, str):
            logger.error("Invalid path passed to JRiverController")
            return "ERROR_INVALID_PATH"

        try:
            port = get_jriver_port()
            token = get_jriver_access_key()   # ✅ THIS WAS MISSING

            # Normalise path for JRiver
            normalized_path = absolute_path.replace("\\", "/")
            encoded_path = urllib.parse.quote(normalized_path)

            url = (
                f"http://{JRiverController.HOST}:{port}"
                f"{JRiverController.ENDPOINT}"
                f"?FileName={encoded_path}"
                f"&Token={token}"
            )

            logger.debug(f"[JRiverController] MCWS URL: {url}")

            response = requests.get(url, timeout=5)

            logger.debug(
                f"[JRiverController] Response {response.status_code}: {response.text}"
            )

            if response.status_code != 200:
                logger.error(f"JRiver HTTP error {response.status_code}")
                return "ERROR_HTTP"

            logger.info("✅ JRiver playback command sent successfully")
            return "OK"

        except Exception:
            logger.exception("❌ JRiver playback exception")
            return "ERROR_EXCEPTION"
