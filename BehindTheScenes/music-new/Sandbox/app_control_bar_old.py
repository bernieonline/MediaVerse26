import logging
from PyQt5.QtWidgets import QFrame, QPushButton, QHBoxLayout
from PyQt5.QtCore import Qt, pyqtSignal

log = logging.getLogger('ControlBar')

class xyzControlBar(QFrame):
    """
    A standalone widget representing the persistent top control bar.
    It encapsulates the view-toggling buttons and emits signals to the parent 
    application upon user interaction.
    """
    # Define signals the main application will connect to
    view_toggled = pyqtSignal()
    split_toggled = pyqtSignal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("button_bar") # Reuses existing QSS style
        
        h_layout = QHBoxLayout(self)
        h_layout.setContentsMargins(15, 10, 15, 10)
        h_layout.setAlignment(Qt.AlignLeft)
        
        # 1. View Toggle Button (Grid/Carousel)
        self.btn_toggle_view = QPushButton("Grid View", self)
        self.btn_toggle_view.clicked.connect(self.view_toggled.emit)
        
        # 2. Detail Panel Toggle Button 
        self.btn_toggle_split = QPushButton("Toggle Detail Panel", self)
        self.btn_toggle_split.clicked.connect(self.split_toggled.emit)
        
        # --- Add Buttons to Layout ---
        h_layout.addWidget(self.btn_toggle_view)
        h_layout.addWidget(self.btn_toggle_split)
        h_layout.addStretch(1) 

    def update_view_state(self, is_grid_active, is_split_active):
        """
        Updates the text and enabled state of the buttons based on the current 
        application view state, ensuring the buttons make sense in context.
        Called by the main application (main_app.py).
        
        Args:
            is_grid_active (bool): True if the main app is showing the Grid View (Page 1).
            is_split_active (bool): True if the detail panel is currently visible.
        """
        print("processing click 1")
        if is_grid_active:
            # On Grid View (Page 1)
            self.btn_toggle_view.setText("Carousel View")
            self.btn_toggle_split.setEnabled(False) 
        else:
            # On Carousel View (Page 0)
            self.btn_toggle_view.setText("Grid View")
            self.btn_toggle_split.setEnabled(True)
            self.btn_toggle_split.setText("Full Screen" if is_split_active else "Toggle Detail Panel")
            
        log.debug(f"ControlBar state updated: Grid={is_grid_active}, Split={is_split_active}")
