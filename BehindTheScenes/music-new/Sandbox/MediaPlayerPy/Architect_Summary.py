# Architect_Summary.py (Refined for Full Path Keys)
import logging

class ArchitectSummary:
    def __init__(self):
        self.cumulative_list = []
        self.cumulative_count = 0

    def process_panel_save(self, panel_num, panel_results, is_and=True, is_filter=False):
        """
        Processes logic using Full Pathnames as the unique keys.
        """
        incoming_set = set()
        
        for item in panel_results:
            full_path = ""
            if isinstance(item, dict):
                # Prioritize the absolute server path as the key
                full_path = item.get("path") or item.get("full_path") or item.get("Filename") or ""
            else:
                full_path = str(item)
            
            if full_path:
                incoming_set.add(full_path.strip())

        incoming_set.discard("") 

        print(f"\n--- 🧪 ARCHITECT ENGINE: PROCESSING PANEL {panel_num + 1} ---")
        print(f"Logic: {'ADD' if is_and else 'NOT'} | Filter: {is_filter}")
        print(f"Incoming Unique Items: {len(incoming_set)}")

        if panel_num == 0:
            return self._case_1_foundation(incoming_set)
        else:
            return self._execute_relational_logic(panel_num, incoming_set, is_and, is_filter)

    def _case_1_foundation(self, incoming_set):
        self.cumulative_list = sorted(list(incoming_set))
        self.cumulative_count = len(self.cumulative_list)
        
        print("✅ LOGIC COMPLETE: Case 1 (The Foundation)")
        print(f"   Cumulative Count: {self.cumulative_count}")
        return self.cumulative_count

    def _execute_relational_logic(self, p_num, incoming_set, is_and, is_filter):
        foundation_set = set(self.cumulative_list)
        result_set = set()

        if is_and:
            if is_filter:
                # INTERSECTION
                result_set = foundation_set.intersection(incoming_set)
                print(f"   🎯 ACTION: Surgical Filter (Intersection)")
            else:
                # UNION
                result_set = foundation_set.union(incoming_set)
                print(f"   🎯 ACTION: Merge Lists (Union)")
        else:
            # DIFFERENCE
            result_set = foundation_set.difference(incoming_set)
            print(f"   🎯 ACTION: Exclusion (NOT)")

        self.cumulative_list = sorted(list(result_set))
        self.cumulative_count = len(self.cumulative_list)

        print(f"✅ LOGIC COMPLETE: Case {p_num + 1}")
        print(f"   New Cumulative Count: {self.cumulative_count}")
        
        # Verify the paths are indeed the full server paths
        if self.cumulative_count > 0:
            print(f"   Path Key Sample: {self.cumulative_list[0]}")
        
        print("--------------------------------------")
        return self.cumulative_count