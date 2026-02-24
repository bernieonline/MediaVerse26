import json

class ArchitectSummary:
    def __init__(self):
        # Unified variable name to match your Controller's expectations
        self.working_foundation = []
        self.panel_results = {} # Used for session history

    # --- THE MATH PIPES ---
    def pipe_union(self, set_a, set_b):
        return set_a.union(set_b)

    def pipe_intersection(self, set_a, set_b):
        return set_a.intersection(set_b)

    def pipe_difference(self, set_a, set_b):
        return set_a.difference(set_b)

    # --- THE ENGINE ---
    def apply_logic(self, panel_index, incoming_ids, gate, is_narrowing):
        incoming_set = set(incoming_ids)
        # Convert existing list to set for math
        current_set = set(self.working_foundation)

        # Initializing Panel 0: The Anchor
        if panel_index == 0:
            self.working_foundation = sorted(list(incoming_set))
            print(f"⚓ [ENGINE] Panel 0 Foundation set: {len(self.working_foundation)} items.")
            return len(self.working_foundation)

        # THE OVERRIDE LOGIC
        # If user unchecks the box, we FORCE a union (Addition)
        if not is_narrowing:
            print(f"➕ [ENGINE] Mode: ADDITIVE (Merge).")
            result_set = self.pipe_union(current_set, incoming_set)
        
        else:
            # Standard Narrowing/Filtering
            if gate == "AND":
                print(f"✂️ [ENGINE] Mode: NARROWING (Filter).")
                result_set = self.pipe_intersection(current_set, incoming_set)
            elif gate == "NOT":
                print(f"🚫 [ENGINE] Mode: EXCLUSION (Subtract).")
                result_set = self.pipe_difference(current_set, incoming_set)
            elif gate == "OR":
                result_set = self.pipe_union(current_set, incoming_set)
            else:
                result_set = current_set # Fallback

        # Update the foundation with the result
        self.working_foundation = sorted(list(result_set))
        return len(self.working_foundation)

    def get_current_result(self):
        """Returns the finalized list of filenames to the Controller."""
        # Now this will work because the name matches apply_logic
        return self.working_foundation

    def reset(self):
        self.working_foundation = []
        self.panel_results = {}
        print("🧹 [ENGINE] Logic Reset.")