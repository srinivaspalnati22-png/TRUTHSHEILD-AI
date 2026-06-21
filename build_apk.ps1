$ErrorActionPreference = "Stop"

$FlutterZipUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.0-stable.zip"
$FlutterZipPath = "C:\src\flutter.zip"
$FlutterExtractPath = "C:\src"
$FlutterBinPath = "C:\src\flutter\bin"

Write-Host "Starting Build Setup..."

if (!(Test-Path "C:\src")) {
    New-Item -ItemType Directory -Force -Path "C:\src" | Out-Null
}

if (!(Test-Path $FlutterBinPath)) {
    Write-Host "Downloading Flutter (Fast Mode)..."
    $webclient = New-Object System.Net.WebClient
    $webclient.DownloadFile($FlutterZipUrl, $FlutterZipPath)
    Write-Host "Extracting Flutter..."
    Expand-Archive -Path $FlutterZipPath -DestinationPath $FlutterExtractPath -Force
    Remove-Item -Path $FlutterZipPath -Force
} else {
    Write-Host "Flutter is already downloaded."
}

$env:Path += ";" + $FlutterBinPath

Write-Host "Running flutter pub get..."
flutter pub get

Write-Host "Building APK..."
flutter build apk --release

Write-Host "Done!"
