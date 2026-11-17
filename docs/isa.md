# BINARY LAB - Instruction Set Architecture

## 1. Instruction Format

Every instruction is 16 bits wide.

| Bits | Field | Width |
|---|---|---|
| 15-12 | Opcode | 4 bits |
| 11-9 | Register / destination | 3 bits |
| 8-6 | Register / base / source | 3 bits |
| 5-0 | Operand / reserved | 6 bits |

The interpretation depends on the instruction format.

## 2. Instruction Formats

### Register Format (R)

Used by register-to-register operations.

| Bits | Field |
|---|---|
| 15-12 | Opcode |
| 11-9 | Destination register |
| 8-6 | Source register |
| 5-0 | Reserved, must be zero |

Example: `ADD R1, R2`

`R1 = R1 + R2`

### Immediate Format (I)

Used by instructions containing an immediate value.

| Bits | Field |
|---|---|
| 15-12 | Opcode |
| 11-9 | Destination register |
| 8-0 | Signed immediate |

Example: `ADDI R1, 5`

`R1 = R1 + 5`

### Memory Format (M)

Used by load and store instructions.

| Bits | Field |
|---|---|
| 15-12 | Opcode |
| 11-9 | Data register |
| 8-6 | Base register |
| 5-0 | Signed offset |

`EA = Base Register + SignExtendedOffset`

### Branch Format (B)

Used by control-flow instructions.

| Bits | Field |
|---|---|
| 15-12 | Opcode |
| 11-0 | Signed relative offset |

`Target = PC_after_fetch + (SignExtendedOffset * 2)`

The offset is measured in instructions, not bytes.

### Extended Format (EXT)

The `EXT` opcode introduces additional ALU operations.

The extended encoding uses:
- Bits 11-9: extended operation selector.
- Bits 8-6: destination register.
- Bits 5-3: source register.
- Bits 2-0: reserved and required to be zero.

The extended operation selector is:

| Selector | Instruction | Operation |
|---|---|---|
| 0 | SHL | Logical shift left |
| 1 | SHR | Logical shift right |
| 2 | SAR | Arithmetic shift right |
| 3 | ROL | Rotate left |
| 4 | ROR | Rotate right |
| 5 | NOT | Bitwise inversion |
| 6 | MUL | Multiplication |
| 7 | DIV | Unsigned division |

For binary register operations, the destination register is also the first operand.

Examples:

- `SHL R1, R2`: shift R1 left by the amount in R2.
- `MUL R1, R2`: multiply R1 by R2 and store the result in R1.
- `NOT R1`: invert every bit in R1.

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
| 0xF | EXT | EXT | Extended ALU operations |

## 4. Instruction Semantics

### Arithmetic and logical instructions

- `ADD Rd, Rs`: `Rd = Rd + Rs`
- `SUB Rd, Rs`: `Rd = Rd - Rs`
- `AND Rd, Rs`: `Rd = Rd & Rs`
- `OR Rd, Rs`: `Rd = Rd | Rs`
- `XOR Rd, Rs`: `Rd = Rd ^ Rs`
- `ADDI Rd, Immediate`: add a signed immediate to the destination register.
- `MOV Rd, Rs`: copy the source register.
- `CMP Rd, Rs`: compare registers without storing the subtraction result.

### Memory instructions

- `LD Rd, [Rb + Offset]`: load one byte from memory.
- `ST Rs, [Rb + Offset]`: store one byte in memory.

### Control-flow instructions

- `JMP Offset`: unconditional relative jump.
- `BEQ Offset`: branch when the Zero flag is set.
- `BNE Offset`: branch when the Zero flag is clear.
- `HALT`: stop normal execution until reset.
- `NOP`: do not modify architectural state.

### Extended ALU instructions

- `SHL Rd, Rs`: logical left shift.
- `SHR Rd, Rs`: logical right shift.
- `SAR Rd, Rs`: arithmetic right shift.
- `ROL Rd, Rs`: rotate left.
- `ROR Rd, Rs`: rotate right.
- `NOT Rd`: bitwise inversion.
- `MUL Rd, Rs`: multiplication.
- `DIV Rd, Rs`: unsigned division.

For division by zero, behavior must be verified against the current ALU implementation before relying on a result.

## 5. Processor Flags

| Flag | Description |
|---|---|
| Z | Set when the result is zero |
| C | Carry or no-borrow indicator |
| N | Set when the most significant result bit is 1 |
| V | Signed arithmetic overflow |

For subtraction, C is set when no borrow occurs.

## 6. Instruction Byte Order

Instructions are 16-bit words.

The most significant byte is stored at the lower memory address.

Example:

Instruction: `0x3120`

- Memory[0x0000] = `0x31`
- Memory[0x0001] = `0x20`

## 7. Reserved Encodings

Reserved bits must be zero.

Unsupported or invalid encodings must not silently execute as valid instructions. The control unit is responsible for detecting illegal instructions.
