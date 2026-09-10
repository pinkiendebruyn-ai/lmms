# LMMS Qt Setup and Build Script
# Run this in PowerShell to install Qt and build LMMS

param(
    [switch]$SkipQt,
    [switch]$Qt6
)

$ErrorActionPreference = "Stop"
$ProjectRoot = "C:\Users\Henri\Desktop\lmms_github_fork"
$BuildDir = Join-Path $ProjectRoot "build"
$QtInstallDir = "C:\Qt"

Write-Host "=== LMMS Build Script ===" -ForegroundColor Cyan

# Step 1: Check for existing Qt installation
Write-Host "`n[1/5] Checking for existing Qt installation..." -ForegroundColor Yellow

$qtPaths = @(
    "C:\Qt",
    "C:\Program Files\Qt",
    "$env:LOCALAPPDATA\Qt"
)

$foundQt = $false
$qtPrefix = $null

foreach ($path in $qtPaths) {
    if (Test-Path $path) {
        $qtDirs = Get-ChildItem -Path $path -Directory | Where-Object { $_.Name -match "^\d+\.\d+" }
        if ($qtDirs) {
            Write-Host "Found Qt installation at: $path" -ForegroundColor Green
            $qtPrefix = $qtDirs[0].FullName
            $foundQt = $true
            break
        }
    }
}

if (-not $foundQt -and -not $SkipQt) {
    Write-Host "Qt not found. Attempting to install Qt..." -ForegroundColor Yellow
    
    # Ensure aqtinstall is available
    $aqtScript = Join-Path $env:LOCALAPPDATA "Packages\PythonSoftwareFoundation.Python.3.10_qbz5n2kfra8p0\LocalCache\local-packages\Python310\Scripts\aqt.exe"
    if (-not (Test-Path $aqtScript)) {
        Write-Host "Installing aqtinstall..." -ForegroundColor Yellow
        pip install aqtinstall | Out-Null
    }
    
    $env:PATH += ";$(Split-Path $aqtScript)"
    
    # Install Qt6 (recommended for newer MSVC)
    $qtVersion = "6.8.3"
    $qtArch = "msvc2022_64"
    
    Write-Host "Downloading Qt $qtVersion for $qtArch (this may take a while)..." -ForegroundColor Yellow
    Write-Host "You may need to accept Qt's license agreement in the installer window." -ForegroundColor Yellow
    
    try {
        aqt install-qt windows desktop $qtVersion $qtArch -O $QtInstallDir
        $qtPrefix = Join-Path $QtInstallDir "$qtVersion\$qtArch"
        Write-Host "Qt installed successfully to: $qtPrefix" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install Qt via aqtinstall: $_" -ForegroundColor Red
        Write-Host "Please install Qt manually from https://www.qt.io/download" -ForegroundColor Yellow
        exit 1
    }
} elseif ($SkipQt) {
    Write-Host "Skipping Qt installation as requested." -ForegroundColor Yellow
    $qtPrefix = $env:CMAKE_PREFIX_PATH
}

if (-not $qtPrefix -or -not (Test-Path $qtPrefix)) {
    Write-Host "ERROR: Qt prefix path not set or invalid: $qtPrefix" -ForegroundColor Red
    Write-Host "Please set CMAKE_PREFIX_PATH to your Qt installation directory." -ForegroundColor Yellow
    exit 1
}

# Step 2: Create build directory
Write-Host "`n[2/5] Creating build directory..." -ForegroundColor Yellow
if (-not (Test-Path $BuildDir)) {
    New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
}
Set-Location $BuildDir

# Step 3: Configure CMake
Write-Host "`n[3/5] Configuring CMake..." -ForegroundColor Yellow

$cmakeArgs = @(
    "..",
    "-DCMAKE_BUILD_TYPE=Release",
    "-G", "Visual Studio 18 2026",
    "-DCMAKE_PREFIX_PATH=$qtPrefix"
)

if ($Qt6) {
    $cmakeArgs += "-DWANT_QT6=ON"
    Write-Host "Configuring with Qt6 support (experimental)..." -ForegroundColor Yellow
} else {
    Write-Host "Configuring with Qt5 support..." -ForegroundColor Yellow
}

$env:CMAKE_PREFIX_PATH = $qtPrefix

try {
    cmake @cmakeArgs
    Write-Host "CMake configuration successful!" -ForegroundColor Green
} catch {
    Write-Host "CMake configuration failed: $_" -ForegroundColor Red
    Write-Host "Try running with -Qt6 flag if Qt5 was not found." -ForegroundColor Yellow
    exit 1
}

# Step 4: Build
Write-Host "`n[4/5] Building LMMS (this will take a while)..." -ForegroundColor Yellow
Write-Host "Using parallel build with all available CPU cores." -ForegroundColor Yellow

try {
    cmake --build . --config Release --parallel
    Write-Host "`nBuild completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "`nBuild failed: $_" -ForegroundColor Red
    exit 1
}

# Step 5: Summary
Write-Host "`n[5/5] Build Summary" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host "Project Root: $ProjectRoot"
Write-Host "Build Directory: $BuildDir"
Write-Host "Qt Prefix: $qtPrefix"
Write-Host "Generator: Visual Studio 18 2026"
Write-Host "Configuration: Release"
Write-Host "`nYou can find the built executable in: $BuildDir\bin\Release" -ForegroundColor Green
