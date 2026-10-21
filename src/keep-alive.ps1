# keep-alive.ps1 - keeps the API and Admin Portal running.
# Registered in the Startup folder so it is detached from any terminal.
# Every 5s it restarts either process if it has gone away.
$ErrorActionPreference = 'SilentlyContinue'

$log = Join-Path $env:TEMP 'insurance-keepalive.log'
function Log($m) {
    try { Add-Content -Path $log -Value ("{0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), $m) } catch {}
}

# Single instance only. Take over if the previous holder died (abandoned mutex).
$mutex = New-Object System.Threading.Mutex($false, 'Global\InsurancePlatformKeepAlive')
try {
    if (-not $mutex.WaitOne(0)) { exit }
} catch [System.Threading.AbandonedMutexException] {
    Log 'previous keep-alive died; taking over'
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$state = @{
    'InsurancePlatform.Api'         = @{ Dir = (Join-Path $root 'InsurancePlatform.Api');         Proc = $null; At = $null }
    'InsurancePlatform.AdminPortal' = @{ Dir = (Join-Path $root 'InsurancePlatform.AdminPortal'); Proc = $null; At = $null }
}

function Ensure($name) {
    $s = $state[$name]
    if (Get-Process -Name $name -ErrorAction SilentlyContinue) { $s.Proc = $null; $s.At = $null; return }

    if ($s.Proc -and -not $s.Proc.HasExited) {
        # A starter is still alive but the app never appeared. Give it 45s, then replace it.
        if ($s.At -and ((Get-Date) - $s.At).TotalSeconds -gt 45) {
            try { $s.Proc.Kill() } catch {}
            Log "killed stuck starter for $name (dotnet pid $($s.Proc.Id))"
            $s.Proc = $null; $s.At = $null
        }
        return
    }

    $p = Start-Process -FilePath 'dotnet' `
        -ArgumentList 'run', '--launch-profile', 'http', '--no-build' `
        -WorkingDirectory $s.Dir -WindowStyle Hidden -PassThru
    $s.Proc = $p; $s.At = Get-Date
    Log "started $name (dotnet pid $($p.Id))"
}

Log 'keep-alive started'
while ($true) {
    Ensure 'InsurancePlatform.Api'
    Ensure 'InsurancePlatform.AdminPortal'
    Start-Sleep -Seconds 5
}
