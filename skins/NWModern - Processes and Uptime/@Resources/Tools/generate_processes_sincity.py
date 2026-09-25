"""House-style ("Sin City") top-20 process board. Same meter names as the
modern board so both share Procs.lua and the same collector data."""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]   # skin root folder
OUT = ROOT / "ProcessesSinCity/ProcessesSinCity.ini"
OUT.parent.mkdir(parents=True, exist_ok=True)

PW, GAP, PAD, ROWS = 220, 8, 12, 20
W = PAD * 2 + PW * 4 + GAP * 3          # 928
ROW0 = 140                              # first data row
H = ROW0 + ROWS * 18 + 44               # 544
RIGHT = W - PAD

PANELS = [("cpu", "CPU", "CPU %"), ("ram", "Memory", "Memory"),
          ("gpu", "GPU", "GPU %"), ("gmem", "GPU Memory", "GPU Mem")]

s = f"""; NWModern Process Monitor - "Sin City" house style. Shares Procs.lua and the
; collector with the modern board, so the two can run side by side live.
[Rainmeter]
Update=1000
AccurateText=1
DynamicWindowSize=0
OnRefreshAction=["#@#Scripts\\Launch.vbs"]
ContextTitle=Open Task Manager
ContextAction=["taskmgr.exe"]

[Metadata]
Name=NWModern Processes (Sin City)
Author=ringmast4r
Information=Top 20 processes by CPU, memory, GPU and GPU memory side by side, in the Sin City monochrome house style with a dark/light toggle.
Version=1.0
License=Creative Commons BY-NC-SA 4.0

[Variables]
; Theme is toggled by the button in the top-right corner.
Theme=dark
@Include=#@#Themes\\SinCity-#Theme#.inc
fMono=Courier New
Mono=1
BarW={PW}
TileW={PW-22}

; ================= styles
[sCap]
FontFace=#fMono#
FontSize=7
StringStyle=Bold
StringCase=Upper
FontColor=#cMid#
AntiAlias=1

[sTileVal]
FontFace=#fMono#
FontSize=15
StringStyle=Bold
FontColor=#cFg#
AntiAlias=1

[sTileSub]
FontFace=#fMono#
FontSize=7
FontColor=#cMid#
AntiAlias=1
ClipString=1
H=12

[sHead]
FontFace=#fMono#
FontSize=7
StringStyle=Bold
StringCase=Upper
FontColor=#cBg#
AntiAlias=1

[sRank]
FontFace=#fMono#
FontSize=7
StringStyle=Bold
StringAlign=Right
FontColor=#cMid#
AntiAlias=1

[sName]
FontFace=#fMono#
FontSize=8
FontColor=#cFg#
AntiAlias=1
ClipString=1
W={PW - 24 - 62}
H=14

[sVal]
FontFace=#fMono#
FontSize=8
StringStyle=Bold
StringAlign=Right
FontColor=#cFg#
AntiAlias=1

; ================= measures
[mScript]
Measure=Script
ScriptFile=#@#Scripts\\Procs.lua

; ================= card
[MCard]
Meter=Shape
Shape=Rectangle 1.5,1.5,{W-3},{H-3} | Fill Color #cBg# | StrokeWidth 3 | Stroke Color #cFg#
; header underline 3px, footer rule 2px
Shape2=Rectangle {PAD},38,{W-2*PAD},3 | Fill Color #cFg# | StrokeWidth 0
Shape3=Rectangle {PAD},{H-32},{W-2*PAD},2 | Fill Color #cFg# | StrokeWidth 0

[MTitle]
Meter=String
FontFace=#fMono#
FontSize=11
StringStyle=Bold
StringCase=Upper
FontColor=#cFg#
AntiAlias=1
X={PAD}
Y=15
Text=Process Monitor

[MSub]
Meter=String
MeterStyle=sCap
X=200
Y=18
Text=// Top 20 per resource - grouped by process name

[MToggle]
Meter=String
FontFace=#fMono#
FontSize=7
StringStyle=Bold
StringAlign=Right
FontColor=#cFg#
SolidColor=#cTrack#
Padding=6,3,6,3
AntiAlias=1
X={RIGHT-6}
Y=16
Text=#ToggleLabel#
LeftMouseUpAction=[!WriteKeyValue Variables Theme #ToggleTo#][!Refresh]
MouseActionCursorName=Hand
ToolTipText=Switch to #ToggleTo# mode
"""

for c, (key, cap, label) in enumerate(PANELS):
    x0 = PAD + c * (PW + GAP)
    P = key.capitalize()
    s += f"""
; ================= {cap} column
[T{P}Box]
Meter=Shape
Shape=Rectangle {x0+1},51,{PW-2},58 | Fill Color #cBg# | StrokeWidth 2 | Stroke Color #cFg#
Shape2=Rectangle {x0+10.5},96.5,{PW-21},5 | Fill Color #cTrack# | StrokeWidth 1 | Stroke Color #cFg#
; table header = highlight block (ink fill, ground text)
Shape3=Rectangle {x0},118,{PW},18 | Fill Color #cFg# | StrokeWidth 0

[T{P}Cap]
Meter=String
MeterStyle=sCap
X={x0+10}
Y=57
Text={cap}

[T{P}Val]
Meter=String
MeterStyle=sTileVal
X={x0+PW-10}
Y=54
StringAlign=Right
Text=--

[T{P}Sub]
Meter=String
MeterStyle=sTileSub
X={x0+10}
Y=80
W={PW-20}
Text=

[T{P}Bar]
Meter=Image
X={x0+11}
Y=97
W=1
H=4
SolidColor=#cFg#

[H{P}Rank]
Meter=String
MeterStyle=sHead
X={x0+18}
Y=121
StringAlign=Right
Text=#

[H{P}Name]
Meter=String
MeterStyle=sHead
X={x0+24}
Y=121
Text=Process

[H{P}Val]
Meter=String
MeterStyle=sHead
X={x0+PW-6}
Y=121
StringAlign=Right
Text={label}
"""
    for i in range(1, ROWS + 1):
        y = ROW0 + (i - 1) * 18
        m = f"{P}{i}"
        if i % 2 == 0:
            s += f"""
[{m}Stripe]
Meter=Image
X={x0}
Y={y}
W={PW}
H=18
SolidColor=#cAlt#
"""
        s += f"""
[{m}Bar]
Meter=Image
X={x0}
Y={y+15}
W=1
H=3
SolidColor=#cBar#
Hidden=1

[{m}Rank]
Meter=String
MeterStyle=sRank
X={x0+18}
Y={y+4}
{"FontColor=#cFg#" if i <= 3 else ""}
Text={i:02d}

[{m}Name]
Meter=String
MeterStyle=sName
X={x0+24}
Y={y+2}
Text=

[{m}Val]
Meter=String
MeterStyle=sVal
X={x0+PW-6}
Y={y+2}
Text=
"""

s += f"""
; ================= footer
[MFootL]
Meter=String
MeterStyle=sCap
StringCase=None
X={PAD}
Y={H-24}
Text=Starting collector...

[MFootR]
Meter=String
MeterStyle=sCap
X={RIGHT}
Y={H-24}
StringAlign=Right
Text=CPU = share of all cores / Memory = private working set / GPU = busiest engine / GPU mem = dedicated + shared
"""
OUT.write_text(s, encoding="utf-8")
print(f"ProcessesSinCity.ini written: {W}x{H}, {len(s.splitlines())} lines")
