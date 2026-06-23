# Installs D6 GIF Keys plugin for Fifine D6 / StreamDock
# Usage: .\install.ps1           - copy only
#        .\install.ps1 -Restart  - copy and restart fifine Control Deck

param([switch]$Restart)

$ErrorActionPreference = "Stop"

$PluginName = "com.rkfsociety.d6gifkeys.sdPlugin"
$LegacyNames = @(
    "com.fifine.d6.starter.sdPlugin",
    "com.fifine.d6.gifkeys.sdPlugin"
)
$Source = Join-Path $PSScriptRoot $PluginName
$TargetDir = Join-Path $env:APPDATA "HotSpot\StreamDock\plugins"
$Target = Join-Path $TargetDir $PluginName
$FifineExe = "C:\Program Files (x86)\fifine Control Deck\fifine Control Deck.exe"

if (-not (Test-Path $Source)) {
    Write-Error "Plugin folder not found: $Source"
}

if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

foreach ($legacy in $LegacyNames) {
    $legacyPath = Join-Path $TargetDir $legacy
    if (Test-Path $legacyPath) {
        Write-Host "Removing legacy plugin ($legacy)..."
        Remove-Item -Recurse -Force $legacyPath
    }
}

if (Test-Path $Target) {
    Write-Host "Removing previous version..."
    Remove-Item -Recurse -Force $Target
}

Write-Host "Copying $PluginName -> $Target"
Copy-Item -Recurse -Force $Source $Target

if ($Restart) {
    $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "*fifine Control Deck*" }
    if ($procs) {
        Write-Host "Restarting fifine Control Deck..."
        $procs | Stop-Process -Force
        Start-Sleep -Seconds 2
    }
    if (Test-Path $FifineExe) {
        Start-Process -FilePath $FifineExe -ArgumentList "--RunInBackground"
        Write-Host "fifine Control Deck started."
    }
} else {
    Write-Host "Restart fifine Control Deck manually to load the update (or use -Restart)."
}

Write-Host ""
Write-Host "Done. Category: D6 GIF Keys (ru: GIF-klyuchi D6)"
