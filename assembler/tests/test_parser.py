
import unittest

from binary_lab_assembler.parser import (
    AssemblySyntaxError,
    parse_line,
    parse_source,
)


class TestParser(unittest.TestCase):

    def test_parse_instruction_without_operands(self):
        instruction = parse_line("HALT")

        self.assertEqual(instruction.mnemonic, "HALT")
        self.assertEqual(instruction.operands, ())

    def test_parse_instruction_with_one_operand(self):
        instruction = parse_line("JMP -2")

        self.assertEqual(instruction.mnemonic, "JMP")
        self.assertEqual(instruction.operands, ("-2",))

    def test_parse_instruction_with_two_operands(self):
        instruction = parse_line("ADD R1, R2")

        self.assertEqual(instruction.mnemonic, "ADD")
        self.assertEqual(instruction.operands, ("R1", "R2"))

    def test_parse_memory_operand(self):
        instruction = parse_line("LD R1, [R2 + 4]")

        self.assertEqual(instruction.mnemonic, "LD")
        self.assertEqual(
            instruction.operands,
            ("R1", "[R2 + 4]"),
        )

    def test_ignore_comments(self):
        instruction = parse_line("ADD R1, R2 ; addition")

        self.assertEqual(instruction.mnemonic, "ADD")
        self.assertEqual(instruction.operands, ("R1", "R2"))

    def test_ignore_empty_lines_and_comments(self):
        self.assertIsNone(parse_line(""))
        self.assertIsNone(parse_line("   "))
        self.assertIsNone(parse_line("; comment"))
        self.assertIsNone(parse_line("# comment"))

    def test_reject_empty_operand(self):
        with self.assertRaises(AssemblySyntaxError):
            parse_line("ADD R1,")

    def test_preserve_line_numbers(self):
        instructions = parse_source(
            "\n"
            "ADDI R1, 5\n"
            "\n"
            "HALT\n"
        )

        self.assertEqual(instructions[0].line_number, 2)
        self.assertEqual(instructions[1].line_number, 4)

    def test_parse_multiple_instructions(self):
        source = """
            ADDI R1, 5
            ADDI R2, 3
            ADD R1, R2
            HALT
        """

        instructions = parse_source(source)

        self.assertEqual(len(instructions), 4)
        self.assertEqual(
            [instruction.mnemonic for instruction in instructions],
            ["ADDI", "ADDI", "ADD", "HALT"],
        )


if __name__ == "__main__":
    unittest.main()
