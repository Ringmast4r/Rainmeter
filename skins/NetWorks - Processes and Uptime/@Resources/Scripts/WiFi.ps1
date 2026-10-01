# Net // Works Wi-Fi card: network name, signal and link details from netsh.
$ErrorActionPreference = 'SilentlyContinue'
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
