# Architect_Summary.py

class ArchitectSummary:
    def __init__(self):
        self.cumulative_list = []
        self.cumulative_count = 0

    def process_panel_save(self, index, new_matches, join_type="ADD", is_filtered=False):
        # 1. Helper to extract just the filename for comparison
        def get_compare_key(item):
            full_path = item.get("Filename") if isinstance(item, dict) else str(item)
            if not full_path: return ""
            return full_path.split("\\")[-1].split("/")[-1].strip().lower()

        # --- CASE 1: THE FOUNDATION (Panel 0) ---
        if index == 0:
            self.cumulative_list = new_matches
            self.cumulative_count = len(new_matches)
            print(f"✅ FOUNDATION SET: {self.cumulative_count} items.")
            return self.cumulative_count
        
        # --- CASE 2+: RELATIONAL LOGIC ---
        foundation_map = {get_compare_key(m): m for m in self.cumulative_list}
        incoming_map = {get_compare_key(m): m for m in new_matches}
        
        f_keys = set(foundation_map.keys())
        i_keys = set(incoming_map.keys())

        # ==========================================================
        # 🛠️ VISUAL PROOF DEBUG SECTION
        # ==========================================================
        overlap = f_keys.intersection(i_keys)
        print(f"\n--- 🧪 ARCHITECT DEBUG (Panel {index}) ---")
        print(f"| Foundation: {len(f_keys)} items")
        print(f"| Incoming:   {len(i_keys)} items")
        print(f"| Overlap:    {len(overlap)} shared items")
        if len(overlap) > 0:
            sample = list(overlap)[:3]
            print(f"| Sample Shared: {sample}")
        print(f"| Requested Action: {join_type} (Filtered: {is_filtered})")
        print("------------------------------------------\n")
        # ==========================================================

        # Decide which keys to keep 
        # FIX: We now allow "AND" or "ADD" to trigger the Filter logic
        if join_type in ["ADD", "AND"]:
            if is_filtered:
                print("🎯 ACTION: Surgical Filter (AND)")
                result_keys = f_keys.intersection(i_keys)
                # For INTERSECTION, we strictly use the foundation's objects
                lookup = foundation_map 
            else:
                print("🎯 ACTION: Merge Union (OR)")
                result_keys = f_keys.union(i_keys)
                # For UNION, we need objects from both maps
                lookup = {**foundation_map, **incoming_map}
        
        elif join_type == "NOT":
            print("🎯 ACTION: Scalpel Exclusion (NOT)")
            result_keys = f_keys.difference(i_keys)
            lookup = foundation_map
        
        else:
            print(f"⚠️ WARNING: Unknown join_type '{join_type}'. Defaulting to ADD.")
            result_keys = f_keys.union(i_keys)
            lookup = {**foundation_map, **incoming_map}

        # 3. Rebuild the objects using the specific lookup defined above
        self.cumulative_list = [lookup[k] for k in sorted(list(result_keys)) if k in lookup]
        self.cumulative_count = len(self.cumulative_list)

        print(f"📊 FINAL COUNT: {self.cumulative_count}")
        return self.cumulative_count
    
    def reset_architect(self):
        """Clears the memory for a fresh start."""
        self.cumulative_list = []
        self.cumulative_count = 0
        print("🧹 ARCHITECT: Memory cleared. Ready for new Foundation.")