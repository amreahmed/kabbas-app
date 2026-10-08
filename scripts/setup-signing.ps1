. (Join-Path $PSScriptRoot 'environment.ps1')
$project = $projectRoot
$keysFile = Join-Path $project 'android/key.properties'
$keystoreFile = Join-Path $project 'android/upload-keystore.jks'
if ((Test-Path -LiteralPath $keysFile) -or (Test-Path -LiteralPath $keystoreFile)) {
    throw 'Signing material already exists. It will not be overwritten.'
}
$keytool = Get-JavaTool 'keytool'
$env:KABBAS_UPLOAD_PASSWORD = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
try {
    & $keytool -genkeypair -v -keystore $keystoreFile -storetype JKS -alias upload -keyalg RSA -keysize 3072 -validity 10000 -dname 'CN=Kabbas, OU=Android, O=Kabbas, C=EG' -storepass:env KABBAS_UPLOAD_PASSWORD -keypass:env KABBAS_UPLOAD_PASSWORD
    if ($LASTEXITCODE -ne 0) { throw 'Upload key generation failed.' }
    @("storePassword=$env:KABBAS_UPLOAD_PASSWORD", "keyPassword=$env:KABBAS_UPLOAD_PASSWORD", 'keyAlias=upload', 'storeFile=upload-keystore.jks') | Set-Content -LiteralPath $keysFile
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    & icacls $keysFile /inheritance:r /grant:r "${identity}:(F)" | Out-Null
    & icacls $keystoreFile /inheritance:r /grant:r "${identity}:(F)" | Out-Null
    & $keytool -exportcert -rfc -keystore $keystoreFile -alias upload -storepass:env KABBAS_UPLOAD_PASSWORD -file (Join-Path $project 'android/upload-certificate.pem')
    if ($LASTEXITCODE -ne 0) { throw 'Certificate export failed.' }
    Write-Host 'Upload key created. Back up android/key.properties and android/upload-keystore.jks securely.'
} finally { Remove-Item Env:KABBAS_UPLOAD_PASSWORD }
