import threading
import requests
import xml.etree.ElementTree as ET
import time
import logging
import ctypes

logger = logging.getLogger(__name__)

MCWS_BASE = "http://localhost:52199/MCWS/v1"


# ---------------------------------------------------------------------------
# Win32 window handback
# ---------------------------------------------------------------------------

def _handback_windows():
    """
    Two-phase handback:

    Phase 1  — Cooperative: send MCC 10014 so JRiver minimises itself from
               within its own message loop.  Windows has no objection to this
               and the foreground is voluntarily relinquished.

    Phase 2  — Assertive: with JRiver no longer dominant, use the
               AttachThreadInput + Alt-key spoof to claim the foreground for
               MediaVerse.  Both tricks are now working with the grain of
               Windows focus rules rather than against them.
    """
    try:
        import win32gui
        import win32con
        import win32api
        import win32process

        # ── Phase 1: ask JRiver to minimize itself ──────────────────────────
        try:
            requests.get(
                f"{MCWS_BASE}/Control/MCC?Command=10014&Parameter=1",
                timeout=2,
            )
            logger.info("MCC 10014 sent — JRiver minimising cooperatively.")
        except Exception as e:
            logger.warning(f"MCC 10014 failed ({e}) — continuing with forced swap.")

        # Give JRiver's message loop time to process the minimize
        time.sleep(0.4)

        # ── Enumerate windows ────────────────────────────────────────────────
        hwnd_jriver = None
        hwnd_mv     = None

        def _enum(hwnd, _):
            nonlocal hwnd_jriver, hwnd_mv
            title = win32gui.GetWindowText(hwnd)
            if hwnd_jriver is None and "JRiver" in title:
                hwnd_jriver = hwnd
            if hwnd_mv is None and "MediaVerse" in title:
                hwnd_mv = hwnd
            return True

        win32gui.EnumWindows(_enum, None)
        logger.info(f"Handback — JRiver hwnd={hwnd_jriver}  MediaVerse hwnd={hwnd_mv}")

        # ── Belt-and-suspenders: hide JRiver in case MCC was slow ───────────
        if hwnd_jriver:
            win32gui.ShowWindow(hwnd_jriver, win32con.SW_HIDE)

        if not hwnd_mv:
            logger.warning("MediaVerse window not found — cannot complete handback.")
            return

        # ── Phase 2: raise MediaVerse ────────────────────────────────────────

        # Alt-key spoof: makes Windows treat our thread as having received
        # keyboard input, which unlocks SetForegroundWindow for non-foreground
        # threads (the documented restriction that blocks a bare call).
        win32api.keybd_event(win32con.VK_MENU, 0, 0, 0)

        # AttachThreadInput: attach to the foreground thread's input queue so
        # we inherit its focus privilege before calling SetForegroundWindow.
        fg_hwnd  = win32gui.GetForegroundWindow()
        fg_tid   = win32process.GetWindowThreadProcessId(fg_hwnd)[0]
        our_tid  = win32api.GetCurrentThreadId()
        attached = False
        if fg_tid and fg_tid != our_tid:
            ctypes.windll.user32.AttachThreadInput(fg_tid, our_tid, True)
            attached = True

        win32gui.BringWindowToTop(hwnd_mv)
        win32gui.ShowWindow(hwnd_mv, win32con.SW_RESTORE)
        win32gui.SetForegroundWindow(hwnd_mv)

        if attached:
            ctypes.windll.user32.AttachThreadInput(fg_tid, our_tid, False)

        # Release the spoofed Alt key
        win32api.keybd_event(win32con.VK_MENU, 0, win32con.KEYEVENTF_KEYUP, 0)

        logger.info("MediaVerse raised to front.")

        # ── Suppression loop: hide JRiver if it reasserts within 2 s ────────
        suppress_until = time.time() + 2.0
        while time.time() < suppress_until:
            time.sleep(0.15)
            h_check = None

            def _find_visible_jr(hwnd, _):
                nonlocal h_check
                if (win32gui.IsWindowVisible(hwnd) and
                        "JRiver" in win32gui.GetWindowText(hwnd)):
                    h_check = hwnd
                return True

            win32gui.EnumWindows(_find_visible_jr, None)
            if h_check:
                win32gui.ShowWindow(h_check, win32con.SW_HIDE)

        # Park JRiver as a taskbar icon now that MediaVerse is settled
        if hwnd_jriver:
            win32gui.ShowWindow(hwnd_jriver, win32con.SW_MINIMIZE)
            logger.info("JRiver minimised to taskbar.")

    except ImportError:
        logger.error("pywin32 not available — install with: pip install pywin32")
    except Exception as e:
        logger.error(f"_handback_windows failed: {e}")


# ---------------------------------------------------------------------------
# PlaybackController
# ---------------------------------------------------------------------------

class PlaybackController:
    def __init__(self, bridge):
        self.bridge = bridge
        self.url    = MCWS_BASE
        self._is_processing = False
        self._stop_event    = threading.Event()
        self._watchdog_thread: threading.Thread | None = None

    def shutdown(self):
        """Signal the watchdog to stop. Only contacts JRiver if it was active."""
        logger.info("PlaybackController shutdown requested.")
        self._stop_event.set()
        # Only send a stop if the watchdog is running (JRiver was playing something).
        # When MPC-BE or another player is in use, skip this entirely so shutdown
        # is instant and we don't block on a 1-second HTTP timeout unnecessarily.
        if self._watchdog_thread and self._watchdog_thread.is_alive():
            try:
                requests.get(f"{self.url}/Playback/Stop", timeout=(1, 1))
                logger.info("Stop command sent to JRiver.")
            except Exception:
                pass
        logger.info("PlaybackController shutdown complete.")

    def play_threaded(self, path):
        if self._is_processing:
            logger.warning("Playback request ignored: already processing.")
            return
        self._stop_event.clear()
        threading.Thread(target=self._execute_sequence, args=(path,), daemon=True).start()

    def _get_file_key(self, absolute_path):
        try:
            clean_path = absolute_path.replace("/", "\\")
            search_url = f"{self.url}/Files/Search?Query=[Filename]=[{clean_path}]"
            print(f"\n[JRIVER SEARCH DEBUG]\nURL: {search_url}")
            r    = requests.get(search_url, timeout=5)
            root = ET.fromstring(r.text)
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
            file_key = self._get_file_key(path)
            if not file_key:
                logger.error(f"Could not find ID for path: {path}")
                return

            requests.get(f"{self.url}/Playback/Stop", timeout=2)
            play_url = f"{self.url}/Playback/PlayByKey?Key={file_key}&Location=0"
            logger.info(f"FORCING EXCLUSIVE PLAYBACK: Key {file_key}")
            requests.get(play_url, timeout=10)

            self._watchdog_thread = threading.Thread(target=self._run_watchdog, daemon=True)
            self._watchdog_thread.start()
        except Exception as e:
            logger.error(f"Playback execution failed: {e}")
        finally:
            self._is_processing = False

    def _run_watchdog(self):
        """
        Polls JRiver.  On stop:
          1. _handback_windows() — MCC 10014 cooperative minimize, then
             AttachThreadInput + Alt-key to raise MediaVerse.
          2. playbackFinished.emit() — QML triggers the cinema fade.
        """
        playback_started = False
        start_time       = time.time()
        logger.info("Watchdog active.")

        while not self._stop_event.is_set():
            try:
                elapsed       = time.time() - start_time
                poll_interval = 0.5 if elapsed < 10 else 1.0

                r = requests.get(f"{self.url}/Playback/Info", timeout=2)
                if r.status_code == 200:
                    root  = ET.fromstring(r.text)
                    state = "0"
                    for item in root.findall(".//Item"):
                        if item.get("Name") == "State":
                            state = item.text
                            break

                    if state != "0":
                        playback_started = True
                    elif playback_started:
                        logger.info("Stop detected — executing window handback.")
                        _handback_windows()
                        self.bridge.playbackFinished.emit()
                        break

                self._stop_event.wait(poll_interval)

            except requests.exceptions.RequestException:
                logger.debug("JRiver busy... retrying.")
                self._stop_event.wait(0.5)
                continue
