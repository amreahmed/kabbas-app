. (Join-Path $PSScriptRoot 'scripts/environment.ps1')
Push-Location $projectRoot
try {
    if (!(Test-Path android/app/google-services.json)) { throw 'Configure your Firebase Android app first. See README.md.' }
    $config = Get-Content android/app/google-services.json -Raw | ConvertFrom-Json
    if ('com.kabbas.app' -notin $config.client.client_info.android_client_info.package_name) {
        throw 'Firebase configuration does not match com.kabbas.app.'
    }
    if (!(Test-Path android/key.properties)) { throw 'Configure release signing first. See PLAY_RELEASE.md.' }
    & $flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'Static analysis failed.' }
    & $flutter test
    if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
    & $flutter build appbundle --release
    if ($LASTEXITCODE -ne 0) { throw 'Release bundle build failed.' }
    Write-Host 'Bundle: build/app/outputs/bundle/release/app-release.aab'
} finally { Pop-Location }
