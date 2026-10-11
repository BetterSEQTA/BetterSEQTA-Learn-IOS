# Return iPhone USB to Windows (detach from WSL). Admin only if device was bound with --force.
param(
  [string] $WslDistro = 'Ubuntu-24.04'
)

$usbipd = Join-Path ${env:ProgramFiles} 'usbipd-win\usbipd.exe'
$line = & $usbipd list | Select-String 'Apple Mobile Device'
if (-not $line) {
  Write-Host 'No Apple device listed.'
  exit 0
}

$busid = ($line.Line -split '\s+')[0]
Write-Host "Detaching BUSID $busid..."
& $usbipd detach --busid $busid
Write-Host 'Done. Use attach-iphone-usb.ps1 to pass through to WSL again.'
