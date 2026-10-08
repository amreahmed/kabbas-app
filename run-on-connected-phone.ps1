param([string]$DeviceAddress = '', [string]$DeviceId = '')
. (Join-Path $PSScriptRoot 'scripts/environment.ps1')
if ($DeviceAddress) {
    $adb = Get-AndroidTool 'platform-tools/adb.exe'
    & $adb connect $DeviceAddress
    if ($LASTEXITCODE -ne 0) { throw 'Device connection failed.' }
}
Push-Location $projectRoot
try {
    $deviceArgs = @()
    if ($DeviceId) { $deviceArgs = @('-d', $DeviceId) }
    & $flutter run @deviceArgs
    if ($LASTEXITCODE -ne 0) { throw 'Flutter run failed.' }
} finally { Pop-Location }
