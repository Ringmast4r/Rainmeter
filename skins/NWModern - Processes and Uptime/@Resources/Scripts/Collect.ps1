# NWModern process collector.
# Measures per-process CPU / RAM / GPU / GPU memory the way Task Manager does and
# writes ..\Data\procs.txt every cycle. Exits on its own once the skin stops
# writing ..\Data\beat.txt, so it never outlives Rainmeter.
#   CPU %    = delta(process CPU time) / delta(wall time) / logical cores
#   Memory   = private working set          (Task Manager "Memory")
#   GPU %    = busiest GPU engine per process (Task Manager "GPU")
#   GPU mem  = dedicated + shared committed  (Task Manager "GPU memory")
param(
    [int]$IntervalMs  = 2000,
    [int]$MaxRows     = 120,
    [int]$BeatTimeout = 20,
    [int]$StartGrace  = 60
)

$mutex = New-Object System.Threading.Mutex($false, 'Local\NWModernProcCollector')
if (-not $mutex.WaitOne(0)) { exit 0 }

$dataDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'Data'
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
$outFile  = Join-Path $dataDir 'procs.txt'
$tmpFile  = Join-Path $dataDir 'procs.tmp'
$beatFile = Join-Path $dataDir 'beat.txt'

$inv   = [Globalization.CultureInfo]::InvariantCulture
$cores = [Environment]::ProcessorCount
$start = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
function F([double]$v, [int]$d = 1) { $v.ToString("F$d", $inv) }

# Static GPU info
$gpuName = 'GPU'; $vramTotalMB = 0
try {
    $smi = & nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits 2>$null
    if ($LASTEXITCODE -eq 0 -and $smi) {
        $p = (@($smi)[0]) -split ',\s*'
        $gpuName = $p[0].Trim(); $vramTotalMB = [double]$p[1]
    }
} catch {}
if ($vramTotalMB -le 0) {
    $vc = Get-CimInstance Win32_VideoController | Sort-Object AdapterRAM -Descending | Select-Object -First 1
    if ($vc) { $gpuName = $vc.Name; $vramTotalMB = [math]::Round($vc.AdapterRAM / 1MB) }
}
$gpuName = $gpuName -replace '^NVIDIA\s+', '' -replace '^GeForce\s+', ''

function Get-ProcSnap {
    $h = @{}
    foreach ($p in Get-CimInstance Win32_PerfRawData_PerfProc_Process) {
        if ($p.IDProcess -eq 0 -or $p.Name -eq '_Total') { continue }
        $h[[int]$p.IDProcess] = $p
    }
    $h
}
function Get-GpuSnap {
    $h = @{}
    try { foreach ($e in Get-CimInstance Win32_PerfRawData_GPUPerformanceCounters_GPUEngine -ErrorAction Stop) { $h[$e.Name] = $e } } catch {}
    $h
}

while ($true) {
    # Heartbeat: stop when the skin is gone.
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $beat = 0
    try { $beat = [long](Get-Content $beatFile -Raw -ErrorAction Stop).Trim() } catch {}
    if ((($now - $start) -gt $StartGrace) -and (($now - $beat) -gt $BeatTimeout)) { break }

    $p1 = Get-ProcSnap; $g1 = Get-GpuSnap
    Start-Sleep -Milliseconds 1000
    $p2 = Get-ProcSnap; $g2 = Get-GpuSnap

    # GPU % per pid = busiest engine
    $gpuByPid = @{}; $gpuTotal = 0.0
    foreach ($k in $g2.Keys) {
        $a = $g1[$k]; $b = $g2[$k]
        if (-not $a) { continue }
        $dt = [double]$b.Timestamp_Sys100NS - [double]$a.Timestamp_Sys100NS
        if ($dt -le 0) { continue }
        $u = ([double]$b.RunningTime - [double]$a.RunningTime) / $dt * 100.0
        if ($u -lt 0) { $u = 0 } elseif ($u -gt 100) { $u = 100 }
        if ($u -gt $gpuTotal) { $gpuTotal = $u }
        if ($k -match '^pid_(\d+)_') {
            $id = [int]$Matches[1]
            if ($u -gt [double]$gpuByPid[$id]) { $gpuByPid[$id] = $u }
        }
    }

    # GPU memory per pid, and dedicated VRAM in use
    $gmemByPid = @{}; $vramUsed = 0.0
    try {
        foreach ($m in Get-CimInstance Win32_PerfRawData_GPUPerformanceCounters_GPUProcessMemory -ErrorAction Stop) {
            if ($m.Name -match '^pid_(\d+)_') {
                $id = [int]$Matches[1]
                $gmemByPid[$id] = [double]$gmemByPid[$id] + [double]$m.TotalCommitted
            }
        }
        foreach ($a in Get-CimInstance Win32_PerfRawData_GPUPerformanceCounters_GPUAdapterMemory -ErrorAction Stop) {
            $vramUsed += [double]$a.DedicatedUsage
        }
    } catch {}

    # Aggregate by process name (like Task Manager's grouped rows)
    $rows = @{}
    foreach ($id in $p2.Keys) {
        $b = $p2[$id]; $a = $p1[$id]
        $cpu = 0.0
        if ($a -and $a.Name -eq $b.Name) {
            $dt = [double]$b.Timestamp_Sys100NS - [double]$a.Timestamp_Sys100NS
            if ($dt -gt 0) {
                $d = [double]$b.PercentProcessorTime - [double]$a.PercentProcessorTime
                if ($d -gt 0) { $cpu = $d / $dt * 100.0 / $cores }
            }
        }
        $name = $b.Name -replace '#\d+$', ''
        $r = $rows[$name]
        if (-not $r) { $r = @{ Cpu = 0.0; Ram = 0.0; Gpu = 0.0; Gmem = 0.0; N = 0 }; $rows[$name] = $r }
        $r.Cpu  += $cpu
        $r.Ram  += [double]$b.WorkingSetPrivate
        $g = [double]$gpuByPid[$id]; if ($g -gt $r.Gpu) { $r.Gpu = $g }
        $r.Gmem += [double]$gmemByPid[$id]
        $r.N++
    }

    $os = Get-CimInstance Win32_OperatingSystem
    $ramTotalMB = $os.TotalVisibleMemorySize / 1KB
    $ramUsedMB  = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1KB
    $cpuTotal = 0.0; foreach ($r in $rows.Values) { $cpuTotal += $r.Cpu }
    if ($cpuTotal -gt 100) { $cpuTotal = 100 }

    # Keep the top rows by each metric so every sort order has real data
    $pick = @{}
    foreach ($key in 'Cpu', 'Ram', 'Gpu', 'Gmem') {
        $rows.GetEnumerator() | Sort-Object { $_.Value[$key] } -Descending | Select-Object -First 25 | ForEach-Object { $pick[$_.Key] = $_.Value }
    }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("Stamp=$now")
    [void]$sb.AppendLine("CpuTotal=$(F $cpuTotal)")
    [void]$sb.AppendLine("Cores=$cores")
    [void]$sb.AppendLine("RamUsedMB=$(F $ramUsedMB 0)")
    [void]$sb.AppendLine("RamTotalMB=$(F $ramTotalMB 0)")
    [void]$sb.AppendLine("GpuTotal=$(F $gpuTotal)")
    [void]$sb.AppendLine("GpuName=$gpuName")
    [void]$sb.AppendLine("VramUsedMB=$(F ($vramUsed / 1MB) 0)")
    [void]$sb.AppendLine("VramTotalMB=$(F $vramTotalMB 0)")
    [void]$sb.AppendLine("ProcCount=$($p2.Count)")
    $i = 0
    foreach ($kv in ($pick.GetEnumerator() | Sort-Object { $_.Value.Cpu } -Descending | Select-Object -First $MaxRows)) {
        $i++; $v = $kv.Value
        [void]$sb.AppendLine("R$i=$($kv.Key)|$(F $v.Cpu 2)|$(F ($v.Ram / 1MB) 1)|$(F $v.Gpu 1)|$(F ($v.Gmem / 1MB) 1)|$($v.N)")
    }
    [IO.File]::WriteAllText($tmpFile, $sb.ToString())
    Move-Item -Force $tmpFile $outFile

    Start-Sleep -Milliseconds ([math]::Max(0, $IntervalMs - 1000))
}
$mutex.ReleaseMutex()
