import json

class ArchitectSummary:
    def __init__(self):
        # This is our 'Bookshelf' - the cumulative list of movie leaf-names
        self.working_foundation = []
        self.panel_results = {} # Session history tracking

    # --- THE ENGINE ---
    def apply_logic(self, panel_index, new_ids, gate, is_narrowing):
        # Rule 0: Foundation Setup
        if panel_index == 0 or not self.working_foundation:
            self.working_foundation = list(set(new_ids))
            return len(self.working_foundation)

        # RULE 1: THE NOT GATE (Highest Priority)
        # We ignore 'is_narrowing' here to avoid double negatives.
        if gate == "NOT":
            print(f" [ENGINE] Excluding {len(new_ids)} items from foundation.")
            self.working_foundation = self.list_excluding(self.working_foundation, new_ids)

        # RULE 2: THE FEATURING LOGIC (Intersection)
        elif is_narrowing:
            self.working_foundation = self.list_featuring(self.working_foundation, new_ids)
        
        # RULE 3: THE UNION LOGIC (Addition)
        else:
            self.working_foundation = self.list_union(self.working_foundation, new_ids)

        return len(self.working_foundation)

    # --- THE MATH OPERATIONS ---

    def list_featuring(self, foundation, new_panel):
        """The 'AND' Gate: Keeps only items present in BOTH lists (A AND B)."""
        # This is the '1960s Westerns' logic
        return list(set(foundation) & set(new_panel))

    def list_union(self, foundation, new_panel):
        """The 'OR' Gate: Combines both lists, no duplicates (A OR B)."""
        return list(set(foundation) | set(new_panel))

    def list_excluding(self, foundation, new_panel):
        """The 'NOT' Gate: Removes panel items from foundation (A - B)."""
        return list(set(foundation) - set(new_panel))

    # --- UTILITIES ---

    def get_current_result(self):
        """Returns the finalized list to the Controller."""
        return self.working_foundation

    def reset(self):
        """Clears the bookshelf."""
        self.working_foundation = []
        self.panel_results = {}
        print("[CLEAN] [ENGINE] Logic Reset.")

    def list_excluding(self, foundation, new_panel):
        """
        The 'NOT' Gate: Removes panel items from the foundation.
        Logic: A - (A AND B)
        """
        set_foundation = set(foundation)
        set_panel = set(new_panel)
        
        # Mathematical Difference: Keep everything in foundation NOT in panel
        result_set = set_foundation - set_panel
        
        # Return as a list (conversion back for the HUD)
        return list(result_set)