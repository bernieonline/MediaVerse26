"""
Populate the excluded_folders table in MediaManager2 with the full list.
Run once: & $py dbMySql\populate_excluded_folders.py
"""
import mysql.connector
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent.parent / "sqlCreds.env")

FOLDERS = [
    "__pycache__",
    "AppData",
    "Application Support",
    "Applications",
    "bin",
    "boot",
    "bower_components",
    "build",
    "cores",
    "dev",
    "dist",
    "etc",
    "jails",
    "lib",
    "lib64",
    "Library",
    "Local",
    "Network",
    "node_modules",
    "private",
    "proc",
    "Program Files",
    "Program Files (x86)",
    "run",
    "sbin",
    "srv",
    "sys",
    "System",
    "System32",
    "Temp",
    "Thumbnails",
    "tmp",
    "var",
    "venv",
    "Volumes",
    "Windows",
    # originals already in DB -- included here so the full list is authoritative
    "@eaDir",
    ".@__thumb",
    "System Volume Information",
    "$RECYCLE.BIN",
    ".Spotlight-V100",
    ".Trashes",
]

try:
    conn = mysql.connector.connect(
        host=os.getenv("MM2_HOST"),
        user=os.getenv("MM2_USER"),
        password=os.getenv("MM2_PASSWORD"),
        database=os.getenv("MM2_DB"),
        connect_timeout=5,
    )
    cur = conn.cursor()

    # Wipe and repopulate so the list is exactly as defined above
    cur.execute("DELETE FROM excluded_folders")
    for folder in sorted(set(FOLDERS)):
        cur.execute(
            "INSERT INTO excluded_folders (folder_name) VALUES (%s)", (folder,)
        )
        print(f"  + {folder}")

    conn.commit()
    print(f"\nDone -- {len(set(FOLDERS))} folders written to excluded_folders.")
    cur.close()
    conn.close()

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
