#Requires -Version 7.0
<#
.SYNOPSIS
    Deploys the storefront build to the web servers.
.EXAMPLE
    ./deploy.ps1 -Environment staging -Verbose
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('staging', 'production')][string]$Environment,
    [int]$Retries = 3,
    [switch]$SkipTests
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$servers = @{ staging = @('web-s1'); production = @('web-p1', 'web-p2') }[$Environment]

function Invoke-WithRetry {
    param([scriptblock]$Action, [int]$Attempts = $Retries)
    for ($i = 1; $i -le $Attempts; $i++) {
        try { return & $Action }
        catch {
            Write-Warning "Attempt $i of $Attempts failed: $($_.Exception.Message)"
            Start-Sleep -Seconds ([math]::Pow(2, $i))
        }
    }
    throw "Giving up after $Attempts attempts"
}

if (-not $SkipTests) {
    Write-Host "Running tests in $root ..." -ForegroundColor Cyan
    dotnet test "$root/tests" --no-build
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$archive = Join-Path $env:TEMP "storefront-$(Get-Date -Format 'yyyyMMdd-HHmm').zip"
Get-ChildItem -Path "$root/dist" -Recurse |
    Where-Object { $_.Length -gt 0 -and $_.Extension -notin '.map', '.pdb' } |
    Compress-Archive -DestinationPath $archive -Force

$size = (Get-Item $archive).Length / 1MB
Write-Host ("Archive: {0} ({1:N1} MB)" -f $archive, $size)

foreach ($server in $servers) {
    Invoke-WithRetry { Copy-Item $archive "\\$server\deploy$\" -Force }
    Write-Host "✔ Deployed to $server" -ForegroundColor Green
}

$summary = @"
Environment: $Environment
Servers:     $($servers -join ', ')
Finished:    $(Get-Date)
"@
Write-Output $summary
