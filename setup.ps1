$ErrorActionPreference = "Stop"

$BaseDir = Join-Path $env:LOCALAPPDATA "DevSetup"
$PythonInstaller = Join-Path $BaseDir "python-installer.exe"
$VSCodeInstaller = Join-Path $BaseDir "vscode-installer.exe"
$WallpaperPath = Join-Path $BaseDir "python-wallpaper.png"

New-Item -ItemType Directory -Path $BaseDir -Force | Out-Null

$PythonVersion = "3.14.7"
$PythonURL = "https://www.python.org/ftp/python/$PythonVersion/python-$PythonVersion-amd64.exe"

Write-Host "Downloading Python $PythonVersion..."
Invoke-WebRequest -Uri $PythonURL -OutFile $PythonInstaller

Write-Host "Installing Python..."
Start-Process `
    -FilePath $PythonInstaller `
    -ArgumentList "/quiet","InstallAllUsers=0","PrependPath=1","Include_pip=1","Include_test=0","Include_launcher=0" `
    -Wait

$PythonPath = "$env:LOCALAPPDATA\Programs\Python\Python314"
$Python = Join-Path $PythonPath "python.exe"

$env:PATH = "$PythonPath;$PythonPath\Scripts;$env:PATH"

Write-Host "Python version:"
& $Python --version

Write-Host "Downloading VS Code..."
$VSCodeURL = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
Invoke-WebRequest -Uri $VSCodeURL -OutFile $VSCodeInstaller

Write-Host "Installing VS Code..."
Start-Process `
    -FilePath $VSCodeInstaller `
    -ArgumentList "/VERYSILENT","/NORESTART","/MERGETASKS=!runcode" `
    -Wait

Write-Host "Upgrading pip..."
& $Python -m pip install --upgrade pip --user

Write-Host "Installing Python packages..."

$Packages = @(
    "sympy",
    "openpyxl",
    "xlsxwriter",
    "pyarrow",
    "tabulate",
    "rich",
    "sortedcontainers",
    "matplotlib",
    "pandas",
    "numpy"
)

& $Python -m pip install --user $Packages

Write-Host "Downloading wallpaper..."

$WallpaperURL = "https://setup-567.pages.dev/wallpaper/python.png"

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

[Wallpaper]::SystemParametersInfo(20, 0, $WallpaperPath, 3) | Out-Null

Write-Host ""
Write-Host "========================================"
Write-Host "Installation Complete"
Write-Host "========================================"
Write-Host ""

Write-Host "Python:"
& $Python --version

Write-Host ""
Write-Host "pip:"
& $Python -m pip --version

Write-Host ""
Write-Host "Installed packages:"
& $Python -m pip list

Write-Host ""
Write-Host "VS Code:"
$VSCodePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"

if (Test-Path $VSCodePath) {
    Write-Host "Installed successfully."
} else {
    Write-Host "VS Code executable not found."
}

Write-Host ""
Write-Host "Wallpaper:"
if (Test-Path $WallpaperPath) {
    Write-Host "Set successfully."
} else {
    Write-Host "Wallpaper file not found."
}

Write-Host ""
Write-Host "Setup finished."
Pause