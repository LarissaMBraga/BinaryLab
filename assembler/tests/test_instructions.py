
import unittest

from binary_lab_assembler.parser import Instruction, parse_line
from binary_lab_assembler.instructions import (
    INSTRUCTION_SET,
    InstructionFormat,
    InstructionValidationError,
    get_instruction_definition,
    validate_instruction,
)


class TestInstructionDefinitions(unittest.TestCase):

    def test_instruction_set_contains_all_supported_instructions(self):
        expected = {
            "NOP", "HALT", "MOV", "ADD", "SUB",
            "AND", "OR", "XOR", "ADDI", "LD",
            "ST", "JMP", "BEQ", "BNE", "CMP",
        }

        self.assertEqual(set(INSTRUCTION_SET.keys()), expected)

    def test_opcodes_are_correct(self):
        expected_opcodes = {
            "NOP": 0x0,
            "HALT": 0x1,
            "MOV": 0x2,
            "ADD": 0x3,
            "SUB": 0x4,
            "AND": 0x5,
            "OR": 0x6,
            "XOR": 0x7,
            "ADDI": 0x8,
            "LD": 0x9,
            "ST": 0xA,
            "JMP": 0xB,
            "BEQ": 0xC,
            "BNE": 0xD,
            "CMP": 0xE,
        }

        for mnemonic, expected_opcode in expected_opcodes.items():
            with self.subTest(mnemonic=mnemonic):
                definition = get_instruction_definition(mnemonic)
                self.assertEqual(definition.opcode, expected_opcode)

    def test_instruction_formats(self):
        expected_formats = {
            "ADD": InstructionFormat.R,
            "CMP": InstructionFormat.R,
            "ADDI": InstructionFormat.I,
            "LD": InstructionFormat.M,
            "ST": InstructionFormat.M,
            "JMP": InstructionFormat.B,
            "BEQ": InstructionFormat.B,
            "BNE": InstructionFormat.B,
        }

        for mnemonic, expected_format in expected_formats.items():
            with self.subTest(mnemonic=mnemonic):
                definition = get_instruction_definition(mnemonic)
                self.assertEqual(definition.format, expected_format)

    def test_operand_counts(self):
        expected_counts = {
            "NOP": 0,
            "HALT": 0,
            "MOV": 2,
            "ADD": 2,
            "SUB": 2,
            "AND": 2,
            "OR": 2,
            "XOR": 2,
            "ADDI": 2,
            "LD": 2,
            "ST": 2,
            "JMP": 1,
            "BEQ": 1,
            "BNE": 1,
            "CMP": 2,
        }

        for mnemonic, expected_count in expected_counts.items():
            with self.subTest(mnemonic=mnemonic):
                definition = get_instruction_definition(mnemonic)
                self.assertEqual(definition.operand_count, expected_count)

    def test_instruction_lookup_is_case_insensitive(self):
        definition = get_instruction_definition("add")

        self.assertEqual(definition.mnemonic, "ADD")
        self.assertEqual(definition.opcode, 0x3)

    def test_unknown_instruction_is_rejected(self):
        with self.assertRaises(InstructionValidationError):
            get_instruction_definition("INVALID")

    def test_reserved_ext_instruction_is_rejected(self):
        with self.assertRaises(InstructionValidationError):
            get_instruction_definition("EXT")


class TestInstructionValidation(unittest.TestCase):

    def test_valid_instruction(self):
        instruction = parse_line("ADD R1, R2")
        definition = validate_instruction(instruction)

        self.assertEqual(definition.mnemonic, "ADD")

    def test_missing_operands_are_rejected(self):
        instruction = Instruction("ADD", ("R1",), 3)

        with self.assertRaises(InstructionValidationError):
            validate_instruction(instruction)

    def test_extra_operands_are_rejected(self):
        instruction = Instruction("HALT", ("R1",), 5)

        with self.assertRaises(InstructionValidationError):
            validate_instruction(instruction)

    def test_validation_error_contains_line_number(self):
        instruction = Instruction("JMP", (), 12)

        with self.assertRaisesRegex(
            InstructionValidationError,
            "Line 12",
        ):
            validate_instruction(instruction)


if __name__ == "__main__":
    unittest.main()
