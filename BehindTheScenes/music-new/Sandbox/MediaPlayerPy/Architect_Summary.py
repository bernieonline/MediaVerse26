import json

class ArchitectSummary:
    def __init__(self):
        self.master_ids = set()
        self.panel_results = {} # Used for session history

    # --- THE MATH PIPES (Kept for your original style) ---
    def pipe_union(self, set_a, set_b):
        return set_a.union(set_b)

    def pipe_intersection(self, set_a, set_b):
        return set_a.intersection(set_b)

    def pipe_difference(self, set_a, set_b):
        return set_a.difference(set_b)

    # --- THE ENGINE ---
    def apply_logic(self, panel_index, incoming_ids, gate, is_narrowing):
        incoming_set = set(incoming_ids)

        # Initializing Panel 0
        if panel_index == 0:
            self.master_ids = incoming_set
            print(f"🎬 [ENGINE] Base layer: {len(self.master_ids)} items.")
            return list(self.master_ids)

        # THE OVERRIDE LOGIC
        # If user unchecks the box, we FORCE a union regardless of the gate.
        if not is_narrowing:
            print(f"➕ [ENGINE] Mode: ADDITIVE (Merge).")
            self.master_ids = self.pipe_union(self.master_ids, incoming_set)
        
        else:
            # Standard Narrowing/Filtering
            if gate == "AND":
                print(f"✂️ [ENGINE] Mode: NARROWING (Filter).")
                self.master_ids = self.pipe_intersection(self.master_ids, incoming_set)
            elif gate == "NOT":
                print(f"🚫 [ENGINE] Mode: EXCLUSION (Subtract).")
                self.master_ids = self.pipe_difference(self.master_ids, incoming_set)
            elif gate == "OR":
                self.master_ids = self.pipe_union(self.master_ids, incoming_set)

        return sorted(list(self.master_ids))

    def reset(self):
        self.master_ids = set()
        self.panel_results = {}
        print("🧹 [ENGINE] Logic Reset.")