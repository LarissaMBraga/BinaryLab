
#ifndef BINARY_LAB_H
#define BINARY_LAB_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#define BINARY_LAB_VERSION "1.0.0"

#define DATA_WIDTH 8
#define ADDRESS_WIDTH 16
#define INSTRUCTION_WIDTH 16
#define INSTRUCTION_SIZE 2

#define REGISTER_COUNT 8

#define MAX_INSTRUCTIONS 32768
#define MAX_LABELS 32768

#define MAX_LINE_LENGTH 256
#define MAX_OPERANDS 2
#define MAX_LABEL_LENGTH 64
#define MAX_PATH_LENGTH 1024

#define MIN_IMMEDIATE (-128)
#define MAX_IMMEDIATE 127

#define MIN_MEMORY_OFFSET (-32)
#define MAX_MEMORY_OFFSET 31

#define MIN_BRANCH_OFFSET (-2048)
#define MAX_BRANCH_OFFSET 2047

typedef enum {
    OPCODE_NOP  = 0x0,
    OPCODE_HALT = 0x1,
    OPCODE_MOV  = 0x2,
    OPCODE_ADD  = 0x3,
    OPCODE_SUB  = 0x4,
    OPCODE_AND  = 0x5,
    OPCODE_OR   = 0x6,
    OPCODE_XOR  = 0x7,
    OPCODE_ADDI = 0x8,
    OPCODE_LD   = 0x9,
    OPCODE_ST   = 0xA,
    OPCODE_JMP  = 0xB,
    OPCODE_BEQ  = 0xC,
    OPCODE_BNE  = 0xD,
    OPCODE_CMP  = 0xE
} Opcode;

typedef enum {
    FORMAT_R,
    FORMAT_I,
    FORMAT_M,
    FORMAT_B
} InstructionFormat;

typedef struct {
    const char *mnemonic;
    Opcode opcode;
    InstructionFormat format;
    uint8_t operand_count;
} InstructionDefinition;

typedef struct {
    char mnemonic[16];
    char operands[MAX_OPERANDS][MAX_LINE_LENGTH];
    uint8_t operand_count;
    uint32_t line_number;
    uint32_t address;
} Instruction;

typedef struct {
    char name[MAX_LABEL_LENGTH];
    uint32_t address;
    uint32_t line_number;
} Label;

typedef struct {
    Instruction *items;
    size_t count;
    size_t capacity;
} InstructionList;

typedef struct {
    Label *items;
    size_t count;
    size_t capacity;
} LabelTable;

typedef struct {
    uint16_t *words;
    size_t count;
    size_t capacity;
} MachineCode;

typedef struct {
    char message[512];
    uint32_t line_number;
} AssemblerError;

const InstructionDefinition *find_instruction(
    const char *mnemonic
);

bool validate_instruction(
    const Instruction *instruction,
    AssemblerError *error
);

bool parse_source(
    const char *source,
    InstructionList *instructions,
    LabelTable *labels,
    AssemblerError *error
);

bool resolve_labels(
    InstructionList *instructions,
    const LabelTable *labels,
    AssemblerError *error
);

bool encode_instruction(
    const Instruction *instruction,
    uint16_t *machine_code,
    AssemblerError *error
);

bool encode_program(
    const InstructionList *instructions,
    MachineCode *machine_code,
    AssemblerError *error
);

bool write_binary_file(
    const char *path,
    const MachineCode *machine_code,
    AssemblerError *error
);

bool write_hex_file(
    const char *path,
    const MachineCode *machine_code,
    AssemblerError *error
);

void free_instruction_list(
    InstructionList *instructions
);

void free_label_table(
    LabelTable *labels
);

void free_machine_code(
    MachineCode *machine_code
);

void set_error(
    AssemblerError *error,
    uint32_t line_number,
    const char *format,
    ...
);

#endif
