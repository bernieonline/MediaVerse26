import os
import shutil
import time
import subprocess
import threading
from datetime import datetime
from PySide6.QtCore import QObject, Slot, Signal, Property

class BackupManager(QObject):
    backupFinished = Signal(str, bool) 
    lastBackupChanged = Signal()
    progressChanged = Signal(float)

    def __init__(self):
        super().__init__()
        self._progress = 0
        self._is_running = False
        
        # Paths
        self.movie_library_root = os.path.normpath(r"W:\Collection")
        self.movie_backup_root = os.path.normpath(r"U:\Movie System Backup\Collection")
        
        self.code_sources = [
            r"D:\MediaVerse1.0\BehindTheScenes\BehindTheScenes\music-new\Sandbox",
            r"D:\MediaVerse1.0\BehindTheScenes\BehindTheScenes\music-new\Assets",
            r"W:\MediaVerse\manifest",
            r"W:\MediaVerse\Collections"
        ]
        
        self.json_sources = [
            r"D:\MediaVerse1.0\BehindTheScenes\BehindTheScenes\db",
            r"D:\MediaVerse1.0\BehindTheScenes\BehindTheScenes\json"
        ]
        
        self.destination_root = os.path.normpath(r"U:\Movie System Backup\Code")
        self.json_destination_root = os.path.normpath(r"U:\Movie System Backup\JSON")

        # Set initial last backup time
        threading.Timer(1.0, self.lastBackupChanged.emit).start()

    @Property(float, notify=progressChanged)
    def progress(self): return self._progress

    @Property(str, notify=lastBackupChanged)
    def lastBackupTime(self):
        path = r"U:\Movie System Backup"
        if not os.path.exists(path): return "DRIVE OFFLINE"
        try:
            # Get all subdirectories in the backup root
            dirs = [os.path.join(path, d) for d in os.listdir(path) if os.path.isdir(os.path.join(path, d))]
            if not dirs: return "NO BACKUPS FOUND"
            # Return the time of the most recently modified folder
            latest = max(dirs, key=os.path.getmtime)
            return datetime.fromtimestamp(os.path.getmtime(latest)).strftime('%d %b %Y, %H:%M')
        except: return "UNKNOWN"

    # --- SLOTS ---

    @Slot()
    def run_code_backup(self):
        if self._is_running: return
        threading.Thread(target=self._threaded_backup, args=(self.code_sources, self.destination_root, "Code"), daemon=True).start()

    @Slot()
    def run_json_backup(self):
        if self._is_running: return
        threading.Thread(target=self._threaded_backup, args=(self.json_sources, self.json_destination_root, "JSON"), daemon=True).start()

    @Slot()
    def run_movie_assets_backup(self):
        if self._is_running: return
        threading.Thread(target=self._threaded_movie_assets_worker, daemon=True).start()

    @Slot(str)
    def open_backup_folder(self, path):
        norm_path = os.path.normpath(path)
        if os.path.exists(norm_path):
            # Using Popen for a clean, non-blocking explorer window
            subprocess.Popen(['explorer', norm_path], shell=False)

    # --- WORKERS ---

    def _threaded_backup(self, sources, dest_root, label):
        """Standard backup for Code/JSON using folder-per-session logic."""
        try:
            self._is_running = True
            os.makedirs(dest_root, exist_ok=True)
            
            timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M")
            session_folder = os.path.join(dest_root, timestamp)
            os.makedirs(session_folder, exist_ok=True)

            manifest = []
            for i, raw_path in enumerate(sources):
                src = os.path.normpath(raw_path)
                if not os.path.exists(src): continue
                
                # Create unique name based on drive and folder
                drive = os.path.splitdrive(src)[0].replace(":", "")
                dst = os.path.join(session_folder, f"{drive}_{os.path.basename(src)}")

                if os.path.isdir(src):
                    shutil.copytree(src, dst, dirs_exist_ok=True)
                else:
                    shutil.copy2(src, dst)
                
                manifest.append(f"{os.path.basename(src)} <--- {src}")
                self._progress = ((i + 1) / len(sources))
                self.progressChanged.emit(self._progress)

            with open(os.path.join(session_folder, "backup_manifest.txt"), "w") as f:
                f.write(f"Type: {label}\nDate: {timestamp}\n\n" + "\n".join(manifest))

            self.backupFinished.emit(f"{label} Backup Success", True)
        except Exception as e:
            self.backupFinished.emit(str(e), False)
        finally:
            self._is_running = False
            self.progressChanged.emit(0)
            self.lastBackupChanged.emit()

    def _threaded_movie_assets_worker(self):
        """Surgical metadata-only backup for movie library."""
        try:
            self._is_running = True
            if not os.path.exists(self.movie_library_root):
                self.backupFinished.emit("W: Drive Not Found", False)
                return

            os.makedirs(self.movie_backup_root, exist_ok=True)
            valid_exts = ('.xml', '.jpg', '.jpeg', '.png', '.nfo', '.jrsid')
            
            dirs = [d for d in os.listdir(self.movie_library_root) 
                    if os.path.isdir(os.path.join(self.movie_library_root, d))]
            
            if not dirs:
                self.backupFinished.emit("No movie folders found", False)
                return

            for index, folder in enumerate(dirs):
                src = os.path.join(self.movie_library_root, folder)
                dst = os.path.join(self.movie_backup_root, folder)

                for root, _, files in os.walk(src):
                    for file in files:
                        if "thumbs" in file.lower(): continue
                        if file.lower().endswith(valid_exts):
                            rel = os.path.relpath(root, src)
                            target = os.path.join(dst, rel)
                            os.makedirs(target, exist_ok=True)
                            shutil.copy2(os.path.join(root, file), os.path.join(target, file))

                self._progress = (index + 1) / len(dirs)
                self.progressChanged.emit(self._progress)

            self.backupFinished.emit("Movie Assets Secured", True)
        except Exception as e:
            self.backupFinished.emit(str(e), False)
        finally:
            self._is_running = False
            self.progressChanged.emit(0)
            self.lastBackupChanged.emit()