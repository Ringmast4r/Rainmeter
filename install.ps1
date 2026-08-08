# Installs these skins into the Rainmeter skins folder and wires up the
# background drive scanner that Drive Space and Disc Drive Size read from.
#
#   powershell -ExecutionPolicy Bypass -File install.ps1
#
# Nothing here needs admin rights. Re-running it is safe.

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$src  = Join-Path $here 'skins'

# ---- find the Rainmeter skins folder ----
$skins = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Rainmeter\Skins'
if (-not (Test-Path $skins)) {
    Write-Host "Rainmeter skins folder not found at:" -ForegroundColor Yellow
    Write-Host "  $skins"
    Write-Host "Install Rainmeter first: https://www.rainmeter.net/"
    exit 1
}
Write-Host "Skins folder : $skins"

# ---- copy ----
foreach ($folder in Get-ChildItem $src -Directory) {
    $dest = Join-Path $skins $folder.Name
    Copy-Item $folder.FullName $dest -Recurse -Force
    $n = (Get-ChildItem $folder.FullName -Recurse -File).Count
    Write-Host ("  copied {0,-20} {1,4} files" -f $folder.Name, $n)
}

# ---- scheduled task for the drive scanner ----
$vbs      = Join-Path $skins '@DriveData\run_hidden.vbs'
$taskName = 'Rainmeter DriveData'

try {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
} catch { }

$action  = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument "`"$vbs`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$trigger.Repetition = (New-ScheduledTaskTrigger -Once -At (Get-Date) `
                        -RepetitionInterval (New-TimeSpan -Minutes 1) `
                        -RepetitionDuration (New-TimeSpan -Days 3650)).Repetition
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
              -DontStopIfGoingOnBatteries -StartWhenAvailable `
              -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger `
    -Settings $settings -Description 'Collects drive info for Rainmeter without blocking the UI' | Out-Null
Write-Host "Task         : '$taskName' registered (every 1 minute)"

# ---- generate the data file now so the skins are not blank ----
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $skins '@DriveData\driveinfo.ps1')
Write-Host "Data file    : DriveData.inc generated"

# ---- nudge Rainmeter if it is running ----
$proc = Get-Process -Name Rainmeter -ErrorAction SilentlyContinue | Select-Object -First 1
if ($proc -and $proc.Path) {
    & $proc.Path !RefreshApp
    Write-Host "Rainmeter    : refreshed"
} else {
    Write-Host "Rainmeter    : not running, start it to load the skins"
}

Write-Host ""
Write-Host "Done. Right click the Rainmeter tray icon > Skins to load them." -ForegroundColor Green
