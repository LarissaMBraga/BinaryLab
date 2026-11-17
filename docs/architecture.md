# BINARY LAB - Processor Architecture

## 1. Overview

BINARY LAB is a custom 8-bit processor designed using SystemVerilog.

The project explores digital logic, computer architecture, instruction decoding, machine-code execution, assembly, and hardware verification.

## 2. Processor Specifications

| Component | Specification |
|---|---|
| Architecture | Harvard |
| Data width | 8 bits |
| Instruction width | 16 bits |
| Address width | 16 bits |
| General-purpose registers | 8 |
| Register width | 8 bits |
| Instruction memory | 64 KB address space |
| Data memory | 64 KB address space |
| Instruction alignment | 2 bytes |
| Flags | Zero, Carry, Negative, Overflow |
| Reset address | 0x0000 |

## 3. Main Components

### Arithmetic Logic Unit (ALU)

The ALU performs arithmetic, logical, shift, and rotate operations.

Implemented operations include:

- Addition and subtraction
- Bitwise AND, OR, XOR, and NOT
- Logical left and right shifts
- Arithmetic right shift
- Rotate left and right
- Multiplication and division

The ALU also calculates processor flags according to the selected operation.

### Register File

Contains eight 8-bit general-purpose registers:

- R0
- R1
- R2
- R3
- R4
- R5
- R6
- R7

The register file supports two asynchronous read ports and one synchronous write port.

### Control Unit

Decodes instructions and generates the control signals required by the processor.

The control unit uses a finite state machine to coordinate instruction execution, including the extended instruction format.

### Program Counter

A 16-bit register containing the address of the next instruction.

Instructions are two bytes long. Sequential execution advances the program counter by two.

### Memory

Instruction memory and data memory are logically separated.

Both use 16-bit addresses and 8-bit data.

Instruction words are assembled from two consecutive bytes, with the most significant byte stored first.

Instruction memory supports initialization from a file and runtime binary-program loading.

## 4. Processor Flags

| Flag | Description |
|---|---|
| Z | Set when the result is zero |
| C | Carry or no-borrow indicator |
| N | Set when the most significant result bit is 1 |
| V | Signed arithmetic overflow |

For subtraction, C is set when no borrow occurs.

## 5. Execution Model

The processor follows a multi-cycle execution model:

1. Fetch: retrieve the instruction from instruction memory.
2. Decode: identify the opcode and operands.
3. Execute: perform the requested operation.
4. Memory: access data memory when required.
5. Writeback: write results into the register file when required.

The control unit coordinates these stages.

## 6. Extended Instruction Set

The EXT opcode provides additional ALU functionality:

- SHL and SHR
- SAR
- ROL and ROR
- NOT
- MUL and DIV

The extended format contains an operation selector and register operands. Its encoding is documented in `docs/isa.md`.

## 7. Verification

The project includes SystemVerilog unit and integration testbenches.

The CPU runner can load a binary program at runtime through the `program` simulation argument. The extended ISA example is located at:

`programs/examples/extended_isa.asm`

## 8. Future Extensions

Potential future work includes:

- Stack operations and stack pointer
- Interrupt handling
- Additional addressing modes
- FPGA deployment
- Additional peripheral interfaces
