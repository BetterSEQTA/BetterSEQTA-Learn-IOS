#Requires -RunAsAdministrator
param(
  [Parameter(Mandatory = $true)]
  [string] $BusId,
  [string] $WslDistro = 'Ubuntu-24.04'
)

$usbipd = Join-Path ${env:ProgramFiles} 'usbipd-win\usbipd.exe'
if (-not (Test-Path $usbipd)) {
  Write-Error 'usbipd-win not found.'
  exit 1
}

Write-Host 'Tip: Quit Apple Devices, iTunes, 3uTools, and any app using the iPhone on Windows.'
Write-Host ''

Write-Host "Detaching BUSID $BusId (if already attached)..."
& $usbipd detach --busid $BusId 2>$null

Write-Host "Binding with --force (Windows releases the device for WSL)..."
& $usbipd bind --busid $BusId --force
if ($LASTEXITCODE -ne 0) {
  Write-Host 'bind --force failed; trying unbind then bind --force...'
  & $usbipd unbind --busid $BusId
  & $usbipd bind --busid $BusId --force
  if ($LASTEXITCODE -ne 0) {
    Write-Host 'bind failed. Close apps using the iPhone and unplug/replug the cable.'
    exit $LASTEXITCODE
  }
}

Write-Host "Attaching to WSL ($WslDistro)..."
$attachResult = & $usbipd attach --wsl $WslDistro --busid $BusId 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -and $attachResult -notmatch 'already attached') {
  Write-Host $attachResult.Trim()
  Write-Host 'attach failed. Try: unplug iPhone 5s, plug back in, run this script again.'
  & $usbipd list
  exit $LASTEXITCODE
}

Write-Host 'USB passthrough OK. You can close this window.'
