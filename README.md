# BINARY LAB

A custom 8-bit processor designed from scratch using SystemVerilog.

## Project Overview

BINARY LAB is a computer architecture project focused on designing,
implementing, simulating, and verifying a custom 8-bit CPU.

The processor will be described in SystemVerilog and tested through
digital circuit simulation.

A custom assembler written in C will translate assembly programs
into binary machine code.

## Architecture

- Custom 8-bit CPU
- Custom Instruction Set Architecture (ISA)
- Arithmetic Logic Unit (ALU)
- Register File
- Control Unit
- Program Counter
- Instruction and Data Memory
- Machine Code Execution
- Clock-driven execution
- Hardware verification through testbenches

## Technology Stack

- SystemVerilog
- C
- Icarus Verilog
- GTKWave
- Verilator
- Yosys
- GNU Make

## Project Structure

- rtl/: hardware implementation
- assembler/: custom assembler written in C
- programs/: assembly examples and binary programs
- testbench/: hardware verification
- simulation/: simulation outputs and waveforms
- synthesis/: synthesis scripts and reports
- docs/: architecture and technical documentation
- scripts/: development automation

## Development Goals

1. Define the processor architecture.
2. Design the Instruction Set Architecture.
3. Implement the ALU and register file.
4. Implement the control unit.
5. Integrate the CPU.
6. Develop the assembler.
7. Execute binary programs.
8. Verify the processor using automated testbenches.
9. Analyze synthesis results.
10. Prepare the design for possible FPGA deployment.

## Hardware Requirements

No physical hardware is required for development or simulation.

FPGA deployment is an optional future extension.