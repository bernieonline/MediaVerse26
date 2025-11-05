import logging
import os
import glob
# CRITICAL: Import pyqtSignal for emitting events
from PyQt5.QtWidgets import (
    QWidget, QStackedWidget, QGridLayout, QLabel, QVBoxLayout
)
from PyQt5.QtCore import Qt, QSize, pyqtSignal
from PyQt5.QtGui import QPixmap, QFont
# Ensure os.path is available for splitext
import os.path 

# Setup logging for this module
log = logging.getLogger('ContentPanel')

class ContentPanel(QWidget):
    """
    Manages the two main content views (Matrix and Carousel) using a QStackedWidget.
    """
    def __init__(self, parent=None):
        super().__init__(parent)
        self.log = logging.getLogger('ContentPanel')
        
        self.stacked_widget = QStackedWidget(self)
        self.stacked_widget.setObjectName("content_stacked_widget")

        self.matrix_view = MatrixViewWidget(self)
        self.carousel_view = CarouselViewWidget(self)
        self.carousel_view.setObjectName("carousel_view_widget")

        self.stacked_widget.addWidget(self.matrix_view) # Index 0: Matrix View
        self.stacked_widget.addWidget(self.carousel_view) # Index 1: Carousel View
        
        # Start at carousel and set focus immediately
        self.stacked_widget.setCurrentIndex(1) 
        self.carousel_view.setFocus(Qt.ActiveWindowFocusReason) 

        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.addWidget(self.stacked_widget)
        self.setLayout(main_layout)
        
        self.log.info("ContentPanel initialized with Matrix and Carousel views.")
        
    def showEvent(self, event):
        """Ensure the active view has focus when the main widget becomes visible/active."""
        super().showEvent(event)
        if self.stacked_widget.currentIndex() == 1:
            self.carousel_view.setFocus(Qt.ActiveWindowFocusReason)


    def toggle_view(self):
        """Switches between the Matrix (0) and Carousel (1) views."""
        current_index = self.stacked_widget.currentIndex()
        new_index = 1 - current_index
        self.stacked_widget.setCurrentIndex(new_index)
        
        if new_index == 1:
            self.carousel_view.setFocus(Qt.ActiveWindowFocusReason)
            view_name = "Carousel"
        else:
            view_name = "Matrix"
            
        self.log.info(f"Content view toggled to: {view_name}")

class MatrixViewWidget(QWidget):
    """
    Placeholder for the Scrollable Grid/Matrix view.
    """
    def __init__(self, parent=None):
        super().__init__(parent)
        
        layout = QGridLayout(self)
        label = QLabel("Matrix View - Placeholder for Scrollable Image Grid")
        label.setAlignment(Qt.AlignCenter)
        layout.addWidget(label, 0, 0)

class CarouselViewWidget(QWidget):
    """
    Displays the dynamic, responsive row of carousel images.
    """
    # CRITICAL FIX: Define the signal that main_app.py connects to
    # This signal will carry the full path to the XML metadata file
    media_selected_for_details = pyqtSignal(str) 

    def __init__(self, parent=None):
        super().__init__(parent)
        self.log = logging.getLogger('CarouselViewWidget')
        
        # --- FOCUS ENABLEMENT ---
        self.setFocusPolicy(Qt.StrongFocus) # Required to receive keyPressEvent
        
        # --- IMAGE DATA CONFIGURATION ---
        self.IMAGE_BASE_PATH = "W:/Collection/War Movies/" 
        self.image_files = self._load_image_files() 

        self.TEST_MEDIA_FOLDER = r"W:\Collection\War Movies"
        
        # CRITICAL CHANGE: Start index set to 2.
        # This makes the visible indices start at self.center_index - 2.
        # If center_index=2, visible indices are [0, 1, 2, 3, 4].
        # The center item (index 2) will then display the image at index 0 (if enough images exist).
        self.center_index = 2 
        # --- END IMAGE DATA CONFIGURATION ---
        
        self.item_ratios = [0.4, 0.6, 1.0, 0.6, 0.4]
        self.aspect_ratio = 2 / 3 # Portrait 2:3 ratio

        self.labels = []
        for i in range(21):
            label = QLabel(self)
            label.setObjectName(f"carousel_label_{i}")
            label.setAlignment(Qt.AlignCenter)
            label.setStyleSheet("background-color: black; color: white;") 
            label.setFont(QFont("Arial", 10))
            label.setVisible(False)
            self.labels.append(label)
            
        self._setup_navigation_buttons()
        
        self.log.info(f"CarouselViewWidget initialized. Total images loaded: {len(self.image_files)}")
        
    def _setup_navigation_buttons(self):
        """Creates the clickable QLabel objects for navigation."""
        
        # Left Arrow Placeholder
        self.btn_left = QLabel("◀", self)
        self.btn_left.setAlignment(Qt.AlignCenter)
        self.btn_left.setStyleSheet("background-color: rgba(0, 0, 0, 150); color: white; border-radius: 10px; padding: 10px; font-size: 24pt;")
        self.btn_left.setFixedSize(QSize(50, 80))
        self.btn_left.setVisible(False)
        
        # Right Arrow Placeholder
        self.btn_right = QLabel("▶", self)
        self.btn_right.setAlignment(Qt.AlignCenter)
        self.btn_right.setStyleSheet("background-color: rgba(0, 0, 0, 150); color: white; border-radius: 10px; padding: 10px; font-size: 24pt;")
        self.btn_right.setFixedSize(QSize(50, 80))
        self.btn_right.setVisible(False)

    def _load_image_files(self):
        """
        Scans the IMAGE_BASE_PATH for image files and returns a list of filenames.
        """
        image_extensions = ('.jpg', '.jpeg', '.png', '.webp', '.gif') 
        files = []
        try:
            all_files = os.listdir(self.IMAGE_BASE_PATH)
            files = [
                f for f in all_files 
                if os.path.isfile(os.path.join(self.IMAGE_BASE_PATH, f)) and f.lower().endswith(image_extensions)
            ]
            self.log.info(f"Dynamically loaded {len(files)} image files from directory.")
            
        except FileNotFoundError:
            self.log.error(f"Image directory not found: {self.IMAGE_BASE_PATH}. Check if the W: drive is mounted.")
        except Exception as e:
            self.log.error(f"Error listing files in directory: {e}")
            
        return files
    
    def _load_and_scale_image(self, file_name, width, height):
        """
        Loads an image, scales it using the KeepAspectRatioByExpanding mode (Strict Cropping),
        and returns the scaled QPixmap.
        """
        full_path = os.path.join(self.IMAGE_BASE_PATH, file_name)
        
        if not os.path.exists(full_path):
            self.log.warning(f"Image not found at: {full_path}")
            return QPixmap() 

        pixmap = QPixmap(full_path)

        if pixmap.isNull():
            self.log.warning(f"Could not load QPixmap from: {full_path}")
            return QPixmap() 

        # STRICT CROPPING (Strategy 1)
        scaled_pixmap = pixmap.scaled(
            QSize(width, height), 
            Qt.KeepAspectRatioByExpanding, 
            Qt.SmoothTransformation
        )
        return scaled_pixmap

    def _move_carousel(self, direction):
        """
        Helper function to change the center index and trigger a redraw.
        Direction is +1 for right, -1 for left.
        """
        current_index = self.center_index
        max_index = len(self.image_files) + 1 # +1 accounts for the two blank slots on the right
        
        if direction == -1: # Move Left
            # Stops when the blank slot on the left is no longer visible
            if current_index > 2: 
                self.center_index -= 1
                self.log.info(f"Move Left: New center index {self.center_index}")
                self.resizeEvent(None) 
            else:
                self.log.info("Move Left: Reached start of collection.")
                
        elif direction == 1: # Move Right
            # Stops when the center item is the last image in the collection
            if current_index < max_index: 
                self.center_index += 1
                self.log.info(f"Move Right: New center index {self.center_index}")
                self.resizeEvent(None) 
            else:
                self.log.info("Move Right: Reached end of collection.")


    def keyPressEvent(self, event):
        """
        Handles key presses for navigation (Left/Right arrows) using the new helper.
        """
        if not self.image_files:
            super().keyPressEvent(event)
            return

        if event.key() == Qt.Key_Left:
            self._move_carousel(-1)
        elif event.key() == Qt.Key_Right:
            self._move_carousel(1)
        else:
            super().keyPressEvent(event)

    def mousePressEvent(self, event):
        """
        Handles mouse clicks to trigger navigation via the arrow labels or 
        selection via any of the visible image labels.
        """
        if event.button() == Qt.LeftButton:
            pos = event.pos()
            
            # 1. Check if a navigation button was clicked
            if self.btn_left.geometry().contains(pos) and self.btn_left.isVisible():
                self._move_carousel(-1) # Move Left
                return
                
            elif self.btn_right.geometry().contains(pos) and self.btn_right.isVisible():
                self._move_carousel(1) # Move Right
                return
            
            # 2. Iterate through the five visible image labels (indices 0 to 4)
            # The logic previously only checked self.labels[2] (center)
            collection_length = len(self.image_files)
            
            for i in range(5):
                label = self.labels[i]
                
                # Check if the label is visible and contains the click position
                if label.isVisible() and label.geometry().contains(pos):
                    
                    # Calculate the actual index in the image_files list (relative to the first image which starts at center_index 2)
                    # The formula is: center_index + (label_index i) - 4
                    # This correctly maps i=0 to img_index=center_index-4 (first visible item)
                    # and i=2 to img_index=center_index-2 (center item)
                    img_index = self.center_index + i - 4 
                    
                    if 0 <= img_index < collection_length:
                        # Get the image file name (e.g., 'A Bridge Too Far.jpg')
                        file_name = self.image_files[img_index]
                        print("inside mousepressevent carousel content file_name ",file_name)
                        #this is the correct filename
                        # Derive the XML file name (e.g., 'A Bridge Too Far.xml')
                        base_name, _ = os.path.splitext(file_name)
                        #xml_file_name = base_name + ".xml"
                        
                        # Construct the full path to the XML file
                        #my error here
                        #xml_path = os.path.join(self.IMAGE_BASE_PATH, xml_file_name)
                        xml_path = self.get_xml_path(base_name)
                        
                        print("inside mousepressevent carousel content xml_path ",xml_path)
                        # Emit the signal with the file path
                        self.media_selected_for_details.emit(xml_path)
                        self.log.info(f"Side media selected (Label {i}): Emitting XML path for {xml_path}")
                        return # Stop processing after successful click
            
            # If no navigation button or image was clicked, pass the event up
            super().mousePressEvent(event)
        else:
            super().mousePressEvent(event)
    def get_xml_path(self, base_name):
        file_name, _ = os.path.splitext(base_name)
        xml_file_name = file_name + ".xml"
        xml_path = os.path.join(self.IMAGE_BASE_PATH, xml_file_name)
        print("inside mousepressevent carousel content xml_path ",xml_path)

        #base_name, _ = os.path.splitext(os.path.basename(image_file_path))
        xml_pattern = os.path.join(self.TEST_MEDIA_FOLDER, base_name + "*.xml")
        matching_xml_files = glob.glob(xml_pattern)
        xml_path = matching_xml_files[0] if matching_xml_files else ""

        
        
        return xml_path

    def resizeEvent(self, event):
        """
        Calculates and sets the geometry for visible carousel items whenever the widget resizes,
        and loads/scales the actual images.
        """
        if event is not None:
            super().resizeEvent(event) 
        
        panel_width = self.width()
        panel_height = self.height()
        
        if panel_width <= 0 or panel_height <= 0:
            return

        # 1. Calculate the MAX acceptable size for the center item (ratio 1.0)
        max_height = panel_height * 0.9 
        max_width_by_height = max_height * self.aspect_ratio
        max_width_by_panel = panel_width * 0.25
        
        center_width_final = min(max_width_by_height, max_width_by_panel)
        center_height_final = center_width_final / self.aspect_ratio
        
        # 2. Define the sizes of the 5 core items based on the final center size
        item_data = [] 
        for ratio in self.item_ratios:
            h = center_height_final * ratio
            w = h * self.aspect_ratio
            item_data.append({'w': w, 'h': h, 'ratio': ratio})

        # 3. Calculate total space taken by the 5 core items
        spacing = center_width_final * 0.02
        core_widths = sum(d['w'] for d in item_data)
        core_spacing = spacing * (len(self.item_ratios) - 1)
        total_core_width = core_widths + core_spacing
        
        # 5. Build the list of 5 visible indices (centered on self.center_index)
        # These are the *potential* indices into the combined image/blank stream
        visible_indices = [
            self.center_index - 2, 
            self.center_index - 1, 
            self.center_index,    # CENTER
            self.center_index + 1, 
            self.center_index + 2
        ]
        
        # 6. Build the final list of item geometries (5 items total)
        visible_items_data = []
        
        def get_item_geom(ratio_index):
              return {'w': item_data[ratio_index]['w'], 'h': item_data[ratio_index]['h']}

        for j in range(5):
              ratio_index = j 
              visible_items_data.append({**get_item_geom(ratio_index), 'img_idx': visible_indices[j]})
            
        # 7. Calculate start position for centering the entire group
        total_visible_width = total_core_width 
        x_start = (panel_width - total_visible_width) / 2
        current_x = x_start

        # 8. Position, load image, and show the labels (only 5 will be processed)
        label_index_counter = 0
        for label in self.labels:
            label.setVisible(False)
            
        collection_length = len(self.image_files)

        for item in visible_items_data:
            label = self.labels[label_index_counter]
            item_y_pos = (panel_height - item['h']) / 2
            
            # --- IMAGE INDEX LOGIC (Strict Boundary Check) ---
            img_index = item['img_idx'] - 2 # Adjust index relative to the first image (index 2)
            
            # Check if the adjusted index is within the actual image collection bounds
            if 0 <= img_index < collection_length:
                # Load the actual image
                file_name = self.image_files[img_index]
                scaled_pixmap = self._load_and_scale_image(
                    file_name,
                    int(item['w']), 
                    int(item['h'])
                )
                
                if scaled_pixmap.isNull():
                     # Fallback for file not found
                     label.setPixmap(QPixmap()) 
                     label.setText(f"Missing:\n{file_name}\n({int(item['w'])}x{int(item['h'])})")
                     label.setStyleSheet("background-color: #333; color: white; border: 1px solid #ffaa00;")
                else:
                     # Success: Display the image
                     label.setPixmap(scaled_pixmap)
                     label.setText("") 
                     label.setStyleSheet("background-color: transparent;")
            else:
                # This handles the blank spaces at the start and end of the scroll stream
                label.setPixmap(QPixmap()) 
                label.setText("") 
                label.setStyleSheet("background-color: transparent; border: none;")

            # Apply geometry and make visible
            label.setGeometry(
                int(current_x), 
                int(item_y_pos), 
                int(item['w']), 
                int(item['h'])
            )
            label.setVisible(True)
            current_x += item['w'] + spacing
            label_index_counter += 1
            
        # 9. Position Navigation Buttons
        if collection_length > 0:
            btn_height = self.btn_left.height()
            btn_width = self.btn_left.width()
            btn_y = (panel_height - btn_height) / 2
            
            # Left Button Position: centered height, x position is just left of the first item
            btn_left_x = x_start - spacing - btn_width
            self.btn_left.setGeometry(int(btn_left_x), int(btn_y), btn_width, btn_height)
            
            # Right Button Position: centered height, x position is just right of the last item
            btn_right_x = current_x + spacing - btn_width # Adjust back by one width for centering effect
            self.btn_right.setGeometry(int(btn_right_x), int(btn_y), btn_width, btn_height)
            
            # Visibility based on boundary conditions
            # Only show left arrow if we are not showing the first item centered
            self.btn_left.setVisible(self.center_index > 2)
            # Only show right arrow if the last image is not yet centered (and we have enough images)
            self.btn_right.setVisible(self.center_index < collection_length + 1)
        else:
            self.btn_left.setVisible(False)
            self.btn_right.setVisible(False)


    # Remove paintEvent as QPixmap handles the display now.
    def paintEvent(self, event):
        pass