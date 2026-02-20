import json

class ArchitectSummary:
    def __init__(self):
        self.cumulative_ids = set()
        self.panel_results = {} # Storage for individual panel sets

    def apply_logic(self, panel_index, current_ids, gate="NONE", is_narrowing=False):
        """
        Pure Set Theory Logic:
        - Panel 0: The Foundation (Initial Set)
        - AND + Narrowing (Checked): Intersection (A ∩ B)
        - AND + Expanding (Unchecked): Union (A ∪ B)
        - NOT: Difference (A - B)
        """
        set_b = set(current_ids)
        self.panel_results[panel_index] = set_b

        if panel_index == 0:
            self.cumulative_ids = set_b
        else:
            set_a = self.cumulative_ids
            
            if gate == "AND":
                if is_narrowing:
                    # Keep only items present in BOTH
                    self.cumulative_ids = set_a.intersection(set_b)
                else:
                    # Merge both lists together
                    self.cumulative_ids = set_a.union(set_b)
            
            elif gate == "NOT":
                # Subtract Panel B from the current total
                self.cumulative_ids = set_a.difference(set_b)

        return len(self.cumulative_ids)

    def reset(self):
        self.cumulative_ids = set()
        self.panel_results = {}