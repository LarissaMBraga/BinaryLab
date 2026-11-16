# BINARY LAB - Processor Architecture

## 1. Overview

BINARY LAB is a custom 8-bit processor designed from scratch
using synthesizable SystemVerilog.

The project focuses on digital logic, computer architecture,
instruction decoding, machine code execution, and hardware verification.

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

Performs arithmetic and logical operations:
- Addition
- Subtraction
- Bitwise AND
- Bitwise OR
- Bitwise XOR

The ALU also calculates processor flags.

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

All registers are writable in the initial architecture.

The register file supports two asynchronous read ports and one
synchronous write port.

### Control Unit

Decodes instructions and generates control signals for the processor.

The initial implementation will use a finite state machine (FSM).

### Program Counter

A 16-bit register containing the address of the next instruction.

Instructions are 2 bytes long. Sequential execution advances
the program counter by 2.

### Memory

Instruction memory and data memory are logically separated.

Both use 16-bit addresses and 8-bit data.

Instruction words are assembled from two consecutive bytes,
with the most significant byte stored first.

## 4. Processor Flags

| Flag | Description |
|---|---|
| Z | Set when the result is zero |
| C | Carry or no-borrow indicator |
| N | Set when the most significant result bit is 1 |
| V | Signed arithmetic overflow |

For subtraction, C is set when no borrow occurs.

## 5. Execution Model

The processor follows these stages:

1. Fetch: retrieve the instruction from instruction memory.
2. Decode: identify the opcode and operands.
3. Execute: perform the requested operation.
4. Memory: access data memory when required.
5. Writeback: write results into the register file when required.

The first implementation will use a multi-cycle control unit.

## 6. Reset Behavior

On reset:
- The program counter is initialized to 0x0000.
- The processor enters its fetch state.
- The processor is not halted.

Register and memory initialization will be defined by the implementation
and testbench requirements.

## 7. Future Extensions

The architecture is designed to support future extensions:
- Stack operations
- Stack pointer
- Interrupt handling
- Additional addressing modes
- Extended instruction encoding
- FPGA deployment
