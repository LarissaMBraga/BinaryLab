
import unittest

from binary_lab_assembler.labels import (
    LabelResolutionError,
    resolve_labels,
)


class TestLabelResolution(unittest.TestCase):

    def test_resolve_forward_label(self):
        source = """
            JMP END
            NOP
            END:
            HALT
        """

        instructions = resolve_labels(source)

        self.assertEqual(instructions[0].operands, ("1",))

    def test_resolve_backward_label(self):
        source = """
            START:
            NOP
            NOP
            JMP START
        """

        instructions = resolve_labels(source)

        self.assertEqual(instructions[2].operands, ("-3",))

    def test_resolve_label_on_instruction_line(self):
        source = """
            START: NOP
            JMP START
        """

        instructions = resolve_labels(source)

        self.assertEqual(instructions[1].operands, ("-2",))

    def test_resolve_beq_label(self):
        source = """
            BEQ END
            NOP
            END: HALT
        """

        instructions = resolve_labels(source)

        self.assertEqual(instructions[0].operands, ("1",))

    def test_resolve_bne_label(self):
        source = """
            START: NOP
            BNE START
        """

        instructions = resolve_labels(source)

        self.assertEqual(instructions[1].operands, ("-2",))

    def test_labels_are_case_insensitive(self):
        source = """
            Start: NOP
            JMP start
        """

        instructions = resolve_labels(source)

        self.assertEqual(instructions[1].operands, ("-2",))

    def test_preserve_numeric_branch_offset(self):
        source = """
            JMP -4
            BEQ 2
        """

        instructions = resolve_labels(source)

        self.assertEqual(instructions[0].operands, ("-4",))
        self.assertEqual(instructions[1].operands, ("2",))

    def test_reject_duplicate_labels(self):
        source = """
            LOOP: NOP
            LOOP: HALT
        """

        with self.assertRaises(LabelResolutionError):
            resolve_labels(source)

    def test_reject_undefined_label(self):
        source = """
            JMP MISSING
        """

        with self.assertRaises(LabelResolutionError):
            resolve_labels(source)

    def test_ignore_labels_in_comments(self):
        source = """
            NOP ; FAKE:
            HALT # ANOTHER_FAKE:
        """

        instructions = resolve_labels(source)

        self.assertEqual(len(instructions), 2)

    def test_label_can_point_to_end_of_program(self):
        source = """
            JMP END
            END:
        """

        instructions = resolve_labels(source)

        self.assertEqual(instructions[0].operands, ("0",))

    def test_preserve_line_numbers(self):
        source = """
            START:
            NOP
            JMP START
        """

        instructions = resolve_labels(source)

        self.assertEqual(instructions[0].line_number, 3)


if __name__ == "__main__":
    unittest.main()
