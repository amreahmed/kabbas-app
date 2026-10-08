# Shared tool discovery. Optional machine settings stay outside version control.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$localSettings = Join-Path $PSScriptRoot 'local-settings.ps1'
if (Test-Path -LiteralPath $localSettings) { . $localSettings }
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if ($env:FLUTTER_ROOT -and (Test-Path (Join-Path $env:FLUTTER_ROOT 'bin/flutter.bat'))) {
    $flutter = Join-Path $env:FLUTTER_ROOT 'bin/flutter.bat'
} elseif (Test-Path (Join-Path $projectRoot '.tools/flutter/bin/flutter.bat')) {
    $flutter = Join-Path $projectRoot '.tools/flutter/bin/flutter.bat'
} elseif ($flutterCommand) {
    $flutter = $flutterCommand.Source
} else { throw 'Install Flutter and add its bin directory to PATH, or set FLUTTER_ROOT.' }
if (!$env:ANDROID_HOME -and $env:ANDROID_SDK_ROOT) { $env:ANDROID_HOME = $env:ANDROID_SDK_ROOT }
if ($env:JAVA_HOME) { $env:PATH = "$(Join-Path $env:JAVA_HOME 'bin');$env:PATH" }

function Get-JavaTool([string]$Name) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if (!$command) { throw "Install a JDK and set JAVA_HOME or add $Name to PATH." }
    return $command.Source
}

function Get-AndroidTool([string]$RelativePath) {
    if (!$env:ANDROID_HOME) { throw 'Set ANDROID_HOME to your Android SDK directory.' }
    $path = Join-Path $env:ANDROID_HOME $RelativePath
    if (!(Test-Path -LiteralPath $path)) { throw "Android tool missing: $path" }
    return $path
}
