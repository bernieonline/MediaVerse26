import subprocess
import os

def launch_jriver(video_path, jriver_path):
    """
    Launch JRiver Media Center with a given video file.
    
    :param video_path: Path to the video file (string)
    :param jriver_path: Path to JRiver executable (string)
    """
    
    

    if not os.path.exists(video_path):
        print(f"❌ Video file not found: {video_path}")
        return
    
    if not os.path.exists(jriver_path):
        print(f"❌ JRiver executable not found: {jriver_path}")
        return
    
    try:
        # Launch JRiver with the video file
        subprocess.Popen([jriver_path, video_path])
        print(f"🎥 Launched JRiver with: {video_path}")
    except Exception as e:
        print(f"❌ Failed to launch JRiver: {e}")


if __name__ == "__main__":
    # Your video file path
    video_file = r"W:\Collection\Caine\Cider House Rules (1999).m2ts"
    
    # Replace this with the actual JRiver executable path on your system
    jriver_exe = r"C:\Program Files\J River\Media Center 33\MC33.exe"

   
    
    launch_jriver(video_file, jriver_exe)