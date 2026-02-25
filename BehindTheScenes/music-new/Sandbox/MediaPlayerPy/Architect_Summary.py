import json

class ArchitectSummary:
    def __init__(self):
        # This is our 'Bookshelf' - the cumulative list of movie leaf-names
        self.working_foundation = []
        self.panel_results = {} # Session history tracking

    # --- THE ENGINE ---
    def apply_logic(self, panel_index, new_ids, gate, is_narrowing):
        """
        Routes panel data to the correct set operation.
        - gate="NOT": Subtracts from foundation (list_excluding)
        - is_narrowing=True: Intersection (list_featuring)
        - else: Addition (list_union)
        """
        
        # Rule 0: First panel sets the base foundation
        if panel_index == 0 or not self.working_foundation:
            self.working_foundation = list(set(new_ids))
            return len(self.working_foundation)

        # Rule 1: The Exclusion (NOT Gate)
        if gate == "NOT":
            self.working_foundation = self.list_excluding(self.working_foundation, new_ids)

        # Rule 2: The Featuring (AND / Checked=TRUE)
        elif is_narrowing:
            # Operation: Westerns AND John Wayne (Intersection)
            self.working_foundation = self.list_featuring(self.working_foundation, new_ids)
        
        # Rule 3: The Union (Addition / Default)
        else:
            # Operation: Westerns OR Sci-Fi (Addition)
            self.working_foundation = self.list_union(self.working_foundation, new_ids)

        return len(self.working_foundation)

    # --- THE MATH OPERATIONS ---

    def list_featuring(self, foundation, new_panel):
        """The 'AND' Gate: Keeps only items present in BOTH lists (A ∩ B)."""
        # This is the '1960s Westerns' logic
        return list(set(foundation) & set(new_panel))

    def list_union(self, foundation, new_panel):
        """The 'OR' Gate: Combines both lists, no duplicates (A ∪ B)."""
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
        print("🧹 [ENGINE] Logic Reset.")