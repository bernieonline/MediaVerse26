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
        
        # --- PATHS (Both old and new preserved) ---
        self.movie_library_root = r"W:\Collection"
        self.movie_backup_root = r"U:\Movie System Backup\Collection"
        
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

        threading.Timer(1.0, self.lastBackupChanged.emit).start()

    # --- PROPERTIES ---
    @Property(float, notify=progressChanged)
    def progress(self): return self._progress

    @Property(str, notify=lastBackupChanged)
    def lastBackupTime(self):
        path = r"U:\Movie System Backup"
        if not os.path.exists(path): return "DRIVE OFFLINE"
        try:
            items = [os.path.join(path, d) for d in os.listdir(path) if os.path.isdir(os.path.join(path, d))]
            if not items: return "NO BACKUPS FOUND"
            latest_subdir = max(items, key=os.path.getmtime)
            return datetime.fromtimestamp(os.path.getmtime(latest_subdir)).strftime('%d %b %Y, %H:%M')
        except: return "UNKNOWN"

    # --- SLOTS (The Launchers) ---

    @Slot()
    def run_code_backup(self):
        """Preserved: Your original Code backup launcher."""
        if self._is_running: return
        threading.Thread(target=self._threaded_backup, 
                         args=(self.code_sources, self.destination_root, "Code"), 
                         daemon=True).start()

    @Slot()
    def run_json_backup(self):
        """Preserved: Your original JSON backup launcher."""
        if self._is_running: return
        threading.Thread(target=self._threaded_backup, 
                         args=(self.json_sources, self.json_destination_root, "JSON"), 
                         daemon=True).start()

    @Slot()
    def run_movie_assets_backup(self):
        """The Fix: Launches the new movie worker in a background thread."""
        if self._is_running: return
        print("[DEBUG] 🚀 Launcher: Starting Movie Asset Thread...")
        threading.Thread(target=self._threaded_movie_assets_worker, daemon=True).start()

    @Slot(str)
    def open_backup_folder(self, path):
        norm_path = os.path.normpath(path)
        if os.path.exists(norm_path):
            subprocess.Popen(f'explorer "{norm_path}"')

    # --- ENGINES (The Background Workers) ---

    def _threaded_backup(self, sources, dest_root, label):
        """PRESERVED: This is your exact original logic for Code and JSON."""
        try:
            self._is_running = True
            self._progress = 0.1
            self.progressChanged.emit(self._progress)
            os.makedirs(dest_root, exist_ok=True)
            
            timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M")
            session_folder = os.path.join(dest_root, timestamp)
            os.makedirs(session_folder, exist_ok=True)

            manifest_data = []
            for index, raw_path in enumerate(sources):
                src = os.path.normpath(raw_path)
                if not os.path.exists(src): continue
                folder_name = os.path.basename(src)
                drive = os.path.splitdrive(src)[0].replace(":", "")
                dest_path = os.path.join(session_folder, f"{drive}_{folder_name}")

                if os.path.isdir(src):
                    shutil.copytree(src, dest_path, dirs_exist_ok=True)
                else:
                    shutil.copy2(src, dest_path)
                
                manifest_data.append(f"{folder_name} <--- {src}")
                self._progress = 0.1 + ((index + 1) / len(sources)) * 0.8
                self.progressChanged.emit(self._progress)

            with open(os.path.join(session_folder, "backup_manifest.txt"), "w") as f:
                f.write(f"Backup Type: {label}\nDate: {timestamp}\n\n" + "\n".join(manifest_data))

            self.lastBackupChanged.emit() 
            self.backupFinished.emit(f"{label} Success", True)
        except Exception as e:
            self.backupFinished.emit(str(e), False)
        finally:
            self._is_running = False
            self.progressChanged.emit(0)

    def _threaded_movie_assets_worker(self):
        """THE NEW ENGINE: Surgical metadata backup with debugs."""
        try:
            self._is_running = True
            print(f"[DEBUG] 🔍 Checking W:\\Collection...")
            
            if not os.path.exists(self.movie_library_root):
                print(f"[DEBUG] ❌ FAILED: Cannot find {self.movie_library_root}")
                self.backupFinished.emit("W: Drive Not Found", False)
                return

            os.makedirs(self.movie_backup_root, exist_ok=True)
            valid_extensions = ('.xml', '.jpg', '.jpeg', '.png', '.nfo', '.jrsid')
            
            all_dirs = [d for d in os.listdir(self.movie_library_root) 
                        if os.path.isdir(os.path.join(self.movie_library_root, d))]
            
            print(f"[DEBUG] 📂 Found {len(all_dirs)} movie folders.")

            for index, folder in enumerate(all_dirs):
                src_folder = os.path.join(self.movie_library_root, folder)
                dest_folder = os.path.join(self.movie_backup_root, folder)

                for root, _, files in os.walk(src_folder):
                    for file in files:
                        if "thumbs" in file.lower(): continue
                        if file.lower().endswith(valid_extensions):
                            rel_path = os.path.relpath(root, src_folder)
                            target_dir = os.path.join(dest_folder, rel_path)
                            os.makedirs(target_dir, exist_ok=True)
                            shutil.copy2(os.path.join(root, file), os.path.join(target_dir, file))

                self._progress = (index + 1) / len(all_dirs)
                self.progressChanged.emit(self._progress)

            self.lastBackupChanged.emit()
            self.backupFinished.emit("Movie Assets Secured", True)
            print("[DEBUG] ✅ Movie Backup Complete.")

        except Exception as e:
            print(f"[DEBUG] ❌ ERROR: {e}")
            self.backupFinished.emit(str(e), False)
        finally:
            self._is_running = False
            self.progressChanged.emit(0)