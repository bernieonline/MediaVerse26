"""
snatcher2_backend.py
Clipboard image monitor and crop/save backend for the Snatcher2 QML popup.
Registered as context property 'snatcher2Backend' in Framework.py.
"""

import sys
import tempfile
from pathlib import Path

from PySide6.QtCore import QObject, Signal, Slot, QTimer

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
from project_paths import paths, splash_path

try:
    from PIL import ImageGrab, Image
    _PIL_OK = True
except ImportError:
    _PIL_OK = False
    print("[Snatcher2] WARNING: Pillow not installed -- clipboard monitoring disabled")


class Snatcher2Backend(QObject):
    """
    Monitors the clipboard for images, exposes them to QML, and
    saves crops to the configured destination directory.
    """

    # uri = file:// temp path QML can load;  w/h = source pixel dimensions
    clipboardImageReady = Signal(str, int, int)
    statusMessage       = Signal(str)

    # ------------------------------------------------------------------
    def __init__(self, parent=None):
        super().__init__(parent)

        self._current_pil: Image.Image | None = None
        self._last_sig    = None   # (size, mode) used to skip duplicate frames
        self._temp_path   = None

        self._path_splash = splash_path
        self._path_temp   = paths["project_root"] / "Assets" / "tempImages"

        self._timer = QTimer(self)
        self._timer.setInterval(500)
        self._timer.timeout.connect(self._check_clipboard)

    # ------------------------------------------------------------------
    @Slot()
    def startMonitoring(self):
        if _PIL_OK:
            self._timer.start()
        else:
            self.statusMessage.emit("[WARN] Pillow not installed")

    @Slot()
    def stopMonitoring(self):
        self._timer.stop()

    # ------------------------------------------------------------------
    def _check_clipboard(self):
        try:
            img = ImageGrab.grabclipboard()
            if img is None or not hasattr(img, "size"):
                return

            sig = (img.size, img.mode)
            if sig == self._last_sig:
                return
            self._last_sig    = sig
            self._current_pil = img.convert("RGB")
            w, h = self._current_pil.size

            # Write to a temp file so the QML Image component can load it
            tmp = tempfile.NamedTemporaryFile(
                suffix=".jpg", prefix="snatch2_", delete=False
            )
            tmp.close()
            self._current_pil.save(tmp.name, "JPEG", quality=92)
            self._temp_path = tmp.name

            uri = Path(tmp.name).as_uri()
            self.clipboardImageReady.emit(uri, w, h)

        except Exception as e:
            print(f"[Snatcher2] clipboard error: {e}")

    # ------------------------------------------------------------------
    @Slot(float, float, float, float, str, str)
    def saveCrop(self, x_ratio: float, y_ratio: float,
                 w_ratio: float, h_ratio: float,
                 name: str, dest: str):
        """
        Crop the current PIL image using normalised 0..1 ratios and save it.
        dest: "Splash" | "Temp"
        """
        if self._current_pil is None:
            self.statusMessage.emit("[WARN] No image loaded yet")
            return

        iw, ih = self._current_pil.size
        left   = max(0,  int(x_ratio * iw))
        top    = max(0,  int(y_ratio * ih))
        right  = min(iw, int((x_ratio + w_ratio) * iw))
        bottom = min(ih, int((y_ratio + h_ratio) * ih))

        if right <= left or bottom <= top:
            self.statusMessage.emit("[WARN] Invalid crop area -- try again")
            return

        cropped = self._current_pil.crop((left, top, right, bottom))

        target = self._path_splash if dest == "Splash" else self._path_temp
        target.mkdir(parents=True, exist_ok=True)

        clean = "".join(
            c for c in name if c.isalnum() or c in " ._-"
        ).strip() or "snatcher2_output"

        save_path = target / f"{clean}.jpg"
        cropped.save(str(save_path), "JPEG", quality=95, subsampling=0)

        crop_w = right - left
        crop_h = bottom - top
        self.statusMessage.emit(
            f" Saved {crop_w}×{crop_h}px -> {save_path.name}"
        )
        print(f"[Snatcher2] [OK] {save_path}")

    # ------------------------------------------------------------------
    @Slot(str)
    def openGoogleSearch(self, query: str):
        """Launch a Google image search in the default browser."""
        import urllib.parse
        import webbrowser
        q   = f'"{query}" 4k uhd wallpaper backdrop'
        url = (
            "https://www.google.com/search?q="
            + urllib.parse.quote(q)
            + "&tbm=isch&tbs=isz:lt,islt:8mp"
        )
        webbrowser.open(url)
