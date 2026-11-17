$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$compiler = Get-Command gcc -ErrorAction SilentlyContinue

if (-not $compiler) {
    throw "GCC was not found. Install or configure the MinGW toolchain."
}

New-Item -ItemType Directory -Path "build" -Force | Out-Null

Write-Host "`nBuilding BINARY LAB for Windows x64..." -ForegroundColor Cyan

& gcc -m64 -o "build\BinaryLab.exe" "src\main.S"

if ($LASTEXITCODE -ne 0) {
    throw "Build failed with exit code $LASTEXITCODE."
}

if (-not (Test-Path "build\BinaryLab.exe")) {
    throw "Executable was not generated."
}

Write-Host "`nBuild successful!" -ForegroundColor Green
Write-Host "Executable: build\BinaryLab.exe" -ForegroundColor Green

& objdump -f "build\BinaryLab.exe"
