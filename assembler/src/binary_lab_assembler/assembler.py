
from pathlib import Path

from binary_lab_assembler.encoder import (
    EncodingError,
    encode_instruction,
)
from binary_lab_assembler.labels import (
    LabelResolutionError,
    resolve_labels,
)
from binary_lab_assembler.output import (
    OutputError,
    machine_code_to_bytes,
    write_binary_file,
    write_hex_file,
)
from binary_lab_assembler.parser import AssemblySyntaxError


class AssemblerError(Exception):
    pass


def assemble(source: str) -> list[int]:
    try:
        instructions = resolve_labels(source)

        machine_code = [
            encode_instruction(instruction)
            for instruction in instructions
        ]

    except (
        AssemblySyntaxError,
        LabelResolutionError,
        EncodingError,
    ) as error:
        raise AssemblerError(str(error)) from error

    return machine_code


def assemble_to_bytes(source: str) -> bytes:
    machine_code = assemble(source)

    try:
        return machine_code_to_bytes(machine_code)
    except OutputError as error:
        raise AssemblerError(str(error)) from error


def assemble_file(
    source_path: str | Path,
    output_path: str | Path,
    hex_output_path: str | Path | None = None,
) -> Path:
    source_file = Path(source_path)

    try:
        source = source_file.read_text(encoding="utf-8")
    except OSError as error:
        raise AssemblerError(
            f"Unable to read source file '{source_file}': {error}"
        ) from error

    machine_code = assemble(source)

    try:
        binary_path = write_binary_file(
            machine_code,
            output_path,
        )

        if hex_output_path is not None:
            write_hex_file(
                machine_code,
                hex_output_path,
            )

    except OutputError as error:
        raise AssemblerError(str(error)) from error

    return binary_path
