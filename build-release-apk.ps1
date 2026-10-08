. (Join-Path $PSScriptRoot 'scripts/environment.ps1')
Push-Location $projectRoot
try {
    & $flutter build apk --release
    if ($LASTEXITCODE -ne 0) { throw 'Release APK build failed.' }
    Write-Host 'APK: build/app/outputs/flutter-apk/app-release.apk'
} finally { Pop-Location }
