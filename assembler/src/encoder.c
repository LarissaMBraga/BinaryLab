
#include "binary_lab.h"

#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>

static bool parse_register(
    const char *operand,
    uint8_t *register_number
) {
    if (operand == NULL || register_number == NULL) {
        return false;
    }

    if (operand[0] != 'R' ||
        operand[1] < '0' ||
        operand[1] > '7' ||
        operand[2] != '\0') {
        return false;
    }

    *register_number = (uint8_t)(operand[1] - '0');

    return true;
}

static bool parse_integer(
    const char *operand,
    int32_t *value
) {
    if (operand == NULL || value == NULL || operand[0] == '\0') {
        return false;
    }

    const char *digits = operand;

    if (*digits == '-') {
        digits++;
    }

    if (*digits == '\0') {
        return false;
    }

    int base = 10;

    if (digits[0] == '0' &&
        (digits[1] == 'X' || digits[1] == 'x')) {
        digits += 2;
        base = 16;

        if (*digits == '\0') {
            return false;
        }
    } else if (digits[0] == '0' && digits[1] != '\0') {
        return false;
    }

    for (const char *cursor = digits; *cursor != '\0'; cursor++) {
        if (base == 16) {
            if (!isxdigit((unsigned char)*cursor)) {
                return false;
            }
        } else if (!isdigit((unsigned char)*cursor)) {
            return false;
        }
    }

    errno = 0;

    char *end = NULL;
    long parsed = strtol(operand, &end, base);

    if (errno == ERANGE || *end != '\0') {
        return false;
    }

    if (parsed < INT32_MIN || parsed > INT32_MAX) {
        return false;
    }

    *value = (int32_t)parsed;

    return true;
}

static bool parse_memory_operand(
    const char *operand,
    uint8_t *base_register,
    int32_t *offset
) {
    if (operand == NULL ||
        base_register == NULL ||
        offset == NULL) {
        return false;
    }

    size_t length = strlen(operand);

    if (length < 4 ||
        operand[0] != '[' ||
        operand[length - 1] != ']') {
        return false;
    }

    char content[MAX_LINE_LENGTH];

    size_t content_length = length - 2;

    if (content_length >= sizeof(content)) {
        return false;
    }

    memcpy(content, operand + 1, content_length);
    content[content_length] = '\0';

    char *cursor = content;

    while (isspace((unsigned char)*cursor)) {
        cursor++;
    }

    if (*cursor != 'R' ||
        cursor[1] < '0' ||
        cursor[1] > '7') {
        return false;
    }

    uint8_t parsed_register = (uint8_t)(cursor[1] - '0');
    cursor += 2;

    while (isspace((unsigned char)*cursor)) {
        cursor++;
    }

    int32_t memory_offset = 0;

    if (*cursor != '\0') {
        char sign = *cursor;

        if (sign != '+' && sign != '-') {
            return false;
        }

        cursor++;

        while (isspace((unsigned char)*cursor)) {
            cursor++;
        }

        if (*cursor == '\0') {
            return false;
        }

        size_t offset_length = strlen(cursor);

        while (offset_length > 0 &&
               isspace((unsigned char)cursor[offset_length - 1])) {
            offset_length--;
        }

        if (offset_length == 0 ||
            offset_length >= MAX_LINE_LENGTH) {
            return false;
        }

        char offset_text[MAX_LINE_LENGTH];

        memcpy(offset_text, cursor, offset_length);
        offset_text[offset_length] = '\0';

        int32_t parsed_offset;

        if (!parse_integer(offset_text, &parsed_offset)) {
            return false;
        }

        if (sign == '-') {
            if (parsed_offset < 0) {
                return false;
            }

            memory_offset = -parsed_offset;
        } else {
            if (parsed_offset < 0) {
                return false;
            }

            memory_offset = parsed_offset;
        }
    }

    if (memory_offset < MIN_MEMORY_OFFSET ||
        memory_offset > MAX_MEMORY_OFFSET) {
        return false;
    }

    *base_register = parsed_register;
    *offset = memory_offset;

    return true;
}

bool encode_instruction(
    const Instruction *instruction,
    uint16_t *machine_code,
    AssemblerError *error
) {
    if (instruction == NULL || machine_code == NULL) {
        set_error(error, 0, "Invalid encoder input.");
        return false;
    }

    if (!validate_instruction(instruction, error)) {
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

    uint16_t encoded = (uint16_t)(definition->opcode << 12);

    uint8_t destination;
    uint8_t source;
    int32_t immediate;

    switch (definition->format) {
        case FORMAT_R:
            if (definition->operand_count == 0) {
                *machine_code = encoded;
                return true;
            }

            if (!parse_register(
                instruction->operands[0],
                &destination
            )) {
                set_error(
                    error,
                    instruction->line_number,
                    "Invalid destination register: %s",
                    instruction->operands[0]
                );

                return false;
            }

            if (!parse_register(
                instruction->operands[1],
                &source
            )) {
                set_error(
                    error,
                    instruction->line_number,
                    "Invalid source register: %s",
                    instruction->operands[1]
                );

                return false;
            }

            encoded |= (uint16_t)(destination << 9);
            encoded |= (uint16_t)(source << 6);

            break;

        case FORMAT_I: {
            if (!parse_register(
                instruction->operands[0],
                &destination
            )) {
                set_error(
                    error,
                    instruction->line_number,
                    "Invalid destination register: %s",
                    instruction->operands[0]
                );

                return false;
            }

            if (!parse_integer(
                instruction->operands[1],
                &immediate
            )) {
                set_error(
                    error,
                    instruction->line_number,
                    "Invalid immediate value: %s",
                    instruction->operands[1]
                );

                return false;
            }

            if (immediate < MIN_IMMEDIATE ||
                immediate > MAX_IMMEDIATE) {
                set_error(
                    error,
                    instruction->line_number,
                    "Immediate value must be between %d and %d.",
                    MIN_IMMEDIATE,
                    MAX_IMMEDIATE
                );

                return false;
            }

            uint8_t encoded_immediate = (uint8_t)immediate;
            uint16_t sign_extension = (encoded_immediate >> 7) & 1;

            encoded |= (uint16_t)(destination << 9);
            encoded |= (uint16_t)(sign_extension << 8);
            encoded |= encoded_immediate;

            break;
        }

        case FORMAT_M: {
            if (!parse_register(
                instruction->operands[0],
                &destination
            )) {
                set_error(
                    error,
                    instruction->line_number,
                    "Invalid data register: %s",
                    instruction->operands[0]
                );

                return false;
            }

            uint8_t base_register;
            int32_t memory_offset;

            if (!parse_memory_operand(
                instruction->operands[1],
                &base_register,
                &memory_offset
            )) {
                set_error(
                    error,
                    instruction->line_number,
                    "Invalid memory operand: %s",
                    instruction->operands[1]
                );

                return false;
            }

            encoded |= (uint16_t)(destination << 9);
            encoded |= (uint16_t)(base_register << 6);
            encoded |= (uint16_t)(memory_offset & 0x3F);

            break;
        }

        case FORMAT_B:
            if (!parse_integer(
                instruction->operands[0],
                &immediate
            )) {
                set_error(
                    error,
                    instruction->line_number,
                    "Invalid branch offset: %s",
                    instruction->operands[0]
                );

                return false;
            }

            if (immediate < MIN_BRANCH_OFFSET ||
                immediate > MAX_BRANCH_OFFSET) {
                set_error(
                    error,
                    instruction->line_number,
                    "Branch offset must be between %d and %d.",
                    MIN_BRANCH_OFFSET,
                    MAX_BRANCH_OFFSET
                );

                return false;
            }

            encoded |= (uint16_t)(immediate & 0x0FFF);

            break;
    }

    *machine_code = encoded;

    return true;
}

bool encode_program(
    const InstructionList *instructions,
    MachineCode *machine_code,
    AssemblerError *error
) {
    if (instructions == NULL ||
        machine_code == NULL ||
        (instructions->count > 0 && instructions->items == NULL)) {
        set_error(error, 0, "Invalid program encoder input.");
        return false;
    }

    if (machine_code->words != NULL) {
        set_error(error, 0, "Machine code output must be empty.");
        return false;
    }

    machine_code->count = 0;
    machine_code->capacity = 0;

    if (instructions->count == 0) {
        return true;
    }

    machine_code->words = malloc(
        instructions->count * sizeof(uint16_t)
    );

    if (machine_code->words == NULL) {
        set_error(error, 0, "Unable to allocate machine code memory.");
        return false;
    }

    machine_code->capacity = instructions->count;

    for (size_t index = 0; index < instructions->count; index++) {
        if (!encode_instruction(
            &instructions->items[index],
            &machine_code->words[index],
            error
        )) {
            free(machine_code->words);
            machine_code->words = NULL;
            machine_code->count = 0;
            machine_code->capacity = 0;

            return false;
        }

        machine_code->count++;
    }

    return true;
}
