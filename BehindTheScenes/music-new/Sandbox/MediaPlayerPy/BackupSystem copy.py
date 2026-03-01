import os
import shutil
import time
import subprocess
from datetime import datetime, timedelta
from PySide6.QtCore import QObject, Slot, Signal, Property
import threading # Add to imports

class BackupManager(QObject):
    backupFinished = Signal(str, bool) 
    lastBackupChanged = Signal()
    progressChanged = Signal(float)

    def __init__(self):
        super().__init__()
        self._last_backup_time = "NEVER"
        self._progress = 0
        self._is_running = False
        
        # Sources for CODE backup
        self.raw_sources = [
            r"D:\MediaVerse1.0\BehindTheScenes\BehindTheScenes\music-new\Sandbox",
            r"D:\MediaVerse1.0\BehindTheScenes\BehindTheScenes\music-new\Assets",
            r"W:\MediaVerse\manifest",
            r"W:\MediaVerse\Collections"
        ]
        
        # Base Destinations
        self.destination_root = os.path.normpath(r"U:\Movie System Backup\Code")
        self.json_destination_root = os.path.normpath(r"U:\Movie System Backup\JSON")

    @Property(str, notify=lastBackupChanged)
    def lastBackupTime(self):
        return self._last_backup_time
    
    @Property(float, notify=progressChanged)
    def progress(self):
        return self._progress

    @Slot(str)
    def open_backup_folder(self, path):
        """Surgical addition: Opens the folder in Windows Explorer."""
        norm_path = os.path.normpath(path)
        if os.path.exists(norm_path):
            # shell=True isn't needed for explorer, Popen handles the string
            subprocess.Popen(f'explorer "{norm_path}"')
        else:
            self.backupFinished.emit(f"Folder not found: {norm_path}", False)

    def cleanup_old_backups(self, root_path, days=30):
        """Amended: Now accepts a path so it can clean Code OR JSON folders."""
        now = time.time()
        cutoff = now - (days * 86400)
        
        if not os.path.exists(root_path): return

        for folder in os.listdir(root_path):
            full_path = os.path.join(root_path, folder)
            if os.path.isdir(full_path):
                if os.path.getmtime(full_path) < cutoff:
                    shutil.rmtree(full_path)
                    print(f"🧹 Purged old backup: {folder}")

    @Slot()
    def run_code_backup(self):
        if self._is_running:
            return # Block multiple clicks
        
        self._is_running = True
        self._progress = 0.1 # Start the bar
        self.progressChanged.emit(self._progress)
        
        # Run in a background thread so the UI stays responsive
        threading.Thread(target=self._threaded_backup, args=(self.raw_sources, self.destination_root, "Code"), daemon=True).start()

    @Slot()
    def run_json_backup(self):
        """Surgical addition: Handles the JSON tab in QML."""
        try:
            # Add your actual JSON/DB source paths here
            json_sources = [
                r"D:\MediaVerse1.0\BehindTheScenes\BehindTheScenes\db",
                r"D:\MediaVerse1.0\BehindTheScenes\BehindTheScenes\json"
            ]
            self.cleanup_old_backups(self.json_destination_root, 30)
            self._execute_copy_sequence(json_sources, self.json_destination_root, "JSON")
        except Exception as e:
            self.backupFinished.emit(f"JSON Backup Error: {str(e)}", False)

    def _execute_copy_sequence(self, sources, dest_root, label):
        """Internal helper to keep the code clean and dry."""
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M")
        session_folder = os.path.join(dest_root, timestamp)
        os.makedirs(session_folder, exist_ok=True)

        report = []
        manifest_data = []

        for raw_path in sources:
            src = os.path.normpath(raw_path)
            if not os.path.exists(src):
                report.append(f"❌ NOT FOUND: {src}")
                continue

            drive = os.path.splitdrive(src)[0].replace(":", "")
            folder_name = os.path.basename(src)
            dest_path = os.path.join(session_folder, f"{drive}_{folder_name}")

            if os.path.isdir(src):
                shutil.copytree(src, dest_path, dirs_exist_ok=True)
            else:
                shutil.copy2(src, dest_path)

            report.append(f"✅ SECURED: {folder_name}")
            manifest_data.append(f"{folder_name} <--- {src}")

        # Write Manifest
        with open(os.path.join(session_folder, "backup_manifest.txt"), "w") as f:
            f.write(f"Backup Type: {label}\nDate: {timestamp}\n\n" + "\n".join(manifest_data))

        # Update Stats
        self._last_backup_time = datetime.now().strftime("%Y-%m-%d %H:%M")
        self.lastBackupChanged.emit()
        self.backupFinished.emit(f"{label} Backup Success ({timestamp})\n" + "\n".join(report), True)

    def _threaded_backup(self, sources, dest_root, label):
        try:
            print(f"--- 🚀 STARTING {label} BACKUP ---")
            self._is_running = True
            
            # 1. Cleanup (with a 'Skip' if folder doesn't exist)
            if os.path.exists(dest_root):
                print(f"🧹 Scanning for old backups in: {dest_root}")
                try:
                    self.cleanup_old_backups(dest_root, 30)
                except Exception as e:
                    print(f"⚠️ Cleanup skipped/failed: {e}")
            else:
                print(f"ℹ️ Destination root '{dest_root}' does not exist yet. Creating it...")

            # 2. Create timestamped session folder
            timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M")
            session_folder = os.path.join(dest_root, timestamp)
            
            print(f"📁 Attempting to create folder: {session_folder}")
            os.makedirs(session_folder, exist_ok=True)
            print("✅ Session folder created successfully.")

            report = []
            manifest_data = []

            # 3. Copying
            for index, raw_path in enumerate(sources):
                src = os.path.normpath(raw_path)
                print(f"📂 [{index+1}/{len(sources)}] Processing: {src}")
                
                if not os.path.exists(src):
                    print(f"   ❌ Source not found: {src}")
                    report.append(f"❌ NOT FOUND: {src}")
                    continue

                folder_name = os.path.basename(src)
                # Note: Drive prefixing (e.g., D_Sandbox) logic here
                drive = os.path.splitdrive(src)[0].replace(":", "")
                dest_path = os.path.join(session_folder, f"{drive}_{folder_name}")

                print(f"   ➡️ Copying to: {dest_path}...")
                if os.path.isdir(src):
                    shutil.copytree(src, dest_path, dirs_exist_ok=True)
                else:
                    shutil.copy2(src, dest_path)
                
                print(f"   ✅ Done copying {folder_name}")
                report.append(f"✅ SECURED: {folder_name}")
                
                # Update progress
                self._progress = 0.1 + ((index + 1) / len(sources)) * 0.8
                self.progressChanged.emit(self._progress)

            # Finalize...
            self._last_backup_time = datetime.now().strftime("%Y-%m-%d %H:%M")
            self.lastBackupChanged.emit()
            self.backupFinished.emit(f"Success\n" + "\n".join(report), True)

        except Exception as e:
            print(f"🛑 CRITICAL THREAD ERROR: {e}")
            self.backupFinished.emit(f"Error: {str(e)}", False)
        finally:
            self._is_running = False
            self._progress = 0
            self.progressChanged.emit(0)

    @Property(str, notify=lastBackupChanged)
    def lastBackupTime(self):
        import os
        import datetime
        
        path = "U:\\Movie System Backup"
        if not os.path.exists(path):
            return "DRIVE OFFLINE"
            
        try:
            # Get the last modified time of the PARENT folder
            mtime = os.path.getmtime(path)
            return datetime.datetime.fromtimestamp(mtime).strftime('%d %b %Y, %H:%M')
        except Exception:
            return "UNKNOWN"