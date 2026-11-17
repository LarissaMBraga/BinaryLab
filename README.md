# BINARY LAB

BINARY LAB is a computer architecture and binary computing project built around a custom 8-bit processor.

The project combines a C assembler, a SystemVerilog CPU, binary program execution, a WebAssembly binary core, and a browser-based learning interface.

## Project Components

### 1. SystemVerilog CPU

A custom 8-bit processor with:

- Eight general-purpose 8-bit registers
- 16-bit instructions
- Separate instruction and data memories
- Arithmetic and logical operations
- Branching and memory instructions
- Extended ALU instructions: SHL, SHR, SAR, ROL, ROR, NOT, MUL, DIV
- Multi-cycle control unit

### 2. C Assembler

The assembler translates BINARY LAB assembly programs into machine-code binaries.

Source code:

- `assembler/include/`
- `assembler/src/`

### 3. WebAssembly Binary Core

The WebAssembly module provides low-level binary operations to the browser interface.

Runtime assets:

- `web/public/binary-core.wasm`
- `web/public/binary-core.bits`

### 4. Browser Interface

The local browser interface provides:

1. Binary Encoder
2. Binary Decoder
3. ASCII Explorer
4. Bit Operations
5. Binary Challenges

The browser interface uses the WebAssembly core. CPU execution is implemented separately by the SystemVerilog processor and its simulation runner.

## Requirements

- Windows
- PowerShell
- MSYS2 UCRT64 toolchain
- GCC
- Icarus Verilog (`iverilog` and `vvp`)

The scripts expect the MSYS2 UCRT64 binaries at:

`C:\msys64\ucrt64\bin`

## Build the Console Application

Run:

```powershell
.\scripts\build.ps1
```

The generated executable is placed in `build\BinaryLab.exe`.

Run it with:

```powershell
.\build\BinaryLab.exe
```

## Run the Browser Interface and Local CPU API

Run:

```powershell
.\scripts\start-local.ps1
```

Open:

`http://localhost:3000`

The local server builds the assembler and CPU simulation runner and serves the browser interface.

## Build and Run the Assembler

Build the assembler:

```powershell
.\scripts\build-assembler.ps1
```

Assemble a program:

```powershell
.\scripts\assemble.ps1 -InputFile "programs\examples\extended_isa.asm"
```

## Run the Test Suite

```powershell
.\scripts\test.ps1
```

The test script builds the assembler and runs the configured unit and integration tests.

## Extended ISA Example

Source:

`programs/examples/extended_isa.asm`

The example exercises shifts, arithmetic shifts, rotations, bitwise inversion, multiplication, division, and HALT on the SystemVerilog CPU.

## Project Structure

```text
BINARY-LAB/
├── assembler/
│   ├── include/
│   └── src/
├── docs/
├── programs/
│   └── examples/
├── rtl/
│   ├── alu/
│   ├── bus/
│   ├── control/
│   ├── cpu/
│   ├── io/
│   ├── memory/
│   └── registers/
├── scripts/
├── src/
├── testbench/
│   ├── integration/
│   └── unit/
└── web/
    └── public/
```

## Documentation

- `docs/architecture.md`: processor architecture.
- `docs/isa.md`: instruction formats, opcodes, and instruction semantics.
- `docs/memory-bus.md`: memory bus documentation.
- `docs/toolchain.md`: toolchain documentation.
