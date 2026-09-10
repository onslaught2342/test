
$ErrorActionPreference = "Stop"

$BaseURL = "http://setup-567.pages.dev/live-wallapaper"
$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\Lively Wallpaper"
$TempDir = Join-Path $env:TEMP "LivelyInstall"
$WallpaperDir = Join-Path $env:LOCALAPPDATA "LivelyCustomWallpapers"

Write-Host ""
Write-Host "========================================"
Write-Host " Lively Wallpaper Setup"
Write-Host "========================================"
Write-Host ""

New-Item -ItemType Directory -Force -Path $TempDir | Out-Null
New-Item -ItemType Directory -Force -Path $WallpaperDir | Out-Null

if (-not (Test-Path $InstallDir)) {

    Write-Host "Lively Wallpaper is not installed."
    Write-Host "Downloading the latest release..."
    Write-Host ""

    $ReleaseApi = "https://api.github.com/repos/rocksdanister/lively/releases/latest"

    $Release = Invoke-RestMethod `
        -Uri $ReleaseApi `
        -Headers @{
            "User-Agent" = "PowerShell"
        }

    $Asset = $Release.assets |
        Where-Object {
            $_.name -match "\.exe$"
        } |
        Select-Object -First 1

    if (-not $Asset) {
        throw "Could not find the Lively installer."
    }

    $Installer = Join-Path $TempDir $Asset.name

    Write-Host "Downloading $($Asset.name)..."

    Invoke-WebRequest `
        -Uri $Asset.browser_download_url `
        -OutFile $Installer

    Write-Host ""
    Write-Host "Installing Lively..."

    $Process = Start-Process `
        -FilePath $Installer `
        -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /CURRENTUSER" `
        -Wait `
        -PassThru

    if ($Process.ExitCode -ne 0) {
        throw "Lively installer failed with exit code $($Process.ExitCode)."
    }

    Write-Host "Lively installation completed."
    Write-Host ""
}

$PossibleLivelyPaths = @(
    (Join-Path $InstallDir "Lively.exe"),
    (Join-Path $env:LOCALAPPDATA "Programs\Lively Wallpaper\Lively.exe"),
    (Join-Path $env:LOCALAPPDATA "Lively Wallpaper\Lively.exe")
)

$LivelyExe = $PossibleLivelyPaths |
    Where-Object {
        Test-Path $_
    } |
    Select-Object -First 1

if (-not $LivelyExe) {

    $LivelyExe = Get-ChildItem `
        -Path $env:LOCALAPPDATA `
        -Filter "Lively.exe" `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
}

if (-not $LivelyExe) {
    throw "Lively.exe could not be found."
}

Write-Host "Lively found:"
Write-Host $LivelyExe
Write-Host ""

Write-Host "========================================"
Write-Host " Choose Wallpaper"
Write-Host "========================================"
Write-Host ""
Write-Host "1. Python"
Write-Host "2. Scratch"
Write-Host ""

do {
    $Choice = Read-Host "Enter 1 or 2"
} until ($Choice -in @("1", "2"))

if ($Choice -eq "1") {
    $WallpaperName = "python"
} else {
    $WallpaperName = "scrath"
}

$WallpaperURL = "$BaseURL/$WallpaperName.html"
$WallpaperFile = Join-Path $WallpaperDir "$WallpaperName.html"

Write-Host ""
Write-Host "Selected: $WallpaperName"
Write-Host "Downloading wallpaper..."
Write-Host ""

Invoke-WebRequest `
    -Uri $WallpaperURL `
    -OutFile $WallpaperFile

if (-not (Test-Path $WallpaperFile)) {
    throw "Wallpaper download failed."
}

Write-Host "Wallpaper saved:"
Write-Host $WallpaperFile
Write-Host ""

Write-Host "Starting Lively..."

Start-Process `
    -FilePath $LivelyExe `
    -ArgumentList "--showApp true"

Start-Sleep -Seconds 5

Write-Host "Applying wallpaper..."

$Arguments = @(
    "setwp",
    "--file",
    "`"$WallpaperFile`""
)

Start-Process `
    -FilePath $LivelyExe `
    -ArgumentList $Arguments `
    -Wait

Remove-Item `
    $TempDir `
    -Recurse `
    -Force `
    -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "========================================"
Write-Host " Setup Complete"
Write-Host "========================================"
Write-Host ""
Write-Host "Wallpaper: $WallpaperName"
Write-Host "File:      $WallpaperFile"
Write-Host ""
Write-Host "Press Enter to exit..."
Read-Host
