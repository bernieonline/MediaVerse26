import logging
import os 
import sys 
from PyQt5.QtWidgets import QWidget, QApplication, QVBoxLayout, QGridLayout, QStackedWidget
from PyQt5.QtCore import Qt, QTimer

from carousel_content import ContentPanel 
from grid_view import GridView 
from detail_panel import DetailPanelWidget
from app_control_bar import ControlBar
'''a copy of the main_app.py file after changes to single image so trying a correction to this code'''
log = logging.getLogger('MainApp')
log_file_path = 'sandbox_application.log'  # log file in current directory

logging.basicConfig(
    level=logging.INFO,  # capture INFO, WARNING, ERROR, CRITICAL
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    handlers=[
        logging.FileHandler('sandbox_application.log', mode='a')  # write all logs to file
    ]
)
log = logging.getLogger('MainApp')





class prototype_pc_monitor(QWidget):

    
    """Main app window with carousel/detail and full-screen GridView."""
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("prototype_pc_monitor")

       
        self.log = logging.getLogger('AboutTab')

        # --- State Tracking ---
        self.is_split_view = False
        self.content_view_state = "Carousel"

        # --- 1. Load Theme ---

        self._load_qss_theme()

        # --- 2. Main Layout ---
        # self is the prototype_pc_monitor widget
        main_v_layout = QVBoxLayout(self)
        main_v_layout.setContentsMargins(0, 0, 0, 0)
        main_v_layout.setSpacing(0)

        # --- 3. Top Control Bar ---
        #its imported and It encapsulates the view-toggling buttons and emits signals
        #  to the parent application upon user interaction.
        self.control_bar = ControlBar(self)
        main_v_layout.addWidget(self.control_bar)

        # --- 4. Main Stacked Widget ---
        self.main_stack = QStackedWidget(self)
        self.main_stack.setObjectName("main_stacked_widget")

        # --- 5. Create Pages ---
        # Page 0: Carousel / Detail split
        self.carousel_split_page = self._create_carousel_split_page()
        self.main_stack.addWidget(self.carousel_split_page)

        # Page 1: Full-screen Grid view
        self.grid_page = self._create_grid_page()
        self.grid_page.media_selected_for_details.connect(self._handle_media_selection)
        self.grid_page.back_to_carousel_requested.connect(self._toggle_main_view)
        self.main_stack.addWidget(self.grid_page)

        main_v_layout.addWidget(self.main_stack)
        self.setLayout(main_v_layout)
        self.setWindowState(Qt.WindowState.WindowMaximized)

        # --- 6. Setup other signal connections ---
        self._setup_connections()

        log.info("Application initialized: ControlBar and GridView connected.")

    def _setup_connections(self):
        self.content_controller.carousel_view.media_selected_for_details.connect(
            self._handle_media_selection
        )
        self.control_bar.view_toggled.connect(self._toggle_main_view)
        self.control_bar.split_toggled.connect(self.toggle_split_view)

    #The purpose of the load_details
    #method is to load data into the "About" tab of the application
    def _handle_media_selection(self, media_file_path):
        self.detail_panel.load_details(media_file_path)
        if self.main_stack.currentIndex() != 0:
            self.main_stack.setCurrentIndex(0)#index 0 is carousel view
        if not self.is_split_view:#adds split detail panel to the view
            self.toggle_split_view()
        log.info(f"Loaded details for: {os.path.basename(media_file_path)}")
        log.info(f"Full path of media file: {os.path.abspath(media_file_path)}")

    def _create_carousel_split_page(self):
        #new widget created
        page_0 = QWidget()
        #new layout for the widget
        self.page_1_layout = QGridLayout(page_0)
        self.page_1_layout.setContentsMargins(0,0,0,0)
        self.page_1_layout.setSpacing(0)

        #instantiate carousel panel with page_0 as the parent
        self.content_controller = ContentPanel(page_0)
        #instantiate the detail panel
        self.detail_panel = DetailPanelWidget(page_0)
        self.detail_panel.setHidden(True)

        self.page_1_layout.addWidget(self.content_controller, 0, 0)
        self.page_1_layout.addWidget(self.detail_panel, 0, 1)
        self.page_1_layout.setColumnStretch(0,1)
        self.page_1_layout.setColumnStretch(1,0)

        return page_0

    def _create_grid_page(self):
        self.grid_page = GridView(parent=self.main_stack)
        self.grid_page.back_to_carousel_requested.connect(self._toggle_main_view)
        return self.grid_page

    def _load_qss_theme(self):
        qss_path = os.path.join(os.path.dirname(__file__), 'cinema_theme_pc_monitor.qss')
        if os.path.exists(qss_path):
            try:
                with open(qss_path,'r') as f:
                    self.setStyleSheet(f.read())
            except Exception as e:
                log.error(f"QSS load error: {e}")
                self.setStyleSheet("background-color:#121212;color:white;")
        else:
            self.setStyleSheet("background-color:#121212;color:white;")

    def _toggle_main_view(self):
        idx = self.main_stack.currentIndex()
        self.main_stack.setCurrentIndex(1 if idx==0 else 0)

    def toggle_split_view(self):
        if self.main_stack.currentIndex() != 0:
            return
        if not self.is_split_view:
            self.detail_panel.setHidden(False)
            self.page_1_layout.setColumnStretch(0,1)
            self.page_1_layout.setColumnStretch(1,1)
            QTimer.singleShot(100, lambda: self._update_split_state(True))
        else:
            self.page_1_layout.setColumnStretch(0,1)
            self.page_1_layout.setColumnStretch(1,0)
            QTimer.singleShot(100, lambda: self._update_split_state(False))

    def _update_split_state(self, new_state):
        self.is_split_view = new_state
        if not self.is_split_view:
            self.detail_panel.setHidden(True)

# --- Entry Point ---
if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = prototype_pc_monitor()
    window.show()
    sys.exit(app.exec_())
