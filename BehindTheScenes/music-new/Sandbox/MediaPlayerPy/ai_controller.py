import threading
import requests
import time
from PySide6.QtCore import QObject, Signal, Slot

class AIController(QObject):
    answerReady = Signal(str)
    loadingStatus = Signal(bool) # True = Spinning, False = Stopped

    def __init__(self, api_key: str, parent=None):
        super().__init__(parent)
        self.api_key = api_key
        # Targetting the stable 2026 Gemini 3 Flash endpoint
        self.url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key={self.api_key}"

    @Slot(str, str)
    def ask(self, movie_title: str, question: str):
        # Start the spinner in QML
        self.loadingStatus.emit(True)
        
        def _execute():
            max_retries = 3
            for attempt in range(max_retries):
                try:
                    payload = {
                        "contents": [{"parts": [{"text": f"Regarding the movie '{movie_title}': {question}. Provide the answer in clean bullet points."}]}]
                    }
                    
                    response = requests.post(self.url, json=payload, timeout=20)
                    
                    # Handle Server Overloaded (503)
                    if response.status_code == 503 and attempt < max_retries - 1:
                        time.sleep(2) # Wait 2 seconds before retry
                        continue
                        
                    data = response.json()
                    if response.status_code == 200:
                        candidates = data.get('candidates', [])
                        if candidates:
                            answer = candidates[0]['content']['parts'][0]['text']
                            self.answerReady.emit(answer)
                        else:
                            self.answerReady.emit("AI returned an empty response.")
                        break # Success, exit loop
                    else:
                        error_msg = data.get('error', {}).get('message', 'Unknown Error')
                        self.answerReady.emit(f"AI Service Error: {error_msg}")
                        break

                except Exception as e:
                    if attempt == max_retries - 1:
                        self.answerReady.emit(f"Connection Error: {str(e)}")
                    time.sleep(1)
            
            # Stop the spinner
            self.loadingStatus.emit(False)

        threading.Thread(target=_execute, daemon=True).start()