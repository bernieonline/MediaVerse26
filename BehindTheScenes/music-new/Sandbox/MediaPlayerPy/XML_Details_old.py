# XML_Details.py
import os
from PySide6.QtCore import QObject, Signal, Slot

class GetXMLDetails(QObject):
    """
    Provides XML details for a selected image.
    Exposes a slot 'getXML_for_details' to QML and emits 'xml_detail_view' signal.
    """
    xml_detail_view = Signal(str)  # Signal to send XML text to QML

    def __init__(self, parent=None):
        super().__init__(parent)

    @Slot(str)
    def loadXML(self, imagePath: str):


        print("inside loadXml with imagePath:,", imagePath)
        """
        Given the full path of an image, find a corresponding XML file in the same folder
        whose filename contains the image filename as a substring.
        Emits 'xml_detail_view' with a string result.
        """
        folder = os.path.dirname(imagePath)
        base_name = os.path.splitext(os.path.basename(imagePath))[0]
        xml_file = None

        # Search for XML file matching image name
        try:
            for f in os.listdir(folder):
                if f.lower().endswith(".xml") and base_name in f:
                    xml_file = os.path.join(folder, f)
                    break

            if xml_file:
                # For now, just return the file path as text; XML parsing can be added later
                text = f"Found XML file: {xml_file}"
            else:
                text = "No XML details available"

             # Terminal confirmation
            print(f"[XML_Details] Emitted XML details: {text}")

            self.xml_detail_view.emit(text)
            print(f"[XML_Details] Emitted XML details: {text}")

        except Exception as e:
            text = f"Error finding XML: {str(e)}"
            self.xml_detail_view.emit(text)
            print(f"[XML_Details] Exception: {str(e)}")


# -----------------------
# Self-test block
# -----------------------
if __name__ == "__main__":
    # Example: Test directly from Python
    provider = GetXMLDetails()

    def print_xml(text):
        print("Received from signal:", text)

    provider.xml_detail_view.connect(print_xml)

    # Replace with a valid image path on your system for testing
    test_image_path = r"W:/Collection/1990s/As Good As It Gets (1997).jpg"
    provider.getXML_for_details(test_image_path)
