import requests
import time
import xml.etree.ElementTree as ET
import ctypes

URL = "http://localhost:52199/MCWS/v1"
# The filename from your selection
TARGET_FILE = "For a Fistful of Dollars (1964).m2ts"

def test_jriver_robust():
    print(f"Targeting JRiver: {URL}")
    
    # Use a simpler query: just the filename without the path
    # This avoids the W:/ vs W:\ slash conflict
    search_url = f"{URL}/Files/Search?Query=[Filename]=[{TARGET_FILE}]"
    
    try:
        print(f"Searching for: {TARGET_FILE}...")
        r = requests.get(search_url)
        root = ET.fromstring(r.text)
        
        file_key = None
        # Look for the Key in the results
        for item in root.findall(".//Item"):
            for field in item.findall("Field"):
                if field.get("Name") == "Key":
                    file_key = field.text
                    break
        
        if not file_key:
            print("File not found. Attempting a 'Like' search...")
            # Fallback: Search for the title alone
            fallback_url = f"{URL}/Files/Search?Query=Fistful of Dollars"
            r = requests.get(fallback_url)
            root = ET.fromstring(r.text)
            # Take the first result
            item = root.find(".//Item")
            if item is not None:
                for field in item.findall("Field"):
                    if field.get("Name") == "Key":
                        file_key = field.text
                        break

        if not file_key:
            print("CRITICAL: File not found in JRiver Library. Please check JRiver import.")
            return

        print(f"SUCCESS: Found File Key {file_key}")

        # 1. Trigger Playback
        requests.get(f"{URL}/Playback/PlayById?Key={file_key}")
        print("Playback triggered in JRiver.")

        # 2. The Watchdog (The Transition Bridge)
        time.sleep(3) # Let the engine warm up
        while True:
            status_resp = requests.get(f"{URL}/Playback/Info")
            status_xml = ET.fromstring(status_resp.text)
            
            state = "0"
            for item in status_xml.findall(".//Item"):
                if item.get("Name") == "State":
                    state = item.text
                    break
            
            if state == "0":
                print("\nPlayback Stopped. Returning to Mediaverse...")
                ctypes.windll.user32.MessageBoxW(0, "Handing back to Mediaverse", "Done", 0)
                break
            
            print(f"Movie is playing (State {state})...", end="\r")
            time.sleep(2)

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_jriver_robust()