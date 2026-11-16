
import re

from binary_lab_assembler.instructions import (
    InstructionFormat,
    InstructionValidationError,
    validate_instruction,
)
from binary_lab_assembler.parser import Instruction


class EncodingError(Exception):
    pass


REGISTER_PATTERN = re.compile(r"R([0-7])$")
IMMEDIATE_PATTERN = re.compile(r"-?(?:0X[0-9A-F]+|\d+)$")
MEMORY_PATTERN = re.compile(
    r"\[\s*(R[0-7])\s*(?:([+-])\s*(0X[0-9A-F]+|\d+))?\s*\]$"
)

MIN_BRANCH_OFFSET = -2048
MAX_BRANCH_OFFSET = 2047


def parse_register(operand: str, line_number: int) -> int:
    match = REGISTER_PATTERN.fullmatch(operand.strip().upper())

    if match is None:
        raise EncodingError(
            f"Line {line_number}: invalid register '{operand}'. "
            "Expected R0 through R7."
        )

    return int(match.group(1))


def parse_immediate(operand: str, line_number: int) -> int:
    normalized_operand = operand.strip().upper()

    if not IMMEDIATE_PATTERN.fullmatch(normalized_operand):
        raise EncodingError(
            f"Line {line_number}: invalid immediate '{operand}'."
        )

    try:
        value = int(normalized_operand, 0)
    except ValueError as error:
        raise EncodingError(
            f"Line {line_number}: invalid immediate '{operand}'."
        ) from error

    if not -128 <= value <= 127:
        raise EncodingError(
            f"Line {line_number}: immediate {value} is out of range. "
            "Expected a value between -128 and 127."
        )

    return value


def parse_branch_offset(operand: str, line_number: int) -> int:
    normalized_operand = operand.strip().upper()

    if not IMMEDIATE_PATTERN.fullmatch(normalized_operand):
        raise EncodingError(
            f"Line {line_number}: invalid branch offset '{operand}'."
        )

    try:
        value = int(normalized_operand, 0)
    except ValueError as error:
        raise EncodingError(
            f"Line {line_number}: invalid branch offset '{operand}'."
        ) from error

    if not MIN_BRANCH_OFFSET <= value <= MAX_BRANCH_OFFSET:
        raise EncodingError(
            f"Line {line_number}: branch offset {value} is out of range. "
            "Expected a value between -2048 and 2047."
        )

    return value


def parse_memory_operand(
    operand: str,
    line_number: int,
) -> tuple[int, int]:
    normalized_operand = operand.strip().upper()
    match = MEMORY_PATTERN.fullmatch(normalized_operand)

    if match is None:
        raise EncodingError(
            f"Line {line_number}: invalid memory operand '{operand}'. "
            "Expected [R0-R7], [R0-R7 + offset] or [R0-R7 - offset]."
        )

    base_register = parse_register(match.group(1), line_number)
    sign = match.group(2)
    offset_text = match.group(3)

    offset = 0

    if offset_text is not None:
        try:
            offset = int(offset_text, 0)
        except ValueError as error:
            raise EncodingError(
                f"Line {line_number}: invalid memory offset '{offset_text}'."
            ) from error

        if sign == "-":
            offset = -offset

    if not -32 <= offset <= 31:
        raise EncodingError(
            f"Line {line_number}: memory offset {offset} is out of range. "
            "Expected a value between -32 and 31."
        )

    return base_register, offset


def encode_register_instruction(
    instruction: Instruction,
    opcode: int,
) -> int:
    if not instruction.operands:
        return opcode << 12

    destination = parse_register(
        instruction.operands[0],
        instruction.line_number,
    )

    source = parse_register(
        instruction.operands[1],
        instruction.line_number,
    )

    return (
        (opcode << 12)
        | (destination << 9)
        | (source << 6)
    )


def encode_immediate_instruction(
    instruction: Instruction,
    opcode: int,
) -> int:
    destination = parse_register(
        instruction.operands[0],
        instruction.line_number,
    )

    immediate = parse_immediate(
        instruction.operands[1],
        instruction.line_number,
    )

    encoded_immediate = immediate & 0xFF
    sign_extension = (encoded_immediate >> 7) & 0x01

    return (
        (opcode << 12)
        | (destination << 9)
        | (sign_extension << 8)
        | encoded_immediate
    )


def encode_memory_instruction(
    instruction: Instruction,
    opcode: int,
) -> int:
    data_register = parse_register(
        instruction.operands[0],
        instruction.line_number,
    )

    base_register, offset = parse_memory_operand(
        instruction.operands[1],
        instruction.line_number,
    )

    encoded_offset = offset & 0x3F

    return (
        (opcode << 12)
        | (data_register << 9)
        | (base_register << 6)
        | encoded_offset
    )


def encode_branch_instruction(
    instruction: Instruction,
    opcode: int,
) -> int:
    offset = parse_branch_offset(
        instruction.operands[0],
        instruction.line_number,
    )

    encoded_offset = offset & 0x0FFF

    return (opcode << 12) | encoded_offset


def encode_instruction(instruction: Instruction) -> int:
    try:
        definition = validate_instruction(instruction)
    except InstructionValidationError as error:
        raise EncodingError(str(error)) from error

    if definition.format == InstructionFormat.R:
        return encode_register_instruction(
            instruction,
            definition.opcode,
        )

    if definition.format == InstructionFormat.I:
        return encode_immediate_instruction(
            instruction,
            definition.opcode,
        )

    if definition.format == InstructionFormat.M:
        return encode_memory_instruction(
            instruction,
            definition.opcode,
        )

    if definition.format == InstructionFormat.B:
        return encode_branch_instruction(
            instruction,
            definition.opcode,
        )

    raise EncodingError(
        f"Line {instruction.line_number}: "
        f"{instruction.mnemonic} has an unsupported format."
    )
