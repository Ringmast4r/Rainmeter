# Get ALL MAC addresses from all network adapters
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputPath = Join-Path $scriptPath "mac-addresses.txt"
$adapters = Get-NetAdapter | Sort-Object -Property Name
$output = ""

foreach ($adapter in $adapters) {
    $mac = $adapter.MacAddress -replace '-', ':'
    $name = $adapter.Name
    $desc = $adapter.InterfaceDescription
    $status = $adapter.Status

    # Determine adapter type
    $type = "Unknown"
    if ($desc -match "Wi-Fi|Wireless|802.11") { $type = "WiFi" }
    elseif ($desc -match "Bluetooth") { $type = "Bluetooth" }
    elseif ($desc -match "Ethernet|Realtek|Intel.*Gigabit") { $type = "Ethernet" }
    elseif ($desc -match "VirtualBox|VMware|Hyper-V") { $type = "Virtual" }

    if ($mac) {
        $statusIndicator = if ($status -eq "Up") { " [UP]" } else { "" }
        $output += "$type - $name$statusIndicator`n  MAC: $mac`n"
    }
}

# Save to file
$output | Out-File -FilePath $outputPath -Encoding ASCII -NoNewline
