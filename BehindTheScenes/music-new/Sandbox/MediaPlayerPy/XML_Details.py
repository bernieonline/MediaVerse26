# XML_Details.py
from pathlib import Path
from PySide6.QtCore import QObject, Signal, Slot, QUrl

class GetXMLDetails(QObject):
    xml_detail_view = Signal(str)

    @Slot(str)
    def loadXML(self, imagePath: str):
        try:
            # 1) Normalize to local Windows path
            local_path = QUrl(imagePath).toLocalFile()
            img_path = Path(local_path)
            folder = img_path.parent
            stem = img_path.stem  # e.g., "A Perfect World (1993)"

            print("[XML_Details] Raw imagePath:", imagePath)
            print("[XML_Details] Local path:", local_path)
            print("[XML_Details] Folder:", folder)
            print("[XML_Details] Image stem:", stem)

            # 2) Find XMLs whose filename contains the stem (case-insensitive)
            candidates = list(folder.glob("*.xml"))
            matches = [p for p in candidates if stem.lower() in p.stem.lower()]

            # Optional: prefer more specific matches (e.g., those ending with 'Sidecar')
            def score(p: Path) -> int:
                s = p.stem.lower()
                return (
                    (1 if s.endswith("sidecar") else 0) +
                    (1 if "jrsidecar" in s else 0) +
                    (1 if "_mp4_" in s or "mp4" in s else 0)
                )

            chosen = None
            if matches:
                # Pick the highest scoring match; tie-break by shortest name
                matches.sort(key=lambda p: (-score(p), len(p.name)))
                chosen = matches[0]

            # 3) Log what we found
            print("[XML_Details] XML candidates:", [p.name for p in candidates])
            print("[XML_Details] Matches:", [p.name for p in matches])
            print("[XML_Details] Chosen:", chosen if chosen else "None")

            # 4) Read and emit, or report not found
            if chosen and chosen.exists():
                with open(chosen, "r", encoding="utf-8") as f:
                    xml_text = f.read()
                print("[XML_Details] Found XML file:", chosen)
                print("[XML_Details] --- XML Content Start ---")
                print(xml_text)
                print("[XML_Details] --- XML Content End ---")
                self.xml_detail_view.emit(xml_text)
            else:
                msg = f"Sidecar not found for stem '{stem}'. Checked {len(candidates)} XMLs."
                print("[XML_Details]", msg)
                self.xml_detail_view.emit(msg)

        except Exception as e:
            print("[XML_Details] Exception:", e)
            self.xml_detail_view.emit(str(e))