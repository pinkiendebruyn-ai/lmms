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
$lmmsExe = "C:\Users\Henri\Desktop\lmms_github_fork\build\Release\lmms.exe"
$testProject = "C:\Users\Henri\Desktop\lmms_github_fork\test_automation.mmp"

Write-Host "[2/3] Launching headless stem export..." -ForegroundColor Yellow

try {
    # Execute headless render using the explicit call operator
    & $lmmsExe rendertracks $testProject --output $outputDir

    # Check if the process exited successfully
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[3/3] Success! Headless stems successfully generated in \test_stems\" -ForegroundColor Green
    } else {
        Write-Host "[3/3] Warning: Process exited with code $LASTEXITCODE. Check output above for errors." -ForegroundColor Red
    }
} catch {
    Write-Host "[3/3] Error: Failed to execute headless export. $_" -ForegroundColor Red
    exit 1
}
