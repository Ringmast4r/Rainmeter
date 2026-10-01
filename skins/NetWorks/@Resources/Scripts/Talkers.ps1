# Net // Works Who's talking card: established TCP connections to public addresses, grouped by program + address.
#   T=<program>|<address>|<port>|<connections>|<cc>|<city>|<owner>|<threat flags>
# New addresses are looked up once through iplookup.py (IP // Revealer, offline) and cached for a week in Data\ipcache.txt.
. "$PSScriptRoot\Conf.ps1"
$conf = Get-ConfMap 'talkers.txt'

function Test-Public([string]$ip) {
    if ($ip -match '^(127\.|10\.|192\.168\.|169\.254\.|0\.|22[4-9]\.|2[3-5]\d\.)') { return $false }
    if ($ip -match '^172\.(1[6-9]|2\d|3[01])\.') { return $false }
    if ($ip -match '^100\.(6[4-9]|[7-9]\d|1[01]\d|12[0-7])\.') { return $false }   # CGNAT, Tailscale
    if ($ip -match '^(::1?$|fe[89ab][0-9a-f]:|f[cd][0-9a-f]{2}:|ff[0-9a-f]{2}:)') { return $false }
    return $true
}

$names = @{}; Get-Process | ForEach-Object { $names[$_.Id] = $_.ProcessName }
$conns = foreach ($c in Get-NetTCPConnection -State Established) {
    $ip = $c.RemoteAddress -replace '^::ffff:', ''
    if (Test-Public $ip) { [pscustomobject]@{ Proc = $names[[int]$c.OwningProcess]; Ip = $ip; Port = $c.RemotePort } }
}
$conns = @($conns)

# cache: ip|cc|city|owner|flags|epoch
$cacheFile = Join-Path $data 'ipcache.txt'
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$cache = @{}
foreach ($l in (Get-Content $cacheFile -Encoding UTF8 -ErrorAction SilentlyContinue)) {
    $f = $l -split '\|'
    if ($f.Count -ge 6 -and ($now - [int64]$f[5]) -lt 604800) { $cache[$f[0]] = $f }
}
$new = @($conns.Ip | Sort-Object -Unique | Where-Object { -not $cache.ContainsKey($_) } | Select-Object -First 40)
if ($new.Count -and $conf['Revealer']) {
    $py = @(($conf['Python'], 'py -3')[-not $conf['Python']] -split '\s+')
    $argv = @($py | Select-Object -Skip 1) + @("$PSScriptRoot\iplookup.py", '--root', $conf['Revealer']) + $new
    $out = & $py[0] $argv 2>$null
    foreach ($l in $out) { $f = $l -split '\|'; if ($f.Count -ge 5) { $cache[$f[0]] = @($f[0..4] + "$now") } }
    Set-Content -Path $cacheFile -Value ($cache.Values | ForEach-Object { $_ -join '|' }) -Encoding UTF8
}

$groups = $conns | Group-Object Proc, Ip
"Conns=$($conns.Count)"
"Hosts=$(@($conns.Ip | Sort-Object -Unique).Count)"
"Procs=$(@($conns.Proc | Sort-Object -Unique).Count)"
"Flagged=$(@($conns.Ip | Sort-Object -Unique | Where-Object { $cache[$_] -and $cache[$_][4] }).Count)"
$rows = foreach ($g in $groups) {
    $ip = $g.Group[0].Ip
    $port = ($g.Group | Group-Object Port | Sort-Object Count -Descending | Select-Object -First 1).Name
    $f = if ($cache[$ip]) { $cache[$ip] } else { @($ip, '', '', '', '') }
    [pscustomobject]@{ Flag = [bool]$f[4]; N = $g.Count; Proc = $g.Group[0].Proc
                       Line = "T=$(Clean $g.Group[0].Proc)|$ip|$port|$($g.Count)|$($f[1])|$(Clean $f[2])|$(Clean $f[3])|$(Clean $f[4])" }
}
$rows | Sort-Object @{ e = 'Flag'; Descending = $true }, @{ e = 'N'; Descending = $true }, Proc | Select-Object -First 40 | ForEach-Object Line
