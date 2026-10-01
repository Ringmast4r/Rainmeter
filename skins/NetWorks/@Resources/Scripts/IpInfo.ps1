# Dot-sourced after Conf.ps1 by the cards that name remote addresses (Who's talking, Egress / ingress).
function Test-Public([string]$ip) {
    if ($ip -match '^(127\.|10\.|192\.168\.|169\.254\.|0\.|22[4-9]\.|2[3-5]\d\.)') { return $false }
    if ($ip -match '^172\.(1[6-9]|2\d|3[01])\.') { return $false }
    if ($ip -match '^100\.(6[4-9]|[7-9]\d|1[01]\d|12[0-7])\.') { return $false }   # CGNAT, Tailscale
    if ($ip -match '^(::1?$|fe[89ab][0-9a-f]:|f[cd][0-9a-f]{2}:|ff[0-9a-f]{2}:)') { return $false }
    return $true
}

# address -> @(ip, cc, city, owner, threat flags, epoch) for every address the cache knows.
# New addresses are looked up once through iplookup.py (IP // Revealer, offline; path in Local\talkers.txt),
# at most 40 a run, and cached for a week in Data\ipcache.txt.
function Get-IpInfo([string[]]$ips) {
    $conf = Get-ConfMap 'talkers.txt'
    $cacheFile = Join-Path $data 'ipcache.txt'
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $cache = @{}
    foreach ($l in (Get-Content $cacheFile -Encoding UTF8 -ErrorAction SilentlyContinue)) {
        $f = $l -split '\|'
        if ($f.Count -ge 6 -and ($now - [int64]$f[5]) -lt 604800) { $cache[$f[0]] = $f }
    }
    $new = @($ips | Sort-Object -Unique | Where-Object { $_ -and -not $cache.ContainsKey($_) } | Select-Object -First 40)
    if ($new.Count -and $conf['Revealer']) {
        $py = @(($conf['Python'], 'py -3')[-not $conf['Python']] -split '\s+')
        $argv = @($py | Select-Object -Skip 1) + @("$PSScriptRoot\iplookup.py", '--root', $conf['Revealer']) + $new
        $out = & $py[0] $argv 2>$null
        foreach ($l in $out) { $f = $l -split '\|'; if ($f.Count -ge 5) { $cache[$f[0]] = @($f[0..4] + "$now") } }
        Set-Content -Path $cacheFile -Value ($cache.Values | ForEach-Object { $_ -join '|' }) -Encoding UTF8
    }
    $cache
}
