import sys
from pathlib import Path



db_path = Path("D:/PythonMusic/pythonproject2026/BehindTheScenes/music-new")
sys.path.append(str(db_path))

# Add the parent of dbMySql to sys.path
#sys.path.append(str(Path(__file__).resolve().parent.parent / "BehindTheScenes" / "music-new"))