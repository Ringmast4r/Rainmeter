# Net // Works Egress / ingress card: every TCP connection this PC holds, split by who opened it, and what it listens on.
#   F=<O|I>|<program>|<peer address>|<pub|lan>|<owner network or LAN name>|<cc>|<city>|<port>|<connections>|<threat flags>|<remote ports>
#   L=<tcp|udp>|<program>|<port>|<all | local | the one address it is bound to>
# Inbound (I) = the local port is one the same program listens on; its port is that local port. Outbound (O) carries
# the remote port. Loopback connections are left out. UDP has no connections to list: its sockets on ports below
# 49152 count as listeners (above that they are mostly a program's own outgoing sockets).
. "$PSScriptRoot\Conf.ps1"
. "$PSScriptRoot\IpInfo.ps1"

$loop = '^(127\.|::1$)'
$names = @{}; Get-Process | ForEach-Object { $names[$_.Id] = $_.ProcessName }
$tcp = @(Get-NetTCPConnection)
$listening = @{}
foreach ($c in $tcp) { if ($c.State -eq 'Listen') { $listening["$($c.OwningProcess):$($c.LocalPort)"] = 1 } }

$conns = @(foreach ($c in $tcp) {
    if ($c.State -ne 'Established') { continue }
    $ip = $c.RemoteAddress -replace '^::ffff:', ''
    if ($ip -match $loop) { continue }
    $in = $listening.ContainsKey("$($c.OwningProcess):$($c.LocalPort)")
    [pscustomobject]@{ Dir = ('O', 'I')[$in]; Proc = $names[[int]$c.OwningProcess]; Ip = $ip; Pub = (Test-Public $ip)
                       Port = ([int]$c.RemotePort, [int]$c.LocalPort)[$in]; RPort = [int]$c.RemotePort }
})

# LAN peers by address: your labels, then Proxmox guests (from the Homelab card), then the LAN card's reverse DNS
$lan = @{}
foreach ($l in (Get-Content (Join-Path $data 'lan_rdns.txt') -Encoding UTF8 -ErrorAction SilentlyContinue)) {
    $f = $l -split '\|'; if ($f.Count -ge 2 -and $f[1]) { $lan[$f[0]] = $f[1] -replace '\.(lan|local|home|localdomain)$', '' }
}
$pve = (Get-ConfMap 'homelab.txt')['Host'] -replace '^.*@', ''
if ($pve) { $lan[$pve] = 'Proxmox host' }
foreach ($l in (Get-Content (Join-Path $data 'ct_ips.txt') -Encoding UTF8 -ErrorAction SilentlyContinue)) {
    $f = $l -split '\|'; if ($f.Count -ge 4 -and $f[1]) { $lan[$f[1]] = "CT $($f[2]) $($f[3])" }
}
$labels = Get-ConfMap 'lan_names.txt'
foreach ($k in $labels.Keys) { if ($k -match '^[\d.]+$') { $lan[$k] = $labels[$k] } }

$info = Get-IpInfo @($conns | Where-Object Pub | ForEach-Object Ip)

'Ok=1'
foreach ($g in ($conns | Group-Object Dir, Proc, Ip)) {
    $c = $g.Group[0]
    $port = ($g.Group | Group-Object Port | Sort-Object Count -Descending | Select-Object -First 1).Name
    $rports = @($g.Group.RPort | Sort-Object -Unique | Select-Object -First 6) -join ','
    $who = ''; $cc = ''; $city = ''; $flag = ''
    if ($c.Pub) { $f = $info[$c.Ip]; if ($f) { $cc = $f[1]; $city = $f[2]; $who = $f[3]; $flag = $f[4] } }
    else { $who = $lan[$c.Ip] }
    "F=$($c.Dir)|$(Clean $c.Proc)|$($c.Ip)|$(('lan', 'pub')[[bool]$c.Pub])|$(Clean $who)|$cc|$(Clean $city)|$port|$($g.Count)|$(Clean $flag)|$rports"
}

$socks = @(foreach ($c in $tcp) {
    if ($c.State -eq 'Listen') { [pscustomobject]@{ Proto = 'tcp'; Proc = $names[[int]$c.OwningProcess]; Port = [int]$c.LocalPort; Addr = $c.LocalAddress } }
}) + @(foreach ($u in Get-NetUDPEndpoint) {
    if ($u.LocalPort -lt 49152) { [pscustomobject]@{ Proto = 'udp'; Proc = $names[[int]$u.OwningProcess]; Port = [int]$u.LocalPort; Addr = $u.LocalAddress } }
})
foreach ($g in ($socks | Group-Object Proto, Proc, Port)) {
    $addrs = @($g.Group.Addr | Sort-Object -Unique)
    $open = @($addrs | Where-Object { $_ -notmatch $loop })
    $scope = if ($addrs -contains '0.0.0.0' -or $addrs -contains '::') { 'all' } elseif (-not $open.Count) { 'local' } else { $open[0] }
    "L=$($g.Group[0].Proto)|$(Clean $g.Group[0].Proc)|$($g.Group[0].Port)|$scope"
}
