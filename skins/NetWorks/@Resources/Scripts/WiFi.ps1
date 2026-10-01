# Net // Works Wi-Fi / Eth card.
#   -Mode wifi : network name, signal and link details from netsh
#   -Mode eth  : the wired adapter's state, link speed, duplex, IPv4, gateway, DNS and MAC
param([string]$Mode = 'wifi')
$ErrorActionPreference = 'SilentlyContinue'

if ($Mode -eq 'eth') {
    # a wired adapter that is up wins; Hyper-V and VPN adapters are not -Physical
    $a = Get-NetAdapter -Physical | Where-Object PhysicalMediaType -eq '802.3' |
         Sort-Object { $_.Status -ne 'Up' }, ifIndex | Select-Object -First 1
    if (-not $a) { 'EthStatus=none'; return }
    $ip  = Get-NetIPAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1
    $gw  = (Get-NetRoute -InterfaceIndex $a.ifIndex -DestinationPrefix '0.0.0.0/0' | Sort-Object RouteMetric | Select-Object -First 1).NextHop
    $dns = (Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4).ServerAddresses -join ', '
    "EthStatus=$($a.Status)"
    "EthName=$($a.Name)"
    "EthDesc=$($a.InterfaceDescription)"
    "EthSpeed=$($a.LinkSpeed)"
    "EthDuplex=$(if ($a.FullDuplex) { 'full duplex' } else { 'half duplex' })"
    "EthMac=$($a.MacAddress -replace '-', ':')"
    "EthV4=$(if ($ip) { "$($ip.IPAddress)/$($ip.PrefixLength)" })"
    "EthGw=$gw"
    "EthDns=$dns"
    return
}

$o = netsh wlan show interfaces
function F([string]$k) {
    $line = $o | Where-Object { $_ -match "^\s*$([regex]::Escape($k))\s*:\s*(.*)$" } | Select-Object -First 1
    if ($line) { ($line -replace "^\s*$([regex]::Escape($k))\s*:\s*", '').Trim() } else { '' }
}
$ch = F 'Channel'
$band = ''
if ($ch -match '^\d+$') { $n = [int]$ch; $band = if ($n -le 14) { '2.4 GHz' } elseif ($n -le 177) { '5 GHz' } else { '6 GHz' } }
$b = F 'Band'; if ($b) { $band = $b }
"State=$(F 'State')"
"SSID=$(F 'SSID')"
"Signal=$((F 'Signal') -replace '[^\d]', '')"
"Radio=$(F 'Radio type')"
"Auth=$(F 'Authentication')"
"Channel=$ch"
"Band=$band"
"Rx=$(F 'Receive rate (Mbps)')"
"Tx=$(F 'Transmit rate (Mbps)')"
"Adapter=$(F 'Description')"
