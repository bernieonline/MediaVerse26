import subprocess
import os
import sys
from pathlib import Path

def play_with_elite_engine(movie_path):
    # 1. Configuration
    # We use MPC-BE as the "host" because it is lightweight and handles DirectShow perfectly.
    mpc_path = Path(r"C:\Program Files\MPC-HC\mpc-hc64.exe")
    #mpc_path = Path(r"C:\Users\berna\OneDrive\BG Files\Downloads\executables\Media Related\MPC-HC.1.7.13.x64.exe")
    #jriver_base = Path(r"C:\Program Files\MPC-HC\mpc-hc64.exe"
    
    print(f"--- MediaVerse Playback Bridge ---")
    print(f"Target: {movie_path}")

    # 2. Validation
    if not mpc_path.exists():
        print(f"❌ Error: MPC-BE not found at {mpc_path}")
        return
    
    if not Path(movie_path).exists():
        print(f"❌ Error: Movie file not found at {movie_path}")
        return

    # 3. Execution Command
    # /play: Start immediately
    # /fullscreen: Open in full screen
    # /close: Exit MPC-BE when movie ends (returning you to MediaVerse)
    cmd = [
        str(mpc_path),
        str(movie_path),
        "/play",
        "/fullscreen",
        "/close"
    ]

    print(f"🚀 Launching via MPC-BE...")
    print(f"Settings Check: Ensure MPC-BE is set to use madVR and JRiver Audio.")
    
    try:
        # Launching the process
        subprocess.Popen(cmd)
        print("✅ Success: Playback started.")
    except Exception as e:
        print(f"❌ Failed to launch: {e}")

if __name__ == "__main__":
    # The file path you provided
    target_movie = r"W:\Collection\1960s 70s 80s\Zulu (1964).M2TS"
    play_with_elite_engine(target_movie)