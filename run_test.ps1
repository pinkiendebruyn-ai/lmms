# run_test.ps1 - Headless LMMS stem export automation script
# Output directory for rendered stems
$outputDir = "C:\Users\Henri\Desktop\lmms_github_fork\test_stems"

# Clean or create the output directory
if (Test-Path $outputDir) {
    Write-Host "[1/3] Cleaning existing test_stems directory..." -ForegroundColor Yellow
    Remove-Item -Path "$outputDir\*" -Recurse -Force
} else {
    Write-Host "[1/3] Creating test_stems directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Paths to the LMMS binary and test project
$lmmsExe = "C:\Users\Henri\Desktop\lmms_github_fork\build\Debug\lmms.exe"
$testProject = "C:\Users\Henri\Desktop\lmms_github_fork\test_automation.mmp"

Write-Host "[2/3] Deploying Qt6 runtime dependencies..." -ForegroundColor Yellow
$windeployqt = "C:\Qt\6.8.3\msvc2022_64\bin\windeployqt.exe"
if (-not (Test-Path $windeployqt)) {
    Write-Host "ERROR: windeployqt.exe not found at $windeployqt" -ForegroundColor Red
    exit 1
}
& $windeployqt --debug "C:\Users\Henri\Desktop\lmms_github_fork\build\Debug\lmms.exe"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: windeployqt failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}

Write-Host "[2.5/3] Deploying native dependencies..." -ForegroundColor Yellow
$buildDir = "C:\Users\Henri\Desktop\lmms_github_fork\build\Debug"
$nativeDeps = @{
    "C:\Users\Henri\Desktop\lmms_github_fork\deps\libsndfile\libsndfile-1.2.2-win64\bin\sndfile.dll" = "sndfile.dll"
    "C:\vcpkg\installed\x64-windows\bin\samplerate.dll" = "samplerate.dll"
    "C:\Users\Henri\Desktop\lmms_github_fork\deps\fftw-prebuilt\prebuilt-fftw-3.3.10-windows-main\bin\fftw3.dll" = "fftw3.dll"
    "C:\Users\Henri\Desktop\lmms_github_fork\deps\fftw-prebuilt\prebuilt-fftw-3.3.10-windows-main\bin\fftw3f.dll" = "fftw3f.dll"
}
foreach ($src in $nativeDeps.Keys) {
    $dest = Join-Path $buildDir $nativeDeps[$src]
    if (Test-Path $src) {
        Copy-Item $src $dest -Force
        Write-Host "  Copied $($nativeDeps[$src])"
    } else {
        Write-Host "  WARNING: Missing $src" -ForegroundColor Yellow
    }
}

Write-Host "[3/3] Launching headless stem export..." -ForegroundColor Yellow

try {
    # Execute headless render using the explicit call operator
    & $lmmsExe rendertracks $testProject --output $outputDir

    # Check if the process exited successfully
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Success! Headless stems successfully generated in \test_stems\" -ForegroundColor Green
    } else {
        Write-Host "Warning: Process exited with code $LASTEXITCODE. Check output above for errors." -ForegroundColor Red
    }
} catch {
    Write-Host "Error: Failed to execute headless export. $_" -ForegroundColor Red
    exit 1
}
