# keep-alive.ps1 - keeps the API, Admin Portal and the M-Pesa callback tunnel running.
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

# ---------------------------------------------------------------------------
# M-Pesa callback tunnel. A dead tunnel is not cosmetic: Safaricom POSTs the
# STK result to the CallBackURL we hand it, so a dead one means the customer
# is charged and the result never lands, leaving the payment PENDING forever.
# A quick tunnel also gets a new random hostname on every restart, so the URL
# in the config goes stale. Both halves are handled here: the tunnel is
# restarted if it dies, and the live URL is written into the development
# config (and the API bounced) so the two can never disagree.
#
# NOTE: Daraja rejects trycloudflare.com callback URLs outright
# (400.002.02 "Threat Detected"), so a push made from this machine is refused
# by Daraja before the customer is ever charged. The live payment test has to
# run against the deployed API, which has a real public callback URL.
# ---------------------------------------------------------------------------
$tunnelDir = Join-Path $env:LOCALAPPDATA 'InsurancePlatform'
$tunnelExe = Join-Path $tunnelDir 'cloudflared.exe'
$tunnelLog = Join-Path $tunnelDir 'tunnel.log'
$devConfig = Join-Path $root 'InsurancePlatform.Api\appsettings.Development.json'
$tunnelUrl = $null

function Read-TunnelUrl {
    if (-not (Test-Path $tunnelLog)) { return $null }
    $raw = Get-Content $tunnelLog -Raw -ErrorAction SilentlyContinue
    if (-not $raw) { return $null }
    $m = [regex]::Matches($raw, 'https://[a-z0-9][a-z0-9-]*\.trycloudflare\.com')
    if ($m.Count -eq 0) { return $null }
    return $m[0].Value
}

function Set-ConfigCallbackUrl([string]$url) {
    if (-not (Test-Path $devConfig)) { return }
    $target = $url + '/api/mpesa/callback/stk'
    $raw = Get-Content $devConfig -Raw
    if ($raw -match [regex]::Escape($target)) { return }
    $updated = [regex]::Replace($raw, '("CallbackUrl"\s*:\s*")[^"]*(")', "`$1$target`$2")
    if ($updated -eq $raw) { return }
    try {
        # no BOM, no trailing newline - the file is byte-for-byte what the app already reads
        [System.IO.File]::WriteAllText($devConfig, $updated, (New-Object System.Text.UTF8Encoding($false)))
        Log "tunnel url changed -> wrote $target into appsettings.Development.json; restarting the API"
        Get-Process -Name 'InsurancePlatform.Api' -ErrorAction SilentlyContinue | ForEach-Object { try { $_.Kill() } catch {} }
    } catch {
        Log "failed to write the new callback url: $($_.Exception.Message)"
    }
}

function Ensure-Tunnel {
    $proc = Get-Process -Name 'cloudflared' -ErrorAction SilentlyContinue
    if (-not $proc) {
        if (-not (Test-Path $tunnelExe)) {
            $fallback = Join-Path $env:TEMP 'cloudflared.exe'
            if (Test-Path $fallback) {
                try {
                    New-Item -ItemType Directory -Path $tunnelDir -Force | Out-Null
                    Copy-Item $fallback $tunnelExe -Force
                    Log "copied cloudflared.exe to $tunnelExe"
                } catch {}
            }
        }
        if (-not (Test-Path $tunnelExe)) { return }
        if (Test-Path $tunnelLog) { Remove-Item $tunnelLog -Force -ErrorAction SilentlyContinue }
        $p = Start-Process -FilePath $tunnelExe `
            -ArgumentList 'tunnel', '--no-autoupdate', '--url', 'http://localhost:5044', '--logfile', $tunnelLog `
            -WindowStyle Hidden -PassThru
        Log "started the callback tunnel (cloudflared pid $($p.Id))"
        Start-Sleep -Seconds 8
        return
    }

    $url = Read-TunnelUrl
    if ($url -and $url -ne $script:tunnelUrl) {
        $script:tunnelUrl = $url
        Log "callback tunnel is live at $url"
        Set-ConfigCallbackUrl $url
    }
}

Log 'keep-alive started'
while ($true) {
    Ensure 'InsurancePlatform.Api'
    Ensure 'InsurancePlatform.AdminPortal'
    Ensure-Tunnel
    Start-Sleep -Seconds 5
}
