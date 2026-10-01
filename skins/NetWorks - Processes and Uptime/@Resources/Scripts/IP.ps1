# Net // Works IP card: prints key=value lines for IP.lua.
#   Local*  = addresses on the interface that holds the default route (what traffic actually uses)
#   Public* = address the internet sees, from ipify.org (IPv6 endpoint answers only over IPv6)
$ErrorActionPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-DefaultIf([string]$prefix) {
    Get-NetRoute -DestinationPrefix $prefix -ErrorAction SilentlyContinue |
        Sort-Object { $_.RouteMetric + (Get-NetIPInterface -InterfaceIndex $_.ifIndex -AddressFamily $_.AddressFamily).InterfaceMetric } |
        Select-Object -First 1
}

$r4 = Get-DefaultIf '0.0.0.0/0'
$r6 = Get-DefaultIf '::/0'

$v4 = if ($r4) { (Get-NetIPAddress -InterfaceIndex $r4.ifIndex -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1).IPAddress }
$v6 = $null
if ($r6) {
    $g = Get-NetIPAddress -InterfaceIndex $r6.ifIndex -AddressFamily IPv6 |
         Where-Object { $_.IPAddress -match '^[23]' -and $_.AddressState -eq 'Preferred' }
    # stable address first; temporary (privacy) addresses are what the public row shows
    $v6 = ($g | Sort-Object { $_.SuffixOrigin -eq 'Random' } | Select-Object -First 1).IPAddress
}
$alias = if ($r4) { (Get-NetAdapter -InterfaceIndex $r4.ifIndex).Name } elseif ($r6) { (Get-NetAdapter -InterfaceIndex $r6.ifIndex).Name }
if (-not $alias -and $r4) { $alias = (Get-NetIPInterface -InterfaceIndex $r4.ifIndex -AddressFamily IPv4).InterfaceAlias }

function Get-Public([string]$url) {
    try { $ip = (Invoke-RestMethod -Uri $url -TimeoutSec 5 -UseBasicParsing).ToString().Trim()
          if ($ip -match '^[0-9a-fA-F:.]+$') { return $ip } } catch {}
    return ''
}

# why IPv6 is missing, if it is
$v6State = ''
if ($r4) {
    $bind = Get-NetAdapterBinding -InterfaceAlias $alias -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
    if ($bind -and -not $bind.Enabled) { $v6State = "IPv6 is turned off on $alias" }
}
if (-not $v6State -and -not $r6) { $v6State = 'This network has no IPv6 route' }

"Iface=$alias"
"V6State=$v6State"
"LocalV4=$v4"
"LocalV6=$v6"
"PublicV4=$(Get-Public 'https://api.ipify.org')"
"PublicV6=$(Get-Public 'https://api6.ipify.org')"
