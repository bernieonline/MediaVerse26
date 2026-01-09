import requests
import logging
import xml.etree.ElementTree as ET
import time
from urllib.parse import quote
from typing import Optional

logger = logging.getLogger(__name__)

class JRiverController:
    HOST = "http://localhost:52199"
    # We use your Access Key as the token
    TOKEN = "fAeKZS"
    TIMEOUT = 5 

    @staticmethod
    def _url(path: str) -> str:
        # Standardizing on /MCWS/v1
        return f"{JRiverController.HOST}/MCWS/v1{path}?Token={JRiverController.TOKEN}"

    @staticmethod
    def is_running() -> bool:
        try:
            url = JRiverController._url("/Server/Info")
            response = requests.get(url, timeout=JRiverController.TIMEOUT)
            return response.status_code == 200
        except requests.RequestException:
            return False

    @staticmethod
    def get_media_id(file_path: str) -> Optional[str]:
        """Lookup Media ID using the robust filename search we verified."""
        try:
            # Extract just the filename to avoid the slash direction issue
            filename = file_path.replace('\\', '/').split('/')[-1]
            
            # Using Files/Search (XML) instead of FindItems (JSON) for stability
            url = JRiverController._url(f"/Files/Search")
            params = {'Query': f'[Filename]=[{filename}]'}
            
            response = requests.get(url, params=params, timeout=JRiverController.TIMEOUT)
            root = ET.fromstring(response.text)
            
            for item in root.findall(".//Item"):
                for field in item.findall("Field"):
                    if field.get("Name") == "Key":
                        return field.text
            return None
        except Exception as e:
            logger.error(f"ID Lookup failed: {e}")
            return None

    @staticmethod
    def monitor_playback(bridge):
        """The Watchdog that handles the transition back to Mediaverse."""
        time.sleep(8) # Initial buffer
        while True:
            try:
                url = JRiverController._url("/Playback/Info")
                r = requests.get(url, timeout=JRiverController.TIMEOUT)
                root = ET.fromstring(r.text)
                
                state = "0"
                for item in root.findall(".//Item"):
                    if item.get("Name") == "State":
                        state = item.text
                        break
                
                if state == "0": # Stopped
                    logger.info("Playback ended. Triggering Hand-back.")
                    bridge.playbackFinished.emit()
                    break
                time.sleep(5)
            except Exception as e:
                logger.error(f"Monitor error: {e}")
                break