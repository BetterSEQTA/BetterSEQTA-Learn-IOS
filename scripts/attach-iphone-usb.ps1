# USB passthrough: iPhone -> WSL for xtool --usb. First attach per boot needs Admin bind (UAC).
param(
  [string] $WslDistro = 'Ubuntu-24.04',
  [switch] $NoElevate
)

function Show-DeployHint {
  param([string] $Distro)
  $deploy = '/mnt/c/Users/Aden/Documents/BetterSEQTA-Learn-IOS/scripts/deploy-iphone.sh'
  Write-Host ''
  Write-Host 'Verify in WSL:'
  Write-Host "  wsl -d $Distro -- xtool devices"
  Write-Host 'Deploy:'
  Write-Host "  wsl -d $Distro -- bash $deploy"
}

function Test-IphoneUsbAttached {
  param([string] $ListLine)
  return ($ListLine -match '\sAttached(\s|$)')
}

$usbipd = Join-Path ${env:ProgramFiles} 'usbipd-win\usbipd.exe'
if (-not (Test-Path $usbipd)) {
  Write-Error 'usbipd-win not found. Install: winget install dorssel.usbipd-win'
  exit 1
}

$line = & $usbipd list | Select-String 'Apple Mobile Device'
if (-not $line) {
  Write-Error 'No Apple device on USB. Unlock iPhone and trust this PC.'
  exit 1
}

$busid = ($line.Line -split '\s+')[0]
Write-Host "iPhone BUSID: $busid"

if (Test-IphoneUsbAttached -ListLine $line.Line) {
  Write-Host 'Already attached to WSL (no action needed).'
  Show-DeployHint -Distro $WslDistro
  exit 0
}

$attachResult = & $usbipd attach --wsl $WslDistro --busid $busid 2>&1 | Out-String
if ($LASTEXITCODE -eq 0 -or $attachResult -match 'already attached') {
  Show-DeployHint -Distro $WslDistro
  exit 0
}

Write-Host $attachResult.Trim()
Write-Host 'Attach failed (device usually not shared yet, or held by Windows).'

if ($NoElevate) {
  Write-Host 'Run elevated script (bind --force required for iPhone on Windows):'
  Write-Host "  Start-Process powershell -Verb RunAs -ArgumentList '-File','$PSScriptRoot\attach-iphone-usb-elevated.ps1','-BusId','$busid'"
  exit 1
}

$elevated = Join-Path $PSScriptRoot 'attach-iphone-usb-elevated.ps1'
Write-Host 'Opening elevated window for bind + attach (approve UAC)...'
$proc = Start-Process powershell.exe -Verb RunAs -Wait -PassThru -ArgumentList @(
  '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $elevated,
  '-BusId', $busid, '-WslDistro', $WslDistro
)

$lineAfter = & $usbipd list | Select-String 'Apple Mobile Device'
if ($lineAfter -and (Test-IphoneUsbAttached -ListLine $lineAfter.Line)) {
  Show-DeployHint -Distro $WslDistro
  exit 0
}

if ($proc.ExitCode -ne 0) {
  Write-Host "Elevated step exited with code $($proc.ExitCode)."
  exit $proc.ExitCode
}

Show-DeployHint -Distro $WslDistro
exit 0
