# Build + install BetterSEQTA Learn on USB-attached iPhone (WSL xtool).
param(
  [string] $WslDistro = 'Ubuntu-24.04'
)

$deploy = '/mnt/c/Users/Aden/Documents/BetterSEQTA-Learn-IOS/scripts/deploy-iphone.sh'
wsl -d $WslDistro -- bash -lc "$deploy"
exit $LASTEXITCODE
