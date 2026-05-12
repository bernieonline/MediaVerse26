"""
cache_updater.py
----------------
Builds and maintains local cache folders for thumbnails and display-ready images.
Run at program startup to ensure fast image loading in QML.
"""
import sys
from pathlib import Path
from PIL import Image

# Add the parent folder (music-new) to sys.path
sys.path.append(str(Path(__file__).resolve().parents[2]))  # BehindTheScenes/music-new

from project_paths import paths   # import your central path definitions

# --- Configure paths ---
nas_root = Path(r"W:\Collection")   # mapped drive to TrueNAS
thumb_dir = paths["thumbs"]
display_dir = paths["display"]

# --- Ensure cache directories exist ---
thumb_dir.mkdir(parents=True, exist_ok=True)
display_dir.mkdir(parents=True, exist_ok=True)

def ensure_cache(img_path: Path):
    """Generate thumbnail and display-ready versions if missing or outdated."""
    try:
        rel = img_path.relative_to(nas_root)
        thumb_out = thumb_dir / rel
        display_out = display_dir / rel

        thumb_out.parent.mkdir(parents=True, exist_ok=True)
        display_out.parent.mkdir(parents=True, exist_ok=True)

        # Thumbnail (small, fast browsing)
        if not thumb_out.exists() or img_path.stat().st_mtime > thumb_out.stat().st_mtime:
            with Image.open(img_path) as im:
                im.thumbnail((256, 256))
                im.save(thumb_out, "JPEG", quality=85)

        # Display-ready (big screen, high quality)
        if not display_out.exists() or img_path.stat().st_mtime > display_out.stat().st_mtime:
            with Image.open(img_path) as im:
                im.thumbnail((1920, 1080))
                im.save(display_out, "JPEG", quality=90)

    except Exception as e:
        print(f"[WARN] Skipped {img_path}: {e}")

def update_cache():
    """Scan NAS and update cache."""
    print("Building image cache... this may take a minute on first run.")
    for ext in ("*.jpg", "*.jpeg"):
        for img_path in nas_root.glob(f"**/{ext}"):
            ensure_cache(img_path)
    print("[OK] Cache ready! Images will now load instantly.")

if __name__ == "__main__":
    update_cache()