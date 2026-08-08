# Test connection to TheForge HiveOS rig
# This script helps find the correct API endpoints

$rigIP = "10.0.0.246"
$rigName = "TheForge"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Testing connection to $rigName" -ForegroundColor Cyan
Write-Host "IP: $rigIP" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Ping test
Write-Host "[1] Testing network connectivity..." -ForegroundColor Yellow
$ping = Test-Connection -ComputerName $rigIP -Count 2 -Quiet
if ($ping) {
    Write-Host "    SUCCESS: Rig is reachable on network!" -ForegroundColor Green
} else {
    Write-Host "    FAILED: Cannot reach rig. Check IP address and network." -ForegroundColor Red
    exit
}
Write-Host ""

# Test 2: Check if web interface is accessible
Write-Host "[2] Testing HiveOS web interface..." -ForegroundColor Yellow
$ports = @(80, 8080, 443)
foreach ($port in $ports) {
    try {
        $test = Test-NetConnection -ComputerName $rigIP -Port $port -WarningAction SilentlyContinue -InformationLevel Quiet
        if ($test) {
            Write-Host "    Port $port is OPEN" -ForegroundColor Green
        } else {
            Write-Host "    Port $port is closed" -ForegroundColor Gray
        }
    } catch {
        Write-Host "    Port $port is closed" -ForegroundColor Gray
    }
}
Write-Host ""

# Test 3: Try to fetch web page
Write-Host "[3] Attempting to fetch HiveOS stats..." -ForegroundColor Yellow
$endpoints = @(
    "http://$rigIP/",
    "http://$rigIP/api/stats",
    "http://$rigIP/worker-api",
    "http://$rigIP/worker-api-0",
    "http://$rigIP/api/v1/stats",
    "http://$rigIP:8080/stats"
)

foreach ($url in $endpoints) {
    try {
        Write-Host "    Trying: $url" -ForegroundColor Gray
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
        Write-Host "    SUCCESS! Status: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "    Content Length: $($response.Content.Length) bytes" -ForegroundColor Green

        # Save response to file
        $filename = "hiveos-response-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
        $response.Content | Out-File -FilePath $filename
        Write-Host "    Response saved to: $filename" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "    First 500 characters:" -ForegroundColor Yellow
        Write-Host "    $($response.Content.Substring(0, [Math]::Min(500, $response.Content.Length)))" -ForegroundColor White
        Write-Host ""
        break
    } catch {
        Write-Host "    Failed: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Test Complete!" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "If you found a working endpoint, update the skin file:" -ForegroundColor Yellow
Write-Host "C:\Users\Squir\Documents\Rainmeter\Skins\ringmast4r\HiveOS\TheForge.ini" -ForegroundColor White
Write-Host ""
pause
