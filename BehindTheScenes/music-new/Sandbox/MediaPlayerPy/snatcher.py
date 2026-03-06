import sys
import webbrowser
import urllib.parse
import os
from pathlib import Path
from PySide6.QtWidgets import (QApplication, QDialog, QVBoxLayout, QHBoxLayout, 
                             QGraphicsView, QGraphicsScene, QGraphicsPixmapItem, 
                             QLineEdit, QPushButton, QLabel, QFrame)
from PySide6.QtCore import Qt, QTimer
from PySide6.QtGui import QPixmap, QImage, QColor
from PIL import ImageGrab, Image, ImageQt
from PySide6.QtGui import QPixmap, QImage, QColor, QPainter  # <--- Add QPainter here

class MediaVerseSnatcher4K(QDialog):
    def __init__(self, default_name="New 4K Entry", mode="movie"):
        super().__init__()
        self.setWindowTitle(f"MediaVerse 4K Snatcher")
        self.setWindowFlags(Qt.WindowStaysOnTopHint)
        self.resize(1350, 950)
        
        self.mode = mode
        # 🎯 Your Staging Folder
        self.target_dir = Path(r"D:\MediaVerse1.0\BehindTheScenes\BehindTheScenes\music-new\Assets\tempImages")
        self.target_dir.mkdir(parents=True, exist_ok=True)
        
        self.last_clipboard_data = None
        self.current_pil_image = None
        self.img_item = None

        self.init_ui(default_name)

        # Clipboard Monitor Timer (500ms)
        self.monitor_timer = QTimer(self)
        self.monitor_timer.timeout.connect(self.check_clipboard)
        self.monitor_timer.start(500)

    def init_ui(self, default_name):
        self.layout = QVBoxLayout(self)
        self.layout.setContentsMargins(20, 20, 20, 20)
        self.layout.setSpacing(15)

        # 1. Naming & Search Bar
        self.top_bar = QHBoxLayout()
        self.name_input = QLineEdit(default_name)
        self.name_input.setStyleSheet("""
            QLineEdit { 
                font-size: 22px; height: 45px; color: #00E676; 
                background: #1A1A1A; border: 2px solid #333; 
                padding-left: 15px; font-weight: bold; border-radius: 5px;
            }
        """)
        
        self.search_btn = QPushButton("🔍 SEARCH 4K UHD")
        self.search_btn.setStyleSheet("""
            QPushButton { background-color: #333; color: white; padding: 0 20px; height: 45px; font-weight: bold; }
            QPushButton:hover { background-color: #444; border: 1px solid #00E676; }
        """)
        self.search_btn.clicked.connect(self.search_web)
        
        self.top_bar.addWidget(QLabel("FILE NAME:"))
        self.top_bar.addWidget(self.name_input)
        self.top_bar.addWidget(self.search_btn)
        self.layout.addLayout(self.top_bar)

        # 2. 16:9 Viewport (Fixed at 720p for UI layout, but crops at Source Res)
        self.scene = QGraphicsScene()
        self.view = QGraphicsView(self.scene)
        self.view.setBackgroundBrush(QColor(10, 10, 10))
        self.view.setFixedSize(1280, 720) 
        self.view.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.view.setVerticalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.view.setRenderHint(QPainter.SmoothPixmapTransform)
        self.layout.addWidget(self.view, alignment=Qt.AlignCenter)

        # 3. Status Bar
        self.status_bar = QHBoxLayout()
        self.status_label = QLabel("READY: Copy a 4K image from browser (Right-click > Copy Image)")
        self.status_label.setStyleSheet("font-size: 14px; color: #888;")
        self.res_label = QLabel("SRC: 0 x 0")
        self.res_label.setStyleSheet("font-family: monospace; color: #555;")
        
        self.status_bar.addWidget(self.status_label)
        self.status_bar.addStretch()
        self.status_bar.addWidget(self.res_label)
        self.layout.addLayout(self.status_bar)

        # 4. Action Bar
        self.btn_layout = QHBoxLayout()
        
        self.open_folder_btn = QPushButton("📁 OPEN STAGING")
        self.open_folder_btn.setFixedWidth(180)
        self.open_folder_btn.clicked.connect(lambda: os.startfile(self.target_dir))
        
        self.save_btn = QPushButton("💾 SAVE 4K UHD BACKDROP")
        self.save_btn.setStyleSheet("""
            QPushButton { 
                background-color: #004D40; color: #00E676; 
                font-weight: bold; height: 60px; font-size: 20px; 
                border: 2px solid #00E676; border-radius: 8px;
            }
            QPushButton:hover { background-color: #00695C; color: white; }
        """)
        self.save_btn.clicked.connect(self.save_result)
        
        self.btn_layout.addWidget(self.open_folder_btn)
        self.btn_layout.addWidget(self.save_btn)
        self.layout.addLayout(self.btn_layout)

    def search_web(self):
        title = self.name_input.text()
        # Surgical search for 4K/8K backdrops
        if self.mode == "movie":
            query = f'"{title}" movie backdrop 4k uhd fanart -poster'
        else:
            query = f'"{title}" artist 4k wallpaper hi-res concert -album'
        
        # tbs=isz:ex,islt:8mp (Larger than 8MP / 4K)
        url = f"https://www.google.com/search?q={urllib.parse.quote(query)}&tbm=isch&tbs=isz:ex,islt:8mp,iar:w"
        webbrowser.open(url)

    def check_clipboard(self):
        cb_img = ImageGrab.grabclipboard()
        if cb_img and cb_img != self.last_clipboard_data:
            if hasattr(cb_img, 'size'):
                self.last_clipboard_data = cb_img
                self.update_view_with_image(cb_img)

    def update_view_with_image(self, pil_img):
        self.current_pil_image = pil_img.convert("RGB")
        w, h = self.current_pil_image.size
        self.scene.clear()
        
        qimg = ImageQt.ImageQt(self.current_pil_image)
        pixmap = QPixmap.fromImage(qimg)
        self.img_item = QGraphicsPixmapItem(pixmap)
        self.img_item.setFlag(QGraphicsPixmapItem.ItemIsMovable)
        self.scene.addItem(self.img_item)
        
        # Coverage scale
        scale = max(1280 / w, 720 / h)
        self.img_item.setScale(scale)
        
        self.res_label.setText(f"SRC: {w} x {h}")
        self.status_label.setText("IMAGE GRABBED - Position your 4K crop inside the frame")
        self.status_label.setStyleSheet("color: #00E676; font-weight: bold;")

    def save_result(self):
        if not self.img_item or not self.current_pil_image: return
            
        pos = self.img_item.pos()
        scale = self.img_item.scale()
        
        # Inverse transform to find crop area on original high-res source
        left, top = -pos.x() / scale, -pos.y() / scale
        right, bottom = left + (1280 / scale), top + (720 / scale)
        
        # 1. High Precision Crop
        final_img = self.current_pil_image.crop((left, top, right, bottom))
        
        # 2. UHD Resize (LANCZOS maintains surgical sharpness)
        final_img = final_img.resize((3840, 2160), Image.Resampling.LANCZOS)
        
        # 3. Clean Name
        raw_name = self.name_input.text().strip()
        clean_name = "".join([c for c in raw_name if c.isalnum() or c in (' ', '.', '_', '-')])
        if not clean_name: clean_name = "uhd_backdrop"
        
        save_path = self.target_dir / f"{clean_name}.jpg"
        
        # 4. Save with no Chroma Subsampling (Highest Color Fidelity)
        final_img.save(save_path, "JPEG", quality=95, subsampling=0)
        
        self.status_label.setText(f"SUCCESS: 4K UHD Staged as {clean_name}.jpg")
        self.status_label.setStyleSheet("color: #00E676; font-weight: bold;")
        print(f"✅ [4K SNATCHER] Saved to: {save_path}")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    # Launch for a specific movie/artist
    win = MediaVerseSnatcher4K("The Searchers (1956)", mode="movie")
    win.show()
    sys.exit(app.exec())