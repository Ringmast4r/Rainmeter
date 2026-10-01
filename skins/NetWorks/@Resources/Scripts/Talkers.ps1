# Net // Works Who's talking card: established TCP connections to public addresses, grouped by program + address.
#   T=<program>|<address>|<port>|<connections>|<cc>|<city>|<owner>|<threat flags>
# New addresses are looked up once through iplookup.py (IP // Revealer, offline) and cached for a week in Data\ipcache.txt.
. "$PSScriptRoot\Conf.ps1"
. "$PSScriptRoot\IpInfo.ps1"

$names = @{}; Get-Process | ForEach-Object { $names[$_.Id] = $_.ProcessName }
$conns = foreach ($c in Get-NetTCPConnection -State Established) {
    $ip = $c.RemoteAddress -replace '^::ffff:', ''
    if (Test-Public $ip) { [pscustomobject]@{ Proc = $names[[int]$c.OwningProcess]; Ip = $ip; Port = $c.RemotePort } }
}
$conns = @($conns)

# cache: ip -> ip|cc|city|owner|flags|epoch
$cache = Get-IpInfo $conns.Ip

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
