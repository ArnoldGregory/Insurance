# keep-alive.ps1 - keeps the API and Admin Portal running.
# Registered as a Windows Scheduled Task (at logon) so it is fully detached
# from any terminal. Every 5s it starts either process again if it is gone.
$ErrorActionPreference = 'SilentlyContinue'

# Single instance only.
$mutex = New-Object System.Threading.Mutex($false, 'Global\InsurancePlatformKeepAlive')
if (-not $mutex.WaitOne(0)) { exit }

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$apiDir = Join-Path $root 'InsurancePlatform.Api'
$portalDir = Join-Path $root 'InsurancePlatform.AdminPortal'

function Ensure($name, $dir) {
    if (-not (Get-Process -Name $name -ErrorAction SilentlyContinue)) {
        Start-Process -FilePath 'dotnet' `
            -ArgumentList 'run', '--launch-profile', 'http', '--no-build' `
            -WorkingDirectory $dir -WindowStyle Hidden
    }
}

while ($true) {
    Ensure 'InsurancePlatform.Api' $apiDir
    Ensure 'InsurancePlatform.AdminPortal' $portalDir
    Start-Sleep -Seconds 5
}
