# Dot-sourced by the lab-card scripts. Settings live in @Resources\Local\ (personal, never committed);
# the first run copies the template from @Resources\Examples\ so there is something to edit.
$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$res  = Split-Path -Parent $PSScriptRoot
$data = Join-Path $res 'Data'
New-Item -ItemType Directory -Force -Path $data | Out-Null

function Get-Conf([string]$name) {
    $loc = Join-Path $res "Local\$name"
    if (-not (Test-Path $loc)) {
        $ex = Join-Path $res "Examples\$name"
        if (Test-Path $ex) { New-Item -ItemType Directory -Force -Path (Split-Path $loc) | Out-Null; Copy-Item $ex $loc }
    }
    if (Test-Path $loc) { Get-Content $loc -Encoding UTF8 | Where-Object { $_.Trim() -and $_ -notmatch '^\s*#' } }
}

function Get-ConfMap([string]$name) {
    $m = @{}
    Get-Conf $name | ForEach-Object { if ($_ -match '^\s*([\w.:-]+)\s*=\s*(.*?)\s*$') { $m[$matches[1]] = $matches[2] } }
    $m
}

function Clean([string]$s) { ($s -replace '[|\r\n]', ' ').Trim() }
