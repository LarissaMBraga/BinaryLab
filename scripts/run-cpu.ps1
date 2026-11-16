param(
    [string]$Source = "programs/examples/all_instructions.asm"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

& (Join-Path $PSScriptRoot "build-assembler.ps1")

$sourcePath = (Resolve-Path -LiteralPath $Source).Path
$assembler = Join-Path $root "assembler/bin/binary-lab-assembler.exe"
$binaryPath = Join-Path $root "build/all_instructions_c.bin"
$simulationPath = Join-Path $root "build/cpu_all_instructions_test.vvp"

& $assembler $sourcePath -o $binaryPath

if ($LASTEXITCODE -ne 0) {
    throw "Program assembly failed."
}

& iverilog -g2012 -s tb_cpu_all_instructions -o $simulationPath `
    rtl/cpu/cpu_pkg.sv `
    rtl/cpu/program_counter.sv `
    rtl/memory/instruction_memory.sv `
    rtl/memory/data_memory.sv `
    rtl/registers/register_file.sv `
    rtl/alu/alu.sv `
    rtl/control/control_unit.sv `
    rtl/cpu/cpu.sv `
    testbench/integration/tb_cpu_all_instructions.sv

if ($LASTEXITCODE -ne 0) {
    throw "CPU simulation compilation failed."
}

& vvp $simulationPath

if ($LASTEXITCODE -ne 0) {
    throw "CPU simulation failed."
}
