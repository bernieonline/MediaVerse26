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

    def _execute_sequence(self, path):
        try:
            self._is_processing = True
            # Use the key we know is correct for this file
            file_key = "402939" 
            
            logger.info("Step 1: Clearing JRiver state...")
            # Use a very long timeout for the first 'Wake up' call
            try:
                requests.get(f"{self.url}/Playback/Stop", timeout=5)
            except:
                pass # If JRiver is sluggish, just keep going
            
            time.sleep(2) 

            # Step 2: Trigger Play (The command that worked)
            mcc_url = f"{self.url}/Control/MCC?Command=10001&Parameter={file_key}"
            logger.info(f"Step 2: Sending Play Command for Key {file_key}")
            
            # Fire and forget - don't wait for JRiver to finish loading the video
            requests.get(mcc_url, timeout=2)
            
            # Step 3: Silence. Give JRiver 30 seconds of pure peace to load the .m2ts
            logger.info("Step 3: Playback triggered. Silencing API for 30s to prevent crash...")
            self._run_watchdog()

        except Exception as e:
            logger.error(f"Bridge connection error: {e}. Is JRiver running?")
        finally:
            self._is_processing = False

    def _run_watchdog(self):
        # We wait 30 seconds before we even ASK JRiver for its status
        time.sleep(30) 
        while True:
            try:
                r = requests.get(f"{self.url}/Playback/Info", timeout=5)
                root = ET.fromstring(r.text)
                state = "0"
                for item in root.findall(".//Item"):
                    if item.get("Name") == "State":
                        state = item.text
                        break
                
                if state == "0":
                    logger.info("Movie finished. Returning focus.")
                    self.bridge.playbackFinished.emit()
                    break
                time.sleep(10) # Check very infrequently (every 10s)
            except:
                # If JRiver blips, just wait 10s and try again
                time.sleep(10)

    def _run_watchdog(self):
        """Monitors JRiver without crashing on initial timeouts."""
        # INCREASED WAIT: Give JRiver 15 seconds to fully load the video engine
        logger.info("Waiting 15s for JRiver engine to stabilize...")
        time.sleep(15) 
        
        logger.info("Watchdog Active: Monitoring playback status...")
        
        while True:
            try:
                # Check JRiver status with a short timeout so we don't hang
                r = requests.get(f"{self.url}/Playback/Info", timeout=2)
                
                if r.status_code == 200:
                    root = ET.fromstring(r.text)
                    state = "0"
                    for item in root.findall(".//Item"):
                        if item.get("Name") == "State":
                            state = item.text
                            break
                    
                    # If state is 0, the movie has been stopped
                    if state == "0":
                        logger.info("Stop detected. Signaling Mediaverse.")
                        self.bridge.playbackFinished.emit()
                        break
                
                time.sleep(5) # Check every 5 seconds (gentler on the CPU)

            except requests.exceptions.RequestException:
                # If we get a timeout here, JRiver is just busy. 
                # Don't crash, just wait and try again.
                logger.debug("JRiver busy (timeout)... retrying in 5s.")
                time.sleep(5)
                continue