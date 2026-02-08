# Architect_Summary.py
import logging

class ArchitectSummary:
    def __init__(self):
        self.cumulative_list = []
        self.cumulative_count = 0

    def process_panel_save(self, panel_num, panel_results, is_and=True, is_not=False):
        """
        Receives results from ArchitectController and applies cumulative logic.
        """
        # --- DEBUG SNIFFER ---
        print(f"\n🔍 [DEBUG] ArchitectSummary Receipt:")
        print(f"   > Panel Index: {panel_num}")
        print(f"   > Raw Results Type: {type(panel_results)}")
        print(f"   > Raw Results Count: {len(panel_results)}")
        if panel_results and len(panel_results) > 0:
            sample = panel_results[0]
            print(f"   > Sample Item Type: {type(sample)}")
            print(f"   > Sample Item Content: {sample}")
        # ---------------------

        # Convert incoming data to a set of unique filenames
        incoming_set = set()
        for item in panel_results:
            if isinstance(item, dict):
                # We extract the 'Filename' key from the library record
                fname = item.get("Filename", "")
                if fname:
                    incoming_set.add(fname)
            else:
                # It's already a string (likely a direct path)
                incoming_set.add(str(item))
        
        incoming_set.discard("") # Remove empties

        print(f"\n--- 🧪 ARCHITECT ENGINE: PROCESSING PANEL {panel_num + 1} ---")
        print(f"Incoming Unique Items: {len(incoming_set)}")

        # panel_num comes from QML (0, 1, 2, 3...)
        if panel_num == 0:
            return self._case_1_foundation(incoming_set)
        elif panel_num == 1:
            return self._case_2_refiner(incoming_set)
        else:
            return self._case_generic_modifier(panel_num, incoming_set, is_and, is_not)

    def _case_1_foundation(self, incoming_set):
        """
        Panel 1 Logic: The Foundation.
        """
        # Step 1: Overwrite global list with Panel 1 results.
        # We sort it so the terminal output is easy to read.
        self.cumulative_list = sorted(list(incoming_set))
        
        # Step 2: Set global count.
        self.cumulative_count = len(self.cumulative_list)
        
        # Step 3: Detailed Print-out for terminal verification
        print("✅ LOGIC COMPLETE: Case 1 (The Foundation)")
        print(f"   Final Cumulative Count: {self.cumulative_count}")
        print("   Final Cumulative List Content:")
        
        for i, path in enumerate(self.cumulative_list):
            print(f"      [{i+1}] {path}")
        
        print("--------------------------------------")
        
        return self.cumulative_count

    def _case_2_refiner(self, incoming_set):
        print("🚧 Case 2: Refiner Logic starting (Panel 2)...")
        # For now, it just returns the current count to keep things stable
        return self.cumulative_count

    def _case_generic_modifier(self, p_num, incoming_set, is_and, is_not):
        return self.cumulative_count