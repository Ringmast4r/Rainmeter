' Starts the process collector with no visible window. Collect.ps1 holds a
' mutex, so repeated launches (every skin refresh) are harmless.
Set sh = CreateObject("WScript.Shell")
dir = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & dir & "Collect.ps1""", 0, False
