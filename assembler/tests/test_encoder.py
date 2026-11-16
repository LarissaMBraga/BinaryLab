
import unittest

from binary_lab_assembler.encoder import (
    EncodingError,
    encode_instruction,
)
from binary_lab_assembler.parser import parse_line


class TestInstructionEncoder(unittest.TestCase):

    def test_encode_nop(self):
        self.assertEqual(encode_instruction(parse_line("NOP")), 0x0000)

    def test_encode_halt(self):
        self.assertEqual(encode_instruction(parse_line("HALT")), 0x1000)

    def test_encode_mov(self):
        self.assertEqual(encode_instruction(parse_line("MOV R1, R2")), 0x2280)

    def test_encode_add(self):
        self.assertEqual(encode_instruction(parse_line("ADD R1, R2")), 0x3280)

    def test_encode_sub(self):
        self.assertEqual(encode_instruction(parse_line("SUB R3, R4")), 0x4700)

    def test_encode_and(self):
        self.assertEqual(encode_instruction(parse_line("AND R0, R7")), 0x51C0)

    def test_encode_or(self):
        self.assertEqual(encode_instruction(parse_line("OR R2, R3")), 0x64C0)

    def test_encode_xor(self):
        self.assertEqual(encode_instruction(parse_line("XOR R5, R1")), 0x7A40)

    def test_encode_cmp(self):
        self.assertEqual(encode_instruction(parse_line("CMP R3, R1")), 0xE640)

    def test_encode_addi_positive(self):
        self.assertEqual(encode_instruction(parse_line("ADDI R1, 5")), 0x8205)

    def test_encode_addi_zero(self):
        self.assertEqual(encode_instruction(parse_line("ADDI R0, 0")), 0x8000)

    def test_encode_addi_negative_one(self):
        self.assertEqual(encode_instruction(parse_line("ADDI R1, -1")), 0x83FF)

    def test_encode_addi_minimum(self):
        self.assertEqual(encode_instruction(parse_line("ADDI R2, -128")), 0x8580)

    def test_encode_addi_maximum(self):
        self.assertEqual(encode_instruction(parse_line("ADDI R3, 127")), 0x867F)

    def test_encode_ld(self):
        self.assertEqual(encode_instruction(parse_line("LD R1, [R2 + 4]")), 0x9284)

    def test_encode_st(self):
        self.assertEqual(encode_instruction(parse_line("ST R3, [R4 + 8]")), 0xA708)

    def test_encode_ld_negative_offset(self):
        self.assertEqual(encode_instruction(parse_line("LD R1, [R2 - 4]")), 0x92BC)

    def test_encode_memory_without_offset(self):
        self.assertEqual(encode_instruction(parse_line("LD R1, [R2]")), 0x9280)

    def test_encode_memory_minimum_offset(self):
        self.assertEqual(encode_instruction(parse_line("LD R0, [R0 - 32]")), 0x9020)

    def test_encode_memory_maximum_offset(self):
        self.assertEqual(encode_instruction(parse_line("ST R7, [R7 + 31]")), 0xAFDF)

    def test_encode_jmp_forward(self):
        self.assertEqual(encode_instruction(parse_line("JMP 4")), 0xB004)

    def test_encode_jmp_backward(self):
        self.assertEqual(encode_instruction(parse_line("JMP -1")), 0xBFFF)

    def test_encode_beq(self):
        self.assertEqual(encode_instruction(parse_line("BEQ 10")), 0xC00A)

    def test_encode_bne(self):
        self.assertEqual(encode_instruction(parse_line("BNE -10")), 0xDFF6)

    def test_encode_branch_minimum_offset(self):
        self.assertEqual(encode_instruction(parse_line("JMP -2048")), 0xB800)

    def test_encode_branch_maximum_offset(self):
        self.assertEqual(encode_instruction(parse_line("JMP 2047")), 0xB7FF)

    def test_reject_addi_value_below_minimum(self):
        with self.assertRaises(EncodingError):
            encode_instruction(parse_line("ADDI R1, -129"))

    def test_reject_addi_value_above_maximum(self):
        with self.assertRaises(EncodingError):
            encode_instruction(parse_line("ADDI R1, 128"))

    def test_reject_memory_offset_below_minimum(self):
        with self.assertRaises(EncodingError):
            encode_instruction(parse_line("LD R1, [R2 - 33]"))

    def test_reject_memory_offset_above_maximum(self):
        with self.assertRaises(EncodingError):
            encode_instruction(parse_line("LD R1, [R2 + 32]"))

    def test_reject_invalid_memory_operand(self):
        with self.assertRaises(EncodingError):
            encode_instruction(parse_line("LD R1, R2"))

    def test_reject_invalid_memory_base_register(self):
        with self.assertRaises(EncodingError):
            encode_instruction(parse_line("LD R1, [R8 + 4]"))

    def test_reject_invalid_register(self):
        with self.assertRaises(EncodingError):
            encode_instruction(parse_line("ADD R8, R1"))

    def test_reject_invalid_register_format(self):
        with self.assertRaises(EncodingError):
            encode_instruction(parse_line("ADD RX, R1"))

    def test_reject_branch_offset_below_minimum(self):
        with self.assertRaises(EncodingError):
            encode_instruction(parse_line("JMP -2049"))

    def test_reject_branch_offset_above_maximum(self):
        with self.assertRaises(EncodingError):
            encode_instruction(parse_line("BEQ 2048"))

    def test_reject_invalid_branch_offset(self):
        with self.assertRaises(EncodingError):
            encode_instruction(parse_line("BNE LOOP"))


if __name__ == "__main__":
    unittest.main()
