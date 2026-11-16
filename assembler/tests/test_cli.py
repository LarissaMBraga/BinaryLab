
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from binary_lab_assembler.cli import (
    create_argument_parser,
    main,
)


class TestAssemblerCLI(unittest.TestCase):

    def test_parse_required_arguments(self):
        parser = create_argument_parser()

        arguments = parser.parse_args([
            "program.asm",
            "-o",
            "program.bin",
        ])

        self.assertEqual(arguments.source, "program.asm")
        self.assertEqual(arguments.output, "program.bin")
        self.assertIsNone(arguments.hex_output)

    def test_parse_hex_output_argument(self):
        parser = create_argument_parser()

        arguments = parser.parse_args([
            "program.asm",
            "-o",
            "program.bin",
            "--hex-output",
            "program.hex",
        ])

        self.assertEqual(arguments.hex_output, "program.hex")

    def test_main_generates_binary_and_hex(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)

            source_path = directory / "program.asm"
            binary_path = directory / "program.bin"
            hex_path = directory / "program.hex"

            source_path.write_text(
                "ADDI R1, 10\nHALT\n",
                encoding="utf-8",
            )

            result = main([
                str(source_path),
                "-o",
                str(binary_path),
                "--hex-output",
                str(hex_path),
            ])

            self.assertEqual(result, 0)
            self.assertEqual(
                binary_path.read_bytes(),
                bytes([0x82, 0x0A, 0x10, 0x00]),
            )
            self.assertEqual(
                hex_path.read_text(encoding="ascii"),
                "82\n0A\n10\n00\n",
            )

    def test_main_generates_binary_without_hex(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)

            source_path = directory / "program.asm"
            binary_path = directory / "program.bin"

            source_path.write_text(
                "HALT\n",
                encoding="utf-8",
            )

            result = main([
                str(source_path),
                "-o",
                str(binary_path),
            ])

            self.assertEqual(result, 0)
            self.assertTrue(binary_path.exists())

    def test_main_reports_assembly_error(self):
        with patch(
            "binary_lab_assembler.cli.assemble_file",
            side_effect=Exception("Unexpected error"),
        ):
            with self.assertRaises(Exception):
                main([
                    "program.asm",
                    "-o",
                    "program.bin",
                ])


if __name__ == "__main__":
    unittest.main()
