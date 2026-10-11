# Build BetterSEQTALearn.ipa via WSL xtool (output: dist\BetterSEQTALearn.ipa).
param(
  [string] $WslDistro = 'Ubuntu-24.04'
)

$build = '/mnt/c/Users/Aden/Documents/BetterSEQTA-Learn-IOS/scripts/build-ipa.sh'
wsl -d $WslDistro -- bash -lc "$build"
exit $LASTEXITCODE
