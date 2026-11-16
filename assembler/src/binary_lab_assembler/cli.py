
import argparse
import sys

from binary_lab_assembler.assembler import (
    AssemblerError,
    assemble_file,
)


def create_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="binary-lab-assembler",
        description="Assemble BINARY LAB source files into machine code.",
    )

    parser.add_argument(
        "source",
        help="Path to the Assembly source file.",
    )

    parser.add_argument(
        "-o",
        "--output",
        required=True,
        help="Path to the generated binary file.",
    )

    parser.add_argument(
        "--hex-output",
        help="Optional path to the generated HEX file.",
    )

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = create_argument_parser()
    arguments = parser.parse_args(argv)

    try:
        output_path = assemble_file(
            arguments.source,
            arguments.output,
            arguments.hex_output,
        )
    except AssemblerError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    output_size = output_path.stat().st_size

    print(
        f"Successfully assembled '{arguments.source}' "
        f"-> '{output_path}' ({output_size} bytes)."
    )

    if arguments.hex_output:
        print(
            f"HEX output generated: '{arguments.hex_output}'."
        )

    return 0
