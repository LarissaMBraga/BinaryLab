
#include "binary_lab.h"

#include <ctype.h>
#include <string.h>

static const InstructionDefinition instruction_set[] = {
    {"NOP",  OPCODE_NOP,  FORMAT_R, 0},
    {"HALT", OPCODE_HALT, FORMAT_R, 0},
    {"MOV",  OPCODE_MOV,  FORMAT_R, 2},
    {"ADD",  OPCODE_ADD,  FORMAT_R, 2},
    {"SUB",  OPCODE_SUB,  FORMAT_R, 2},
    {"AND",  OPCODE_AND,  FORMAT_R, 2},
    {"OR",   OPCODE_OR,   FORMAT_R, 2},
    {"XOR",  OPCODE_XOR,  FORMAT_R, 2},
    {"ADDI", OPCODE_ADDI, FORMAT_I, 2},
    {"LD",   OPCODE_LD,   FORMAT_M, 2},
    {"ST",   OPCODE_ST,   FORMAT_M, 2},
    {"JMP",  OPCODE_JMP,  FORMAT_B, 1},
    {"BEQ",  OPCODE_BEQ,  FORMAT_B, 1},
    {"BNE",  OPCODE_BNE,  FORMAT_B, 1},
    {"CMP",  OPCODE_CMP,  FORMAT_R, 2},
    {"SHL",  OPCODE_EXT,  FORMAT_R, 2},
    {"SHR",  OPCODE_EXT,  FORMAT_R, 2},
    {"SAR",  OPCODE_EXT,  FORMAT_R, 2},
    {"ROL",  OPCODE_EXT,  FORMAT_R, 2},
    {"ROR",  OPCODE_EXT,  FORMAT_R, 2},
    {"NOT",  OPCODE_EXT,  FORMAT_R, 1},
    {"MUL",  OPCODE_EXT,  FORMAT_R, 2},
    {"DIV",  OPCODE_EXT,  FORMAT_R, 2}
};

static const size_t instruction_set_count =
    sizeof(instruction_set) / sizeof(instruction_set[0]);

const InstructionDefinition *find_instruction(
    const char *mnemonic
) {
    if (mnemonic == NULL) {
        return NULL;
    }

    for (size_t index = 0; index < instruction_set_count; index++) {
        if (strcmp(instruction_set[index].mnemonic, mnemonic) == 0) {
            return &instruction_set[index];
        }
    }

    return NULL;
}

bool validate_instruction(
    const Instruction *instruction,
    AssemblerError *error
) {
    if (instruction == NULL) {
        set_error(error, 0, "Invalid instruction reference.");
        return false;
    }

    const InstructionDefinition *definition =
        find_instruction(instruction->mnemonic);

    if (definition == NULL) {
        set_error(
            error,
            instruction->line_number,
            "Unsupported instruction: %s",
            instruction->mnemonic
        );

        return false;
    }

    if (instruction->operand_count != definition->operand_count) {
        set_error(
            error,
            instruction->line_number,
            "%s expects %u operand(s), got %u.",
            definition->mnemonic,
            definition->operand_count,
            instruction->operand_count
        );

        return false;
    }

    return true;
}
