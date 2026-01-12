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
            #print(f"✅ XmlController loaded JSON from: {Path(path).resolve()}")
            #print("✅ Categories:", self._categories)
            #print("✅ Category → Fields mapping:", self._data)
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
    def loadXMLOld(self, image_path: str):
        """Parse XML sidecar file for the given image path."""
        try:
            print(f"🔎 loadXML called with image_path: {image_path}")
            img_fs_path = self._file_url_to_path(image_path)
            stem = img_fs_path.stem
            folder = img_fs_path.parent

            print(f"🔎 Looking for XML sidecar in {folder} with stem '{stem}'")

            # Find any .xml file in the folder that starts with the image stem
            matches = list(folder.glob(f"{stem}*.xml"))

            if not matches:
                print(f"❌ No XML sidecar found for {image_path}")
                self._xml_fields = {}
                return

            # Take the first match
            xml_path = matches[0]
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
        print(f"🔎 BG Emitting values for {category}: {values}")
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


    @Slot(str)
    def loadXML(self, xml_path_str: str):
        """Load XML directly from the provided server path."""
        try:
            print("────────────────────────────────────────────")
            print(f"📥 [XmlController] loadXML() called")
            print(f"    Raw xmlPath: {xml_path_str}")

            xml_fs_path = self._file_url_to_path(xml_path_str)
            print(f"    Resolved filesystem path: {xml_fs_path}")

            tree = ET.parse(xml_fs_path)
            root = tree.getroot()

            parsed = {}
            for field in root.findall(".//Field"):
                name = field.get("Name")
                value = field.text.strip() if field.text else ""
                if name:
                    parsed[name] = value

            self._xml_fields = parsed
            print(f"    Parsed fields: {len(parsed)} entries")
            print("📄 [XmlController] XML load complete")
            print("────────────────────────────────────────────")

        except Exception as e:
            print("❌ [XmlController] XML load FAILED")
            print(f"    Path: {xml_path_str}")
            print(f"    Error: {e}")
            print("────────────────────────────────────────────")
            self._xml_fields = {}

    @Slot(str, result="QVariantMap")
    def resolve_paths(self, manifest_display_path):
        import urllib.parse
        import os
        from pathlib import Path

        #print("\n==============================")
        #print("[resolve_paths] START")
        #print(f"[resolve_paths] manifest_display_path = {manifest_display_path}")

        # ------------------------------------------------------------
        # 0. Normalize and decode the incoming path
        # ------------------------------------------------------------
        raw = manifest_display_path or ""
        raw = urllib.parse.unquote(raw)  # decode %20 etc.

        # Strip file:/// prefix if present
        if raw.startswith("file:///"):
            raw = raw[8:]

        raw_norm = raw.replace("\\", "/")
        print(f"[resolve_paths] normalized input = {raw_norm}")

        # ------------------------------------------------------------
        # 1. Determine whether this is a thumb or display path
        # ------------------------------------------------------------
        is_thumb = "cacheV2/images/thumb" in raw_norm
        is_display = "cacheV2/images/display" in raw_norm

        # Extract filename
        filename = os.path.basename(raw_norm)
        print(f"[resolve_paths] filename = {filename}")
        print(f"[resolve_paths] is_thumb={is_thumb}, is_display={is_display}")

        # ------------------------------------------------------------
        # 2. Build the correct display image path
        # ------------------------------------------------------------
        display_root = Path(paths["local_display_v2"])
        print(f"[resolve_paths] local_display_v2 = {display_root}")

        if is_thumb:
            # Convert thumb → display
            display_path = display_root / filename
        else:
            # Already a display path
            display_path = Path(raw_norm)

        # Always convert to file:/// URI
        image_path = "file:///" + str(display_path).replace("\\", "/")
        print(f"[resolve_paths] resolved image_path = {image_path}")

        # ------------------------------------------------------------
        # 3. Manifest lookup for XML
        # ------------------------------------------------------------
        manifest_file = Path(paths["server_manifest_v2"])
        print(f"[resolve_paths] manifest file = {manifest_file}")

        xml_path = ""

        try:
            with open(manifest_file, "r", encoding="utf-8") as f:
                manifest = json.load(f)

            items = manifest.get("items", [])
            print(f"[resolve_paths] manifest loaded, items = {len(items)}")

            # Match by filename only (most reliable)
            for item in items:
                manifest_display = item["cache"]["display"]
                manifest_filename = os.path.basename(manifest_display)

                if manifest_filename == filename:
                    xml_path = Path(item["shared"]["xml"]).as_uri()
                    video_path = item["shared"].get("video", "")
                    print(f"[resolve_paths] MATCH FOUND → xml_path = {xml_path}")
                    video_path = str(item["shared"].get("video", "") or "")

                    break

            if not xml_path:
                print("[resolve_paths] WARNING: No matching XML entry found in manifest")

        except Exception as e:
            print(f"[resolve_paths] ERROR reading manifest: {e}")

        print("[resolve_paths] END")
        print("==============================\n")

        return {
            "image": image_path,
            "xml": xml_path,
            "video": video_path


        }