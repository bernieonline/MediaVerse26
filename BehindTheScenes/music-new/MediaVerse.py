"""
MediaVerse Launcher -- PyInstaller entry point.
Sets up the environment and delegates to Framework.py.
"""
import sys
import os
import traceback

# Ensure UTF-8 output -- frozen windowed exe has no console, so redirect
# stdout/stderr to a UTF-8 log file to prevent cp1252 encoding crashes
os.environ["PYTHONUTF8"] = "1"
if getattr(sys, 'frozen', False):
    import io
    _log_path = os.path.join(os.path.expanduser("~"), "MediaVerse_output.log")
    _log_file = open(_log_path, "w", encoding="utf-8", errors="replace")
    sys.stdout = _log_file
    sys.stderr = _log_file

from pathlib import Path

if getattr(sys, 'frozen', False):
    # Running as a PyInstaller bundle -- data files are in _internal/
    app_root = Path(sys.executable).resolve().parent / "_internal"
    # Log crashes to user's home (Program Files is not writable)
    crash_log = Path.home() / "MediaVerse_crash_log.txt"
else:
    # Running from source -- this file sits in the music-new root
    app_root = Path(__file__).resolve().parent
    crash_log = None

# Add the paths Framework.py normally sets up
sandbox_root = app_root / "Sandbox"
py_root = sandbox_root / "MediaPlayerPy"
sys.path.insert(0, str(py_root))
sys.path.insert(0, str(sandbox_root))
sys.path.insert(0, str(app_root))

os.chdir(str(py_root))

try:
    # Now import and run Framework
    import Framework
    Framework.main()
except Exception as e:
    if crash_log:
        with open(crash_log, "w", encoding="utf-8") as f:
            f.write(f"app_root: {app_root}\n")
            f.write(f"py_root: {py_root}\n")
            f.write(f"cwd: {os.getcwd()}\n\n")
            traceback.print_exc(file=f)
    raise
