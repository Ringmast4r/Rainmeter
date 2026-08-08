' Launches driveinfo.ps1 with no visible window (prevents console flash every minute).
' Locates the script relative to itself, so this folder can live anywhere.
Dim fso, here
Set fso = CreateObject("Scripting.FileSystemObject")
here = fso.GetParentFolderName(WScript.ScriptFullName)
CreateObject("Wscript.Shell").Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & here & "\driveinfo.ps1""", 0, False
