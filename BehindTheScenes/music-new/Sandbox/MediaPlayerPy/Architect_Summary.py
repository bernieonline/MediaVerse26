# architect_summary.py
# Phase 1: JSON Loader + Panel 1 Case Statement
# ---------------------------------------------

import json
import os
from datetime import datetime
from PySide6.QtCore import QObject, Slot, Signal


# ------------------------------------------------------------
# DataLoader: reads xml_collection_data.json and provides lookups
# ------------------------------------------------------------
class DataLoader:
    def __init__(self, json_path):
        self.movies = []

        if os.path.exists(json_path):
            with open(json_path, "r", encoding="utf-8") as f:
                data = json.load(f)

                # Filter out TV shows
                self.movies = [
                    m for m in data
                    if m.get("Media Sub Type", "").lower() == "movie"
                ]

    # --------------------------------------------------------
    # PANEL 1 LOOKUPS
    # --------------------------------------------------------

    def get_files_from_folder(self, folder_name):
        """
        Return all movie filenames where the folder name appears in the path.
        Example: folder_name = "Bond Movies"
        """
        results = []
        for m in self.movies:
            filename = m.get("Filename", "")
            if folder_name.lower() in filename.lower():
                results.append(filename)
        return results

    def get_files_by_category(self, key, value):
        """
        Generic category lookup.
        key examples: "Actor", "Director", "Genre", "Year"
        """
        results = []

        for m in self.movies:
            if key == "Actor":
                if value in m.get("Actors", []):
                    results.append(m["Filename"])

            elif key == "Director":
                if value == m.get("Director"):
                    results.append(m["Filename"])

            elif key == "Genre":
                genres = m.get("Genre", "").split(";")
                if value in genres:
                    results.append(m["Filename"])

            elif key == "Year":
                if value == m.get("Year"):
                    results.append(m["Filename"])

        return results


# ------------------------------------------------------------
# ArchitectSummary: main backend logic
# ------------------------------------------------------------
class ArchitectSummary(QObject):

    cumulativeListReady = Signal(list)
    cumulativeCountReady = Signal(int)

    def __init__(self, parent=None):
        super().__init__(parent)

        # Load movie metadata from local JSON
        self.db = DataLoader("./xml_collection_data.json")

        # In-memory rule store
        self.rules = {}

        # In-memory cumulative list
        self.cumulative_list = []

    # --------------------------------------------------------
    # PANEL 1 COMMIT ENTRY POINT
    # --------------------------------------------------------
    @Slot(dict)
    def commit_panel(self, rule_data):
        """
        Called by QML when the user clicks Commit on any panel.
        Phase 1: Only Panel 1 logic is implemented.
        """

        panel_index = rule_data.get("panelIndex")
        mode = rule_data.get("mode")
        data = rule_data.get("data")
        checked = rule_data.get("checked")
        gate = rule_data.get("gate")

        # 1. Evaluate rule using case statement
        panel_list = self.evaluate_rule(mode, data)

        # 2. Store cumulative list (Panel 1 only)
        self.cumulative_list = panel_list

        # 3. Store rule record
        self.rules[str(panel_index)] = {
            "mode": mode,
            "data": data,
            "checked": checked,
            "gate": gate
        }

        # 4. Send results back to QML
        self.cumulativeListReady.emit(self.cumulative_list)
        self.cumulativeCountReady.emit(len(self.cumulative_list))

    # --------------------------------------------------------
    # CASE STATEMENT (Panel 1)
    # --------------------------------------------------------
    def evaluate_rule(self, mode, data):
        """
        Case statement for Panel 1.
        Later panels will reuse this logic.
        """

        if mode == "Folder":
            return self.db.get_files_from_folder(data["folder"])

        if mode == "Category":
            return self.db.get_files_by_category(data["key"], data["value"])

        if mode == "Files":
            return data["paths"]

        return []  # safety fallback

    # --------------------------------------------------------
    # SAVE LOGIC (Phase 2 — not implemented yet)
    # --------------------------------------------------------
    @Slot(dict)
    def save_collection(self, save_data):
        pass