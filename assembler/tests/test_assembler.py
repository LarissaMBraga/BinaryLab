
import unittest

from binary_lab_assembler.assembler import (
    AssemblerError,
    assemble,
)


class TestAssembler(unittest.TestCase):

    def test_assemble_simple_program(self):
        source = """
            ADDI R1, 10
            ADDI R2, 20
            ADD R1, R2
            HALT
        """

        self.assertEqual(
            assemble(source),
            [0x820A, 0x8414, 0x3280, 0x1000],
        )

    def test_assemble_program_with_forward_label(self):
        source = """
            JMP END
            NOP
            END:
            HALT
        """

        self.assertEqual(
            assemble(source),
            [0xB001, 0x0000, 0x1000],
        )

    def test_assemble_program_with_backward_label(self):
        source = """
            START:
            NOP
            NOP
            JMP START
        """

        self.assertEqual(
            assemble(source),
            [0x0000, 0x0000, 0xBFFD],
        )

    def test_assemble_beq_with_label(self):
        source = """
            BEQ END
            NOP
            END:
            HALT
        """

        self.assertEqual(
            assemble(source),
            [0xC001, 0x0000, 0x1000],
        )

    def test_assemble_bne_with_label(self):
        source = """
            START: NOP
            BNE START
        """

        self.assertEqual(
            assemble(source),
            [0x0000, 0xDFFE],
        )

    def test_assemble_empty_source(self):
        self.assertEqual(assemble(""), [])

    def test_assemble_comments_only(self):
        source = """
            ; comment
            # another comment
        """

        self.assertEqual(assemble(source), [])

    def test_reject_undefined_label(self):
        with self.assertRaises(AssemblerError):
            assemble("JMP MISSING")

    def test_reject_invalid_instruction(self):
        with self.assertRaises(AssemblerError):
            assemble("INVALID R1, R2")

    def test_reject_invalid_operand(self):
        with self.assertRaises(AssemblerError):
            assemble("ADDI R1, 200")

    def test_reject_wrong_operand_count(self):
        with self.assertRaises(AssemblerError):
            assemble("ADD R1")

    def test_reject_duplicate_label(self):
        source = """
            LOOP: NOP
            LOOP: HALT
        """

        with self.assertRaises(AssemblerError):
            assemble(source)

    def test_reject_branch_offset_out_of_range(self):
        with self.assertRaises(AssemblerError):
            assemble("JMP 2048")


if __name__ == "__main__":
    unittest.main()
