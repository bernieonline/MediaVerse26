Set WinScriptHost = CreateObject("WScript.Shell")
' 0 hides the window, False means don't wait for it to finish
WinScriptHost.Run "pythonw.exe Sandbox/MediaPlayerPy/main.py", 0, False
Set WinScriptHost = Nothing