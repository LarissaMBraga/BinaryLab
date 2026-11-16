param(
    [string]$Output = "assembler/bin/binary-lab-assembler.exe"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

New-Item -ItemType Directory -Force (Split-Path -Parent $Output) | Out-Null

$sourceFiles = @(
    "assembler/src/main.c",
    "assembler/src/error.c",
    "assembler/src/parser.c",
    "assembler/src/instructions.c",
    "assembler/src/labels.c",
    "assembler/src/encoder.c",
    "assembler/src/output.c"
)

& gcc -std=c17 -Wall -Wextra -Wpedantic -Werror -I assembler/include @sourceFiles -o $Output

if ($LASTEXITCODE -ne 0) {
    throw "Assembler compilation failed."
}

Write-Host "Assembler successfully built: $Output" -ForegroundColor Green
