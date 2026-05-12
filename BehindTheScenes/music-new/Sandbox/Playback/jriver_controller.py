import requests
import logging
import xml.etree.ElementTree as ET
import time
from typing import Optional

logger = logging.getLogger(__name__)


class JRiverController:
    HOST    = "http://localhost:52199"
    TOKEN   = "fAeKZS"
    TIMEOUT = 5

    @staticmethod
    def _url(path: str) -> str:
        """Build a MCWS URL.  path may already contain query params."""
        sep = "&" if "?" in path else "?"
        return f"{JRiverController.HOST}/MCWS/v1{path}{sep}Token={JRiverController.TOKEN}"

    # -- MCC helpers ---------------------------------------------------------

    @staticmethod
    def send_mcc(command_id: int, parameter: int = 0):
        url = JRiverController._url(
            f"/Control/MCC?Command={command_id}&Parameter={parameter}"
        )
        requests.get(url, timeout=JRiverController.TIMEOUT)

    @staticmethod
    def toggle_play_pause():  JRiverController.send_mcc(10000)

    @staticmethod
    def stop():               JRiverController.send_mcc(10002)

    @staticmethod
    def volume_up():          JRiverController.send_mcc(10018, 5)

    @staticmethod
    def volume_down():        JRiverController.send_mcc(10019, 5)

    @staticmethod
    def minimize_window():
        """MCC_MINIMIZE_WINDOW -- parameter 1 toggles minimize/restore."""
        JRiverController.send_mcc(10014, parameter=1)

    # -- Server ---------------------------------------------------------------

    @staticmethod
    def is_running() -> bool:
        try:
            r = requests.get(JRiverController._url("/Server/Info"),
                             timeout=JRiverController.TIMEOUT)
            return r.status_code == 200
        except requests.RequestException:
            return False

    # -- Media ID lookup ------------------------------------------------------

    @staticmethod
    def get_media_id(file_path: str) -> Optional[str]:
        try:
            filename = file_path.replace("\\", "/").split("/")[-1]
            url      = JRiverController._url("/Files/Search")
            r        = requests.get(url, params={"Query": f"[Filename]=[{filename}]"},
                                    timeout=JRiverController.TIMEOUT)
            root = ET.fromstring(r.text)
            for item in root.findall(".//Item"):
                for field in item.findall("Field"):
                    if field.get("Name") == "Key":
                        return field.text
            return None
        except Exception as e:
            logger.error(f"ID lookup failed: {e}")
            return None

    # -- Watchdog -------------------------------------------------------------

    @staticmethod
    def monitor_playback(bridge):
        """
        Polls JRiver playback state.  On stop, actively prepares the window
        state before signalling QML:

          1.  MCC 10014  -- JRiver minimises itself (cooperative; Windows allows it).
          2.  _handback_windows() -- AttachThreadInput + Alt-key to raise MediaVerse.
          3.  playbackFinished.emit() -- QML triggers the cinema fade.
        """
        # Import here to avoid any circular-import risk at module load time
        from Sandbox.Playback.playback_controller import _handback_windows

        playback_started = False
        start_time       = time.time()
        logger.info("JRiverController watchdog active.")

        while True:
            try:
                elapsed       = time.time() - start_time
                poll_interval = 0.5 if elapsed < 10 else 1.0

                r = requests.get(
                    JRiverController._url("/Playback/Info"),
                    timeout=JRiverController.TIMEOUT,
                )
                root  = ET.fromstring(r.text)
                state = "0"
                for item in root.findall(".//Item"):
                    if item.get("Name") == "State":
                        state = item.text
                        break

                if state != "0":
                    playback_started = True
                elif playback_started:
                    logger.info("Stop detected -- preparing window handback.")
                    _handback_windows()
                    bridge.playbackFinished.emit()
                    break

                time.sleep(poll_interval)

            except requests.RequestException as e:
                logger.debug(f"MCWS poll error: {e} -- retrying.")
                time.sleep(0.5)
            except Exception as e:
                logger.error(f"monitor_playback error: {e}")
                break
