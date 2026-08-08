# Gathers drive info in the background and writes DriveData.inc for Rainmeter.
# Rainmeter never touches the drives itself, so slow network shares can never freeze it.
#
# Writes two variable sets:
#   1. Letter variables (C_Pct, C_Name, ...) for the fixed-row DISC DRIVE SIZE list skin
#   2. Slot variables (Slot1_*, Slot2_*, ...) for Dark\Drive Space - live drives are
#      packed into slots in alphabetical order so the ring grid remaps itself
#      automatically whenever drive letters change.

$listLetters = @('C','D','E','F','G','H','I','U','V','W','X','Y','Z')   # DISC DRIVE SIZE rows
$scanLetters = [char[]]([char]'C'..[char]'Z')                            # ring skin scans everything
$maxSlots    = 13
$outFile = Join-Path $PSScriptRoot 'DriveData.inc'
$tmpFile = "$outFile.tmp"

function Humanize([double]$bytes) {
    if ($bytes -ge 1TB) { return ('{0:N1} TB' -f ($bytes / 1TB)) }
    if ($bytes -ge 1GB) { return ('{0:N0} GB' -f ($bytes / 1GB)) }
    return ('{0:N0} MB' -f ($bytes / 1MB))
}

# Rainmeter String meters don't word-wrap on their own - they just hard-clip a
# single line. Break long text into #CRLF#-joined lines ourselves so nothing
# gets cut off.
function WrapText([string]$text, [int]$maxLen) {
    $words = $text -split ' '
    $lines = @()
    $cur = ''
    foreach ($w in $words) {
        $candidate = if ($cur -eq '') { $w } else { "$cur $w" }
        if ($candidate.Length -le $maxLen) {
            $cur = $candidate
        } else {
            if ($cur -ne '') { $lines += $cur }
            $cur = $w
        }
    }
    if ($cur -ne '') { $lines += $cur }
    return ($lines -join '#CRLF#')
}

# ---- scan all letters once ----
$info = @{}
foreach ($L in $scanLetters) {
    $L = [string]$L
    $on = 0; $label = ''; $pct = 0; $total = 0; $free = 0
    try {
        $d = New-Object System.IO.DriveInfo ("${L}:")
        if ($d.IsReady) {
            $total = $d.TotalSize
            $free  = $d.AvailableFreeSpace
            if ($total -gt 0) {
                $on = 1
                $label = $d.VolumeLabel
                $pct = [math]::Round(($total - $free) / $total * 100)
            }
        }
    } catch { }
    $info[$L] = @{ On=$on; Label=$label; Pct=$pct; Total=$total; Free=$free }
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('[Variables]')
$lines.Add("Generated=$(Get-Date -Format 'HH:mm:ss')")

# ---- 1. letter variables (DISC DRIVE SIZE) ----
foreach ($L in $listLetters) {
    $d = $info[$L]
    if ($d.On -eq 1) {
        $name    = if ($d.Label) { "${L}: $($d.Label)" } else { "${L}:" }
        $size    = "$(Humanize $d.Free) free / $(Humanize $d.Total)"
        $bar     = if ($d.Pct -ge 90) { '235,70,70,255' } elseif ($d.Pct -ge 75) { '240,170,60,255' } else { '60,205,120,255' }
        $hidden  = 0
    } else {
        $name = "${L}:"; $size = ''; $bar = '45,48,58,255'; $hidden = 1
    }
    $lines.Add("${L}_Pct=$($d.Pct)")
    $lines.Add("${L}_Name=$name")
    $lines.Add("${L}_Size=$size")
    $lines.Add("${L}_Bar=$bar")
    $lines.Add("${L}_Hidden=$hidden")
}

# ---- 2. slot variables (Dark\Drive Space) ----
$live = @()
foreach ($L in $scanLetters) {
    $L = [string]$L
    if ($info[$L].On -eq 1) { $live += $L }
}
if ($live.Count -gt $maxSlots) { $live = $live[0..($maxSlots-1)] }

for ($s = 1; $s -le $maxSlots; $s++) {
    $idx = $s - 1
    $col = $idx % 4
    $row = [math]::Floor($idx / 4)
    $x = 20 + 145 * $col
    $y = 55 + 220 * $row

    if ($idx -lt $live.Count) {
        $L = $live[$idx]
        $d = $info[$L]
        $name = if ($d.Label) { WrapText "${L}: $($d.Label)" 14 } else { "${L}:" }
        $ring = if ($d.Pct -ge 85) { '255,50,50,255' } else { '0,150,136,255' }
        $lines.Add("Slot${s}_Drive=$L")
        $lines.Add("Slot${s}_Pct=$($d.Pct)")
        $lines.Add("Slot${s}_PctText=$($d.Pct)%")
        $lines.Add("Slot${s}_Name=$name")
        $lines.Add("Slot${s}_Size=$(WrapText "$(Humanize $d.Free) free / $(Humanize $d.Total)" 16)")
        $lines.Add("Slot${s}_Ring=$ring")
        $lines.Add("Slot${s}_Hidden=0")
    } else {
        $lines.Add("Slot${s}_Drive=C")
        $lines.Add("Slot${s}_Pct=0")
        $lines.Add("Slot${s}_PctText=")
        $lines.Add("Slot${s}_Name=")
        $lines.Add("Slot${s}_Size=")
        $lines.Add("Slot${s}_Ring=0,0,0,0")
        $lines.Add("Slot${s}_Hidden=1")
    }
    $lines.Add("Slot${s}_X=$x")
    $lines.Add("Slot${s}_Y=$y")
}

# ---- layout: system row sits under the last used drive row ----
$rowsUsed = [math]::Max(1, [math]::Ceiling($live.Count / 4.0))
$sysY = 55 + 220 * $rowsUsed
$bgH  = $sysY + 175
$lines.Add("SysY=$sysY")
$lines.Add("BgH=$bgH")
$lines.Add("LiveCount=$($live.Count)")

[System.IO.File]::WriteAllText($tmpFile, ($lines -join "`r`n") + "`r`n", (New-Object System.Text.UTF8Encoding($false)))
Move-Item -Path $tmpFile -Destination $outFile -Force

# Tell Rainmeter to re-read the data (no-op if Rainmeter is not running).
# The running process gives us the exe path, so no install location is hardcoded.
$proc = Get-Process -Name Rainmeter -ErrorAction SilentlyContinue | Select-Object -First 1
if ($proc -and $proc.Path) {
    & $proc.Path !Refresh "Dark\Drive Space"
    & $proc.Path !Refresh "DISC DRIVE SIZE"
}
