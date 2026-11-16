param(
    [Parameter(Mandatory = $true)]
    [string]$Source,

    [string]$Output,

    [string]$HexOutput
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$sourcePath = (Resolve-Path -LiteralPath $Source).Path
$assembler = Join-Path $root "assembler/bin/binary-lab-assembler.exe"

if (-not (Test-Path $assembler)) {
    & (Join-Path $PSScriptRoot "build-assembler.ps1")
}

if ([string]::IsNullOrWhiteSpace($Output)) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($sourcePath)
    $Output = "build/$name.bin"
}

$outputPath = Join-Path $root $Output
New-Item -ItemType Directory -Force (Split-Path -Parent $outputPath) | Out-Null

if ([string]::IsNullOrWhiteSpace($HexOutput)) {
    & $assembler $sourcePath -o $outputPath
} else {
    $hexPath = Join-Path $root $HexOutput
    New-Item -ItemType Directory -Force (Split-Path -Parent $hexPath) | Out-Null
    & $assembler $sourcePath -o $outputPath --hex-output $hexPath
}

if ($LASTEXITCODE -ne 0) {
    throw "Assembly failed."
}
