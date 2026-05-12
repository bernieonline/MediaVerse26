"""
media_manager_backend.py -- QObject backend for the Physical Collection Management module.

Context property name: mediaManagerBackend
"""

import threading
import os
import shutil
import logging
import socket
import hashlib
from datetime import datetime
from pathlib import Path

from PySide6.QtCore import QObject, Signal, Slot

import media_manager_db as db

log = logging.getLogger(__name__)


# -----------------------------------------------------------------------------
#  Module-level helpers
# -----------------------------------------------------------------------------

def _build_collection_name(folder_path: str, device: str) -> str:
    """Build the canonical collection name: device:drive:/subfolder:YYYY-MM-DD HH:MM:SS"""
    p = Path(folder_path)
    drive_letter = p.drive.rstrip(":")          # "T"  (empty on UNC/Linux paths)
    rest = str(p)[len(p.drive):].replace("\\", "/")   # "/Music/FLAC"
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    if drive_letter:
        return f"{device}:{drive_letter}:{rest}:{timestamp}"
    return f"{device}:{rest}:{timestamp}"


def _build_collection_prefix(folder_path: str, device: str) -> str:
    """Return the name prefix (without timestamp) used for duplicate detection."""
    p = Path(folder_path)
    drive_letter = p.drive.rstrip(":")
    rest = str(p)[len(p.drive):].replace("\\", "/")
    if drive_letter:
        return f"{device}:{drive_letter}:{rest}:"
    return f"{device}:{rest}:"


def _fast_checksum(fpath: str, chunk: int = 65536) -> str:
    """Partial-content checksum for fast deduplication.
    Hashes: file size + first 64 KB + last 64 KB (if file > 128 KB).
    Returns first 16 hex chars of MD5.
    """
    h = hashlib.md5()
    try:
        size = os.path.getsize(fpath)
        h.update(str(size).encode())
        with open(fpath, "rb") as f:
            head = f.read(chunk)
            h.update(head)
            if size > chunk * 2:
                f.seek(-chunk, 2)
                h.update(f.read(chunk))
    except OSError:
        pass
    return h.hexdigest()[:16]


class MediaManagerBackend(QObject):
    # -- Signals --------------------------------------------------------------
    scanProgress  = Signal(int, int, str)   # current, total, current_file
    scanComplete  = Signal(str, int)        # collection_name, record_count
    scanError     = Signal(str)
    dbConnected   = Signal(bool)
    listLoaded    = Signal(str, list)       # list_name, items
    listSaved     = Signal(str, bool)       # list_name, success
    searchResults = Signal(list)            # list of result dicts
    reportData    = Signal(list)            # list of collection summary dicts
    compareResult = Signal(list, list)      # only_in_a, only_in_b
    operationDone = Signal(str, bool)       # operation_name, success
    statusMessage = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._cancel_scan = False

    # -- DB connection test ----------------------------------------------------

    @Slot()
    def test_connection(self):
        result = db.test_connection()
        self.dbConnected.emit(result)
        msg = "MediaManager2 DB connected " if result else "MediaManager2 DB connection failed "
        self.statusMessage.emit(msg)
        log.info("[MM] test_connection: %s", result)

    # -- List management -------------------------------------------------------

    @Slot(str)
    def load_list(self, list_name: str):
        """Load a named list and emit listLoaded(list_name, items)."""
        try:
            if list_name == "media_types":
                items = db.get_media_types()
            elif list_name == "excluded_folders":
                items = db.get_excluded_folders()
            elif list_name == "master_types":
                items = db.get_master_types()
            elif list_name == "extensions":
                items = db.get_file_extensions()
            else:
                log.warning("[MM] load_list: unknown list '%s'", list_name)
                items = []
            self.listLoaded.emit(list_name, items)
        except Exception as e:
            log.error("[MM] load_list(%s): %s", list_name, e)
            self.listLoaded.emit(list_name, [])

    @Slot(str, list)
    def save_list(self, list_name: str, items: list):
        """Persist a named list back to DB."""
        table_map = {
            "media_types":       "mediatypename",
            "excluded_folders":  "excluded_folders",
            "master_types":      "mastertype",
            "extensions":        "mediatypes",
        }
        table = table_map.get(list_name)
        if not table:
            self.listSaved.emit(list_name, False)
            return
        ok = db.upsert_list(table, items)
        self.listSaved.emit(list_name, ok)
        self.statusMessage.emit(f"{'Saved' if ok else 'Save failed:'} {list_name}")

    # -- Search ----------------------------------------------------------------

    @Slot(str)
    def search_collections(self, query: str):
        def _run():
            results = db.search_all_collections(query)
            self.searchResults.emit(results)
        threading.Thread(target=_run, daemon=True).start()

    # -- Scan Location ---------------------------------------------------------

    @Slot(str)
    def start_scan(self, folder_path: str):
        """Scan a folder tree and insert into mediafiledetail.
        Collection name is auto-generated from device + path + timestamp.
        Emits scanError with 'DUPLICATE' prefix if collection already exists,
        so QML can show a popup and call start_scan_confirmed to proceed.
        """
        self._cancel_scan = False
        device = socket.gethostname()
        prefix = _build_collection_prefix(folder_path, device)
        dupes = db.collection_exists(prefix)
        if dupes:
            existing = dupes[0].get("collection_name", "?")
            self.scanError.emit("DUPLICATE:" + existing)
            return
        self._launch_scan(folder_path, "mediafiledetail", "Master")

    @Slot(str)
    def start_scan_confirmed(self, folder_path: str):
        """Start scan bypassing duplicate check (user confirmed continue)."""
        self._cancel_scan = False
        self._launch_scan(folder_path, "mediafiledetail", "Master")

    def _launch_scan(self, folder_path, table, master_type, media_type=""):
        threading.Thread(
            target=self._scan_worker,
            args=(folder_path, table, master_type, media_type),
            daemon=True,
        ).start()

    # -- Scan Master -----------------------------------------------------------

    @Slot(str, str, str)
    def start_master_scan(self, folder_path: str, media_type: str, master_type: str):
        """Scan a folder tree and insert into masterfiledetail.
        Collection name is auto-generated from device + path + timestamp.
        """
        self._cancel_scan = False
        self._launch_scan(folder_path, "masterfiledetail", master_type, media_type)

    @Slot()
    def cancel_scan(self):
        self._cancel_scan = True
        self.statusMessage.emit("Scan cancelled.")

    def _scan_worker(self, folder_path: str, table: str,
                     master_type: str = "Master", media_type: str = ""):
        """Worker thread: walk folder, collect file records, batch-insert to DB."""
        try:
            device = socket.gethostname()
            collection_name = _build_collection_name(folder_path, device)

            excluded = set(db.get_excluded_folders())
            ext_map = {r["file_extension"].lower(): r["media_category"]
                       for r in db.get_file_extensions()}

            # Collect files
            all_files = []
            for root, dirs, files in os.walk(folder_path):
                dirs[:] = [d for d in dirs if d not in excluded]
                if self._cancel_scan:
                    self.statusMessage.emit("Scan cancelled.")
                    return
                for fname in files:
                    fpath = os.path.join(root, fname)
                    ext = Path(fname).suffix.lower()
                    all_files.append((fpath, fname, ext))

            total = len(all_files)
            self.statusMessage.emit(f"Found {total} files, filtering by media type...")

            batch = []
            accepted = 0
            for idx, (fpath, fname, ext) in enumerate(all_files):
                if self._cancel_scan:
                    self.statusMessage.emit("Scan cancelled.")
                    return

                # Stat once: get size and creation time together
                try:
                    st = os.stat(fpath)
                    size = st.st_size
                    file_creation_date = datetime.fromtimestamp(st.st_ctime).strftime(
                        "%Y-%m-%d %H:%M:%S"
                    )
                except OSError:
                    size = 0
                    file_creation_date = None

                category = ext_map.get(ext)  # None if extension not in mediatypes table

                # Filter: master scan -> only the selected media type;
                #         non-master scan -> any known media type, reject unknowns
                if media_type:
                    if category != media_type:
                        continue
                else:
                    if category is None:
                        continue

                checksum = _fast_checksum(fpath)

                record = {
                    "file_path":           fpath,
                    "file_name":           fname,
                    "file_extension":      ext,
                    "file_size_bytes":     size,
                    "file_creation_date":  file_creation_date,
                    "collection_name":     collection_name,
                    "media_category":      category or "",
                    "device":              device,
                    "location":            folder_path,
                    "checksum":            checksum,
                    "duplicated":          "0",
                }
                if table == "masterfiledetail":
                    record["master_type"] = master_type

                batch.append(record)
                accepted += 1

                if accepted % 50 == 0:
                    self.scanProgress.emit(accepted, total, fname)

                if len(batch) >= 200:
                    db.batch_insert_files(table, batch)
                    batch.clear()

            if batch:
                db.batch_insert_files(table, batch)

            self.scanProgress.emit(accepted, total, "")
            self.scanComplete.emit(collection_name, accepted)
            self.statusMessage.emit(
                f"Scan complete -- {accepted} media files accepted (of {total} found) in '{collection_name}'"
            )
        except Exception as e:
            log.error("[MM] scan_worker: %s", e)
            self.scanError.emit(str(e))

    # -- Reporting -------------------------------------------------------------

    @Slot(str, bool)
    def load_report(self, table: str, master_only: bool):
        def _run():
            data = db.get_collection_summary(table, master_only)
            self.reportData.emit(data)
        threading.Thread(target=_run, daemon=True).start()

    # -- Compare ---------------------------------------------------------------

    @Slot(str, str, str, str)
    def compare_collections(self, table_a: str, coll_a: str,
                             table_b: str, coll_b: str):
        def _key(p: str) -> str:
            return os.path.basename(p).lower().strip()

        def _run():
            raw_a = db.get_file_paths_for_collection(table_a, coll_a)
            raw_b = db.get_file_paths_for_collection(table_b, coll_b)
            map_a = {_key(p): p for p in raw_a}
            map_b = {_key(p): p for p in raw_b}
            keys_a, keys_b = set(map_a), set(map_b)
            only_a = [{"file_path": map_a[k]} for k in sorted(keys_a - keys_b)]
            only_b = [{"file_path": map_b[k]} for k in sorted(keys_b - keys_a)]
            self.compareResult.emit(only_a, only_b)
            self.statusMessage.emit(
                f"Compare done -- {len(only_a)} missing from B, {len(only_b)} missing from A"
            )
        threading.Thread(target=_run, daemon=True).start()

    # -- Manage ----------------------------------------------------------------

    @Slot(str, str)
    def remove_collection(self, table: str, collection_name: str):
        """Delete DB rows only."""
        count = db.remove_collection_records(table, collection_name)
        ok = count >= 0
        self.operationDone.emit("remove", ok)
        self.statusMessage.emit(f"Removed {count} records for '{collection_name}'")

    @Slot(str, str)
    def delete_collection(self, table: str, collection_name: str):
        """Delete DB rows AND disk files."""
        paths = db.get_file_paths_for_collection(table, collection_name)
        deleted_files = 0
        errors = 0
        for fpath in paths:
            try:
                if os.path.isfile(fpath):
                    os.remove(fpath)
                    deleted_files += 1
            except OSError as e:
                log.error("[MM] delete_collection file error: %s", e)
                errors += 1
        db.remove_collection_records(table, collection_name)
        ok = errors == 0
        self.operationDone.emit("delete", ok)
        self.statusMessage.emit(
            f"Deleted {deleted_files} files, {errors} errors -- '{collection_name}'"
        )

    @Slot(str, str, str)
    def move_collection(self, table: str, collection_name: str, new_path: str):
        """Move files on disk and update DB paths."""
        paths = db.get_file_paths_for_collection(table, collection_name)
        moved = 0
        errors = 0
        try:
            conn = db.get_mm2_connection()
            cur = conn.cursor()
            for old_path in paths:
                try:
                    fname = os.path.basename(old_path)
                    dest = os.path.join(new_path, fname)
                    shutil.move(old_path, dest)
                    cur.execute(
                        f"UPDATE {table} SET file_path=%s WHERE file_path=%s",
                        (dest, old_path),
                    )
                    moved += 1
                except Exception as e:
                    log.error("[MM] move_collection file error: %s", e)
                    errors += 1
            conn.commit()
            cur.close(); conn.close()
        except Exception as e:
            log.error("[MM] move_collection: %s", e)
            errors += 1
        ok = errors == 0
        self.operationDone.emit("move", ok)
        self.statusMessage.emit(
            f"Moved {moved} files, {errors} errors -- '{collection_name}'"
        )

    @Slot(str, str, str)
    def transfer_collection(self, from_table: str, to_table: str, collection_name: str):
        """Copy rows from one table to the other."""
        count = db.transfer_records(from_table, to_table, collection_name)
        ok = count > 0
        self.operationDone.emit("transfer", ok)
        self.statusMessage.emit(
            f"Transferred {count} records from {from_table} -> {to_table} for '{collection_name}'"
        )

    # -- Helper slots used by QML dropdowns -----------------------------------

    @Slot(str, result=list)
    def get_collection_names(self, table: str) -> list:
        return db.get_distinct_collection_names(table)

    @Slot(str, result=list)
    def get_distinct_devices(self, table: str) -> list:
        return db.get_distinct_devices(table)

    @Slot(str, result=list)
    def get_collection_detail_sync(self, collection_name: str) -> list:
        """Return detail rows for canvas chart click (called from QML, runs on main thread)."""
        # Small enough to do sync for now
        for tbl in ("masterfiledetail", "mediafiledetail"):
            rows = db.get_collection_detail(tbl, collection_name)
            if rows:
                return rows
        return []
