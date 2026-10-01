# Net // Works Wi-Fi survey card: every BSSID Windows can see, from netsh, then asks the radio for a fresh scan
# (WlanScan) so the next cycle sees networks that appeared since.
#   B=<ssid>|<bssid>|<signal %>|<channel>|<band>|<radio>|<authentication>
. "$PSScriptRoot\Conf.ps1"

$o = netsh wlan show networks mode=bssid
if (-not $o -or ($o -join ' ') -match 'no wireless interface|not running') { 'Err=no Wi-Fi adapter'; return }
if (($o -join ' ') -match 'powered down|radio.*off') { 'Err=Wi-Fi radio is off'; return }

$rows = New-Object Collections.Generic.List[string]
$ssid = ''; $auth = ''; $b = $null
function Flush { if ($script:b) { $script:rows.Add("B=$(Clean $script:ssid)|$($script:b.Mac)|$($script:b.Sig)|$($script:b.Ch)|$($script:b.Band)|$($script:b.Radio)|$(Clean $script:auth)") }; $script:b = $null }
foreach ($line in $o) {
    if ($line -match '^SSID \d+ :\s?(.*)$') { Flush; $ssid = $matches[1].Trim(); $auth = ''; continue }
    if ($line -match '^\s+Authentication\s*:\s*(.*)$') { $auth = $matches[1].Trim(); continue }
    if ($line -match '^\s+BSSID \d+\s*:\s*(\S+)') { Flush; $b = @{ Mac = $matches[1].ToUpper(); Sig = ''; Ch = ''; Band = ''; Radio = '' }; continue }
    if (-not $b) { continue }
    if ($line -match '^\s+Signal\s*:\s*(\d+)%') { $b.Sig = $matches[1] }
    elseif ($line -match '^\s+Radio type\s*:\s*(.*)$') { $b.Radio = $matches[1].Trim() }
    elseif ($line -match '^\s+Band\s*:\s*(.*)$') { $b.Band = $matches[1].Trim() }
    elseif ($line -match '^\s+Channel\s*:\s*(\d+)') {
        $b.Ch = $matches[1]
        if (-not $b.Band) { $b.Band = if ([int]$b.Ch -le 14) { '2.4 GHz' } else { '5 GHz' } }
    }
}
Flush
$rows

# WlanScan helper, compiled once into Data\ (never committed)
$dll = Join-Path $data 'WlanScan.dll'
if (-not (Test-Path $dll)) {
    Add-Type -OutputAssembly $dll -OutputType Library -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class WlanScanner {
    [DllImport("wlanapi.dll")] static extern int WlanOpenHandle(uint v, IntPtr r, out uint neg, out IntPtr h);
    [DllImport("wlanapi.dll")] static extern int WlanEnumInterfaces(IntPtr h, IntPtr r, out IntPtr list);
    [DllImport("wlanapi.dll")] static extern int WlanScan(IntPtr h, ref Guid g, IntPtr ssid, IntPtr ie, IntPtr r);
    [DllImport("wlanapi.dll")] static extern void WlanFreeMemory(IntPtr p);
    [DllImport("wlanapi.dll")] static extern int WlanCloseHandle(IntPtr h, IntPtr r);
    public static int Scan() {
        uint neg; IntPtr h;
        if (WlanOpenHandle(2, IntPtr.Zero, out neg, out h) != 0) return -1;
        int n = 0;
        try {
            IntPtr list;
            if (WlanEnumInterfaces(h, IntPtr.Zero, out list) != 0) return -1;
            try {
                int count = Marshal.ReadInt32(list);
                // WLAN_INTERFACE_INFO_LIST: two DWORDs, then WLAN_INTERFACE_INFO[] (GUID + WCHAR[256] + state = 532 bytes)
                for (int i = 0; i < count; i++) {
                    Guid g = (Guid)Marshal.PtrToStructure(new IntPtr(list.ToInt64() + 8 + i * 532), typeof(Guid));
                    if (WlanScan(h, ref g, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero) == 0) n++;
                }
            } finally { WlanFreeMemory(list); }
        } finally { WlanCloseHandle(h, IntPtr.Zero); }
        return n;
    }
}
'@
}
Add-Type -Path $dll
[void][WlanScanner]::Scan()
