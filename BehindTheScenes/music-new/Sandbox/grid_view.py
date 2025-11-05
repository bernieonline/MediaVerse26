import os
import glob
import logging
from PyQt5.QtWidgets import QWidget, QVBoxLayout, QFrame, QLabel, QScrollArea, QGridLayout
from PyQt5.QtCore import Qt, pyqtSignal
from PyQt5.QtGui import QPixmap, QPainter
import constants

log = logging.getLogger('GridView')
'''updated to show xml after left image change'''
class ImageHolderLabel(QLabel):
    """A QLabel subclass that scales the pixmap while preserving aspect ratio."""
    def __init__(self, pixmap, width, height, parent=None):
        super().__init__(parent)
        self.original_pixmap = pixmap
        self.setAlignment(Qt.AlignCenter)
        self.setStyleSheet("background-color: transparent;")
        self.setFixedSize(width, height)

    def paintEvent(self, event):
        if self.original_pixmap and not self.original_pixmap.isNull():
            scaled = self.original_pixmap.scaled(
                self.size(), Qt.KeepAspectRatio, Qt.SmoothTransformation
            )
            x = (self.width() - scaled.width()) / 2
            y = (self.height() - scaled.height()) / 2
            painter = QPainter(self)
            painter.drawPixmap(int(x), int(y), scaled)

class ClickableFrame(QFrame):
    clicked = pyqtSignal(str)

    def __init__(self, file_path, parent=None):
        super().__init__(parent)
        self.file_path = file_path

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton:
            log.info(f"Card clicked: {self.file_path}")
            self.clicked.emit(self.file_path)

class GridView(QWidget):
    back_to_carousel_requested = pyqtSignal()
    # Emit both image path and XML path
    media_selected_for_details = pyqtSignal(str, str)

    BASE_CARD_WIDTH = 450
    ASPECT_RATIO = 1.5
    TEXT_HEIGHT = 70
    TEST_MEDIA_FOLDER = r"W:\Collection\War Movies"

    def __init__(self, parent=None):
        super().__init__(parent)
        self.media_files = self._get_media_files()
        self.cards = []

        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(10, 10, 10, 10)
        main_layout.setSpacing(10)

        # Scroll area
        self.scroll_area = QScrollArea()
        self.scroll_area.setWidgetResizable(True)
        self.scroll_area.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.scroll_area.setVerticalScrollBarPolicy(Qt.ScrollBarAsNeeded)

        self.grid_container = QWidget()
        self.grid_layout = QGridLayout(self.grid_container)
        self.grid_layout.setContentsMargins(20, 20, 20, 20)
        self.grid_layout.setHorizontalSpacing(25)
        self.grid_layout.setVerticalSpacing(50)

        self.scroll_area.setWidget(self.grid_container)
        main_layout.addWidget(self.scroll_area, 1)

        self._populate_grid()

    def _card_clicked(self, image_file_path):
        """Handle clicks on a card, emit image path and corresponding XML path."""
        constants.selected_image_path = image_file_path

        # Construct XML path from image name
        base_name, _ = os.path.splitext(os.path.basename(image_file_path))
        xml_pattern = os.path.join(self.TEST_MEDIA_FOLDER, base_name + "*.xml")
        matching_xml_files = glob.glob(xml_pattern)
        xml_path = matching_xml_files[0] if matching_xml_files else ""

        # Emit both paths
        self.media_selected_for_details.emit(image_file_path, xml_path)

    def _populate_grid(self):
        """Populate the grid with image cards."""
        self.cards.clear()
        for path in self.media_files:
            card = self._create_image_card(path)
            self.cards.append(card)

        # Build the layout
        self._rebuild_grid(4, int(self.BASE_CARD_WIDTH), int(self.BASE_CARD_WIDTH * self.ASPECT_RATIO), 25)

    def _rebuild_grid(self, cols, card_width, card_height, grid_spacing):
        """Place existing cards into the grid layout."""
        if not self.cards:
            return

        # Clear layout
        while self.grid_layout.count():
            item = self.grid_layout.takeAt(0)
            w = item.widget()
            if w:
                w.setParent(None)

        # Place cards
        for i, card in enumerate(self.cards):
            row, col = divmod(i, cols)
            card.setFixedSize(card_width, card_height + self.TEXT_HEIGHT)
            self.grid_layout.addWidget(card, row, col)

    def _create_image_card(self, file_path, width=None, height=None):
        width = width or self.BASE_CARD_WIDTH
        height = height or int(width * self.ASPECT_RATIO)

        card = ClickableFrame(file_path, parent=self.grid_container)
        card.clicked.connect(self._card_clicked)
        card.setCursor(Qt.PointingHandCursor)
        card.setObjectName("grid_card")
        card.setStyleSheet("""
            QFrame#grid_card {
                background-color: #1a1a1a;
                border: 2px solid #555;
                border-radius: 8px;
            }
        """)
        total_height = height + self.TEXT_HEIGHT
        card.setFixedSize(width, total_height)

        vbox = QVBoxLayout(card)
        vbox.setContentsMargins(6, 6, 6, 6)
        vbox.setSpacing(6)

        pix = QPixmap(file_path)
        img_label = ImageHolderLabel(pix, max(20, width - 12), max(20, height - 12))
        img_label.setAttribute(Qt.WA_TransparentForMouseEvents, True)
        vbox.addWidget(img_label, 0, Qt.AlignCenter)

        title = os.path.splitext(os.path.basename(file_path))[0]
        lbl_title = QLabel(title)
        lbl_title.setAlignment(Qt.AlignCenter)
        lbl_title.setStyleSheet("color: white; font-weight: bold; font-size: 14pt;")
        lbl_title.setAttribute(Qt.WA_TransparentForMouseEvents, True)
        vbox.addWidget(lbl_title)

        return card

    def _get_media_files(self):
        if not os.path.exists(self.TEST_MEDIA_FOLDER):
            log.warning(f"Media folder not found: {self.TEST_MEDIA_FOLDER}")
            return []
        files = []
        for ext in ['*.jpg', '*.jpeg', '*.png', '*.webp']:
            files.extend(glob.glob(os.path.join(self.TEST_MEDIA_FOLDER, ext)))
        return files
