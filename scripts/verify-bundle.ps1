. (Join-Path $PSScriptRoot 'environment.ps1')
$project = $projectRoot
$java = Get-JavaTool 'java'
$jarsigner = Get-JavaTool 'jarsigner'
$bundletool = if ($env:BUNDLETOOL_JAR) { $env:BUNDLETOOL_JAR } else { Join-Path $project '.tools/bundletool.jar' }
if (!(Test-Path -LiteralPath $bundletool)) { throw 'Download bundletool and set BUNDLETOOL_JAR to its .jar path.' }
$zipalign = Get-AndroidTool 'build-tools/36.0.0/zipalign.exe'
$apksigner = Get-AndroidTool 'build-tools/36.0.0/apksigner.bat'
$bundle = Join-Path $project 'build/app/outputs/bundle/release/app-release.aab'
Push-Location $project
try {
    & $java -jar $bundletool validate --bundle=$bundle
    if ($LASTEXITCODE -ne 0) { throw 'Bundle validation failed.' }
    & $java -jar $bundletool dump manifest --bundle=$bundle --module=base > .dart_tool/release-manifest.xml
    if ($LASTEXITCODE -ne 0) { throw 'Manifest extraction failed.' }
    $manifest = [xml](Get-Content .dart_tool/release-manifest.xml -Raw)
    if ($manifest.manifest.package -ne 'com.kabbas.app') { throw 'Incorrect package.' }
    $androidNamespace = 'http://schemas.android.com/apk/res/android'
    $versionMatch = [regex]::Match((Get-Content pubspec.yaml -Raw), '(?m)^version:\s*([^+\s]+)\+(\d+)')
    if (!$versionMatch.Success) { throw 'Version must include a build number.' }
    if ($manifest.manifest.GetAttribute('versionName', $androidNamespace) -ne $versionMatch.Groups[1].Value -or
        $manifest.manifest.GetAttribute('versionCode', $androidNamespace) -ne $versionMatch.Groups[2].Value) {
        throw 'Bundle version does not match pubspec.yaml.'
    }
    if ([int]$manifest.manifest.'uses-sdk'.GetAttribute('targetSdkVersion', $androidNamespace) -lt 36) {
        throw 'The release must target Android API 36 or later.'
    }
    if ($manifest.manifest.application.GetAttribute('debuggable', $androidNamespace) -eq 'true') {
        throw 'The release must not be debuggable.'
    }
    & $java -jar $bundletool dump config --bundle=$bundle > .dart_tool/bundle-config.json
    if ($LASTEXITCODE -ne 0) { throw 'Bundle configuration extraction failed.' }
    & $jarsigner -verify $bundle
    if ($LASTEXITCODE -ne 0) { throw 'Bundle signature validation failed.' }
    python scripts/check-native-alignment.py $bundle
    if ($LASTEXITCODE -ne 0) { throw 'Native alignment verification failed.' }
    $keys = Get-Content android/key.properties -Raw | ConvertFrom-StringData
    $passFile = Join-Path $project '.dart_tool/upload-key.pass'
    $keyPassFile = Join-Path $project '.dart_tool/upload-alias.pass'
    $keystore = [IO.Path]::GetFullPath((Join-Path $project "android/$($keys.storeFile)"))
    try {
        [IO.File]::WriteAllText($passFile, $keys.storePassword)
        [IO.File]::WriteAllText($keyPassFile, $keys.keyPassword)
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
        & icacls $passFile /inheritance:r /grant:r "${identity}:(F)" | Out-Null
        & icacls $keyPassFile /inheritance:r /grant:r "${identity}:(F)" | Out-Null
        & $java -jar $bundletool build-apks --bundle=$bundle --output=.dart_tool/release.apks --mode=universal --overwrite --ks=$keystore --ks-key-alias=$($keys.keyAlias) --ks-pass=file:$passFile --key-pass=file:$keyPassFile
        if ($LASTEXITCODE -ne 0) { throw 'APK generation failed.' }
    } finally { Remove-Item -LiteralPath $passFile,$keyPassFile -ErrorAction SilentlyContinue }
    python -c "import zipfile; z=zipfile.ZipFile('.dart_tool/release.apks'); z.extract('universal.apk', '.dart_tool')"
    & $zipalign -c -P 16 -v 4 .dart_tool/universal.apk > .dart_tool/apk-alignment.txt
    if ($LASTEXITCODE -ne 0) { throw 'APK ZIP alignment verification failed.' }
    & $apksigner verify --print-certs .dart_tool/universal.apk
    if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
    Write-Host 'Bundle, signatures, native segments and APK ZIP alignment verified.'
} finally { Pop-Location }
