# Binary Lab Memory Bus

## Overview

The memory bus separates CPU execution logic from memory and memory-mapped peripherals.

The CPU issues read and write requests through a shared address and data interface. The bus decoder selects the target device.

## Architecture

```text
                 +----------------+
                 |      CPU       |
                 +-------+--------+
                         |
                  Address / Data
                         |
                 +-------v--------+
                 |   Memory Bus   |
                 +-------+--------+
                         |
                 +-------v--------+
                 | Address Decoder|
                 +---+---------+--+
                     |         |
              +------v--+  +---v------+
              |   RAM   |  |   GPIO   |
              +---------+  +----------+
```

## Address map

| Address | Device | Register |
|---|---|---|
| `0x0000` - `0xFFFF` except reserved addresses | RAM | Data memory |
| `0x00F0` | GPIO | Data |
| `0x00F1` | GPIO | Direction |

GPIO addresses are reserved and are not forwarded to RAM.

## Bus signals

| Signal | Direction | Description |
|---|---|---|
| `read_enable` | Input | Requests a read |
| `write_enable` | Input | Requests a write |
| `address` | Input | 16-bit target address |
| `write_data` | Input | 8-bit data to write |
| `read_data` | Output | Selected device read data |

## Address decoder

The address decoder generates independent RAM and GPIO selection signals.

- RAM reads and writes are enabled only for valid, non-reserved addresses.
- GPIO writes are enabled only for `0x00F0` and `0x00F1`.
- Invalid addresses do not select a device and return zero on reads.

## Compatibility

The instruction set and binary instruction format are unchanged.

Existing assembly programs continue to use `LD` and `ST`. GPIO remains accessible through its existing memory-mapped addresses.

## Verification

The automated test suite includes:

- Address decoder unit tests.
- Memory bus read and write tests.
- RAM access verification.
- GPIO data and direction register verification.
- Existing CPU integration tests.