param([string]$DeviceId = '')
. (Join-Path $PSScriptRoot 'scripts/environment.ps1')
& (Join-Path $PSScriptRoot 'build-release-apk.ps1')
$adb = Get-AndroidTool 'platform-tools/adb.exe'
$deviceArgs = @()
if ($DeviceId) { $deviceArgs = @('-s', $DeviceId) }
& $adb @deviceArgs install -r (Join-Path $projectRoot 'build/app/outputs/flutter-apk/app-release.apk')
if ($LASTEXITCODE -ne 0) { throw 'Installation failed. Connect one device or pass -DeviceId.' }
& $adb @deviceArgs shell am start -n 'com.kabbas.app/.MainActivity'
if ($LASTEXITCODE -ne 0) { throw 'App launch failed.' }
