
import re
from dataclasses import replace

from binary_lab_assembler.parser import (
    Instruction,
    parse_line,
)


class LabelResolutionError(Exception):
    pass


LABEL_PATTERN = re.compile(
    r"^([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$"
)

NUMERIC_PATTERN = re.compile(
    r"-?(?:0X[0-9A-F]+|\d+)$",
    re.IGNORECASE,
)

BRANCH_INSTRUCTIONS = {"JMP", "BEQ", "BNE"}

MIN_BRANCH_OFFSET = -2048
MAX_BRANCH_OFFSET = 2047
INSTRUCTION_SIZE = 2


def resolve_labels(source: str) -> list[Instruction]:
    instructions = []
    labels = {}
    current_address = 0

    for line_number, original_line in enumerate(
        source.splitlines(),
        start=1,
    ):
        line = original_line.split(";", 1)[0]
        line = line.split("#", 1)[0].strip()

        if not line:
            continue

        label_match = LABEL_PATTERN.fullmatch(line)

        if label_match is not None:
            label_name = label_match.group(1).upper()
            remaining_line = label_match.group(2).strip()

            if label_name in labels:
                raise LabelResolutionError(
                    f"Line {line_number}: duplicate label "
                    f"'{label_name}'."
                )

            labels[label_name] = current_address
            line = remaining_line

            if not line:
                continue

        elif ":" in line:
            raise LabelResolutionError(
                f"Line {line_number}: invalid label declaration."
            )

        instruction = parse_line(line, line_number)

        if instruction is None:
            continue

        instructions.append(
            (instruction, current_address)
        )

        current_address += INSTRUCTION_SIZE

    resolved_instructions = []

    for instruction, instruction_address in instructions:
        if instruction.mnemonic not in BRANCH_INSTRUCTIONS:
            resolved_instructions.append(instruction)
            continue

        operand = instruction.operands[0]

        if operand in labels:
            target_address = labels[operand]

            displacement = (
                target_address
                - (instruction_address + INSTRUCTION_SIZE)
            )

            if displacement % INSTRUCTION_SIZE != 0:
                raise LabelResolutionError(
                    f"Line {instruction.line_number}: "
                    f"label '{operand}' is not aligned."
                )

            offset = displacement // INSTRUCTION_SIZE

            if not MIN_BRANCH_OFFSET <= offset <= MAX_BRANCH_OFFSET:
                raise LabelResolutionError(
                    f"Line {instruction.line_number}: "
                    f"branch to '{operand}' is out of range."
                )

            resolved_instructions.append(
                replace(
                    instruction,
                    operands=(str(offset),),
                )
            )
            continue

        if NUMERIC_PATTERN.fullmatch(operand):
            resolved_instructions.append(instruction)
            continue

        raise LabelResolutionError(
            f"Line {instruction.line_number}: "
            f"undefined label '{operand}'."
        )

    return resolved_instructions
