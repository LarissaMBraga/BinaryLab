
import tempfile
import unittest
from pathlib import Path

from binary_lab_assembler.assembler import (
    AssemblerError,
    assemble_file,
    assemble_to_bytes,
)
from binary_lab_assembler.output import (
    OutputError,
    machine_code_to_bytes,
    machine_code_to_hex,
    write_binary_file,
    write_hex_file,
)


class TestBinaryOutput(unittest.TestCase):

    def test_convert_instruction_to_big_endian(self):
        result = machine_code_to_bytes([0x820A])

        self.assertEqual(result, bytes([0x82, 0x0A]))

    def test_convert_multiple_instructions(self):
        result = machine_code_to_bytes([
            0x820A,
            0x8414,
            0x3280,
            0x1000,
        ])

        self.assertEqual(
            result,
            bytes([
                0x82, 0x0A,
                0x84, 0x14,
                0x32, 0x80,
                0x10, 0x00,
            ]),
        )

    def test_convert_empty_machine_code(self):
        self.assertEqual(machine_code_to_bytes([]), b"")

    def test_reject_negative_instruction(self):
        with self.assertRaises(OutputError):
            machine_code_to_bytes([-1])

    def test_reject_instruction_above_16_bits(self):
        with self.assertRaises(OutputError):
            machine_code_to_bytes([0x10000])

    def test_reject_non_integer_instruction(self):
        with self.assertRaises(OutputError):
            machine_code_to_bytes(["0x1000"])

    def test_reject_boolean_instruction(self):
        with self.assertRaises(OutputError):
            machine_code_to_bytes([True])

    def test_write_binary_file(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            output_path = Path(temporary_directory) / "program.bin"

            result = write_binary_file(
                [0x820A, 0x1000],
                output_path,
            )

            self.assertEqual(result, output_path)
            self.assertTrue(output_path.exists())
            self.assertEqual(
                output_path.read_bytes(),
                bytes([0x82, 0x0A, 0x10, 0x00]),
            )

    def test_convert_machine_code_to_hex(self):
        result = machine_code_to_hex([
            0x820A,
            0x8414,
            0x3280,
            0x1000,
        ])

        self.assertEqual(
            result,
            "82\n0A\n84\n14\n32\n80\n10\n00\n",
        )

    def test_convert_empty_machine_code_to_hex(self):
        self.assertEqual(machine_code_to_hex([]), "")

    def test_write_hex_file(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            output_path = Path(temporary_directory) / "program.hex"

            result = write_hex_file(
                [0x820A, 0x1000],
                output_path,
            )

            self.assertEqual(result, output_path)
            self.assertTrue(output_path.exists())
            self.assertEqual(
                output_path.read_text(encoding="ascii"),
                "82\n0A\n10\n00\n",
            )

    def test_assemble_to_bytes(self):
        source = """
            ADDI R1, 10
            HALT
        """

        self.assertEqual(
            assemble_to_bytes(source),
            bytes([0x82, 0x0A, 0x10, 0x00]),
        )

    def test_assemble_file(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            source_path = Path(temporary_directory) / "program.asm"
            output_path = Path(temporary_directory) / "program.bin"

            source_path.write_text(
                "ADDI R1, 10\nHALT\n",
                encoding="utf-8",
            )

            result = assemble_file(source_path, output_path)

            self.assertEqual(result, output_path)
            self.assertTrue(output_path.exists())
            self.assertEqual(
                output_path.read_bytes(),
                bytes([0x82, 0x0A, 0x10, 0x00]),
            )

    def test_assemble_file_with_hex_output(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)

            source_path = directory / "program.asm"
            binary_path = directory / "program.bin"
            hex_path = directory / "program.hex"

            source_path.write_text(
                "ADDI R1, 10\nHALT\n",
                encoding="utf-8",
            )

            result = assemble_file(
                source_path,
                binary_path,
                hex_path,
            )

            self.assertEqual(result, binary_path)
            self.assertTrue(binary_path.exists())
            self.assertTrue(hex_path.exists())

            self.assertEqual(
                binary_path.read_bytes(),
                bytes([0x82, 0x0A, 0x10, 0x00]),
            )

            self.assertEqual(
                hex_path.read_text(encoding="ascii"),
                "82\n0A\n10\n00\n",
            )

    def test_reject_missing_source_file(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            source_path = Path(temporary_directory) / "missing.asm"
            output_path = Path(temporary_directory) / "program.bin"

            with self.assertRaises(AssemblerError):
                assemble_file(source_path, output_path)

    def test_reject_invalid_assembly_file(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            source_path = Path(temporary_directory) / "invalid.asm"
            output_path = Path(temporary_directory) / "program.bin"

            source_path.write_text(
                "INVALID R1, R2\n",
                encoding="utf-8",
            )

            with self.assertRaises(AssemblerError):
                assemble_file(source_path, output_path)


if __name__ == "__main__":
    unittest.main()
