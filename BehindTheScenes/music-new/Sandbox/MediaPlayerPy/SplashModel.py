from PySide6.QtCore import QObject, Slot
import json
from pathlib import Path

class SplashModel(QObject):
    def __init__(self, json_path, images_path):
        super().__init__()
        self._json_path = Path(json_path)
        self._images_path = Path(images_path)
        self._data = []

        # Load JSON on startup
        if self._json_path.exists():
            try:
                with open(self._json_path, "r", encoding="utf-8") as f:
                    self._data = json.load(f)
                print(f"[SplashModel] Loaded {len(self._data)} splash entries")
            except Exception as e:
                print("[SplashModel] ERROR loading JSON:", e)
        else:
            print("[SplashModel] JSON file not found:", self._json_path)

    # ---------------------------------------------------------
    # QML-accessible: return the full splash list
    # ---------------------------------------------------------
    @Slot(result="QVariantList")
    def get_splash_data(self):
        return self._data

    # ---------------------------------------------------------
    # QML-accessible: resolve an image filename to a full path
    # ---------------------------------------------------------
    @Slot(str, result=str)
    def resolve_image(self, filename):
        full_path = self._images_path / filename
        #return str(full_path).replace("\\", "/")
        return Path(full_path).as_uri()