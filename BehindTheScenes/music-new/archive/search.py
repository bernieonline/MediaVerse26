import tkinter as tk
from tkinter import filedialog
'''I dont think my program uses this'''
def select_folder():
    # Create a root window and hide it
    root = tk.Tk()
    root.withdraw()  # Hide the root window

    # Open a file dialog to select a directory
    folder_path = filedialog.askdirectory(title="Select a Folder")

    # Destroy the root window after selection
    root.destroy()

    # Return the selected folder path
    return folder_path

# Example usage
if __name__ == "__main__":
    selected_folder = select_folder()
    if selected_folder:
        print(f"Selected folder: {selected_folder}")
    else:
        print("No folder selected.")












































        
