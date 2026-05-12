import os
from PySide6.QtCore import QObject, Slot, Signal

class ToDoManager(QObject):
    # This lets the UI update instantly if the file changes
    todoChanged = Signal(str)

    def __init__(self):
        super().__init__()
        # Using raw string for the server path
        self.filepath = r"W:\MediaVerse\ToDo\ToDo.txt"
        
    def _ensure_dir(self):
        """Ensures the directory exists before saving."""
        folder = os.path.dirname(self.filepath)
        if not os.path.exists(folder):
            try:
                os.makedirs(folder, exist_ok=True)
                print(f"Created directory: {folder}")
            except Exception as e:
                print(f"Directory Error: {e}")

    @Slot(result=str)
    def load_todo(self):
        """Reads the shared text file from the server."""
        if not os.path.exists(self.filepath):
            return ""
        try:
            with open(self.filepath, 'r', encoding='utf-8') as f:
                return f.read()
        except Exception as e:
            print(f"Read Error: {e}")
            return ""

    @Slot(str)
    def save_todo(self, content):
        """Writes the text to the server and signals success."""
        self._ensure_dir()
        try:
            with open(self.filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"[OK] Saved to: {self.filepath}")
            self.todoChanged.emit(content)
        except Exception as e:
            print(f"[ERROR] Save Error: {e}")