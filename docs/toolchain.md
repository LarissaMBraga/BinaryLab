# Binary Lab Toolchain

## Overview

Binary Lab contains a custom 8-bit CPU implemented in SystemVerilog and a C17 assembler that translates assembly programs into 16-bit machine instructions.

The C assembler is the primary assembler implementation. The legacy Python assembler is not required to build or run the project.

## Requirements

- GCC with C17 support
- Icarus Verilog (`iverilog` and `vvp`)
- PowerShell

## Build the C assembler

```powershell
.\scripts\build-assembler.ps1
```

The executable is generated at:

```text
assembler/bin/binary-lab-assembler.exe
```

## Assemble a program

```powershell
.\scripts\assemble.ps1 -Source programs/examples/all_instructions.asm
```

Specify output paths when needed:

```powershell
.\scripts\assemble.ps1 -Source programs/examples/all_instructions.asm -Output build/program.bin -HexOutput build/program.hex
```

The assembler supports:

- Register instructions: `MOV`, `ADD`, `SUB`, `AND`, `OR`, `XOR`
- Immediate instructions: `ADDI`
- Memory instructions: `LD`, `ST`
- Control flow: `JMP`, `BEQ`, `BNE`
- Comparison and control: `CMP`, `NOP`, `HALT`
- Labels and relative branch offsets
- Decimal, hexadecimal, and binary numeric literals
- Validation of registers, immediates, memory offsets, labels, and instruction formats

## Run the CPU

```powershell
.\scripts\run-cpu.ps1
```

A different assembly program can be supplied:

```powershell
.\scripts\run-cpu.ps1 -Source programs/examples/gpio.asm
```

## GPIO memory map

The GPIO peripheral is memory-mapped:

| Address | Register | Description |
|---|---|---|
| `0x00F0` | GPIO data | Reads pin values and writes output values |
| `0x00F1` | GPIO direction | Configures each pin as input or output |

A direction bit set to `1` configures the corresponding pin as output. A bit set to `0` configures it as input.

## Run the validation suite

```powershell
.\scripts\test.ps1
```

The validation suite builds the C assembler, assembles valid example programs, verifies rejection of invalid programs, and runs the assembler, memory, ALU, program counter, CPU integration, control-flow, and GPIO simulations.

## Machine-code format

Instructions are 16 bits wide. Binary output is written as two bytes per instruction in big-endian order.

The CPU instruction memory supports both binary (`BIN`) and hexadecimal (`HEX`) initialization formats.