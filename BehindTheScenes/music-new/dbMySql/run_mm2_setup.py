"""Run from the project root to create the MediaManager2 database and tables."""
import mysql.connector
import os
import re
import sys
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent.parent / "sqlCreds.env")

sql_file = Path(__file__).parent / "create_mediamanager2.sql"
raw = sql_file.read_text(encoding="utf-8")

# Strip single-line comments before splitting on ;
lines = [l for l in raw.splitlines() if not l.strip().startswith("--")]
sql = "\n".join(lines)

try:
    conn = mysql.connector.connect(
        host=os.getenv("MM2_HOST"),
        user=os.getenv("MM2_USER"),
        password=os.getenv("MM2_PASSWORD"),
        connect_timeout=5,
        # No database= -- CREATE DATABASE runs first
    )
    cur = conn.cursor()
    for stmt in sql.split(";"):
        s = stmt.strip()
        if s:
            try:
                cur.execute(s)
                if cur.with_rows:
                    cur.fetchall()
                print(f"OK: {s[:70]}")
            except Exception as e:
                print(f"SKIP: {e}")
    conn.commit()
    cur.close()
    conn.close()
    print("\nMediaManager2 setup complete.")
except Exception as e:
    print(f"Connection failed: {e}")
    sys.exit(1)
