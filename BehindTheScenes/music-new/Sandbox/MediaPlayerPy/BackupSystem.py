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
        
        # Sources
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
        
        # Base Destinations
        self.destination_root = os.path.normpath(r"U:\Movie System Backup\Code")
        self.json_destination_root = os.path.normpath(r"U:\Movie System Backup\JSON")

        threading.Timer(1.0, self.lastBackupChanged.emit).start()

    # --- PROPERTIES ---
    
    @Property(str, notify=lastBackupChanged)
    def lastBackupTime(self):
        """Finds the newest sub-folder timestamp to show the TRUE last backup."""
        import os
        import datetime
        
        path = r"U:\Movie System Backup"
        if not os.path.exists(path):
            return "DRIVE OFFLINE"
            
        try:
            # Get a list of all items in the backup root
            items = [os.path.join(path, d) for d in os.listdir(path)]
            # Filter to keep only directories (Code, JSON, etc.)
            dirs = [d for d in items if os.path.isdir(d)]
            
            if not dirs:
                return "NO BACKUPS FOUND"

            # 1. Get the modified time of the newest sub-item
            # 2. This works because even if the parent 'Movie System Backup' 
            #    doesn't update, the 'Code' or 'JSON' folder inside it WILL.
            latest_subdir = max(dirs, key=os.path.getmtime)
            mtime = os.path.getmtime(latest_subdir)
            
            return datetime.datetime.fromtimestamp(mtime).strftime('%d %b %Y, %H:%M')
        except Exception as e:
            print(f"Timestamp Error: {e}")
            return "UNKNOWN"
    
    @Property(float, notify=progressChanged)
    def progress(self):
        return self._progress

    # --- SLOTS ---

    @Slot()
    def run_code_backup(self):
        if self._is_running: return
        threading.Thread(target=self._threaded_backup, 
                         args=(self.code_sources, self.destination_root, "Code"), 
                         daemon=True).start()

    @Slot()
    def run_json_backup(self):
        if self._is_running: return
        threading.Thread(target=self._threaded_backup, 
                         args=(self.json_sources, self.json_destination_root, "JSON"), 
                         daemon=True).start()

    @Slot(str)
    def open_backup_folder(self, path):
        norm_path = os.path.normpath(path)
        if os.path.exists(norm_path):
            subprocess.Popen(f'explorer "{norm_path}"')
        else:
            self.backupFinished.emit(f"Folder not found: {norm_path}", False)

    # --- CORE LOGIC ---

    def cleanup_old_backups(self, root_path, days=30):
        now = time.time()
        cutoff = now - (days * 86400)
        if not os.path.exists(root_path): return

        for folder in os.listdir(root_path):
            full_path = os.path.join(root_path, folder)
            if os.path.isdir(full_path):
                if os.path.getmtime(full_path) < cutoff:
                    try:
                        shutil.rmtree(full_path)
                        print(f"🧹 Purged old backup: {folder}")
                    except Exception as e:
                        print(f"⚠️ Cleanup error: {e}")

    def _threaded_backup(self, sources, dest_root, label):
        """The single engine for all backup types."""
        try:
            self._is_running = True
            self._progress = 0.1
            self.progressChanged.emit(self._progress)

            # 1. Ensure Root & Cleanup
            os.makedirs(dest_root, exist_ok=True)
            self.cleanup_old_backups(dest_root, 30)

            # 2. Create timestamped session folder
            timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M")
            session_folder = os.path.join(dest_root, timestamp)
            os.makedirs(session_folder, exist_ok=True)

            report = []
            manifest_data = []

            # 3. Process Sources
            for index, raw_path in enumerate(sources):
                src = os.path.normpath(raw_path)
                if not os.path.exists(src):
                    report.append(f"❌ NOT FOUND: {os.path.basename(src)}")
                    continue

                folder_name = os.path.basename(src)
                drive = os.path.splitdrive(src)[0].replace(":", "")
                dest_path = os.path.join(session_folder, f"{drive}_{folder_name}")

                if os.path.isdir(src):
                    shutil.copytree(src, dest_path, dirs_exist_ok=True)
                else:
                    shutil.copy2(src, dest_path)
                
                report.append(f"✅ SECURED: {folder_name}")
                manifest_data.append(f"{folder_name} <--- {src}")
                
                # Update progress
                self._progress = 0.1 + ((index + 1) / len(sources)) * 0.8
                self.progressChanged.emit(self._progress)

            # 4. Write Manifest
            with open(os.path.join(session_folder, "backup_manifest.txt"), "w") as f:
                f.write(f"Backup Type: {label}\nDate: {timestamp}\n\n" + "\n".join(manifest_data))

            # 5. Finalize - This triggers the QML UI to refresh its text
            self.lastBackupChanged.emit() 
            self.backupFinished.emit(f"{label} Success", True)

        except Exception as e:
            self.backupFinished.emit(f"Error: {str(e)}", False)
        finally:
            self._is_running = False
            self._progress = 0
            self.progressChanged.emit(0)