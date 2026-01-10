import threading
import requests
import xml.etree.ElementTree as ET
import time
import logging

logger = logging.getLogger(__name__)

class PlaybackController:
    def __init__(self, bridge):
        self.bridge = bridge
        self.url = "http://localhost:52199/MCWS/v1"
        self._is_processing = False 

    def play_threaded(self, path):
        """Starts the sequence in a background thread."""
        if self._is_processing:
            logger.warning("Playback request ignored: already processing a file.")
            return
            
        thread = threading.Thread(target=self._execute_sequence, args=(path,), daemon=True)
        thread.start()
    def _get_file_key(self, absolute_path):
        """Standard JRiver lookup using the bracketed filename."""
        try:
            clean_path = absolute_path.replace("/", "\\")
            # We use [Filename]=[path] which is the most reliable internal query
            search_url = f"{self.url}/Files/Search?Query=[Filename]=[{clean_path}]"

            # --- DEBUG PRINTS ---
            print(f"\n[JRIVER SEARCH DEBUG]")
            print(f"URL: {search_url}")
            # --------------------



            r = requests.get(search_url, timeout=5)
            root = ET.fromstring(r.text)
            
            # Look specifically for the first <Item> and its <Field Name="Key">
            for item in root.findall(".//Item"):
                for field in item.findall("Field"):
                    if field.get("Name") == "Key":
                        return field.text
            return None
        except Exception as e:
            logger.error(f"Search failed: {e}")
            return None

    
    
    def _execute_sequence(self, path):
        try:
            self._is_processing = True
            
            # 1. Get the Key (we know it's 402945 from your log)
            file_key = self._get_file_key(path)
            
            if not file_key:
                logger.error(f"Could not find ID for path: {path}")
                return

            # --- THE NEW RESET SEQUENCE ---
            
            # A. Stop and Clear the "Playing Now" list completely
            # This prevents JRiver from playing the 'wrong' movie left in the queue
            requests.get(f"{self.url}/Playback/Stop", timeout=2)
            
            # B. Explicitly Play ONLY this key, and tell JRiver to "Set" the playlist to it
            # We use 'Location=0' to ensure it's the very first (and only) item.
            play_url = f"{self.url}/Playback/PlayByKey?Key={file_key}&Location=0"
            
            logger.info(f"FORCING EXCLUSIVE PLAYBACK: Key {file_key}")
            requests.get(play_url, timeout=10)

            # 3. Start the watchdog
            threading.Thread(target=self._run_watchdog, daemon=True).start()

        except Exception as e:
            logger.error(f"Playback execution failed: {e}")
        finally:
            self._is_processing = False
    def _run_watchdog(self):
        """Monitors JRiver status."""
        logger.info("Waiting 15s for JRiver engine to stabilize...")
        time.sleep(15) 
        
        logger.info("Watchdog Active: Monitoring playback status...")
        
        while True:
            try:
                r = requests.get(f"{self.url}/Playback/Info", timeout=2)
                if r.status_code == 200:
                    root = ET.fromstring(r.text)
                    state = "0"
                    for item in root.findall(".//Item"):
                        if item.get("Name") == "State":
                            state = item.text
                            break
                    
                    if state == "0":
                        logger.info("Stop detected. Signaling Mediaverse.")
                        self.bridge.playbackFinished.emit()
                        break
                
                time.sleep(5) 

            except requests.exceptions.RequestException:
                logger.debug("JRiver busy... retrying in 5s.")
                time.sleep(5)
                continue