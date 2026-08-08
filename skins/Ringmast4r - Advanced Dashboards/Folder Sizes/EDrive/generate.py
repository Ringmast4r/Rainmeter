import os
import re

base = 'E:/'
folders = []
for d in os.listdir(base):
    full = os.path.join(base, d)
    if os.path.isdir(full) and d not in ['$RECYCLE.BIN', 'System Volume Information']:
        total = 0
        for root, dirs, files in os.walk(full):
            for f in files:
                try:
                    total += os.path.getsize(os.path.join(root, f))
                except:
                    pass
        folders.append((d, total))
        print(f'  Scanned: {d} = {total/1024/1024:.1f} MB')

folders.sort(key=lambda x: x[1], reverse=True)
print(f'\nSorted {len(folders)} folders by size:')
for name, size in folders:
    print(f'  {size/1024/1024:>10.1f} MB  {name}')

folder_names = [f[0] for f in folders]

colors = [
    '66,133,244,255',   # Google Blue
    '234,67,53,255',    # Google Red
    '251,188,5,255',    # Google Yellow
    '52,168,83,255',    # Google Green
    '255,112,67,255',   # Deep Orange
    '0,188,212,255',    # Cyan
    '171,71,188,255',   # Purple
    '255,167,38,255',   # Orange
    '38,166,154,255',   # Teal
    '239,83,80,255',    # Red 400
    '66,165,245,255',   # Blue 400
    '156,204,101,255',  # Light Green
    '255,138,101,255',  # Deep Orange 300
    '126,87,194,255',   # Deep Purple
    '41,182,246,255',   # Light Blue
    '255,213,79,255',   # Amber 300
    '77,208,225,255',   # Cyan 300
    '229,115,115,255',  # Red 300
    '121,134,203,255',  # Indigo 300
    '129,199,132,255',  # Green 300
]

def sanitize_key(name):
    return re.sub(r'[^A-Za-z0-9]', '', name)

n = len(folder_names)
cols = 3
rows_per_col = (n + cols - 1) // cols
col_w = 310
slot_h = 52
header_h = 92
panel_w = col_w * cols + 10
col_height = header_h + rows_per_col * slot_h
total_section_h = 100
bg_h = col_height + total_section_h

# === Generate EDrive.ini ===
lines = []
lines.append('[Rainmeter]')
lines.append('Update=1000')
lines.append('AccurateText=1')
lines.append('DynamicWindowSize=1')
lines.append('AntiAlias=1')
lines.append('DpiScaling=0')
lines.append('Draggable=1')
lines.append('')
lines.append('[Metadata]')
lines.append('Name=E Drive Folder Monitor')
lines.append('Author=Claude')
lines.append('Version=6.0')
lines.append('Description=E: drive folder sizes — 3 column, Lua sorted on refresh')
lines.append('')
lines.append('[Variables]')
lines.append('FontFace=Segoe UI')
lines.append('FontColor=240,240,240,255')
lines.append('LabelColor=180,180,180,240')
lines.append('DimColor=120,120,120,180')
lines.append('BackgroundColor=15,15,15,200')
lines.append('BorderColor=50,50,50,200')
lines.append('AccentColor=66,133,244,255')
lines.append(f'PanelW={panel_w}')
lines.append('')

# Lua sort script
lines.append('[MeasureSort]')
lines.append('Measure=Script')
lines.append('ScriptFile=#CURRENTPATH#Sort.lua')
lines.append('')

# Background
lines.append('[MeterBackground]')
lines.append('Meter=Shape')
lines.append(f'Shape=Rectangle 0,0,#PanelW#,{bg_h},10 | Fill Color #BackgroundColor# | Stroke Color #BorderColor# | StrokeWidth 1')
lines.append('')

# Header
lines.append('[MeterHeader]')
lines.append('Meter=String')
lines.append('X=(#PanelW#/2)')
lines.append('Y=12')
lines.append('StringAlign=Center')
lines.append('FontFace=#FontFace#')
lines.append('FontSize=12')
lines.append('FontWeight=700')
lines.append('FontColor=#AccentColor#')
lines.append('Text=E: Drive')
lines.append('')
lines.append('[MeterSubHeader]')
lines.append('Meter=String')
lines.append('X=(#PanelW#/2)')
lines.append('Y=30')
lines.append('StringAlign=Center')
lines.append('FontFace=#FontFace#')
lines.append('FontSize=8')
lines.append('FontColor=#DimColor#')
lines.append('Text=sorted by size // click refresh to update')
lines.append('')
lines.append('[MeterDivider0]')
lines.append('Meter=Shape')
lines.append(f'Shape=Rectangle 15,48,{panel_w-30},1,0 | Fill Color #BorderColor# | StrokeWidth 0')
lines.append('')

# Drive space
lines.append('[MeasureUsedSpace]')
lines.append('Measure=FreeDiskSpace')
lines.append('Drive=E:')
lines.append('InvertMeasure=1')
lines.append('')
lines.append('[MeasureTotalSpace]')
lines.append('Measure=FreeDiskSpace')
lines.append('Drive=E:')
lines.append('Total=1')
lines.append('')
lines.append('[MeasureFreeSpace]')
lines.append('Measure=FreeDiskSpace')
lines.append('Drive=E:')
lines.append('')
lines.append('[MeterDriveUsed]')
lines.append('Meter=String')
lines.append('MeasureName=MeasureUsedSpace')
lines.append('MeasureName2=MeasureTotalSpace')
lines.append('X=15')
lines.append('Y=55')
lines.append('FontFace=#FontFace#')
lines.append('FontSize=9')
lines.append('FontColor=#LabelColor#')
lines.append('AutoScale=1')
lines.append('Text=Used: %1B / %2B')
lines.append('')
lines.append('[MeterDriveFree]')
lines.append('Meter=String')
lines.append('MeasureName=MeasureFreeSpace')
lines.append('X=(#PanelW#-15)')
lines.append('Y=0r')
lines.append('StringAlign=Right')
lines.append('FontFace=#FontFace#')
lines.append('FontSize=9')
lines.append('FontColor=#LabelColor#')
lines.append('AutoScale=1')
lines.append('Text=Free: %1B')
lines.append('')
lines.append('[MeterDriveBarBg]')
lines.append('Meter=Shape')
lines.append(f'Shape=Rectangle 15,75,{panel_w-30},8,3 | Fill Color 40,40,40,200 | StrokeWidth 0')
lines.append('')
lines.append('[MeterDriveBar]')
lines.append('Meter=Bar')
lines.append('MeasureName=MeasureUsedSpace')
lines.append('X=15')
lines.append('Y=75')
lines.append(f'W={panel_w-30}')
lines.append('H=8')
lines.append('BarColor=#AccentColor#')
lines.append('SolidColor=0,0,0,0')
lines.append('BarOrientation=Horizontal')
lines.append('')
lines.append('[MeterDividerDrive]')
lines.append('Meter=Shape')
lines.append(f'Shape=Rectangle 15,{header_h},{panel_w-30},1,0 | Fill Color #BorderColor# | StrokeWidth 0')
lines.append('')

# FolderInfo measures for each folder
size_formula = []
files_formula = []
folders_formula = []

for i, fname in enumerate(folder_names):
    key = sanitize_key(fname)
    lines.append(f'[Measure{key}Size]')
    lines.append('Measure=Plugin')
    lines.append('Plugin=FolderInfo')
    lines.append(f'Folder=E:\\{fname}')
    lines.append('InfoType=FolderSize')
    lines.append('IncludeSubFolders=1')
    lines.append('RegExpFilter=.*')
    lines.append('UpdateDivider=-1')
    lines.append('')
    lines.append(f'[Measure{key}Files]')
    lines.append('Measure=Plugin')
    lines.append('Plugin=FolderInfo')
    lines.append(f'Folder=E:\\{fname}')
    lines.append('InfoType=FileCount')
    lines.append('IncludeSubFolders=1')
    lines.append('RegExpFilter=.*')
    lines.append('UpdateDivider=-1')
    lines.append('')
    lines.append(f'[Measure{key}Folders]')
    lines.append('Measure=Plugin')
    lines.append('Plugin=FolderInfo')
    lines.append(f'Folder=E:\\{fname}')
    lines.append('InfoType=FolderCount')
    lines.append('IncludeSubFolders=1')
    lines.append('RegExpFilter=.*')
    lines.append('UpdateDivider=-1')
    lines.append('')
    size_formula.append(f'Measure{key}Size')
    files_formula.append(f'Measure{key}Files')
    folders_formula.append(f'Measure{key}Folders')

# Slot meters in 3-column layout
for i in range(n):
    slot = i + 1
    col = i // rows_per_col
    row = i % rows_per_col
    x_base = 15 + col * col_w
    x_right = x_base + col_w - 20
    y_name = header_h + 8 + row * slot_h
    y_detail = y_name + 18

    lines.append(f'[MeterSlot{slot}Name]')
    lines.append('Meter=String')
    lines.append(f'X={x_base}')
    lines.append(f'Y={y_name}')
    lines.append('FontFace=#FontFace#')
    lines.append('FontSize=11')
    lines.append('FontWeight=600')
    lines.append('FontColor=#AccentColor#')
    lines.append('Text=---')
    lines.append('DynamicVariables=1')
    lines.append('')
    lines.append(f'[MeterSlot{slot}Size]')
    lines.append('Meter=String')
    lines.append(f'MeasureName=Measure{sanitize_key(folder_names[0])}Size')
    lines.append(f'X={x_right}')
    lines.append('Y=0r')
    lines.append('StringAlign=Right')
    lines.append('FontFace=#FontFace#')
    lines.append('FontSize=11')
    lines.append('FontWeight=700')
    lines.append('FontColor=#FontColor#')
    lines.append('AutoScale=1')
    lines.append('Text=%1B')
    lines.append('DynamicVariables=1')
    lines.append('')
    lines.append(f'[MeterSlot{slot}Detail]')
    lines.append('Meter=String')
    lines.append(f'MeasureName=Measure{sanitize_key(folder_names[0])}Files')
    lines.append(f'MeasureName2=Measure{sanitize_key(folder_names[0])}Folders')
    lines.append(f'X={x_base}')
    lines.append(f'Y={y_detail}')
    lines.append('FontFace=#FontFace#')
    lines.append('FontSize=9')
    lines.append('FontColor=#LabelColor#')
    lines.append('Text=Files: %1  |  Folders: %2')
    lines.append('DynamicVariables=1')
    lines.append('')

# Totals
ty = col_height + 8
lines.append('[MeterDividerTotal]')
lines.append('Meter=Shape')
lines.append(f'Shape=Rectangle 15,{col_height},{panel_w-30},1,0 | Fill Color #BorderColor# | StrokeWidth 0')
lines.append('')
lines.append('[MeasureTotalSize]')
lines.append('Measure=Calc')
lines.append(f'Formula={"+".join(size_formula)}')
lines.append('')
lines.append('[MeasureTotalFiles]')
lines.append('Measure=Calc')
lines.append(f'Formula={"+".join(files_formula)}')
lines.append('')
lines.append('[MeasureTotalFolders]')
lines.append('Measure=Calc')
lines.append(f'Formula={"+".join(folders_formula)}')
lines.append('')
lines.append('[MeterTotalLabel]')
lines.append('Meter=String')
lines.append('X=15')
lines.append(f'Y={ty}')
lines.append('FontFace=#FontFace#')
lines.append('FontSize=10')
lines.append('FontWeight=700')
lines.append('FontColor=#AccentColor#')
lines.append('Text=COMBINED TOTAL')
lines.append('')
lines.append('[MeterTotalSize]')
lines.append('Meter=String')
lines.append('MeasureName=MeasureTotalSize')
lines.append('X=(#PanelW#-15)')
lines.append('Y=0r')
lines.append('StringAlign=Right')
lines.append('FontFace=#FontFace#')
lines.append('FontSize=10')
lines.append('FontWeight=700')
lines.append('FontColor=#AccentColor#')
lines.append('AutoScale=1')
lines.append('Text=%1B')
lines.append('')
lines.append('[MeterTotalDetail]')
lines.append('Meter=String')
lines.append('MeasureName=MeasureTotalFiles')
lines.append('MeasureName2=MeasureTotalFolders')
lines.append('X=15')
lines.append(f'Y={ty+22}')
lines.append('FontFace=#FontFace#')
lines.append('FontSize=9')
lines.append('FontColor=#LabelColor#')
lines.append('Text=Total Files: %1  |  Total Folders: %2')
lines.append('')
gy = ty + 44
lines.append('[MeterGuide]')
lines.append('Meter=String')
lines.append('X=(#PanelW#/2)')
lines.append(f'Y={gy}')
lines.append('StringAlign=Center')
lines.append('FontFace=#FontFace#')
lines.append('FontSize=8')
lines.append('FontColor=#DimColor#')
lines.append('Text=B > kB > MB > GB > TB > PB > EB')
lines.append('')
lines.append('[MeterRefreshBtn]')
lines.append('Meter=String')
lines.append('X=(#PanelW#/2)')
lines.append(f'Y={gy+18}')
lines.append('StringAlign=Center')
lines.append('FontFace=#FontFace#')
lines.append('FontSize=9')
lines.append('FontWeight=700')
lines.append('FontColor=#AccentColor#')
lines.append('Text=[ REFRESH ]')
lines.append('MouseOverAction=[!SetOption MeterRefreshBtn FontColor "255,255,255,255"][!UpdateMeter MeterRefreshBtn][!Redraw]')
lines.append('MouseLeaveAction=[!SetOption MeterRefreshBtn FontColor "#AccentColor#"][!UpdateMeter MeterRefreshBtn][!Redraw]')
lines.append('LeftMouseUpAction=[!Refresh]')

outpath = os.path.join(os.path.dirname(__file__), 'EDrive.ini')
with open(outpath, 'w') as f:
    f.write('\n'.join(lines))

# === Generate Sort.lua ===
lua_lines = []
lua_lines.append('function Initialize()')
lua_lines.append('    folders = {')
for i, fname in enumerate(folder_names):
    key = sanitize_key(fname)
    color = colors[i % len(colors)]
    path_escaped = f'E:\\\\{fname}'
    lua_lines.append(f"        {{ key = '{key}', color = '{color}', path = '{path_escaped}', name = '{fname}' }},")
lua_lines.append('    }')
lua_lines.append('    ticks = 0')
lua_lines.append('end')
lua_lines.append('')
lua_lines.append('function Update()')
lua_lines.append('    ticks = ticks + 1')
lua_lines.append('')
lua_lines.append('    for _, f in ipairs(folders) do')
lua_lines.append("        f.size    = SKIN:GetMeasure('Measure' .. f.key .. 'Size'):GetValue()")
lua_lines.append("        f.files   = SKIN:GetMeasure('Measure' .. f.key .. 'Files'):GetValue()")
lua_lines.append("        f.folders = SKIN:GetMeasure('Measure' .. f.key .. 'Folders'):GetValue()")
lua_lines.append('    end')
lua_lines.append('')
lua_lines.append('    local sorted = {}')
lua_lines.append('    for i, f in ipairs(folders) do')
lua_lines.append('        sorted[i] = f')
lua_lines.append('    end')
lua_lines.append('    table.sort(sorted, function(a, b) return a.size > b.size end)')
lua_lines.append('')
lua_lines.append('    for i, f in ipairs(sorted) do')
lua_lines.append("        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Name',   'Text',              f.name)")
lua_lines.append("        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Name',   'FontColor',         f.color)")
lua_lines.append("        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Name',   'LeftMouseUpAction', '[\"' .. f.path .. '\"]')")
lua_lines.append("        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Size',   'MeasureName',       'Measure' .. f.key .. 'Size')")
lua_lines.append("        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Detail', 'MeasureName',       'Measure' .. f.key .. 'Files')")
lua_lines.append("        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Detail', 'MeasureName2',      'Measure' .. f.key .. 'Folders')")
lua_lines.append('    end')
lua_lines.append('')
lua_lines.append('    -- After 5 ticks (5 seconds), data should be ready. Pause the skin.')
lua_lines.append('    if ticks >= 5 then')
lua_lines.append("        SKIN:Bang('!SetOption', 'Rainmeter', 'Update', '-1')")
lua_lines.append('    end')
lua_lines.append('end')

lua_path = os.path.join(os.path.dirname(__file__), 'Sort.lua')
with open(lua_path, 'w') as f:
    f.write('\n'.join(lua_lines))

print(f'\nGenerated: {n} folders, {cols} cols, {rows_per_col} rows/col, {panel_w}x{bg_h}px')
print(f'Sort.lua: {n} folder entries')
