# Net // Works Homelab card: one SSH call (your own key) to a Proxmox host, printed as key=value lines.
# Also writes Data\ct_ips.txt (mac|ip|vmid|name|status) so the LAN card can name containers and spot IP clashes.
. "$PSScriptRoot\Conf.ps1"
$target = (Get-ConfMap 'homelab.txt')['Host']
if (-not $target -or $target -match 'example') { 'Err=set Host= in @Resources\Local\homelab.txt'; return }

$remote = @'
pvesh get /cluster/resources --type vm --output-format json
echo '@@NODE'
hostname; nproc; cut -d' ' -f1 /proc/loadavg; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo
echo '@@STAT'
head -1 /proc/stat; sleep 1; head -1 /proc/stat
echo '@@BOOT'
for f in /etc/pve/lxc/*.conf /etc/pve/qemu-server/*.conf; do awk -v f="$f" '/^\[/{exit} /^onboot:/{print f":"$0}' "$f"; done 2>/dev/null
echo '@@NET'
for f in /etc/pve/lxc/*.conf; do awk -v f="$f" '/^\[/{exit} /^net[0-9]+:/{print f":"$0}' "$f"; done 2>/dev/null
echo '@@D'
ps -eo stat= | grep -c '^D'
'@
# onboot/net lines are read only up to the first [snapshot] section, which holds old copies of the config.
# base64 keeps quoting out of the PowerShell -> ssh -> bash chain
$b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($remote -replace "`r", '')))
$raw = & ssh -n -o BatchMode=yes -o ConnectTimeout=6 $target "echo $b64 | base64 -d | bash" 2>$null
if (-not $raw) { 'Err=host unreachable'; return }

$sec = @{ VM = New-Object Collections.Generic.List[string] }; $cur = 'VM'
foreach ($l in $raw) {
    if ($l -match '^@@(\w+)$') { $cur = $matches[1]; $sec[$cur] = New-Object Collections.Generic.List[string] }
    else { $sec[$cur].Add($l) }
}
$vms = ($sec['VM'] -join "`n") | ConvertFrom-Json
$nd  = $sec['NODE']
if (-not $nd -or $nd.Count -lt 3) { 'Err=no answer from the host'; return }

$boot = @{}
foreach ($l in $sec['BOOT']) { if ($l -match '/(\d+)\.conf:onboot:\s*(\d)') { $boot[$matches[1]] = $matches[2] } }

# CPU busy and IO wait from two /proc/stat samples a second apart (pvestatd reads 0 when the host is starved)
$s = @($sec['STAT'] | ForEach-Object { , ([int64[]](($_ -split '\s+')[1..8])) })
if ($s.Count -eq 2) {
    $d = 0..7 | ForEach-Object { $s[1][$_] - $s[0][$_] }
    $tot = ($d | Measure-Object -Sum).Sum
    if ($tot -gt 0) {
        "Cpu=$([math]::Round(100 * ($tot - $d[3] - $d[4]) / $tot, 1))"
        "Wait=$([math]::Round(100 * $d[4] / $tot, 1))"
    }
}
$kb = @{}; foreach ($l in $nd) { if ($l -match '^(\w+):\s+(\d+)') { $kb[$matches[1]] = [int64]$matches[2] * 1024 } }
"Node=$($nd[0])"
"Cores=$($nd[1])"
"Load=$($nd[2])"
"MemUsed=$($kb['MemTotal'] - $kb['MemAvailable'])"
"MemTotal=$($kb['MemTotal'])"
"DState=$(($sec['D'] | Select-Object -First 1))"

$names = @{}; $state = @{}
foreach ($v in $vms) {
    if ($v.template -eq 1) { continue }
    $id = [string]$v.vmid; $names[$id] = $v.name; $state[$id] = $v.status
    $onboot = if ($boot.ContainsKey($id)) { $boot[$id] } else { '0' }
    "G=$id|$(Clean $v.name)|$($v.type)|$($v.status)|$onboot|$([math]::Round($v.cpu * 100, 1))|$($v.mem)|$($v.maxmem)|$($v.uptime)"
}

$ips = foreach ($l in $sec['NET']) {
    if ($l -match '/(\d+)\.conf:net\d+:.*hwaddr=([0-9A-Fa-f:]{17})' ) {
        $id = $matches[1]; $mac = $matches[2].ToUpper()
        $ip = if ($l -match '[,\s]ip=(\d+\.\d+\.\d+\.\d+)') { $matches[1] } else { '' }
        "$mac|$ip|$id|$($names[$id])|$($state[$id])"
    }
}
Set-Content -Path (Join-Path $data 'ct_ips.txt') -Value $ips -Encoding UTF8
