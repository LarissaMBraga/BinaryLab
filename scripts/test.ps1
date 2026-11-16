$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$assembler = Join-Path $root "assembler/bin/binary-lab-assembler.exe"

function Invoke-Simulation {
    param(
        [string]$Top,
        [string]$Testbench,
        [string]$Output,
        [string[]]$Sources
    )

    Write-Host "`n--- $Top ---" -ForegroundColor Cyan

    & iverilog -g2012 -s $Top -o $Output @Sources $Testbench

    if ($LASTEXITCODE -ne 0) {
        throw "$Top compilation failed."
    }

    & vvp $Output

    if ($LASTEXITCODE -ne 0) {
        throw "$Top simulation failed."
    }
}

Write-Host "`n=== BUILD C ASSEMBLER ===" -ForegroundColor Cyan

& (Join-Path $PSScriptRoot "build-assembler.ps1")

if ($LASTEXITCODE -ne 0) {
    throw "Assembler build failed."
}

Write-Host "`n=== VALID ASSEMBLY PROGRAMS ===" -ForegroundColor Cyan

$examples = Get-ChildItem "programs/examples" -Filter "*.asm" |
    Where-Object { $_.Name -notlike "invalid_*" }

foreach ($example in $examples) {
    $output = Join-Path $root "build/$($example.BaseName)_test.bin"

    & $assembler $example.FullName -o $output

    if ($LASTEXITCODE -ne 0) {
        throw "Valid program rejected: $($example.Name)"
    }

    if (-not (Test-Path $output) -or (Get-Item $output).Length -eq 0) {
        throw "Missing binary output: $($example.Name)"
    }

    Write-Host "$($example.Name): PASSED" -ForegroundColor Green
}

Write-Host "`n=== INVALID ASSEMBLY PROGRAMS ===" -ForegroundColor Cyan

$invalidExamples = Get-ChildItem "programs/examples" -Filter "invalid_*.asm"

foreach ($example in $invalidExamples) {
    $output = Join-Path $root "build/$($example.BaseName)_invalid.bin"

    if (Test-Path $output) {
        Remove-Item $output -Force
    }

    & $assembler $example.FullName -o $output

    if ($LASTEXITCODE -eq 0) {
        throw "Invalid program unexpectedly accepted: $($example.Name)"
    }

    Write-Host "$($example.Name): REJECTED AS EXPECTED" -ForegroundColor Green
}

Write-Host "`n=== GENERATE CPU TEST BINARIES ===" -ForegroundColor Cyan

$cpuPrograms = @(
    @{ Source = "programs/examples/all_instructions.asm"; Output = "build/all_instructions_c.bin" },
    @{ Source = "programs/examples/control_flow.asm"; Output = "build/control_flow_c.bin" },
    @{ Source = "programs/examples/memory_offsets.asm"; Output = "build/memory_offsets_c.bin" },
    @{ Source = "programs/examples/gpio.asm"; Output = "build/gpio_c.bin" }
)

foreach ($program in $cpuPrograms) {
    & $assembler $program.Source -o $program.Output

    if ($LASTEXITCODE -ne 0) {
        throw "Could not assemble $($program.Source)"
    }
}

[System.IO.File]::WriteAllBytes(
    (Join-Path $root "build/invalid_opcode.bin"),
    [byte[]](0xF0, 0x00)
)

$cpuSources = @(
    "rtl/cpu/cpu_pkg.sv",
    "rtl/cpu/program_counter.sv",
    "rtl/memory/instruction_memory.sv",
    "rtl/memory/data_memory.sv",
    "rtl/registers/register_file.sv",
    "rtl/alu/alu.sv",
    "rtl/io/gpio.sv",
    "rtl/control/control_unit.sv",
    "rtl/cpu/cpu.sv"
)

Write-Host "`n=== UNIT TESTS ===" -ForegroundColor Cyan

Invoke-Simulation -Top "tb_alu" -Testbench "testbench/unit/tb_alu.sv" -Output "build/tb_alu.vvp" -Sources @("rtl/cpu/cpu_pkg.sv", "rtl/alu/alu.sv")

Invoke-Simulation -Top "tb_program_counter" -Testbench "testbench/unit/tb_program_counter.sv" -Output "build/tb_program_counter.vvp" -Sources @("rtl/cpu/cpu_pkg.sv", "rtl/cpu/program_counter.sv")

Write-Host "`n=== CPU INTEGRATION TESTS ===" -ForegroundColor Cyan

Invoke-Simulation -Top "tb_cpu_all_instructions" -Testbench "testbench/integration/tb_cpu_all_instructions.sv" -Output "build/tb_cpu_all_instructions.vvp" -Sources $cpuSources

Invoke-Simulation -Top "tb_cpu_control_flow" -Testbench "testbench/integration/tb_cpu_control_flow.sv" -Output "build/tb_cpu_control_flow.vvp" -Sources $cpuSources

Invoke-Simulation -Top "tb_cpu_memory_offsets" -Testbench "testbench/integration/tb_cpu_memory_offsets.sv" -Output "build/tb_cpu_memory_offsets.vvp" -Sources $cpuSources

Invoke-Simulation -Top "tb_cpu_invalid_instruction" -Testbench "testbench/integration/tb_cpu_invalid_instruction.sv" -Output "build/tb_cpu_invalid_instruction.vvp" -Sources $cpuSources

Invoke-Simulation -Top "tb_cpu_gpio" -Testbench "testbench/integration/tb_cpu_gpio.sv" -Output "build/tb_cpu_gpio.vvp" -Sources $cpuSources

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "ALL BINARY LAB TESTS PASSED" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green