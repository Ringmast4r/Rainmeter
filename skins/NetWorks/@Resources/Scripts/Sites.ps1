# Net // Works Sites card: GETs every site in Local\sites.txt in parallel (headers only) and prints
#   S=<site>|<status code, 0 = no answer>|<ms>|<error>
. "$PSScriptRoot\Conf.ps1"
$sites = @(Get-Conf 'sites.txt' | ForEach-Object { $_.Trim() } | Select-Object -First 64)
if (-not $sites) { 'Err=add sites to @Resources\Local\sites.txt'; return }

Add-Type -AssemblyName System.Net.Http
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$h = New-Object Net.Http.HttpClientHandler
$h.AllowAutoRedirect = $true
$client = New-Object Net.Http.HttpClient($h)
$client.Timeout = [TimeSpan]::FromSeconds(10)
$client.DefaultRequestHeaders.UserAgent.ParseAdd('Mozilla/5.0 (Windows NT 10.0; Win64; x64) NetWorks-Rainmeter/1.0')

$sw = [Diagnostics.Stopwatch]::StartNew()
$jobs = foreach ($s in $sites) {
    $url = if ($s -match '^https?://') { $s } else { "https://$s" }
    $req = New-Object Net.Http.HttpRequestMessage([Net.Http.HttpMethod]::Get, $url)
    [pscustomobject]@{ Site = $s; Task = $client.SendAsync($req, [Net.Http.HttpCompletionOption]::ResponseHeadersRead); Ms = $null }
}
# poll so each site gets its own finish time
while ($sw.ElapsedMilliseconds -lt 11000) {
    $pending = 0
    foreach ($j in $jobs) {
        if ($null -eq $j.Ms) { if ($j.Task.IsCompleted) { $j.Ms = $sw.ElapsedMilliseconds } else { $pending++ } }
    }
    if (-not $pending) { break }
    Start-Sleep -Milliseconds 20
}
foreach ($j in $jobs) {
    $code = 0; $err = ''
    if ($j.Task.Status -eq 'RanToCompletion') { $code = [int]$j.Task.Result.StatusCode; $j.Task.Result.Dispose() }
    elseif ($j.Task.IsFaulted) {
        $e = $j.Task.Exception; while ($e.InnerException) { $e = $e.InnerException }
        $m = $e.Message
        $err = if ($m -match 'resolved|No such host') { 'no DNS' } elseif ($m -match 'SSL|TLS|trust') { 'TLS error' }
               elseif ($m -match 'refused|actively') { 'refused' } elseif ($m -match 'closed|reset') { 'connection reset' } else { $m }
    }
    else { $err = 'timeout' }
    "S=$(Clean $j.Site)|$code|$($j.Ms)|$(Clean $err)"
}
$client.Dispose()
