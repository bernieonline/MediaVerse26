import logging
import os
import xml.etree.ElementTree as ET
from pathlib import Path
from PySide6.QtCore import QObject, Signal, Slot, Property

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[logging.FileHandler("sandbox_application.log", mode="a")]
)
log = logging.getLogger("DetailProvider")


XML_SUFFIX = "_JRSidecar.xml"


class DetailProvider(QObject):
    """
    Exposes parsed XML metadata to QML.
    """

    # Signals for each property
    detailsChanged = Signal(str)
    actorsChanged = Signal(str)
    directorChanged = Signal(str)
    filmingChanged = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._details = "Select a media item to view details."
        self._actors = ""
        self._director = ""
        self._filming = ""

    # Properties exposed to QML
    @Property(str, notify=detailsChanged)
    def details(self):
        return self._details

    @Property(str, notify=actorsChanged)
    def actors(self):
        return self._actors

    @Property(str, notify=directorChanged)
    def director(self):
        return self._director

    @Property(str, notify=filmingChanged)
    def filming(self):
        return self._filming

    @Slot(str)
    def loadDetails(self, media_file_path: str):
        """
        Called from QML (e.g. onClicked).
        Receives the image/media path, finds the XML sidecar, parses it,
        and updates the properties.
        """
        log.info(f"Loading details for: {media_file_path}")
        log.info(">>> loadDetails called with: %s", media_file_path)
        xml_path = self._find_sidecar_xml(media_file_path)

        if not xml_path:
            self._details = f"<h1>Details Not Found</h1><p>No XML sidecar for: <b>{os.path.basename(media_file_path)}</b></p>"
            self.detailsChanged.emit(self._details)
            return

        try:
            tree = ET.parse(xml_path)
            root = tree.getroot()
            item = root.find("Item")

            # Reset values
            self._details = ""
            self._actors = ""
            self._director = ""
            self._filming = ""

            if item is not None:
                # Collect all fields
                for field in item.findall("Field"):
                    tag = field.attrib.get("Name", "Unknown")
                    text = field.text.strip() if field.text else ""

                    # Route fields to the right property
                    if tag.lower() == "actors":
                        self._actors = text
                        self.actorsChanged.emit(self._actors)
                    elif tag.lower() == "director":
                        self._director = text
                        self.directorChanged.emit(self._director)
                    elif tag.lower() in ("filming", "filming_location"):
                        self._filming = text
                        self.filmingChanged.emit(self._filming)
                    else:
                        # Everything else goes into details
                        self._details += f"<p style='margin-bottom: 5px;'><b>{tag.replace('_',' ').title()}:</b> {text}</p>"

                if not self._details:
                    self._details = "<p>No general details found.</p>"
            else:
                self._details = "<p>No <Item> found in XML.</p>"

            # Emit signals
            self.detailsChanged.emit(self._details)
            if self._actors: self.actorsChanged.emit(self._actors)
            if self._director: self.directorChanged.emit(self._director)
            if self._filming: self.filmingChanged.emit(self._filming)

        except Exception as e:
            self._details = f"<h1>Error</h1><p>{e}</p>"
            self.detailsChanged.emit(self._details)

    def _find_sidecar_xml(self, media_file_path: str):
        media_path = Path(media_file_path)
        parent_dir = media_path.parent
        base_name = media_path.stem.lower()

        candidates = []
        for p in parent_dir.glob("*.xml"):
            if base_name in p.stem.lower():
                candidates.append(p)

        if not candidates:
            log.info("No XML candidates found in %s containing '%s'", parent_dir, base_name)
            return None

        # Prefer exact match if available
        exact = [p for p in candidates if p.stem.lower() == base_name]
        if exact:
            return str(exact[0])

        # Otherwise pick the shortest stem (closest match)
        candidates.sort(key=lambda p: len(p.stem))
        return str(candidates[0])