import os
import sys
from pathlib import Path

# --- 1. Path Setup (Your verified brute-force) ---
root_path = r"D:\MediaVerse1.0\BehindTheScenes\BehindTheScenes\music-new"
if root_path not in sys.path:
    sys.path.insert(0, root_path)

try:
    from project_paths import paths
    from PIL import Image, ImageDraw, ImageFont
    print(f"[OK] [DEBUG] project_paths loaded from: {root_path}")
except ImportError as e:
    print(f"[ERROR] [DEBUG] Failed to load modules: {e}")
    sys.exit(1)

def generate_with_debug():
    # --- 2. Determine Target Directory ---
    # We'll try to force it into the "Assets" folder
    target_dir = Path(root_path) / "Assets"
    
    print(f"[SEARCH] [DEBUG] Target Directory set to: {target_dir}")
    
    if not target_dir.exists():
        print(f"[DIR] [DEBUG] Creating missing directory: {target_dir}")
        target_dir.mkdir(parents=True, exist_ok=True)
    else:
        print(f"[DIR] [DEBUG] Target directory already exists.")

    output_path = target_dir / "mediaverse.ico"
    print(f" [DEBUG] Full intended file path: {output_path}")

    # --- 3. Drawing Logic ---
    try:
        size = 512
        icon = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(icon)
        
        # Gold & Dark Slate colors
        draw.rounded_rectangle(
            [(10, 10), (size-10, size-10)], 
            radius=90, fill="#1e1e1e", outline="#D4AF37", width=8
        )
        
        # Text
        try:
            font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 260)
        except:
            font = ImageFont.load_default()
            print("[WARN] [DEBUG] Custom font failed, using default.")
            
        draw.text((size/2, size/2-20), "MV", font=font, fill="#D4AF37", anchor="mm")
        print(" [DEBUG] Icon drawing complete in memory.")

        # --- 4. The Critical Save ---
        print(f"[SAVE] [DEBUG] Attempting to save to disk...")
        icon.save(
            str(output_path), 
            format='ICO', 
            sizes=[(16,16), (32,32), (48,48), (64,64), (128,128), (256,256)]
        )
        
        # --- 5. Physical Confirmation ---
        if os.path.exists(output_path):
            file_size = os.path.getsize(output_path)
            print(f"[STAR] [SUCCESS] File physically exists!")
            print(f" [DEBUG] File size: {file_size} bytes")
        else:
            print(f" [FAILURE] Save command finished, but file is NOT on disk.")

    except Exception as e:
        print(f" [CRASH] An error occurred during generation: {e}")

if __name__ == "__main__":
    generate_with_debug()