import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]   # skin root folder
OUT = ROOT / "Processes/Processes.ini"

PW, GAP, PAD, ROWS = 226, 10, 18, 20
W = PAD * 2 + PW * 4 + GAP * 3          # 970
H = 520
RIGHT = W - PAD

PANELS = [  # key, tile caption, column label, colour
    ("cpu",  "CPU",        "CPU %",   "94,206,255"),
    ("ram",  "Memory",     "Memory",  "150,124,255"),
    ("gpu",  "GPU",        "GPU %",   "112,224,160"),
    ("gmem", "GPU Memory", "GPU mem", "255,198,92"),
]

s = f"""[Rainmeter]
Update=1000
AccurateText=1
DynamicWindowSize=0
OnRefreshAction=["#@#Scripts\\Launch.vbs"]
ContextTitle=Open Task Manager
ContextAction=["taskmgr.exe"]

[Metadata]
Name=NWModern Processes
Author=ringmast4r
Information=Top 20 processes by CPU, memory, GPU and GPU memory side by side, measured the way Task Manager does.
Version=2.0
License=Creative Commons BY-NC-SA 4.0

[Variables]
@Include=#@#Palette.inc

; ---------------- styles
[sTitle]
FontFace=#fMain#
FontSize=9
StringStyle=Bold
StringCase=Upper
FontColor=#cText#
AntiAlias=1

[sCap]
FontFace=#fMain#
FontSize=7
StringStyle=Bold
StringCase=Upper
FontColor=#cText3#
AntiAlias=1

[sTileVal]
FontFace=#fLight#
FontSize=17
FontColor=#cText#
AntiAlias=1

[sTileSub]
FontFace=#fMain#
FontSize=7
FontColor=#cText2#
AntiAlias=1
ClipString=1
H=12

[sRank]
FontFace=#fMono#
FontSize=7
StringAlign=Right
FontColor=#cText3#
AntiAlias=1

[sName]
FontFace=#fMain#
FontSize=8
FontColor=#cText#
AntiAlias=1
ClipString=1
W={PW - 22 - 62}
H=14

[sVal]
FontFace=#fMono#
FontSize=8
StringAlign=Right
FontColor=#cText2#
AntiAlias=1

; ---------------- measures
[mScript]
Measure=Script
ScriptFile=#@#Scripts\\Procs.lua

; ---------------- chrome
[MCard]
Meter=Shape
Shape=Rectangle 0.5,0.5,{W-1},{H-1},16 | Fill LinearGradient gCard | StrokeWidth 1 | Stroke Color #cLine#
gCard=90 | #cBgTop# ; 0.0 | #cBg# ; 1.0

[MTopBar]
Meter=Shape
Shape=Rectangle {PAD},0,{W-2*PAD},3,1.5 | Fill LinearGradient gTop | StrokeWidth 0
gTop=0 | #cAccent# ; 0.0 | #cAccent2# ; 1.0

[MDot]
Meter=Shape
Shape=Rectangle {PAD},17,7,7,2 | Fill LinearGradient gDot | StrokeWidth 0
gDot=45 | #cAccent# ; 0.0 | #cAccent2# ; 1.0

[MTitle]
Meter=String
MeterStyle=sTitle
X=32
Y=13
Text=Process Monitor

[MSub]
Meter=String
MeterStyle=sCap
X={RIGHT}
Y=15
StringAlign=Right
Text=Top 20 per resource  -  grouped by process name

[MRule]
Meter=Shape
Shape=Rectangle {PAD},100,{W-2*PAD},1 | Fill Color #cLine# | StrokeWidth 0
Shape2=Rectangle {PAD},{H-30},{W-2*PAD},1 | Fill Color #cLine# | StrokeWidth 0
"""

for c, (key, cap, label, col) in enumerate(PANELS):
    x0 = PAD + c * (PW + GAP)
    P = key.capitalize()
    s += f"""
; ================= {cap} column
[T{P}Bg]
Meter=Shape
Shape=Rectangle {x0},32,{PW},58,10 | Fill Color #cTile# | StrokeWidth 0
Shape2=Rectangle {x0+10},80,{PW-20},3,1.5 | Fill Color 255,255,255,14 | StrokeWidth 0
Shape3=Rectangle {x0},120,{PW},1 | Fill Color 255,255,255,10 | StrokeWidth 0

[T{P}Cap]
Meter=String
MeterStyle=sCap
X={x0+10}
Y=38
FontColor={col}
Text={cap}

[T{P}Val]
Meter=String
MeterStyle=sTileVal
X={x0+8}
Y=45
Text=--

[T{P}Sub]
Meter=String
MeterStyle=sTileSub
X={x0+10}
Y=66
W={PW-20}
Text=

[T{P}Bar]
Meter=Image
X={x0+10}
Y=80
W=1
H=3
SolidColor={col},255

[H{P}Rank]
Meter=String
MeterStyle=sCap
X={x0+16}
Y=106
StringAlign=Right
Text=#

[H{P}Name]
Meter=String
MeterStyle=sCap
X={x0+22}
Y=106
Text=Process

[H{P}Val]
Meter=String
MeterStyle=sCap
X={x0+PW-4}
Y=106
StringAlign=Right
FontColor={col}
Text={label}
"""
    for i in range(1, ROWS + 1):
        y = 124 + (i - 1) * 18
        m = f"{P}{i}"
        if i % 2 == 0:
            s += f"""
[{m}Stripe]
Meter=Image
X={x0}
Y={y}
W={PW}
H=16
SolidColor=255,255,255,5
"""
        s += f"""
[{m}Bar]
Meter=Image
X={x0}
Y={y}
W=1
H=16
SolidColor={col},48
SolidColor2={col},0
GradientAngle=0
Hidden=1

[{m}Rank]
Meter=String
MeterStyle=sRank
X={x0+16}
Y={y+3}
FontColor={col if i <= 3 else '#cText3#'}
Text={i}

[{m}Name]
Meter=String
MeterStyle=sName
X={x0+22}
Y={y+1}
Text=

[{m}Val]
Meter=String
MeterStyle=sVal
X={x0+PW-4}
Y={y+2}
Text=
"""

s += f"""
; ---------------- footer
[MFootL]
Meter=String
MeterStyle=sCap
StringCase=None
StringStyle=Normal
X={PAD}
Y={H-22}
Text=Starting collector...

[MFootR]
Meter=String
MeterStyle=sCap
StringCase=None
StringStyle=Normal
X={RIGHT}
Y={H-22}
StringAlign=Right
Text=CPU = share of all cores  -  Memory = private working set  -  GPU = busiest engine  -  GPU mem = dedicated + shared
"""
OUT.write_text(s, encoding="utf-8")
print(f"Processes.ini written: {W}x{H}, {len(s.splitlines())} lines")
