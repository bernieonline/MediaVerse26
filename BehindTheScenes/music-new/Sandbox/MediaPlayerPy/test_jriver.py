import subprocess
import os

# 1. THE EXACT PATH FROM YOUR SIDECAR
# Note the 'r' prefix - this makes it a 'raw' string so backslashes aren't treated as escape characters.
movie_path = r"W:\Collection\1960s 70s 80s\Bear Island (1979).mp4"

# 2. YOUR JRIVER EXECUTABLE PATH
# Update this if you are using a different version (MC31, MC30, etc.)
jriver_exe = r"C:\Program Files\J River\Media Center 32\MC32.exe"

def test_playback():
    print(f"Checking if file exists: {os.path.exists(movie_path)}")
    print(f"Checking if JRiver exists: {os.path.exists(jriver_exe)}")
    
    if not os.path.exists(jriver_exe):
        print("❌ ERROR: JRiver EXE not found at that location.")
        return

    # TEST A: THE SIMPLEST METHOD (Passing path as an argument)
    # This is what we are currently trying to do in DriveManager.
    print("\n--- TEST A: Direct Path Argument ---")
    try:
        subprocess.Popen([jriver_exe, movie_path])
        print("Command sent: [jriver_exe, movie_path]")
    except Exception as e:
        print(f"Test A failed: {e}")

    input("\nPress Enter to try TEST B (Alternative Slash Direction)...")

    # TEST B: FORWARD SLASHES (Some players prefer this even on Windows)
    print("\n--- TEST B: Forward Slashes ---")
    forward_path = movie_path.replace('\\', '/')
    try:
        subprocess.Popen([jriver_exe, forward_path])
        print(f"Command sent: [jriver_exe, {forward_path}]")
    except Exception as e:
        print(f"Test B failed: {e}")

    input("\nPress Enter to try TEST C (The /Play Command Switch)...")

    # TEST C: EXPLICIT PLAY SWITCH
    # Some versions of JRiver prefer the /Play switch to ensure it starts immediately.
    print("\n--- TEST C: Explicit /Play Switch ---")
    try:
        subprocess.Popen([jriver_exe, "/Play", movie_path])
        print(f"Command sent: [jriver_exe, '/Play', movie_path]")
    except Exception as e:
        print(f"Test C failed: {e}")

if __name__ == "__main__":
    test_playback()