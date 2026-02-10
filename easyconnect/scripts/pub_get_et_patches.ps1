# Script: pub_get_et_patches.ps1
# 1. Execute "flutter pub get"
# 2. Applique le correctif namespace sur flutter_app_badger (compatible Android Gradle Plugin recent)
# Utilisez ce script a la place de "flutter pub get" pour que le correctif soit toujours applique.

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $ProjectRoot

Write-Host "Execution de: flutter pub get" -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Appliquer le correctif flutter_app_badger (namespace manquant pour AGP)
$PubCache = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { Join-Path $env:LOCALAPPDATA "Pub\Cache" }
$HostedPath = Join-Path $PubCache "hosted\pub.dev"
if (-not (Test-Path $HostedPath)) {
    Write-Host "Cache Pub non trouve: $HostedPath" -ForegroundColor Yellow
    exit 0
}

$BadgerDir = Get-ChildItem -Path $HostedPath -Directory -Filter "flutter_app_badger-*" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $BadgerDir) {
    Write-Host "Package flutter_app_badger non trouve dans le cache." -ForegroundColor Yellow
    exit 0
}

$BuildGradle = Join-Path $BadgerDir.FullName "android\build.gradle"
if (-not (Test-Path $BuildGradle)) {
    Write-Host "Fichier build.gradle non trouve: $BuildGradle" -ForegroundColor Yellow
    exit 0
}

$Content = Get-Content $BuildGradle -Raw
$NamespaceLine = "namespace 'fr.g123k.flutterappbadge.flutterappbadger'"
if ($Content -match [regex]::Escape($NamespaceLine)) {
    Write-Host "Correctif flutter_app_badger deja applique." -ForegroundColor Green
    exit 0
}

# Inserer la ligne namespace apres "android {"
$Content = $Content -replace "(android \{\r?\n)(\s+compileSdkVersion)", "`$1    $NamespaceLine`r`n`$2"
Set-Content -Path $BuildGradle -Value $Content.TrimEnd() -NoNewline
Write-Host "Correctif flutter_app_badger (namespace) applique avec succes." -ForegroundColor Green
