# run-local.ps1 - one-command local launcher with self-healing.
#   * ensures the cloudflared quick tunnel is running and reads its public URL
#   * writes that URL into appsettings.Development.json (Mpesa:CallbackUrl)
#   * opens an auto-restarting window for the API and for the Admin Portal
# Keep the two windows open. If a process dies it comes back within ~3s.
$ErrorActionPreference = 'Stop'
$root   = Split-Path -Parent $MyInvocation.MyCommand.Path
$config = Join-Path $root 'InsurancePlatform.Api\appsettings.Development.json'
$cf     = Join-Path $env:TEMP 'cloudflared.exe'
$cfLog  = Join-Path $env:TEMP 'cloudflared.log'

# 0. Stop any stale instances so ports 5044/5150 are free.
foreach ($n in @('InsurancePlatform.Api','InsurancePlatform.AdminPortal')) {
    Get-Process -Name $n -ErrorAction SilentlyContinue | Stop-Process -Force
}
Start-Sleep -Seconds 2

# 1. Ensure the tunnel is up.
if (-not (Get-Process cloudflared -ErrorAction SilentlyContinue)) {
    if (-not (Test-Path $cf)) { Write-Host "cloudflared not found at $cf"; exit 1 }
    if (Test-Path $cfLog) { Remove-Item $cfLog -Force }
    Start-Process -FilePath $cf -ArgumentList @('tunnel','--url','http://localhost:5044','--no-autoupdate') -RedirectStandardError $cfLog -WindowStyle Hidden
}

# 2. Read the public URL from the tunnel log.
$url = $null
for ($i = 0; $i -lt 40 -and -not $url; $i++) {
    Start-Sleep -Seconds 1
    if (Test-Path $cfLog) {
        $m = [regex]::Match((Get-Content $cfLog -Raw), 'https://[a-z0-9-]+\.trycloudflare\.com')
        if ($m.Success) { $url = $m.Value }
    }
}
if (-not $url) { Write-Host 'Could not determine the tunnel URL. Is cloudflared working?'; exit 1 }
Write-Host "Tunnel URL: $url"

# 3. Point Mpesa:CallbackUrl at the tunnel (targeted replace, keeps file format).
$want = "$url/api/mpesa/callback/stk"
$raw  = Get-Content $config -Raw
$new  = [regex]::Replace($raw, '("CallbackUrl"\s*:\s*")[^"]*(")', ('${1}' + $want + '${2}'))
if ($new -ne $raw) { Set-Content -Path $config -Value $new -NoNewline; Write-Host "CallbackUrl -> $want" }
else { Write-Host "CallbackUrl already correct" }

# 4. Launch the auto-restarting windows.
Start-Process -FilePath 'cmd.exe' -ArgumentList '/k', "`"$root\dev-api.cmd`""
Start-Sleep -Seconds 12
Start-Process -FilePath 'cmd.exe' -ArgumentList '/k', "`"$root\dev-portal.cmd`""
Write-Host 'Launched API + Portal (auto-restart). Keep both windows open.'
Write-Host "Portal: http://localhost:5150   API: http://localhost:5044/health"
