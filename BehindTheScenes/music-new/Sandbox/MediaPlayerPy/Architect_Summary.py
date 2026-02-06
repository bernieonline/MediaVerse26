# Architect_Summary.py
import logging

class ArchitectSummary:
    def __init__(self):
        self.cumulative_list = []
        self.cumulative_count = 0

    def process_panel_save(self, panel_num, panel_results, is_and=True, is_not=False):
        incoming_set = set(panel_results)
        
        print(f"\n--- 🧪 ARCHITECT TEST: PANEL {panel_num} ---")
        print(f"Incoming Panel Items: {len(incoming_set)}")

        if panel_num == 1:
            return self._case_1_foundation(incoming_set)
        elif panel_num == 2:
            return self._case_2_refiner(incoming_set)
        elif panel_num == 3 or panel_num == 4:
            return self._case_generic_modifier(panel_num, incoming_set, is_and, is_not)
        else:
            return self.cumulative_count

    def _case_1_foundation(self, incoming_set):
        """
        Panel 1 Logic: 
        1. Overwrite global list with Panel 1 results.
        2. Set global count.
        3. Print full list for verification.
        """
        # Step 1: Add the panel generated movie list to the cumulative list
        self.cumulative_list = list(incoming_set)
        
        # Step 2: Count the records
        self.cumulative_count = len(self.cumulative_list)
        
        # Step 3: Detailed Print-out for command of the process
        print("✅ LOGIC COMPLETE: Case 1 (The Foundation)")
        print(f"   Final Cumulative Count: {self.cumulative_count}")
        print("   Final Cumulative List Content:")
        
        # If the list is long, we print the first 10 so we don't flood the terminal, 
        # but feel free to change this to print all of them.
        for i, path in enumerate(self.cumulative_list):
            print(f"      [{i+1}] {path}")
        
        print("--------------------------------------")
        
        # Step 4: Pass count back to QML
        return self.cumulative_count

    # Placeholder methods for next steps...
    def _case_2_refiner(self, incoming_set):
        return self.cumulative_count
    def _case_generic_modifier(self, p_num, incoming_set, is_and, is_not):
        return self.cumulative_count