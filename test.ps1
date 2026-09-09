#requires -Version 5.1

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# ============================================================
# PYTHON 3.14.7 - NON-ADMIN INSTALLER
#
# Run:
#
#   irm https://YOUR-URL/install-python.ps1 | iex
#
# NO ADMIN REQUIRED
#
# Installs for CURRENT USER only.
#
# ============================================================

$PythonVersion = "3.14.7"

$Packages = @(
    "sympy",
    "openpyxl",
    "XlsxWriter",
    "pyarrow",
    "tabulate",
    "sortedcontainers",
    "matplotlib",
    "pandas",
    "numpy"
)

# ============================================================
# Helpers
# ============================================================

function Step {
    param([string]$Message)

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor DarkGray
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor DarkGray
}

function OK {
    param([string]$Message)

    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Warn {
    param([string]$Message)

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Fail {
    param([string]$Message)

    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Refresh-Path {

    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $MachinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")

    if ([string]::IsNullOrWhiteSpace($UserPath)) {
        $UserPath = ""
    }

    if ([string]::IsNullOrWhiteSpace($MachinePath)) {
        $MachinePath = ""
    }

    $env:Path = "$UserPath;$MachinePath"

    # Common WindowsApps location
    $WindowsApps = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps"

    if (Test-Path $WindowsApps) {
        if ($env:Path -notlike "*$WindowsApps*") {
            $env:Path = "$WindowsApps;$env:Path"
        }
    }
}

function Add-UserPath {
    param([string]$PathToAdd)

    if ([string]::IsNullOrWhiteSpace($PathToAdd)) {
        return
    }

    if (-not (Test-Path $PathToAdd)) {
        return
    }

    $Current = [Environment]::GetEnvironmentVariable("Path", "User")

    if ([string]::IsNullOrWhiteSpace($Current)) {
        $Current = ""
    }

    $Entries = @(
        $Current -split ';' |
        Where-Object {
            -not [string]::IsNullOrWhiteSpace($_)
        }
    )

    $NormalizedTarget = $PathToAdd.TrimEnd('\')

    $Exists = $false

    foreach ($Entry in $Entries) {
        if ($Entry.TrimEnd('\') -ieq $NormalizedTarget) {
            $Exists = $true
            break
        }
    }

    if (-not $Exists) {

        if ($Entries.Count -eq 0) {
            $NewPath = $PathToAdd
        }
        else {
            $NewPath = (($Entries + $PathToAdd) -join ';')
        }

        [Environment]::SetEnvironmentVariable(
            "Path",
            $NewPath,
            "User"
        )

        Write-Host "Added to USER PATH: $PathToAdd" -ForegroundColor Green
    }
}

# ============================================================
# Check Windows
# ============================================================

Step "Checking Windows"

if ($env:OS -ne "Windows_NT") {
    throw "This script only supports Windows."
}

OK "Windows detected."

# ============================================================
# IMPORTANT: detect Administrator
#
# We do NOT fail if elevated.
# We simply warn that the script itself doesn't require it.
# ============================================================

Step "Checking execution mode"

try {

    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)

    $IsAdmin = $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    if ($IsAdmin) {
        Warn "PowerShell is currently running as Administrator."
        Warn "This script will still target the current user's installation."
    }
    else {
        OK "Running without Administrator privileges."
    }

}
catch {
    Warn "Could not determine elevation state."
}

# ============================================================
# Refresh PATH
# ============================================================

Refresh-Path

# ============================================================
# Find existing Python 3.14.7
# ============================================================

Step "Checking for existing Python $PythonVersion"

$PythonExe = $null

$Candidates = @()

# Existing python.exe
$ExistingPython = Get-Command python.exe -ErrorAction SilentlyContinue

if ($ExistingPython) {
    $Candidates += $ExistingPython.Source
}

# Common per-user installation paths
$LocalPythonRoot = Join-Path $env:LOCALAPPDATA "Programs\Python"

if (Test-Path $LocalPythonRoot) {

    $PythonDirs = Get-ChildItem `
        -Path $LocalPythonRoot `
        -Directory `
        -ErrorAction SilentlyContinue

    foreach ($Dir in $PythonDirs) {

        $Candidate = Join-Path $Dir.FullName "python.exe"

        if (Test-Path $Candidate) {
            $Candidates += $Candidate
        }
    }
}

foreach ($Candidate in ($Candidates | Select-Object -Unique)) {

    try {

        $Version = (& $Candidate --version 2>&1).ToString().Trim()

        if ($Version -eq "Python $PythonVersion") {

            $PythonExe = $Candidate
            break
        }

    }
    catch {
        # Ignore invalid candidates
    }
}

if ($PythonExe) {

    OK "Python $PythonVersion already installed:"
    Write-Host "     $PythonExe"

}
else {

    Warn "Python $PythonVersion was not found."
}

# ============================================================
# Check WinGet
# ============================================================

Step "Checking WinGet"

$Winget = Get-Command winget.exe -ErrorAction SilentlyContinue

if (-not $Winget) {

    Fail "WinGet is not available."

    throw @"
WinGet is required for the automatic installation.

Install Microsoft's App Installer / WinGet, then run this
script again.
"@
}

OK "WinGet found: $($Winget.Source)"

# ============================================================
# Install Python if necessary
# ============================================================

if (-not $PythonExe) {

    Step "Installing Python $PythonVersion for current user"

    Write-Host ""
    Write-Host "IMPORTANT:" -ForegroundColor Yellow
    Write-Host "The installer will be requested in USER scope."
    Write-Host "No system-wide Python installation will be attempted."
    Write-Host ""

    # --------------------------------------------------------
    # Python.org WinGet package
    # --------------------------------------------------------

    $InstallArgs = @(
        "install",
        "--id", "Python.Python.3.14",
        "--exact",
        "--source", "winget",
        "--scope", "user",
        "--accept-source-agreements",
        "--accept-package-agreements",
        "--disable-interactivity"
    )

    Write-Host "Running WinGet..." -ForegroundColor Cyan

    & winget.exe @InstallArgs

    $WingetExitCode = $LASTEXITCODE

    if ($WingetExitCode -ne 0) {

        Fail "WinGet failed with exit code $WingetExitCode."

        throw @"
Python could not be installed without elevation.

No Administrator prompt was intentionally triggered.

If WinGet reports that this package requires elevation,
the Windows package metadata is requiring it and this
script will not bypass that requirement.
"@
    }

    OK "WinGet installation completed."

    # --------------------------------------------------------
    # Refresh PATH
    # --------------------------------------------------------

    Refresh-Path

    # --------------------------------------------------------
    # Locate Python again
    # --------------------------------------------------------

    $PythonExe = $null

    $PythonCommand = Get-Command python.exe -ErrorAction SilentlyContinue

    if ($PythonCommand) {

        try {

            $Version = (& $PythonCommand.Source --version 2>&1).ToString().Trim()

            if ($Version -eq "Python $PythonVersion") {
                $PythonExe = $PythonCommand.Source
            }

        }
        catch {
            # Continue searching
        }
    }

    # Search common per-user Python directory
    if (-not $PythonExe -and (Test-Path $LocalPythonRoot)) {

        $PythonDirs = Get-ChildItem `
            -Path $LocalPythonRoot `
            -Directory `
            -ErrorAction SilentlyContinue

        foreach ($Dir in $PythonDirs) {

            $Candidate = Join-Path $Dir.FullName "python.exe"

            if (Test-Path $Candidate) {

                try {

                    $Version = (& $Candidate --version 2>&1).ToString().Trim()

                    if ($Version -eq "Python $PythonVersion") {

                        $PythonExe = $Candidate
                        break
                    }

                }
                catch {
                    # Continue
                }
            }
        }
    }

    if (-not $PythonExe) {
        throw "Python $PythonVersion was installed but could not be located."
    }
}

# ============================================================
# Verify exact version
# ============================================================

Step "Verifying Python"

$ActualVersion = (& $PythonExe --version 2>&1).ToString().Trim()

Write-Host "Detected: $ActualVersion"

if ($ActualVersion -ne "Python $PythonVersion") {

    throw @"
Incorrect Python version.

Expected:
    Python $PythonVersion

Detected:
    $ActualVersion
"@
}

OK "Python $PythonVersion verified."

Write-Host ""
Write-Host "Python executable:"
Write-Host "  $PythonExe"

# ============================================================
# Add Python directory to USER PATH
# ============================================================

Step "Configuring USER PATH"

$PythonDir = Split-Path -Parent $PythonExe

$PythonScripts = Join-Path $PythonDir "Scripts"

Add-UserPath $PythonDir
Add-UserPath $PythonScripts

# ============================================================
# Refresh current PowerShell PATH
# ============================================================

Refresh-Path

OK "USER PATH configured."

# ============================================================
# Verify pip
# ============================================================

Step "Checking pip"

$PipWorks = $false

try {

    & $PythonExe -m pip --version

    if ($LASTEXITCODE -eq 0) {
        $PipWorks = $true
    }

}
catch {
    $PipWorks = $false
}

if (-not $PipWorks) {

    Warn "pip is missing."

    Write-Host "Bootstrapping pip using ensurepip..." -ForegroundColor Cyan

    & $PythonExe -m ensurepip --upgrade

    if ($LASTEXITCODE -ne 0) {
        throw "ensurepip failed."
    }
}

OK "pip is available."

# ============================================================
# Upgrade pip
# ============================================================

Step "Updating pip"

& $PythonExe -m pip install --upgrade pip

if ($LASTEXITCODE -ne 0) {
    throw "pip upgrade failed."
}

OK "pip updated."

# ============================================================
# Install packages
# ============================================================

Step "Installing Python packages"

Write-Host ""

foreach ($Package in $Packages) {
    Write-Host "  $Package" -ForegroundColor Cyan
}

Write-Host ""

& $PythonExe -m pip install --upgrade @Packages

if ($LASTEXITCODE -ne 0) {
    throw "pip package installation failed."
}

OK "All packages installed."

# ============================================================
# Verify packages
# ============================================================

Step "Verifying packages"

$ImportTests = [ordered]@{
    "sympy"            = "sympy"
    "openpyxl"         = "openpyxl"
    "XlsxWriter"       = "xlsxwriter"
    "pyarrow"          = "pyarrow"
    "tabulate"         = "tabulate"
    "sortedcontainers" = "sortedcontainers"
    "matplotlib"       = "matplotlib"
    "pandas"           = "pandas"
    "numpy"            = "numpy"
}

$Failed = @()

foreach ($Package in $ImportTests.Keys) {

    $ImportName = $ImportTests[$Package]

    Write-Host ""
    Write-Host "Testing $Package..." -ForegroundColor Cyan

    try {

        & $PythonExe -c "import $ImportName; print('IMPORT_OK')" 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "Import failed."
        }

        OK "$Package works."

    }
    catch {

        Fail "$Package failed."
        $Failed += $Package
    }
}

# ============================================================
# Verify PATH commands
# ============================================================

Step "Checking PATH"

Refresh-Path

$PathPython = Get-Command python.exe -ErrorAction SilentlyContinue

if ($PathPython) {

    Write-Host "python.exe resolves to:"
    Write-Host "  $($PathPython.Source)"

}
else {

    Warn "python.exe is not visible to this PowerShell process."
    Warn "A new PowerShell window may be required."
}

# ============================================================
# Final verification
# ============================================================

Step "Final verification"

Write-Host ""
Write-Host "Python:"
& $PythonExe --version

Write-Host ""
Write-Host "pip:"
& $PythonExe -m pip --version

Write-Host ""
Write-Host "Executable:"
Write-Host "  $PythonExe"

Write-Host ""
Write-Host "Scripts:"
Write-Host "  $PythonScripts"

# ============================================================
# Fail if packages failed
# ============================================================

if ($Failed.Count -gt 0) {

    Write-Host ""

    Fail "The following packages failed verification:"

    foreach ($Package in $Failed) {
        Write-Host "  - $Package" -ForegroundColor Red
    }

    throw "Installation did not completely succeed."
}

# ============================================================
# SUCCESS
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "              INSTALLATION SUCCESSFUL" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green

Write-Host ""
Write-Host "Python $PythonVersion is ready." -ForegroundColor Green
Write-Host "pip is ready." -ForegroundColor Green
Write-Host "All requested packages imported successfully." -ForegroundColor Green

Write-Host ""
Write-Host "Installed packages:" -ForegroundColor Cyan

& $PythonExe -m pip list

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "You can now use:" -ForegroundColor Cyan
Write-Host "  python --version"
Write-Host "  python -m pip list"
Write-Host "  py -3.14 --version"
Write-Host "============================================================" -ForegroundColor Green

Write-Host ""
Write-Host "If 'python' is not recognized in another terminal, close and" -ForegroundColor Yellow
Write-Host "reopen PowerShell so it receives the updated USER PATH." -ForegroundColor Yellow
