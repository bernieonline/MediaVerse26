import json
from pathlib import Path

def build_tree(manifest_path: str):
    """Build a nested dictionary tree from manifest entries using video paths."""
    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    tree = {}
    for item in manifest["items"]:
        video_path = item["shared"].get("video", "")
        if not video_path:
            continue

        parts = Path(video_path).parts
        node = tree
        for part in parts:
            if part.lower().endswith((".mkv", ".mp4", ".avi", ".webm", ".m2ts", ".ts", ".vob")):
                node.setdefault("images", []).append(part)
            else:
                node = node.setdefault(part.lower(), {"__name__": part})
    return tree

def get_children(tree, folder_name: str):
    """Return subfolders and images for a given folder name."""
    folder_name = folder_name.lower()

    def find_node(node):
        if folder_name in node:
            return node[folder_name]
        for key, child in node.items():
            if isinstance(child, dict) and key != "__name__":
                result = find_node(child)
                if result:
                    return result
        return None

    node = find_node(tree)
    if not node:
        return {"subfolders": [], "images": []}

    subfolders = [v["__name__"] for k, v in node.items() if isinstance(v, dict) and k != "__name__"]
    images = node.get("images", [])
    return {"subfolders": subfolders, "images": images}


# -------------------------------
# Example usage
# -------------------------------
if __name__ == "__main__":
    manifest_path = r"W:\Collection\ManifestCache\manifest.json"
    tree = build_tree(manifest_path)

    print("Cache search ready. Type a folder name to inspect, or 'q' to quit.")
    while True:
        folder = input("\nEnter folder name: ").strip()
        if folder.lower() == "q":
            break
        result = get_children(tree, folder)
        print(f"{folder} → {result}")
