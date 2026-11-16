
from dataclasses import dataclass
from enum import Enum

from binary_lab_assembler.parser import Instruction


class InstructionFormat(str, Enum):
    R = "R"
    I = "I"
    M = "M"
    B = "B"


@dataclass(frozen=True)
class InstructionDefinition:
    mnemonic: str
    opcode: int
    format: InstructionFormat
    operand_count: int


class InstructionValidationError(Exception):
    pass


INSTRUCTION_SET = {
    "NOP": InstructionDefinition("NOP", 0x0, InstructionFormat.R, 0),
    "HALT": InstructionDefinition("HALT", 0x1, InstructionFormat.R, 0),
    "MOV": InstructionDefinition("MOV", 0x2, InstructionFormat.R, 2),
    "ADD": InstructionDefinition("ADD", 0x3, InstructionFormat.R, 2),
    "SUB": InstructionDefinition("SUB", 0x4, InstructionFormat.R, 2),
    "AND": InstructionDefinition("AND", 0x5, InstructionFormat.R, 2),
    "OR": InstructionDefinition("OR", 0x6, InstructionFormat.R, 2),
    "XOR": InstructionDefinition("XOR", 0x7, InstructionFormat.R, 2),
    "ADDI": InstructionDefinition("ADDI", 0x8, InstructionFormat.I, 2),
    "LD": InstructionDefinition("LD", 0x9, InstructionFormat.M, 2),
    "ST": InstructionDefinition("ST", 0xA, InstructionFormat.M, 2),
    "JMP": InstructionDefinition("JMP", 0xB, InstructionFormat.B, 1),
    "BEQ": InstructionDefinition("BEQ", 0xC, InstructionFormat.B, 1),
    "BNE": InstructionDefinition("BNE", 0xD, InstructionFormat.B, 1),
    "CMP": InstructionDefinition("CMP", 0xE, InstructionFormat.R, 2),
}


def get_instruction_definition(mnemonic: str) -> InstructionDefinition:
    normalized_mnemonic = mnemonic.strip().upper()

    definition = INSTRUCTION_SET.get(normalized_mnemonic)

    if definition is None:
        raise InstructionValidationError(
            f"Unsupported instruction: {normalized_mnemonic}"
        )

    return definition


def validate_instruction(
    instruction: Instruction,
) -> InstructionDefinition:
    definition = get_instruction_definition(instruction.mnemonic)

    actual_count = len(instruction.operands)

    if actual_count != definition.operand_count:
        raise InstructionValidationError(
            f"Line {instruction.line_number}: "
            f"{definition.mnemonic} expects "
            f"{definition.operand_count} operand(s), "
            f"got {actual_count}."
        )

    return definition
