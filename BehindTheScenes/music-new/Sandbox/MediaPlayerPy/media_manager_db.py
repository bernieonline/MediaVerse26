"""
media_manager_db.py -- MySQL layer for MediaManager2 database.

All functions open a fresh connection per call (same pattern as dbMySql/db_utils.py).
Credentials loaded from sqlCreds.env: MM2_HOST, MM2_USER, MM2_PASSWORD, MM2_DB.
"""

import mysql.connector
import os
import logging
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(dotenv_path=Path(__file__).parent.parent.parent / "sqlCreds.env")

_MM2_HOST = os.getenv("MM2_HOST")
_MM2_USER = os.getenv("MM2_USER")
_MM2_PASSWORD = os.getenv("MM2_PASSWORD")
_MM2_DB = os.getenv("MM2_DB", "MediaManager2")

log = logging.getLogger(__name__)


# -----------------------------------------------------------------------------
#  Connection
# -----------------------------------------------------------------------------

def get_mm2_connection() -> mysql.connector.MySQLConnection:
    """Open and return a fresh connection to MediaManager2."""
    return mysql.connector.connect(
        host=_MM2_HOST,
        user=_MM2_USER,
        password=_MM2_PASSWORD,
        database=_MM2_DB,
        connect_timeout=5,
    )


def test_connection() -> bool:
    """Return True if MediaManager2 is reachable, False otherwise."""
    try:
        conn = get_mm2_connection()
        ok = conn.is_connected()
        conn.close()
        return ok
    except Exception as e:
        log.error("[MM2] Connection failed: %s", e)
        return False


# -----------------------------------------------------------------------------
#  List management
# -----------------------------------------------------------------------------

def get_media_types() -> list:
    """Return all rows from mediatypename."""
    try:
        conn = get_mm2_connection()
        cur = conn.cursor(dictionary=True)
        cur.execute("SELECT id, media_type_name FROM mediatypename ORDER BY media_type_name")
        rows = cur.fetchall()
        cur.close(); conn.close()
        return rows
    except Exception as e:
        log.error("[MM2] get_media_types: %s", e)
        return []


def get_excluded_folders() -> list:
    """Return list of folder name strings to skip during os.walk."""
    try:
        conn = get_mm2_connection()
        cur = conn.cursor()
        cur.execute("SELECT folder_name FROM excluded_folders ORDER BY folder_name")
        rows = [r[0] for r in cur.fetchall()]
        cur.close(); conn.close()
        return rows
    except Exception as e:
        log.error("[MM2] get_excluded_folders: %s", e)
        return []


def get_master_types() -> list:
    """Return all rows from mastertype."""
    try:
        conn = get_mm2_connection()
        cur = conn.cursor(dictionary=True)
        cur.execute("SELECT id, master_type_name FROM mastertype ORDER BY master_type_name")
        rows = cur.fetchall()
        cur.close(); conn.close()
        return rows
    except Exception as e:
        log.error("[MM2] get_master_types: %s", e)
        return []


def get_file_extensions() -> list:
    """Return all rows from mediatypes (extension -> category mapping)."""
    try:
        conn = get_mm2_connection()
        cur = conn.cursor(dictionary=True)
        cur.execute("SELECT id, file_extension, media_category FROM mediatypes ORDER BY file_extension")
        rows = cur.fetchall()
        cur.close(); conn.close()
        return rows
    except Exception as e:
        log.error("[MM2] get_file_extensions: %s", e)
        return []


def upsert_list(table: str, items: list) -> bool:
    """
    Replace all rows in `table` with `items`.
    Supported tables: excluded_folders (list of strings),
                      mediatypename / mastertype / mediatypes (list of dicts).
    """
    _allowed = {"excluded_folders", "mediatypename", "mastertype", "mediatypes"}
    if table not in _allowed:
        log.error("[MM2] upsert_list: table '%s' not allowed", table)
        return False
    try:
        conn = get_mm2_connection()
        cur = conn.cursor()
        if table == "excluded_folders":
            cur.execute("DELETE FROM excluded_folders")
            for name in items:
                cur.execute("INSERT INTO excluded_folders (folder_name) VALUES (%s)", (str(name),))
        elif table == "mediatypename":
            cur.execute("DELETE FROM mediatypename")
            for item in items:
                name = item.get("media_type_name", item) if isinstance(item, dict) else str(item)
                cur.execute("INSERT INTO mediatypename (media_type_name) VALUES (%s)", (name,))
        elif table == "mastertype":
            cur.execute("DELETE FROM mastertype")
            for item in items:
                name = item.get("master_type_name", item) if isinstance(item, dict) else str(item)
                cur.execute("INSERT INTO mastertype (master_type_name) VALUES (%s)", (name,))
        elif table == "mediatypes":
            cur.execute("DELETE FROM mediatypes")
            for item in items:
                if isinstance(item, dict):
                    ext = item.get("file_extension", "")
                    cat = item.get("media_category", "")
                else:
                    ext, cat = str(item), ""
                cur.execute(
                    "INSERT INTO mediatypes (file_extension, media_category) VALUES (%s, %s)",
                    (ext, cat),
                )
        conn.commit()
        cur.close(); conn.close()
        return True
    except Exception as e:
        log.error("[MM2] upsert_list(%s): %s", table, e)
        return False


# -----------------------------------------------------------------------------
#  Search
# -----------------------------------------------------------------------------

def search_all_collections(query: str) -> list:
    """Search both mediafiledetail and masterfiledetail for LIKE %query%."""
    results = []
    try:
        conn = get_mm2_connection()
        cur = conn.cursor(dictionary=True)
        like = f"%{query}%"
        for tbl in ("mediafiledetail", "masterfiledetail"):
            cur.execute(
                f"""SELECT id, file_path, file_name, file_extension,
                           file_creation_date, collection_name, media_category,
                           device, location, created_at,
                           '{tbl}' AS source_table
                    FROM {tbl}
                    WHERE file_name LIKE %s OR file_path LIKE %s OR collection_name LIKE %s
                    LIMIT 200""",
                (like, like, like),
            )
            results.extend(cur.fetchall())
        cur.close(); conn.close()
    except Exception as e:
        log.error("[MM2] search_all_collections: %s", e)
    return results


# -----------------------------------------------------------------------------
#  Collection creation
# -----------------------------------------------------------------------------

def insert_media_file(record: dict) -> bool:
    """Insert one record into mediafiledetail."""
    try:
        conn = get_mm2_connection()
        cur = conn.cursor()
        cur.execute(
            """INSERT INTO mediafiledetail
               (file_path, file_name, file_extension, file_size_bytes,
                collection_name, media_category, device, checksum)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
            (
                record.get("file_path", ""),
                record.get("file_name", ""),
                record.get("file_extension", ""),
                record.get("file_size_bytes", 0),
                record.get("collection_name", ""),
                record.get("media_category", ""),
                record.get("device", ""),
                record.get("checksum", ""),
            ),
        )
        conn.commit()
        cur.close(); conn.close()
        return True
    except Exception as e:
        log.error("[MM2] insert_media_file: %s", e)
        return False


def insert_master_file(record: dict) -> bool:
    """Insert one record into masterfiledetail."""
    try:
        conn = get_mm2_connection()
        cur = conn.cursor()
        cur.execute(
            """INSERT INTO masterfiledetail
               (file_path, file_name, file_extension, file_size_bytes,
                collection_name, media_category, device, master_type, checksum)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
            (
                record.get("file_path", ""),
                record.get("file_name", ""),
                record.get("file_extension", ""),
                record.get("file_size_bytes", 0),
                record.get("collection_name", ""),
                record.get("media_category", ""),
                record.get("device", ""),
                record.get("master_type", "Master"),
                record.get("checksum", ""),
            ),
        )
        conn.commit()
        cur.close(); conn.close()
        return True
    except Exception as e:
        log.error("[MM2] insert_master_file: %s", e)
        return False


def batch_insert_files(table: str, records: list) -> int:
    """Insert a batch of file records. Returns count inserted."""
    if table not in ("mediafiledetail", "masterfiledetail"):
        return 0
    inserted = 0
    try:
        conn = get_mm2_connection()
        cur = conn.cursor()
        if table == "mediafiledetail":
            sql = """INSERT INTO mediafiledetail
                     (file_path, file_name, file_extension, file_size_bytes,
                      file_creation_date, collection_name, media_category,
                      device, location, checksum, duplicated)
                     VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"""
            rows = [
                (r["file_path"], r["file_name"], r["file_extension"],
                 r.get("file_size_bytes", 0), r.get("file_creation_date"),
                 r["collection_name"], r.get("media_category", ""),
                 r.get("device", ""), r.get("location", ""),
                 r.get("checksum", ""), r.get("duplicated", "0"))
                for r in records
            ]
        else:
            sql = """INSERT INTO masterfiledetail
                     (file_path, file_name, file_extension, file_size_bytes,
                      file_creation_date, collection_name, media_category,
                      device, location, master_type, checksum, duplicated)
                     VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"""
            rows = [
                (r["file_path"], r["file_name"], r["file_extension"],
                 r.get("file_size_bytes", 0), r.get("file_creation_date"),
                 r["collection_name"], r.get("media_category", ""),
                 r.get("device", ""), r.get("location", ""),
                 r.get("master_type", "Master"), r.get("checksum", ""),
                 r.get("duplicated", "0"))
                for r in records
            ]
        cur.executemany(sql, rows)
        inserted = cur.rowcount
        conn.commit()
        cur.close(); conn.close()
    except Exception as e:
        log.error("[MM2] batch_insert_files(%s): %s", table, e)
    return inserted


def collection_exists(prefix: str) -> list:
    """Return existing collection records whose name starts with prefix (duplicate check).
    prefix should be built as: device:drive_letter:/subfolder:
    """
    results = []
    try:
        conn = get_mm2_connection()
        cur = conn.cursor(dictionary=True)
        like = f"{prefix}%"
        for tbl in ("mediafiledetail", "masterfiledetail"):
            cur.execute(
                f"SELECT DISTINCT collection_name FROM {tbl} WHERE collection_name LIKE %s LIMIT 10",
                (like,),
            )
            results.extend(cur.fetchall())
        cur.close(); conn.close()
    except Exception as e:
        log.error("[MM2] collection_exists: %s", e)
    return results


# -----------------------------------------------------------------------------
#  Reporting
# -----------------------------------------------------------------------------

def get_collection_summary(table: str, master_only: bool = False,
                           device_filter: str = "", category_filter: str = "") -> list:
    """
    Return per-collection summary: name, file_count, total_size_mb, device, category.
    `table` must be 'mediafiledetail' or 'masterfiledetail'.
    """
    if table not in ("mediafiledetail", "masterfiledetail"):
        return []
    try:
        conn = get_mm2_connection()
        cur = conn.cursor(dictionary=True)
        where_parts = []
        params = []
        if master_only and table == "masterfiledetail":
            where_parts.append("master_type = %s")
            params.append("Master")
        if device_filter:
            where_parts.append("device = %s")
            params.append(device_filter)
        if category_filter:
            where_parts.append("media_category = %s")
            params.append(category_filter)
        where = ("WHERE " + " AND ".join(where_parts)) if where_parts else ""
        cur.execute(
            f"""SELECT collection_name, device, media_category,
                       COUNT(*) AS file_count,
                       ROUND(SUM(file_size_bytes) / 1048576.0, 2) AS total_size_mb
                FROM {table} {where}
                GROUP BY collection_name, device, media_category
                ORDER BY total_size_mb DESC""",
            params,
        )
        rows = cur.fetchall()
        cur.close(); conn.close()
        # Convert Decimal -> float so QML can do arithmetic on total_size_mb
        for row in rows:
            if "total_size_mb" in row and row["total_size_mb"] is not None:
                row["total_size_mb"] = float(row["total_size_mb"])
        return rows
    except Exception as e:
        log.error("[MM2] get_collection_summary: %s", e)
        return []


def get_collection_detail(table: str, collection_name: str) -> list:
    """Return all file records for a named collection."""
    if table not in ("mediafiledetail", "masterfiledetail"):
        return []
    try:
        conn = get_mm2_connection()
        cur = conn.cursor(dictionary=True)
        cur.execute(
            f"""SELECT file_path, file_name, file_extension, file_size_bytes,
                       media_category, created_at
                FROM {table}
                WHERE collection_name = %s
                ORDER BY file_path""",
            (collection_name,),
        )
        rows = cur.fetchall()
        cur.close(); conn.close()
        return rows
    except Exception as e:
        log.error("[MM2] get_collection_detail: %s", e)
        return []


# -----------------------------------------------------------------------------
#  Utilities
# -----------------------------------------------------------------------------

def remove_collection_records(table: str, collection_name: str) -> int:
    """Delete all DB rows for a collection. Returns rows deleted."""
    if table not in ("mediafiledetail", "masterfiledetail"):
        return 0
    try:
        conn = get_mm2_connection()
        cur = conn.cursor()
        cur.execute(f"DELETE FROM {table} WHERE collection_name = %s", (collection_name,))
        count = cur.rowcount
        conn.commit()
        cur.close(); conn.close()
        return count
    except Exception as e:
        log.error("[MM2] remove_collection_records: %s", e)
        return 0


def get_file_paths_for_collection(table: str, collection_name: str) -> list:
    """Return list of file_path strings for a collection (used before disk deletion)."""
    if table not in ("mediafiledetail", "masterfiledetail"):
        return []
    try:
        conn = get_mm2_connection()
        cur = conn.cursor()
        cur.execute(
            f"SELECT file_path FROM {table} WHERE collection_name = %s",
            (collection_name,),
        )
        paths = [r[0] for r in cur.fetchall()]
        cur.close(); conn.close()
        return paths
    except Exception as e:
        log.error("[MM2] get_file_paths_for_collection: %s", e)
        return []


def transfer_records(from_table: str, to_table: str, collection_name: str) -> int:
    """Copy rows from from_table to to_table for a collection. Returns rows copied."""
    _allowed = {"mediafiledetail", "masterfiledetail"}
    if from_table not in _allowed or to_table not in _allowed:
        return 0
    try:
        conn = get_mm2_connection()
        cur = conn.cursor()
        # Get common columns (file_path, file_name, file_extension, file_size_bytes,
        # collection_name, media_category, device, checksum)
        cur.execute(
            f"""INSERT INTO {to_table}
                (file_path, file_name, file_extension, file_size_bytes,
                 collection_name, media_category, device, checksum)
                SELECT file_path, file_name, file_extension, file_size_bytes,
                       collection_name, media_category, device, checksum
                FROM {from_table}
                WHERE collection_name = %s""",
            (collection_name,),
        )
        count = cur.rowcount
        conn.commit()
        cur.close(); conn.close()
        return count
    except Exception as e:
        log.error("[MM2] transfer_records: %s", e)
        return 0


def get_distinct_devices(table: str) -> list:
    """Return distinct device values from a table."""
    if table not in ("mediafiledetail", "masterfiledetail"):
        return []
    try:
        conn = get_mm2_connection()
        cur = conn.cursor()
        cur.execute(f"SELECT DISTINCT device FROM {table} ORDER BY device")
        devs = [r[0] for r in cur.fetchall()]
        cur.close(); conn.close()
        return devs
    except Exception as e:
        log.error("[MM2] get_distinct_devices: %s", e)
        return []


def get_distinct_collection_names(table: str) -> list:
    """Return distinct collection_name values from a table."""
    if table not in ("mediafiledetail", "masterfiledetail"):
        return []
    try:
        conn = get_mm2_connection()
        cur = conn.cursor()
        cur.execute(
            f"SELECT DISTINCT collection_name FROM {table} ORDER BY collection_name"
        )
        names = [r[0] for r in cur.fetchall()]
        cur.close(); conn.close()
        return names
    except Exception as e:
        log.error("[MM2] get_distinct_collection_names: %s", e)
        return []
