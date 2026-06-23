# Package D6 GIF Keys for Space Platform / manual install

param(
    [switch]$Install
)

$ErrorActionPreference = "Stop"

$Root = $PSScriptRoot
$PluginFolder = "com.rkfsociety.d6gifkeys.sdPlugin"
$Source = Join-Path $Root $PluginFolder
$DistDir = Join-Path $Root "dist"
$ZipName = "$PluginFolder.zip"
$ZipPath = Join-Path $DistDir $ZipName

if (-not (Test-Path $Source)) {
    Write-Error "Plugin folder not found: $Source"
}

$manifestPath = Join-Path $Source "manifest.json"
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$version = $manifest.Version
Write-Host "Packaging D6 GIF Keys v$version"

$requiredIcons = @(
    @{ Path = "static/icon.png"; Size = 128 },
    @{ Path = "static/category.png"; Size = 48 }
)

Add-Type -AssemblyName System.Drawing
foreach ($item in $requiredIcons) {
    $path = Join-Path $Source $item.Path
    if (-not (Test-Path $path)) {
        Write-Error "Missing icon: $($item.Path)"
    }
    $img = [System.Drawing.Image]::FromFile($path)
    if ($img.Width -ne $item.Size -or $img.Height -ne $item.Size) {
        $img.Dispose()
        Write-Error "Invalid icon size for $($item.Path): expected $($item.Size)x$($item.Size)"
    }
    $img.Dispose()
}

if (Test-Path $DistDir) {
    Remove-Item $DistDir -Recurse -Force
}
New-Item -ItemType Directory -Path $DistDir | Out-Null

$staging = Join-Path $DistDir $PluginFolder
Copy-Item -Recurse -Force $Source $staging

Compress-Archive -Path $staging -DestinationPath $ZipPath -Force
Remove-Item $staging -Recurse -Force

$sizeKb = [math]::Round((Get-Item $ZipPath).Length / 1KB, 1)
Write-Host ""
Write-Host "Ready: $ZipPath ($sizeKb KB)"
Write-Host "Upload this zip to https://space.key123.vip/"
Write-Host "See STORE.md for the submission checklist."

if ($Install) {
    & (Join-Path $Root "install.ps1")
}
