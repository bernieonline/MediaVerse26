import logging
import os
import xml.etree.ElementTree as ET
from PyQt5.QtWidgets import QWidget, QVBoxLayout, QTabWidget, QTextEdit, QLabel
from PyQt5.QtCore import Qt, QTimer



logging.basicConfig(
    level=logging.INFO,  # capture INFO and above
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    handlers=[
        logging.FileHandler('sandbox_application.log', mode='a')  # log only to file
    ]
)
log = logging.getLogger('DetailPanel')

# Define the expected naming convention for the metadata file
XML_SUFFIX = "_JRSidecar.xml"

class AboutTab(QWidget):
    """
    The 'About' tab responsible for loading, parsing, and displaying movie metadata from the XML sidecar.
    """
    def __init__(self, parent=None):
        super().__init__(parent)
        self.log = logging.getLogger('AboutTab')
        
        self.layout = QVBoxLayout(self)
        self.detail_display = QTextEdit()
        self.detail_display.setReadOnly(True)
        self.detail_display.setObjectName("detail_text_display") # For QSS styling
        self.detail_display.setText("Select a media item to view details.")
        
        self.layout.addWidget(self.detail_display)
        self.layout.setContentsMargins(10, 10, 10, 10) # Reduced margins for inner tab

    def load_details_from_path(self, media_file_path):
        """
        Public method called by the parent DetailPanelWidget.
        Finds the XML sidecar and initiates display.

        """
        print("media_file_path ",media_file_path)
        self.detail_display.setText(f"Loading details for: {os.path.basename(media_file_path)}...")
        print("fffffff",media_file_path)
        #result = media_file_path = W:\Collection\War Movies\Guns of Navarone (1961)_mp4_JRSidecar.xml
        #xml_path = self._find_sidecar_xml(media_file_path)
        #the use of xml path was not required
        xml_path = media_file_path
        print ("gggggg",xml_path)
        
        if xml_path:
            self.log.info(f"Found XML sidecar: {xml_path}")
            # Use QTimer.singleShot to allow the UI to update the 'Loading' message before parsing starts
            #QTimer.singleShot(10, lambda: self._display_xml_content(xml_path))
            QTimer.singleShot(10, lambda: self._display_xml_content(media_file_path))
            print ("hhhhhhh")
        else:
            self.detail_display.setText(f"<h1>Details Not Found</h1><p>Expected XML sidecar not found for: <b>{os.path.basename(media_file_path)}</b></p>")

    def _find_sidecar_xml(self, media_file_path):
        """Calculates the expected XML file path based on the media file."""
        
        base_dir = os.path.dirname(media_file_path)
        base_name_with_ext = os.path.basename(media_file_path)
        base_name, ext = os.path.splitext(base_name_with_ext)
        
        # Format: 'filename' + '_ext' + '_JRSidecar.xml' 
        # (e.g., 'american sniper (2014)' + '_mp4' + '_JRSidecar.xml')
        expected_xml_filename = f"{base_name}{ext.replace('.', '_')}{XML_SUFFIX}"
        
        full_xml_path = os.path.join(base_dir, expected_xml_filename)

        if os.path.exists(full_xml_path):
            return full_xml_path
        
        return None

    def _display_xml_content(self, xml_path):
        """Parses the XML and displays the content in readable HTML format."""
        #we use html to represent the displayed text
        output_html = "<h2>Movie Details</h2>"
        
        try:
            #
            #ET is an alias for xml.etree.ElementTree
            #it loads and parses the xml from disk
            #so the for loop generates a series of data rows in memory
            tree = ET.parse(xml_path)
            print("ggg2")
            #getroot gets the first row of information from the xml file
            root = tree.getroot()
            #it finds the item tag <item> in the xml
    
            item = root.find('Item')
            if item is not None:
                #so this for loop for field in item.findall('Field'):loops through each <field tag in turn>
                for field in item.findall('Field'):
                    try:
                        #each Field has a key value pair, such as director and clint eastwood
                        tag = field.attrib.get('Name', 'Unknown')
                        #this is the value of the key above
                        text = field.text.strip() if field.text else ""
                        #this formats the HTML output of the 2 values
                        output_html += f"<p style='margin-bottom: 5px;'><b>{tag.replace('_', ' ').title()}:</b> {text}</p>"
                    except Exception as inner_e:
                        print(f"Error processing field: {field.tag}, {inner_e}")
                else:
                    output_html += "<p>No <Item> found in XML.</p>"

        
            # Simple iteration to display all key/value pairs
            #for child in root:
                #print("ggg4")
                #tag = child.tag.split('}')[-1] if '}' in child.tag else child.tag 
                #print("ggg5")
                #text = child.text.strip() if child.text else ""
                #print("ggg6",tag,text)
                #prints only the word item
                
                #output_html += f"<p style='margin-bottom: 5px;'><b>{tag.replace('_', ' ').title()}:</b> {text}</p>"
                #print("ggg7")
            # this then displays all of our prepared html
            self.detail_display.setHtml(output_html)
            print("ggg8")
        
        except ET.ParseError as e:
            self.detail_display.setText(f"<h1>Error Parsing XML</h1><p>File: {os.path.basename(xml_path)}</p><p>Error: {e}</p>")
        except FileNotFoundError:
            self.detail_display.setText(f"<h1>Error</h1><p>XML file not found unexpectedly: {xml_path}</p>")
        except Exception as e:
            self.detail_display.setText(f"<h1>Unexpected Error</h1><p>An unknown error occurred: {e}</p>")


class DetailPanelWidget(QWidget):
    """
    The main container for the Detail Panel, using QTabWidget for future expansion.
    """
    def __init__(self, parent=None):
        super().__init__(parent)
        self.log = logging.getLogger('DetailPanelWidget')
        
        v_layout = QVBoxLayout(self)
        v_layout.setContentsMargins(0, 0, 0, 0)
        
        self.tabs = QTabWidget(self)
        self.tabs.setObjectName("detail_tabs") # For QSS styling
        
        # 1. Instantiate the new 'About' tab
        self.about_tab = AboutTab(self)
        self.tabs.addTab(self.about_tab, "About")
        
        # 2. Add other future tabs here (e.g., Playback, Cast, Tags)
        self.tabs.addTab(QLabel("Future Tab 2: Cast/Crew"), "Cast")
        
        v_layout.addWidget(self.tabs)
        self.setLayout(v_layout)
        
    def load_details(self, media_file_path):
        """
        Central entry point to load data into the 'About' tab.
        """
        self.about_tab.load_details_from_path(media_file_path)