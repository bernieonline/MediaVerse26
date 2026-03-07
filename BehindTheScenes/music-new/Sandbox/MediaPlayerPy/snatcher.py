import sys
import webbrowser
import urllib.parse
import os
from pathlib import Path
from PySide6.QtWidgets import (QApplication, QDialog, QVBoxLayout, QHBoxLayout, 
                             QGraphicsView, QGraphicsScene, QGraphicsPixmapItem, 
                             QLineEdit, QPushButton, QLabel, QFrame, QRadioButton, QButtonGroup)
from PySide6.QtCore import Qt, QTimer, QPointF
from PySide6.QtGui import QPixmap, QImage, QColor, QPainter, QWheelEvent
from PIL import ImageGrab, Image, ImageQt

class MediaVerseSnatcher4K(QDialog):
    def __init__(self, default_name="New 4K Entry", mode="movie"):
        super().__init__()
        self.setWindowTitle("MediaVerse 4K Command Center")
        self.setWindowFlags(Qt.WindowStaysOnTopHint)
        self.resize(1350, 980)
        
        # Paths
        self.path_splash = Path(r"D:\MediaVerse1.0\BehindTheScenes\BehindTheScenes\music-new\Assets\Splash")
        self.path_temp = Path(r"D:\MediaVerse1.0\BehindTheScenes\BehindTheScenes\music-new\Assets\tempImages")
        self.target_dir = self.path_splash # Default
        
        self.current_pil_image = None
        self.img_item = None
        self.last_clipboard_data = None

        self.init_ui(default_name)

        # Monitor Clipboard
        self.monitor_timer = QTimer(self)
        self.monitor_timer.timeout.connect(self.check_clipboard)
        self.monitor_timer.start(500)

    def init_ui(self, default_name):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 10, 20, 20)

        # --- TOP: FILE & DESTINATION ---
        top_section = QHBoxLayout()
        
        self.name_input = QLineEdit(default_name)
        self.name_input.setStyleSheet("font-size: 20px; height: 45px; background: #1A1A1A; color: #00E676; border: 1px solid #333; padding-left: 10px;")
        
        # Dest Toggle
        self.dest_group = QButtonGroup(self)
        self.radio_splash = QRadioButton("Splash")
        self.radio_temp = QRadioButton("Temp")
        self.radio_splash.setChecked(True)
        self.radio_splash.toggled.connect(self.update_target_path)
        self.dest_group.addButton(self.radio_splash)
        self.dest_group.addButton(self.radio_temp)

        top_section.addWidget(QLabel("FILENAME:"))
        top_section.addWidget(self.name_input, 4)
        top_section.addWidget(QLabel("SAVE TO:"))
        top_section.addWidget(self.radio_splash)
        top_section.addWidget(self.radio_temp)
        
        search_btn = QPushButton("🔍 GOOGLE 4K")
        search_btn.setFixedSize(150, 45)
        search_btn.clicked.connect(self.search_web)
        top_section.addWidget(search_btn)
        
        layout.addLayout(top_section)

        # --- MIDDLE: THE VIEWPORT ---
        self.scene = QGraphicsScene()
        self.view = QGraphicsView(self.scene)
        self.view.setFixedSize(1280, 720)
        self.view.setBackgroundBrush(QColor(15, 15, 15))
        self.view.setRenderHint(QPainter.SmoothPixmapTransform)
        self.view.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.view.setVerticalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        
        # Enable Mouse Wheel Zooming
        self.view.wheelEvent = self.handle_wheel
        
        layout.addWidget(self.view, alignment=Qt.AlignCenter)

        # --- BOTTOM: METRICS & ACTION ---
        metrics_layout = QHBoxLayout()
        self.res_label = QLabel("SRC: 0 x 0")
        self.res_label.setStyleSheet("font-size: 18px; color: #00E676; font-family: monospace;")
        self.crop_info = QLabel("CROP: 16:9 Window Active")
        self.crop_info.setStyleSheet("color: #888;")
        
        metrics_layout.addWidget(self.res_label)
        metrics_layout.addStretch()
        metrics_layout.addWidget(self.crop_info)
        layout.addLayout(metrics_layout)

        self.save_btn = QPushButton("💾 SAVE SURGICAL CROP (4K UHD)")
        self.save_btn.setStyleSheet("""
            QPushButton { 
                background-color: #004D40; color: white; font-size: 24px; font-weight: bold; 
                height: 80px; border-radius: 10px; border: 2px solid #00E676;
            }
            QPushButton:hover { background-color: #00695C; }
        """)
        self.save_btn.clicked.connect(self.save_result)
        layout.addWidget(self.save_btn)

    def update_target_path(self):
        self.target_dir = self.path_splash if self.radio_splash.isChecked() else self.path_temp

    def handle_wheel(self, event: QWheelEvent):
        if not self.img_item: return
        factor = 1.1 if event.angleDelta().y() > 0 else 0.9
        self.img_item.setScale(self.img_item.scale() * factor)

    def check_clipboard(self):
        cb_img = ImageGrab.grabclipboard()
        if cb_img and cb_img != self.last_clipboard_data:
            if hasattr(cb_img, 'size'):
                self.last_clipboard_data = cb_img
                self.load_image(cb_img)

    def load_image(self, pil_img):
        self.current_pil_image = pil_img.convert("RGB")
        w, h = self.current_pil_image.size
        self.res_label.setText(f"SRC: {w} x {h}")
        
        qimg = ImageQt.ImageQt(self.current_pil_image)
        pixmap = QPixmap.fromImage(qimg)
        
        self.scene.clear()
        self.img_item = QGraphicsPixmapItem(pixmap)
        self.img_item.setFlag(QGraphicsPixmapItem.ItemIsMovable)
        self.scene.addItem(self.img_item)
        
        # Initial fit
        scale = max(1280/w, 720/h)
        self.img_item.setScale(scale)
        self.img_item.setPos(0, 0)

    def search_web(self):
        query = f'"{self.name_input.text()}" 4k uhd wallpaper backdrop'
        url = f"https://www.google.com/search?q={urllib.parse.quote(query)}&tbm=isch&tbs=isz:lt,islt:8mp"
        webbrowser.open(url)

    def save_result(self):
        if not self.img_item: return
        
        # Geometry Math
        scale = self.img_item.scale()
        pos = self.img_item.pos()
        
        left = int(-pos.x() / scale)
        top = int(-pos.y() / scale)
        width = int(1280 / scale)
        height = int(720 / scale)
        
        # Surgical Crop
        final = self.current_pil_image.crop((left, top, left + width, top + height))
        final = final.resize((3840, 2160), Image.Resampling.LANCZOS)
        
        # File Handling
        clean_name = "".join(c for c in self.name_input.text() if c.isalnum() or c in " ._-").strip()
        self.target_dir.mkdir(parents=True, exist_ok=True)
        save_path = self.target_dir / f"{clean_name}.jpg"
        
        final.save(save_path, "JPEG", quality=95, subsampling=0)
        print(f"✅ Saved to: {save_path}")
        self.save_btn.setText("SUCCESSFULLY SAVED!")
        QTimer.singleShot(2000, lambda: self.save_btn.setText("💾 SAVE SURGICAL CROP (4K UHD)"))

if __name__ == "__main__":
    app = QApplication(sys.argv)
    win = MediaVerseSnatcher4K("The Searchers (1956)")
    win.show()
    sys.exit(app.exec())