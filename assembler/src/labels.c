
#include "binary_lab.h"

#include <ctype.h>
#include <string.h>

static bool is_branch_instruction(const char *mnemonic) {
    return strcmp(mnemonic, "JMP") == 0 ||
           strcmp(mnemonic, "BEQ") == 0 ||
           strcmp(mnemonic, "BNE") == 0;
}

static bool is_numeric_operand(const char *operand) {
    if (operand == NULL || operand[0] == '\0') {
        return false;
    }

    const char *cursor = operand;

    if (*cursor == '-') {
        cursor++;
    }

    if (*cursor == '\0') {
        return false;
    }

    if (cursor[0] == '0' &&
        (cursor[1] == 'X' || cursor[1] == 'x')) {
        cursor += 2;

        if (*cursor == '\0') {
            return false;
        }

        while (*cursor != '\0') {
            if (!isxdigit((unsigned char)*cursor)) {
                return false;
            }

            cursor++;
        }

        return true;
    }

    while (*cursor != '\0') {
        if (!isdigit((unsigned char)*cursor)) {
            return false;
        }

        cursor++;
    }

    return true;
}

static const Label *find_label(
    const LabelTable *labels,
    const char *name
) {
    if (labels == NULL || name == NULL) {
        return NULL;
    }

    for (size_t index = 0; index < labels->count; index++) {
        if (strcmp(labels->items[index].name, name) == 0) {
            return &labels->items[index];
        }
    }

    return NULL;
}

bool resolve_labels(
    InstructionList *instructions,
    const LabelTable *labels,
    AssemblerError *error
) {
    if (instructions == NULL || labels == NULL ||
        (instructions->count > 0 && instructions->items == NULL) ||
        (labels->count > 0 && labels->items == NULL)) {
        set_error(error, 0, "Invalid label resolver input.");
        return false;
    }

    for (size_t index = 0; index < instructions->count; index++) {
        Instruction *instruction = &instructions->items[index];

        if (!is_branch_instruction(instruction->mnemonic)) {
            continue;
        }

        const char *operand = instruction->operands[0];

        if (is_numeric_operand(operand)) {
            continue;
        }

        const Label *label = find_label(labels, operand);

        if (label == NULL) {
            set_error(
                error,
                instruction->line_number,
                "Undefined label: %s",
                operand
            );

            return false;
        }

        int64_t current_address = instruction->address;
        int64_t next_address = current_address + INSTRUCTION_SIZE;
        int64_t byte_offset = (int64_t)label->address - next_address;

        if (byte_offset % INSTRUCTION_SIZE != 0) {
            set_error(
                error,
                instruction->line_number,
                "Label target is not instruction-aligned: %s",
                operand
            );

            return false;
        }

        int64_t branch_offset = byte_offset / INSTRUCTION_SIZE;

        if (branch_offset < MIN_BRANCH_OFFSET ||
            branch_offset > MAX_BRANCH_OFFSET) {
            set_error(
                error,
                instruction->line_number,
                "Branch offset out of range for label: %s",
                operand
            );

            return false;
        }

        snprintf(
            instruction->operands[0],
            MAX_LINE_LENGTH,
            "%lld",
            (long long)branch_offset
        );
    }

    return true;
}
