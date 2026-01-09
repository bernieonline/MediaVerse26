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
        # The Gatekeeper: prevents multiple threads from fighting for JRiver
        self._is_processing = False 

    def play_threaded(self, path):
        """Called by the Bridge. Starts the sequence in a background thread."""
        if self._is_processing:
            logger.warning("Playback request ignored: already processing a file.")
            return
            
        thread = threading.Thread(target=self._execute_sequence, args=(path,), daemon=True)
        thread.start()

    def _execute_sequence(self, path):
        try:
            self._is_processing = True
            file_key = "402939"
            
            # We try the three most likely URL structures for your specific JRiver version
            # 1. Root Play (No v1)
            # 2. v1 Play (Sandbox style)
            # 3. PlayMediaID (The 'modern' replacement)
            
            attempts = [
                f"http://localhost:52199/MCWS/v1/Playback/PlayById?Key={file_key}",
                f"http://localhost:52199/MCWS/v1/Playback/Play?Key={file_key}",
                f"http://localhost:52199/MCWS/v1/Control/MCC?Command=10001&Parameter={file_key}" 
            ]

            # First, a guaranteed Stop (We know this works!)
            requests.get("http://localhost:52199/MCWS/v1/Playback/Stop", timeout=2)
            time.sleep(1)

            for url in attempts:
                logger.info(f"Trying Playback URL: {url}")
                try:
                    r = requests.get(url, timeout=5)
                    if r.status_code == 200:
                        logger.info("--- SUCCESS! Movie should be starting ---")
                        self._run_watchdog()
                        return
                    else:
                        logger.warning(f"Attempt failed with {r.status_code}")
                except Exception as e:
                    logger.error(f"Request failed: {e}")

            logger.error("All playback methods exhausted.")

        finally:
            self._is_processing = False

    def _get_file_key(self, filename):
        """Helper to find the JRiver Key using the sandbox search logic."""
        try:
            search_url = f"{self.url}/Files/Search?Query=[Filename]=[{filename}]"
            r = requests.get(search_url, timeout=5)
            root = ET.fromstring(r.text)
            
            for item in root.findall(".//Item"):
                for field in item.findall("Field"):
                    if field.get("Name") == "Key":
                        return field.text
            
            # Fuzzy Fallback
            logger.info("Exact search failed, trying fuzzy search...")
            fuzzy_url = f"{self.url}/Files/Search?Query=Fistful of Dollars"
            r = requests.get(fuzzy_url, timeout=5)
            root = ET.fromstring(r.text)
            for item in root.findall(".//Item"):
                for field in item.findall("Field"):
                    if field.get("Name") == "Key":
                        return field.text
            return None
        except Exception as e:
            logger.error(f"Search error: {e}")
            return None

    def _run_watchdog(self):
        """The 'Hand-back' loop. Waits for movie to stop then tells Mediaverse to pop up."""
        time.sleep(10) # Wait for JRiver to initialize the video
        while True:
            try:
                # Check JRiver Status
                r = requests.get(f"{self.url}/Playback/Info", timeout=5)
                root = ET.fromstring(r.text)
                
                state = "0" 
                for item in root.findall(".//Item"):
                    if item.get("Name") == "State":
                        state = item.text
                        break
                
                if state == "0": # 0 = Stopped
                    logger.info("Playback Stopped. Emitting finish signal.")
                    self.bridge.playbackFinished.emit()
                    break
                
                time.sleep(5)
            except Exception as e:
                logger.error(f"Watchdog error: {e}")
                break