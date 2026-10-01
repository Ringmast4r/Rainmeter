# Net // Works LAN watch card: devices on the local network (default-route interface, at most its /24).
# Every 5 minutes (or with -Sweep) it pings the whole range so the ARP table fills, then reads the ARP table.
#   D=<ip>|<mac>|<name>|<first seen epoch, 0 = before the card started>|<1 if a Proxmox guest>|<guest whose static IP this is, if another MAC answers on it>
param([switch]$Sweep)
. "$PSScriptRoot\Conf.ps1"

$route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' |
         Sort-Object { $_.RouteMetric + (Get-NetIPInterface -InterfaceIndex $_.ifIndex -AddressFamily IPv4).InterfaceMetric } |
         Select-Object -First 1
if (-not $route) { 'Err=no network'; return }
$me = Get-NetIPAddress -InterfaceIndex $route.ifIndex -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1
if (-not $me) { 'Err=no IPv4 address'; return }

function ToInt([string]$ip) { $b = [Net.IPAddress]::Parse($ip).GetAddressBytes(); [Array]::Reverse($b); [BitConverter]::ToUInt32($b, 0) }
function ToIp([uint32]$n) { $b = [BitConverter]::GetBytes($n); [Array]::Reverse($b); ([Net.IPAddress]$b).ToString() }
$plen = [Math]::Max([int]$me.PrefixLength, 24)
# decimal on purpose: in PowerShell 0xFFFFFFFF is the Int32 -1
$mask = [uint32](([uint64]4294967295 -shl (32 - $plen)) -band 4294967295)
$base = (ToInt $me.IPAddress) -band $mask
$hosts = [Math]::Pow(2, 32 - $plen) - 2
"Me=$($me.IPAddress)"
"Net=$(ToIp $base)/$plen"

$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$seenFile = Join-Path $data 'lan_seen.txt'
$baseline = -not (Test-Path $seenFile)          # first run: sweep, then everything found counts as known
$stamp = Join-Path $data 'lan_sweep.txt'
$last = [int64](Get-Content $stamp -ErrorAction SilentlyContinue | Select-Object -First 1)
if ($Sweep -or $baseline -or ($now - $last) -gt 300) {
    $tasks = for ($i = 1; $i -le $hosts; $i++) { (New-Object Net.NetworkInformation.Ping).SendPingAsync((ToIp ($base + $i)), 500) }
    try { [void][Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]$tasks, 4000) } catch {}
    Set-Content $stamp $now
}
"Swept=$((Get-Content $stamp | Select-Object -First 1))"

# names: your labels (MAC or IP = label), then Proxmox guests (from the Homelab card), then reverse DNS (cached a day)
$labels = Get-ConfMap 'lan_names.txt'
$pve = (Get-ConfMap 'homelab.txt')['Host'] -replace '^.*@', ''
# Proxmox guests by MAC; their configured static IPs are only used to catch another device answering on one
$ctMac = @{}; $ctIp = @{}
foreach ($l in (Get-Content (Join-Path $data 'ct_ips.txt') -Encoding UTF8 -ErrorAction SilentlyContinue)) {
    $f = $l -split '\|'
    if ($f.Count -ge 4) {
        $ctMac[$f[0]] = "CT $($f[2]) $($f[3])"
        if ($f[1] -and ($f.Count -lt 5 -or $f[4] -eq 'running')) { $ctIp[$f[1]] = @{ Name = "CT $($f[2]) $($f[3])"; Mac = $f[0] } }
    }
}
$rdnsFile = Join-Path $data 'lan_rdns.txt'
$rdns = @{}
foreach ($l in (Get-Content $rdnsFile -Encoding UTF8 -ErrorAction SilentlyContinue)) {
    $f = $l -split '\|'; if ($f.Count -ge 3 -and ($now - [int64]$f[2]) -lt 86400) { $rdns[$f[0]] = $f }
}

$seen = @{}
foreach ($l in (Get-Content $seenFile -ErrorAction SilentlyContinue)) { $f = $l -split '\|'; if ($f.Count -ge 2) { $seen[$f[0]] = [int64]$f[1] } }

$nb = Get-NetNeighbor -InterfaceIndex $route.ifIndex -AddressFamily IPv4 |
      Where-Object { $_.State -in 'Reachable', 'Stale', 'Delay', 'Probe', 'Permanent' -and $_.LinkLayerAddress -and
                     $_.LinkLayerAddress -notmatch '^(00-00-00-00-00-00|FF-FF-FF-FF-FF-FF|01-00-5E)' }
$own = (Get-NetAdapter -InterfaceIndex $route.ifIndex).MacAddress
$devs = @($nb | ForEach-Object { [pscustomobject]@{ Ip = $_.IPAddress; Mac = ($_.LinkLayerAddress -replace '-', ':').ToUpper() } }) +
        [pscustomobject]@{ Ip = $me.IPAddress; Mac = ($own -replace '-', ':').ToUpper() }
$devs = $devs | Where-Object { ((ToInt $_.Ip) -band $mask) -eq $base -and $_.Ip -ne (ToIp ($base + $hosts + 1)) }

$lookups = 0
foreach ($d in ($devs | Sort-Object { ToInt $_.Ip })) {
    if (-not $seen.ContainsKey($d.Mac)) { $seen[$d.Mac] = if ($baseline) { 0 } else { $now } }
    $name = if ($d.Ip -eq $me.IPAddress) { 'this PC' } elseif ($labels[$d.Mac]) { $labels[$d.Mac] } elseif ($labels[$d.Ip]) { $labels[$d.Ip] }
            elseif ($ctMac[$d.Mac]) { $ctMac[$d.Mac] } elseif ($d.Ip -eq $pve) { 'Proxmox host' } else { '' }
    $conflict = if ($ctIp[$d.Ip] -and $ctIp[$d.Ip].Mac -ne $d.Mac) { $ctIp[$d.Ip].Name } else { '' }
    if (-not $name) {
        if (-not $rdns.ContainsKey($d.Ip) -and $lookups -lt 8) {
            $lookups++
            $ptr = (Resolve-DnsName -Name $d.Ip -Type PTR -Server $route.NextHop -QuickTimeout -DnsOnly -ErrorAction SilentlyContinue |
                    Where-Object NameHost | Select-Object -First 1).NameHost
            $rdns[$d.Ip] = @($d.Ip, "$ptr", "$now")
        }
        if ($rdns[$d.Ip]) { $name = ($rdns[$d.Ip][1] -replace '\.(lan|local|home|localdomain)$', '') }
    }
    $isCt = [int][bool]$ctMac[$d.Mac]
    "D=$($d.Ip)|$($d.Mac)|$(Clean $name)|$($seen[$d.Mac])|$isCt|$(Clean $conflict)"
}
Set-Content -Path $seenFile -Value ($seen.GetEnumerator() | ForEach-Object { "$($_.Key)|$($_.Value)" })
Set-Content -Path $rdnsFile -Value ($rdns.Values | ForEach-Object { $_ -join '|' }) -Encoding UTF8
