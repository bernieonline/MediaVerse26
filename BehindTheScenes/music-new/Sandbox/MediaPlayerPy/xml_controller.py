import json
from pathlib import Path
import xml.etree.ElementTree as ET
from urllib.parse import urlparse, unquote
from PySide6.QtCore import QObject, Signal, Slot

# Import the paths dictionary
from project_paths import paths


class XmlController(QObject):
    categoriesChanged = Signal()
    tabChangeRequested = Signal(int)
    categoryContentUpdated = Signal(str, list)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._data = {}          # JSON categories {category: [fields]}
        self._categories = []    # category names
        self._json_path = None
        self._xml_fields = {}    # parsed XML fields {Name: Value}

        # Use central path system for JSON
        self._json_path = paths["json"]
        self._load_json(self._json_path)

    # ---------------- Helpers ----------------
    def _file_url_to_path(self, url_or_path: str) -> Path:
        """
        Convert a file URL (e.g., file:///W:/dir/file.jpg) to a local Path.
        If it's already a filesystem path, return Path as-is.
        """
        if url_or_path.startswith("file:"):
            parsed = urlparse(url_or_path)
            raw_path = unquote(parsed.path)
            # On Windows, strip leading slash before drive letter (/W:/ → W:/)
            if raw_path.startswith("/") and len(raw_path) > 2 and raw_path[2] == ":":
                raw_path = raw_path[1:]
            p = Path(raw_path)
            print(f"🔎 _file_url_to_path → URL: {url_or_path} → FS Path: {p}")
            return p
        else:
            p = Path(url_or_path)
            print(f"🔎 _file_url_to_path → Plain path: {p}")
            return p

    # ---------------- JSON loading ----------------
    def _load_json(self, path: Path):
        try:
            with Path(path).open("r", encoding="utf-8") as f:
                self._data = json.load(f)
            self._categories = list(self._data.keys())
            print(f"✅ XmlController loaded JSON from: {Path(path).resolve()}")
            print("✅ Categories:", self._categories)
            print("✅ Category → Fields mapping:", self._data)
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
        print("🔎 getCategories called →", self._categories)
        return self._categories

    @Slot(str, result="QVariant")
    def getFieldsForCategory(self, category):
        fields = self._data.get(category, [])
        print(f"🔎 getFieldsForCategory({category}) → {fields}")
        return fields

    # ---------------- XML parsing ----------------
    @Slot(str)
    def loadXML(self, image_path: str):
        """Parse XML sidecar file for the given image path."""
        try:
            print(f"🔎 loadXML called with image_path: {image_path}")
            img_fs_path = self._file_url_to_path(image_path)
            print(f"🔎 Image filesystem path: {img_fs_path}")

            # Construct expected JR sidecar filename: <stem>_mp4_JRSidecar.xml
            xml_path = img_fs_path.parent / f"{img_fs_path.stem}_mp4_JRSidecar.xml"
            print(f"🔎 Resolved sidecar candidate: {xml_path}")

            if not xml_path.exists():
                print(f"❌ Sidecar not found on disk: {xml_path}")
                self._xml_fields = {}
                return

            print(f"✅ Sidecar found: {xml_path}")
            tree = ET.parse(xml_path)
            root = tree.getroot()

            parsed = {}
            for field in root.findall(".//Field"):
                name = field.get("Name")
                value = field.text.strip() if field.text else ""
                if name:
                    parsed[name] = value

            self._xml_fields = parsed
            print(f"✅ Parsed XML fields: {len(parsed)} entries from {xml_path}")
            first_keys = list(parsed.keys())[:10]
            print(f"🔎 First 10 keys: {first_keys}")
            sample_vals = {k: parsed[k] for k in first_keys}
            print(f"🔎 Sample key→value: {sample_vals}")

        except Exception as e:
            print(f"❌ Error parsing XML for {image_path}: {e}")
            self._xml_fields = {}

    # ---------------- Category content ----------------
    @Slot(str)
    def requestCategoryContent(self, category):
        """Emit field:value pairs for the given category."""
        fields = self._data.get(category, [])
        print(f"🔎 requestCategoryContent({category}) → fields: {fields}")
        values = []
        for field in fields:
            val = self._xml_fields.get(field, "")
            if val:
                values.append(f"{field}: {val}")
            else:
                values.append(f"{field}: (no value)")
        print(f"🔎 Emitting values for {category}: {values}")
        self.categoryContentUpdated.emit(category, values)

    # ---------------- Tab navigation ----------------
    @Slot(int, int)
    def nextTab(self, currentIndex, totalTabs):
        if totalTabs > 0:
            new_index = (currentIndex + 1) % totalTabs
            print(f"🔎 nextTab → {new_index}")
            self.tabChangeRequested.emit(new_index)

    @Slot(int, int)
    def prevTab(self, currentIndex, totalTabs):
        if totalTabs > 0:
            new_index = (currentIndex - 1 + totalTabs) % totalTabs
            print(f"🔎 prevTab → {new_index}")
            self.tabChangeRequested.emit(new_index)