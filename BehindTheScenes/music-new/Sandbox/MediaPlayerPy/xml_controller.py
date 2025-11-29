import json
from pathlib import Path
from PySide6.QtCore import QObject, Signal, Slot

class XmlController(QObject):
    categoriesChanged = Signal()
    tabChangeRequested = Signal(int)
    categoryContentUpdated = Signal(str, list)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._data = {}
        self._categories = []
        self._json_path = None

        # Resolve live JSON path
        self._json_path = self._resolve_live_json()
        self._load_json(self._json_path)

    def _resolve_live_json(self) -> Path:
        # Walk up to find "music-new" folder
        here = Path(__file__).resolve()
        for ancestor in [here.parent, *here.parents]:
            if ancestor.name == "music-new":
                candidate = ancestor / "Assets" / "XMLCategories.json"
                if candidate.exists():
                    return candidate
        # Fallback
        return Path(__file__).resolve().parent / "Assets" / "XMLCategories.json"

    def _load_json(self, path: Path):
        try:
            with Path(path).open("r", encoding="utf-8") as f:
                self._data = json.load(f)
            self._categories = list(self._data.keys())
            print(f"✅ XmlController loaded JSON from: {Path(path).resolve()}")
            print("✅ Categories:", self._categories)
            self.categoriesChanged.emit()
        except Exception as e:
            print(f"❌ Error loading JSON at {path}: {e}")
            self._data = {}
            self._categories = []
            self.categoriesChanged.emit()

    @Slot(str)
    def setJsonPath(self, path_str: str):
        p = Path(path_str)
        if not p.is_absolute():
            p = Path(__file__).resolve().parent / p
        self._json_path = p
        self._load_json(self._json_path)

    @Slot(result="QVariant")
    def getCategories(self):
        return self._categories

    @Slot(str, result="QVariant")
    def getFieldsForCategory(self, category):
        return self._data.get(category, [])

    @Slot(str)
    def requestCategoryContent(self, category):
        fields = self._data.get(category, [])
        self.categoryContentUpdated.emit(category, fields)

    @Slot(int, int)
    def nextTab(self, currentIndex, totalTabs):
        if totalTabs > 0:
            self.tabChangeRequested.emit((currentIndex + 1) % totalTabs)

    @Slot(int, int)
    def prevTab(self, currentIndex, totalTabs):
        if totalTabs > 0:
            self.tabChangeRequested.emit((currentIndex - 1 + totalTabs) % totalTabs)