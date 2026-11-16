
from dataclasses import dataclass


@dataclass(frozen=True)
class Instruction:
    mnemonic: str
    operands: tuple[str, ...]
    line_number: int


class AssemblySyntaxError(Exception):
    pass


def parse_line(line: str, line_number: int = 1) -> Instruction | None:
    cleaned_line = line.split(";", 1)[0]
    cleaned_line = cleaned_line.split("#", 1)[0]
    cleaned_line = cleaned_line.strip()

    if not cleaned_line:
        return None

    parts = cleaned_line.split(None, 1)

    mnemonic = parts[0].upper()

    if len(parts) == 1:
        return Instruction(
            mnemonic=mnemonic,
            operands=(),
            line_number=line_number,
        )

    operand_text = parts[1].strip()

    if not operand_text:
        raise AssemblySyntaxError(
            f"Line {line_number}: missing operands."
        )

    operands = tuple(
        operand.strip().upper()
        for operand in operand_text.split(",")
    )

    if any(not operand for operand in operands):
        raise AssemblySyntaxError(
            f"Line {line_number}: empty operand."
        )

    return Instruction(
        mnemonic=mnemonic,
        operands=operands,
        line_number=line_number,
    )


def parse_source(source: str) -> list[Instruction]:
    instructions = []

    for line_number, line in enumerate(source.splitlines(), start=1):
        instruction = parse_line(line, line_number)

        if instruction is not None:
            instructions.append(instruction)

    return instructions
