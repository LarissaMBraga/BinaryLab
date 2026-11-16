# BINARY LAB - Instruction Set Architecture

## 1. Instruction Format

Every instruction is 16 bits wide.

The instruction is divided into fields:

| Bits | Field | Width |
|---|---|---|
| 15-12 | Opcode | 4 bits |
| 11-9 | Register / destination | 3 bits |
| 8-6 | Register / base | 3 bits |
| 5-0 | Operand / reserved | 6 bits |

The interpretation of the fields depends on the instruction format.

## 2. Instruction Formats

### Register Format (R)

Used by register-to-register operations.

| Bits | Field |
|---|---|
| 15-12 | Opcode |
| 11-9 | Destination register |
| 8-6 | Source register |
| 5-0 | Reserved (must be zero) |

Example:

ADD R1, R2

The operation is:

R1 = R1 + R2

### Immediate Format (I)

Used by instructions containing an immediate value.

| Bits | Field |
|---|---|
| 15-12 | Opcode |
| 11-9 | Destination register |
| 8-0 | Signed immediate |

The immediate value is sign-extended to 8 bits.

Example:

ADDI R1, 5

The operation is:

R1 = R1 + 5

### Memory Format (M)

Used by load and store instructions.

| Bits | Field |
|---|---|
| 15-12 | Opcode |
| 11-9 | Data register |
| 8-6 | Base register |
| 5-0 | Signed offset |

The effective address is calculated as:

EA = Base Register + SignExtendedOffset

The effective address is 16 bits wide.

### Branch Format (B)

Used by control-flow instructions.

| Bits | Field |
|---|---|
| 15-12 | Opcode |
| 11-0 | Signed relative offset |

The branch target is calculated as:

Target = PC_after_fetch + (SignExtendedOffset * 2)

The offset is measured in instructions, not bytes.

## 3. Opcode Table

| Opcode | Instruction | Format | Description |
|---|---|---|---|
| 0x0 | NOP | R | No operation |
| 0x1 | HALT | R | Stop execution |
| 0x2 | MOV | R | Copy register |
| 0x3 | ADD | R | Addition |
| 0x4 | SUB | R | Subtraction |
| 0x5 | AND | R | Bitwise AND |
| 0x6 | OR | R | Bitwise OR |
| 0x7 | XOR | R | Bitwise XOR |
| 0x8 | ADDI | I | Add immediate |
| 0x9 | LD | M | Load byte from memory |
| 0xA | ST | M | Store byte into memory |
| 0xB | JMP | B | Unconditional relative jump |
| 0xC | BEQ | B | Branch if equal |
| 0xD | BNE | B | Branch if not equal |
| 0xE | CMP | R | Compare registers |
| 0xF | EXT | Reserved | Extended instruction space |

## 4. Instruction Semantics

### NOP

Does not modify architectural state.

### HALT

Stops normal instruction execution until reset.

### MOV

Copies the source register into the destination register.

MOV Rd, Rs

Rd = Rs

### ADD

Adds the source register to the destination register.

ADD Rd, Rs

Rd = Rd + Rs

Updates Z, C, N and V.

### SUB

Subtracts the source register from the destination register.

SUB Rd, Rs

Rd = Rd - Rs

Updates Z, C, N and V.

### AND

Performs a bitwise AND operation.

AND Rd, Rs

Rd = Rd & Rs

Updates Z and N. Clears C and V.

### OR

Performs a bitwise OR operation.

OR Rd, Rs

Rd = Rd | Rs

Updates Z and N. Clears C and V.

### XOR

Performs a bitwise XOR operation.

XOR Rd, Rs

Rd = Rd ^ Rs

Updates Z and N. Clears C and V.

### ADDI

Adds a signed immediate value to a register.

ADDI Rd, Immediate

Rd = Rd + SignExtendedImmediate

Updates Z, C, N and V.

### LD

Loads one byte from memory.

LD Rd, [Rb + Offset]

Rd = Memory[Rb + Offset]

### ST

Stores one byte into memory.

ST Rs, [Rb + Offset]

Memory[Rb + Offset] = Rs

### JMP

Performs an unconditional relative jump.

JMP Offset

PC = PC_after_fetch + (SignExtendedOffset * 2)

### BEQ

Branches when the Zero flag is set.

BEQ Offset

If Z == 1:
    PC = PC_after_fetch + (SignExtendedOffset * 2)

### BNE

Branches when the Zero flag is clear.

BNE Offset

If Z == 0:
    PC = PC_after_fetch + (SignExtendedOffset * 2)

### CMP

Compares two registers by performing subtraction without storing
the result.

CMP Rd, Rs

Flags = Rd - Rs

Updates Z, C, N and V.

### EXT

Reserved for future extended instructions.

Execution of an unsupported EXT encoding must be treated as an
illegal instruction.

## 5. Flag Definitions

### Zero (Z)

Set when the operation result is zero.

### Carry (C)

For addition, set when the unsigned result exceeds 255.

For subtraction, set when no borrow occurs.

### Negative (N)

Set when bit 7 of the 8-bit result is 1.

### Overflow (V)

Set when signed arithmetic produces a result outside the range
-128 to 127.

## 6. Instruction Byte Order

Instructions are 16-bit words.

The most significant byte is stored at the lower memory address.

Example:

Instruction: 0x3120

Memory[0x0000] = 0x31
Memory[0x0001] = 0x20

## 7. Reserved Encodings

Reserved bits must be zero.

Invalid encodings must not silently execute as valid instructions.

The control unit will detect unsupported instructions.
