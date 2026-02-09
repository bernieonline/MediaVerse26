from PySide6.QtCore import QObject, Slot, Signal

class ArchitectController(QObject):
    # Signal to tell the HUD to update its display count
    countChanged = Signal(int)

    def __init__(self):
        super().__init__()
        # THE VAULT: 4 slots for 4 panels. Persistent and Stable.
        self._vault = {
            0: {"movies": set(), "mode": "selection", "filter": False},
            1: {"movies": set(), "mode": "selection", "filter": False},
            2: {"movies": set(), "mode": "selection", "filter": False},
            3: {"movies": set(), "mode": "selection", "filter": False}
        }
        self.foundation_list = [] # The final "Calculated Truth"

    @Slot(int, str, list, bool)
    def commit_to_vault(self, index, mode, movie_list, is_filter):
        """Secures data from a specific panel into its vault slot."""
        # We use a set() for high-speed math (Intersections/Unions)
        movie_set = set(movie_list)
        
        self._vault[index] = {
            "movies": movie_set,
            "mode": mode,
            "filter": is_filter
        }
        
        print(f"🔒 [VAULT] Slot {index} Locked. Items: {len(movie_set)} | Mode: {mode} | Filter: {is_filter}")
        
        # Every time a panel is committed, we re-run the chain of logic
        self.recalculate_foundation()

    def recalculate_foundation(self):
        """The Engine: Processes all 4 slots to build the final collection."""
        temp_result = set()
        first_active_found = False

        for i in range(4):
            slot = self._vault[i]
            current_movies = slot["movies"]
            
            # Skip empty slots that haven't been 'Selection'ed yet
            if not current_movies and slot["mode"] == "selection":
                continue

            if not first_active_found:
                # The first panel with data becomes the Foundation
                temp_result = current_movies
                first_active_found = True
                print(f"🏗️ Foundation established by Panel {i} with {len(temp_result)} items.")
            else:
                # Subsequent panels apply logic
                if slot["filter"]:
                    # SURGICAL FILTER (AND): Only keep what's in both
                    temp_result = temp_result.intersection(current_movies)
                    print(f"✂️ Panel {i} filtered results down to {len(temp_result)} items.")
                else:
                    # MERGE UNION (OR): Add new items to the pile
                    temp_result = temp_result.union(current_movies)
                    print(f"➕ Panel {i} added items. Total now: {len(temp_result)}")

        self.foundation_list = list(temp_result)
        self.countChanged.emit(len(self.foundation_list))
        print(f"✅ FINAL COLLECTION READY: {len(self.foundation_list)} items.")

    @Slot()
    def save_and_purge(self):
        """Longevity ends here. Transfers data to DB and clears memory."""
        # 1. Logic to save self.foundation_list to your JSON/Database
        print("💾 Saving final collection to system...")
        
        # 2. Reset the Vault
        self.__init__()
        print("🧹 Vault purged. Ready for next build.")

    def recalculate_foundation(self):
        """The Engine: Processes all 4 slots using the Gate Logic."""
        temp_result = set()
        first_active_found = False

        # We iterate through the vault slots we've established
        for i in range(4):
            slot = self._vault[i]
            current_movies = slot["movies"]
            
            # Skip empty/uninitialized panels
            if not current_movies and slot["mode"] == "selection":
                continue

            if not first_active_found:
                # Establishing the baseline
                temp_result = current_movies
                first_active_found = True
                print(f"🏗️ Slot {i} set as Foundation.")
            else:
                # Apply Gate Logic from the PREVIOUS panel's choice
                # (Panel 0's gate determines how Panel 1 joins the pile)
                # Note: You can pass the gate value along with the commit_to_vault
                gate = slot.get("gate", "AND") 

                if gate == "NOT":
                    temp_result = temp_result.difference(current_movies)
                    print(f"➖ Slot {i} subtracted. Remaining: {len(temp_result)}")
                else:
                    # Default to ADD/UNION logic
                    temp_result = temp_result.union(current_movies)
                    print(f"➕ Slot {i} added. Total: {len(temp_result)}")

        self.foundation_list = list(temp_result)
        self.countChanged.emit(len(self.foundation_list))