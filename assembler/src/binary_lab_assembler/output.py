
from pathlib import Path


class OutputError(Exception):
    pass


def machine_code_to_bytes(machine_code: list[int]) -> bytes:
    output = bytearray()

    for index, instruction in enumerate(machine_code):
        if (
            not isinstance(instruction, int)
            or isinstance(instruction, bool)
            or not 0 <= instruction <= 0xFFFF
        ):
            raise OutputError(
                f"Invalid machine instruction at index {index}: "
                f"{instruction!r}. Expected a 16-bit unsigned integer."
            )

        output.extend(instruction.to_bytes(2, byteorder="big"))

    return bytes(output)


def machine_code_to_hex(machine_code: list[int]) -> str:
    binary_data = machine_code_to_bytes(machine_code)

    if not binary_data:
        return ""

    return "\n".join(
        f"{byte:02X}" for byte in binary_data
    ) + "\n"


def write_binary_file(
    machine_code: list[int],
    output_path: str | Path,
) -> Path:
    binary_data = machine_code_to_bytes(machine_code)
    destination = Path(output_path)

    try:
        destination.write_bytes(binary_data)
    except OSError as error:
        raise OutputError(
            f"Unable to write binary file '{destination}': {error}"
        ) from error

    return destination


def write_hex_file(
    machine_code: list[int],
    output_path: str | Path,
) -> Path:
    hex_data = machine_code_to_hex(machine_code)
    destination = Path(output_path)

    try:
        destination.write_text(hex_data, encoding="ascii")
    except OSError as error:
        raise OutputError(
            f"Unable to write HEX file '{destination}': {error}"
        ) from error

    return destination
