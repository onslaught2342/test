$ErrorActionPreference = "Stop"

$BaseDir = Join-Path $env:LOCALAPPDATA "DevSetup"
$WallpaperPath = Join-Path $BaseDir "wallpaper.png"

New-Item -ItemType Directory -Path $BaseDir -Force | Out-Null

Write-Host ""
Write-Host "=============================="
Write-Host "      Wallpaper Installer"
Write-Host "=============================="
Write-Host ""
Write-Host "1. Python"
Write-Host "2. Scratch"
Write-Host ""

do {
    $Choice = Read-Host "Select wallpaper (1 or 2)"
} while ($Choice -notin @("1", "2"))

if ($Choice -eq "1") {
    $WallpaperURL = "https://setup-567.pages.dev/wallpaper/python.png"
    Write-Host "Selected: Python"
} else {
    $WallpaperURL = "https://setup-567.pages.dev/wallpaper/scratch.png"
    Write-Host "Selected: Scratch"
}

Write-Host ""
Write-Host "Downloading wallpaper..."

Invoke-WebRequest `
    -Uri $WallpaperURL `
    -OutFile $WallpaperPath

Add-Type @"
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int SystemParametersInfo(
        int uAction,
        int uParam,
        string lpvParam,
        int fuWinIni
    );
}
"@

Write-Host "Setting wallpaper..."

$result = [Wallpaper]::SystemParametersInfo(
    20,
    0,
    $WallpaperPath,
    3
)

if ($result -eq 0) {
    Write-Host "Failed to set wallpaper."
    exit 1
}

Write-Host ""
Write-Host "Wallpaper set successfully."
Write-Host "File: $WallpaperPath"
Write-Host ""

Pause
