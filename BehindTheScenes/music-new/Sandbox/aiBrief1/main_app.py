import logging
import os
import sys
from PyQt5.QtWidgets import QWidget, QApplication, QVBoxLayout, QGridLayout, QStackedWidget, QLabel, QPushButton, QHBoxLayout
from PyQt5.QtCore import Qt, pyqtSignal
from PyQt5.QtGui import QPixmap

from carousel_content import ContentPanel
from grid_view import GridView
from detail_panel import DetailPanelWidget

log = logging.getLogger('MainApp')
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    handlers=[logging.FileHandler('sandbox_application.log', mode='a')]
)

# --------------------------
# ControlBar definition
# --------------------------
class ControlBar(QWidget):
    view_toggled = pyqtSignal(str)  # emits 'carousel' or 'grid'

    def __init__(self, parent=None):
        super().__init__(parent)
        layout = QHBoxLayout(self)
        self.carousel_btn = QPushButton("Carousel")
        self.grid_btn = QPushButton("Grid")
        layout.addWidget(self.carousel_btn)
        layout.addWidget(self.grid_btn)
        layout.addStretch()

        self.carousel_btn.clicked.connect(lambda: self.view_toggled.emit("carousel"))
        self.grid_btn.clicked.connect(lambda: self.view_toggled.emit("grid"))


# --------------------------
# Main Application
# --------------------------
class prototype_pc_monitor(QWidget):
    """Main app window with carousel, grid, and single-image split view."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("prototype_pc_monitor")
        self.log = logging.getLogger('AboutTab')

        self._load_qss_theme()

        # Main layout
        main_v_layout = QVBoxLayout(self)
        main_v_layout.setContentsMargins(0, 0, 0, 0)
        main_v_layout.setSpacing(0)

        # Control bar
        self.control_bar = ControlBar(self)
        main_v_layout.addWidget(self.control_bar)

        # Main stacked widget
        self.main_stack = QStackedWidget(self)
        self.main_stack.setObjectName("main_stacked_widget")

        # Pages
        self.carousel_split_page = self._create_carousel_split_page()
        self.main_stack.addWidget(self.carousel_split_page)

        self.grid_page = self._create_grid_page()
        self.main_stack.addWidget(self.grid_page)

        self.single_image_split_page = self._create_single_image_split_page()
        self.main_stack.addWidget(self.single_image_split_page)

        main_v_layout.addWidget(self.main_stack)
        self.setLayout(main_v_layout)
        self.setWindowState(Qt.WindowState.WindowMaximized)

        self._setup_connections()
        log.info("Application initialized with carousel, grid, and single-image pages.")

        # Current poster pixmap for scaling
        self._single_image_pixmap = None

    def _setup_connections(self):
        # Carousel clicks
        self.content_controller.carousel_view.media_selected_for_details.connect(
            self._handle_carousel_selection
        )
        # Grid clicks: now emits (image_path, xml_path)
        self.grid_page.media_selected_for_details.connect(self._handle_grid_selection)
        # Control bar
        self.control_bar.view_toggled.connect(self._handle_view_toggle)

    # ----------------------------
    # Page creation
    # ----------------------------
    def _create_carousel_split_page(self):
        page = QWidget()
        layout = QGridLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        self.content_controller = ContentPanel(page)
        self.detail_panel = DetailPanelWidget(page)
        self.detail_panel.setHidden(True)

        layout.addWidget(self.content_controller, 0, 0)
        layout.addWidget(self.detail_panel, 0, 1)
        layout.setColumnStretch(0, 1)
        layout.setColumnStretch(1, 0)

        return page

    def _create_grid_page(self):
        grid = GridView(parent=self.main_stack)
        grid.back_to_carousel_requested.connect(self._show_carousel_page)
        return grid

    def _create_single_image_split_page(self):
        page = QWidget()
        layout = QGridLayout(page)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # Left: poster label
        self.single_image_label = QLabel(page)
        self.single_image_label.setAlignment(Qt.AlignCenter)
        layout.addWidget(self.single_image_label, 0, 0)

        # Right: detail panel
        self.single_image_detail_panel = DetailPanelWidget(page)
        layout.addWidget(self.single_image_detail_panel, 0, 1)

        layout.setColumnStretch(0, 1)
        layout.setColumnStretch(1, 1)

        return page

    # ----------------------------
    # Event handlers
    # ----------------------------
    def _handle_carousel_selection(self, media_file_path):
        print("inside _handle_carousel_selection",media_file_path)
        self.detail_panel.load_details(media_file_path) #sends wrong path
        print("main_app inside carousel selection testing xml path",media_file_path)
        if self.main_stack.currentWidget() != self.carousel_split_page:
            self.main_stack.setCurrentWidget(self.carousel_split_page)
        self.toggle_carousel_split_view(True)

    def _handle_grid_selection(self, image_path, xml_path):
        """Display single-image split page with poster and XML details."""
        if xml_path:
            self.single_image_detail_panel.load_details(xml_path)

        if image_path:
            self._single_image_pixmap = QPixmap(image_path)
            self.main_stack.setCurrentWidget(self.single_image_split_page)
            self._scale_single_image()

    def _handle_view_toggle(self, view_name: str):
        if view_name == "carousel":
            self._show_carousel_page()
        elif view_name == "grid":
            self._show_grid_page()

    # ----------------------------
    # Page switches
    # ----------------------------
    def _show_carousel_page(self):
        self.main_stack.setCurrentWidget(self.carousel_split_page)

    def _show_grid_page(self):
        self.main_stack.setCurrentWidget(self.grid_page)

    def toggle_carousel_split_view(self, show: bool):
        """Show/hide detail panel in carousel page."""
        self.detail_panel.setHidden(not show)
        layout = self.carousel_split_page.layout()
        if show:
            layout.setColumnStretch(0, 1)
            layout.setColumnStretch(1, 1)
        else:
            layout.setColumnStretch(0, 1)
            layout.setColumnStretch(1, 0)

    # ----------------------------
    # Image scaling for single-image split
    # ----------------------------
    def _scale_single_image(self):
        if self._single_image_pixmap and not self._single_image_pixmap.isNull():
            w = self.single_image_label.width()
            h = self.single_image_label.height()
            if w > 0 and h > 0:
                scaled = self._single_image_pixmap.scaled(w, h, Qt.KeepAspectRatio, Qt.SmoothTransformation)
                self.single_image_label.setPixmap(scaled)

    def resizeEvent(self, event):
        super().resizeEvent(event)
        self._scale_single_image()

    # ----------------------------
    # Theme
    # ----------------------------
    def _load_qss_theme(self):
        qss_path = os.path.join(os.path.dirname(__file__), 'cinema_theme_pc_monitor.qss')
        if os.path.exists(qss_path):
            try:
                with open(qss_path, 'r') as f:
                    self.setStyleSheet(f.read())
            except Exception as e:
                log.error(f"QSS load error: {e}")
                self.setStyleSheet("background-color:#121212;color:white;")
        else:
            self.setStyleSheet("background-color:#121212;color:white;")


# --- Entry Point ---
if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = prototype_pc_monitor()
    window.show()
    sys.exit(app.exec_())