# Net // Works VPN card: which VPN is connected, and which interface carries traffic.
# Prints key=value lines for VPN.lua.
$ErrorActionPreference = 'SilentlyContinue'
$up = @(Get-NetAdapter | Where-Object Status -eq 'Up')
function Find-Tun([string]$rx) { $up | Where-Object { $_.Name -match $rx -or $_.InterfaceDescription -match $rx } | Select-Object -First 1 }
function Get-V4($a) { if ($a) { (Get-NetIPAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 | Select-Object -First 1).IPAddress } }

# Interface that wins the default route. VPNs often add 0.0.0.0/1 + 128.0.0.0/1,
# which beat 0.0.0.0/0 by prefix length, so longer prefixes sort first.
$rt = Get-NetRoute -DestinationPrefix '0.0.0.0/0', '0.0.0.0/1', '128.0.0.0/1' -AddressFamily IPv4 |
      Sort-Object @{ e = { [int]($_.DestinationPrefix -split '/')[1] }; Descending = $true },
                  @{ e = { $_.RouteMetric + (Get-NetIPInterface -InterfaceIndex $_.ifIndex -AddressFamily IPv4).InterfaceMetric } } |
      Select-Object -First 1
$route = $rt.InterfaceAlias

function State($tun, [bool]$running, [bool]$installed, [string]$hint) {
    if ($tun)              { return 'CONNECTED' }
    if ($hint -eq 'connecting') { return 'CONNECTING' }
    if ($running)          { return 'READY' }
    if ($installed)        { return 'OFF' }
    return 'NOT INSTALLED'
}

# Proton VPN: wintun/TUN adapter named ProtonVPN while connected
$pTun = Find-Tun 'Proton'
$pRun = [bool](Get-Process -Name 'ProtonVPN*', 'Proton.VPN*' -ErrorAction SilentlyContinue) -or ((Get-Service 'ProtonVPN Service').Status -eq 'Running')
$pState = State $pTun $pRun (Test-Path 'C:\Program Files\Proton\VPN') ''

# Mullvad: ask its own CLI, adapter named Mullvad while connected
$mExe = 'C:\Program Files\Mullvad VPN\resources\mullvad.exe'
$mHint = ''
if (Test-Path $mExe) { $s = (& $mExe status 2>$null | Select-Object -First 1); if ($s -match '^Connecting') { $mHint = 'connecting' } }
$mTun = Find-Tun 'Mullvad'
$mState = State $mTun ((Get-Service MullvadVPN).Status -eq 'Running') (Test-Path $mExe) $mHint

# Net // Works VPN: WireGuard for Windows tunnel service "networksvpn"
$nTun = Find-Tun '^networksvpn$'
$nState = State $nTun ([bool](Get-Process NetWorksVPN -ErrorAction SilentlyContinue)) (Test-Path 'C:\Program Files\NetWorks VPN\NetWorksVPN.exe') ''

# any other tunnel that is up
$known = @($pTun, $mTun, $nTun) | Where-Object { $_ } | ForEach-Object { $_.ifIndex }
$other = $up | Where-Object { $known -notcontains $_.ifIndex -and ($_.InterfaceDescription -match 'WireGuard|Wintun|TAP-|OpenVPN|TUN\b|VPN' -or $_.Name -match 'VPN|wg\d') } | Select-Object -First 1

$active = ''
foreach ($pair in @(@('Proton VPN', $pTun), @('Mullvad', $mTun), @('Net // Works VPN', $nTun), @("$($other.Name)", $other))) {
    if ($pair[1] -and $pair[1].Name -eq $route) { $active = $pair[0] }
}

"Route=$route"
"Active=$active"
"Proton=$pState|$(Get-V4 $pTun)"
"Mullvad=$mState|$(Get-V4 $mTun)"
"NetWorks=$nState|$(Get-V4 $nTun)"
"Other=$(if ($other) { "$($other.Name)|$(Get-V4 $other)" })"
