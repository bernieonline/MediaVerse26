import re
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
        self._current_path: str = ""          # path passed to play_threaded
        self.progress_store = None            # injected by Framework.py

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
            self._current_path = path
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
          1. _record_progress() — writes position/duration to tv_watch_progress.json
             if a TVWatchProgressStore has been injected.
          2. _handback_windows() — MCC 10014 cooperative minimize, then
             AttachThreadInput + Alt-key to raise MediaVerse.
          3. playbackFinished.emit() — QML triggers the cinema fade.
        """
        playback_started  = False
        start_time        = time.time()
        last_position_ms  = 0    # last non-zero PositionMS seen
        last_duration_ms  = 0    # last non-zero DurationMS seen
        logger.info("Watchdog active.")

        while not self._stop_event.is_set():
            try:
                elapsed       = time.time() - start_time
                poll_interval = 0.5 if elapsed < 10 else 1.0

                r = requests.get(f"{self.url}/Playback/Info", timeout=2)
                if r.status_code == 200:
                    root  = ET.fromstring(r.text)
                    state = "0"
                    pos_ms = 0
                    dur_ms = 0
                    for item in root.findall(".//Item"):
                        name = item.get("Name", "")
                        if name == "State":
                            state = item.text or "0"
                        elif name == "PositionMS":
                            try:
                                pos_ms = int(item.text or 0)
                            except (ValueError, TypeError):
                                pass
                        elif name == "DurationMS":
                            try:
                                dur_ms = int(item.text or 0)
                            except (ValueError, TypeError):
                                pass

                    # Track last known non-zero position/duration
                    if pos_ms > 0:
                        last_position_ms = pos_ms
                    if dur_ms > 0:
                        last_duration_ms = dur_ms

                    if state != "0":
                        playback_started = True
                    elif playback_started:
                        logger.info("Stop detected — recording progress then handback.")
                        self._record_progress(last_position_ms, last_duration_ms)
                        _handback_windows()
                        self.bridge.playbackFinished.emit()
                        break

                self._stop_event.wait(poll_interval)

            except requests.exceptions.RequestException:
                logger.debug("JRiver busy... retrying.")
                self._stop_event.wait(0.5)
                continue

    def _record_progress(self, position_ms: int, duration_ms: int) -> None:
        """Write watch progress to TVWatchProgressStore if one is injected."""
        if self.progress_store is None or not self._current_path:
            return
        if duration_ms <= 0:
            logger.debug("_record_progress: duration unknown — skipping.")
            return
        try:
            self.progress_store.record(
                self._current_path,
                position_ms / 1000.0,
                duration_ms / 1000.0,
            )
        except Exception as exc:
            logger.warning(f"_record_progress failed: {exc}")


# ---------------------------------------------------------------------------
# MpcBeWatchdog
# ---------------------------------------------------------------------------

class MpcBeWatchdog:
    """
    Monitors MPC-BE via its built-in HTTP web interface.

    Prerequisite: Options → Player → Web Interface must be enabled in MPC-BE,
    listening on the port stored in Config.json as "MpcBePort" (default 13579).

    Strategy:
      - Process exit is the PRIMARY stop trigger (reliable with /close flag).
      - state == 0 from the web API is a SECONDARY fallback.
      - Position/duration are captured on every poll tick; the last non-zero
        values are what gets written to TVWatchProgressStore on stop.
    """

    def __init__(self, bridge):
        self.bridge         = bridge
        self.progress_store = None   # injected by Framework.py
        self._stop_event    = threading.Event()
        self._thread: threading.Thread | None = None

    # ── Lifecycle ────────────────────────────────────────────────────────────

    def start(self, path: str, process, port: int = 13579) -> None:
        """Begin monitoring a freshly launched MPC-BE process."""
        self._stop_event.clear()
        self._thread = threading.Thread(
            target=self._run,
            args=(path, process, port),
            daemon=True,
        )
        self._thread.start()

    def shutdown(self) -> None:
        self._stop_event.set()

    # ── Web API helpers ──────────────────────────────────────────────────────

    @staticmethod
    def _parse(html: str) -> dict:
        """Extract state / position_ms / duration_ms from variables.html."""
        def _get(key):
            m = re.search(rf'id="{key}"[^>]*>([^<]*)<', html)
            return m.group(1).strip() if m else ""

        def _int(s):
            try:
                return int(s)
            except (ValueError, TypeError):
                return 0

        state_raw = _get("state")
        return {
            "state":       _int(state_raw) if state_raw else -1,
            "position_ms": _int(_get("position")),
            "duration_ms": _int(_get("duration")),
        }

    def _poll(self, port: int) -> dict:
        try:
            r = requests.get(f"http://localhost:{port}/variables.html", timeout=2)
            if r.status_code == 200:
                return self._parse(r.text)
        except Exception:
            pass
        return {}

    # ── Main loop ────────────────────────────────────────────────────────────

    def _run(self, path: str, process, port: int) -> None:
        logger.info(f"MpcBeWatchdog active on port {port} for: {path}")

        # Wait up to 15 s for MPC-BE's web server to come up
        deadline = time.time() + 15
        while time.time() < deadline:
            if self._stop_event.is_set():
                return
            if process.poll() is not None:
                logger.info("MPC-BE exited before web API responded — nothing to record.")
                return
            if self._poll(port):
                logger.info("MPC-BE web API is responding.")
                break
            self._stop_event.wait(0.5)

        last_position_ms = 0
        last_duration_ms = 0
        playback_started = False
        recorded         = False

        while not self._stop_event.is_set():

            # ── Primary: process has exited ───────────────────────────────
            if process.poll() is not None:
                logger.info("MPC-BE process exited — recording progress.")
                if not recorded:
                    recorded = True
                    self._record(path, last_position_ms, last_duration_ms)
                    self.bridge.playbackFinished.emit()
                break

            # ── Poll web API for current position/state ───────────────────
            info = self._poll(port)
            if info:
                pos = info.get("position_ms", 0)
                dur = info.get("duration_ms", 0)
                if pos > 0:
                    last_position_ms = pos
                if dur > 0:
                    last_duration_ms = dur

                state = info.get("state", -1)
                if state == 2:   # playing
                    playback_started = True
                elif state == 0 and playback_started and not recorded:
                    # ── Secondary: stopped while process still alive ───────
                    logger.info("MPC-BE state → stopped — recording progress.")
                    recorded = True
                    self._record(path, last_position_ms, last_duration_ms)
                    self.bridge.playbackFinished.emit()
                    break

            self._stop_event.wait(1.0)

        logger.info("MpcBeWatchdog finished.")

    # ── Progress recording ───────────────────────────────────────────────────

    def _record(self, path: str, position_ms: int, duration_ms: int) -> None:
        if self.progress_store is None:
            logger.debug("MpcBeWatchdog: no progress_store injected — skipping.")
            return
        if not path or duration_ms <= 0:
            logger.debug("MpcBeWatchdog: missing path or duration — skipping.")
            return
        try:
            self.progress_store.record(path, position_ms / 1000.0, duration_ms / 1000.0)
        except Exception as exc:
            logger.warning(f"MpcBeWatchdog._record failed: {exc}")
