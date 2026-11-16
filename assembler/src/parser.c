
#include "binary_lab.h"

#include <ctype.h>
#include <stdlib.h>
#include <string.h>

static void trim(char *text) {
    if (text == NULL) {
        return;
    }

    char *start = text;

    while (isspace((unsigned char)*start)) {
        start++;
    }

    if (start != text) {
        memmove(text, start, strlen(start) + 1);
    }

    size_t length = strlen(text);

    while (length > 0 && isspace((unsigned char)text[length - 1])) {
        text[--length] = '\0';
    }
}

static void uppercase(char *text) {
    for (size_t index = 0; text[index] != '\0'; index++) {
        text[index] = (char)toupper((unsigned char)text[index]);
    }
}

static bool reserve_instructions(InstructionList *list) {
    if (list->count >= MAX_INSTRUCTIONS) {
        return false;
    }

    if (list->count < list->capacity) {
        return true;
    }

    size_t new_capacity = list->capacity == 0
        ? 16
        : list->capacity * 2;

    if (new_capacity > MAX_INSTRUCTIONS) {
        new_capacity = MAX_INSTRUCTIONS;
    }

    Instruction *items = realloc(
        list->items,
        new_capacity * sizeof(Instruction)
    );

    if (items == NULL) {
        return false;
    }

    list->items = items;
    list->capacity = new_capacity;

    return true;
}

static bool reserve_labels(LabelTable *table) {
    if (table->count >= MAX_LABELS) {
        return false;
    }

    if (table->count < table->capacity) {
        return true;
    }

    size_t new_capacity = table->capacity == 0
        ? 16
        : table->capacity * 2;

    if (new_capacity > MAX_LABELS) {
        new_capacity = MAX_LABELS;
    }

    Label *items = realloc(
        table->items,
        new_capacity * sizeof(Label)
    );

    if (items == NULL) {
        return false;
    }

    table->items = items;
    table->capacity = new_capacity;

    return true;
}

static bool add_label(
    LabelTable *labels,
    const char *name,
    uint32_t address,
    uint32_t line_number,
    AssemblerError *error
) {
    if (strlen(name) >= MAX_LABEL_LENGTH) {
        set_error(
            error,
            line_number,
            "Label name exceeds the maximum length of %d characters.",
            MAX_LABEL_LENGTH - 1
        );

        return false;
    }

    for (size_t index = 0; index < labels->count; index++) {
        if (strcmp(labels->items[index].name, name) == 0) {
            set_error(
                error,
                line_number,
                "Duplicate label: %s",
                name
            );

            return false;
        }
    }

    if (!reserve_labels(labels)) {
        set_error(
            error,
            line_number,
            "Unable to allocate memory for labels."
        );

        return false;
    }

    Label *label = &labels->items[labels->count++];

    strcpy(label->name, name);
    label->address = address;
    label->line_number = line_number;

    return true;
}

static bool parse_instruction(
    char *line,
    uint32_t line_number,
    InstructionList *instructions,
    AssemblerError *error
) {
    trim(line);

    if (line[0] == '\0') {
        return true;
    }

    if (!reserve_instructions(instructions)) {
        set_error(
            error,
            line_number,
            "Unable to allocate memory for instructions or instruction limit reached."
        );

        return false;
    }

    Instruction instruction = {0};

    instruction.line_number = line_number;
    instruction.address =
        (uint32_t)(instructions->count * INSTRUCTION_SIZE);

    char *separator = line;

    while (*separator != '\0' && !isspace((unsigned char)*separator)) {
        separator++;
    }

    size_t mnemonic_length = (size_t)(separator - line);

    if (mnemonic_length >= sizeof(instruction.mnemonic)) {
        set_error(
            error,
            line_number,
            "Instruction mnemonic is too long."
        );

        return false;
    }

    memcpy(
        instruction.mnemonic,
        line,
        mnemonic_length
    );

    instruction.mnemonic[mnemonic_length] = '\0';
    uppercase(instruction.mnemonic);

    while (isspace((unsigned char)*separator)) {
        separator++;
    }

    if (*separator != '\0') {
        char *operand = separator;

        while (true) {
            char *comma = strchr(operand, ',');

            if (comma != NULL) {
                *comma = '\0';
            }

            trim(operand);

            if (*operand == '\0') {
                set_error(
                    error,
                    line_number,
                    "Empty operand in instruction %s.",
                    instruction.mnemonic
                );

                return false;
            }

            if (instruction.operand_count >= MAX_OPERANDS) {
                set_error(
                    error,
                    line_number,
                    "Too many operands in instruction %s.",
                    instruction.mnemonic
                );

                return false;
            }

            size_t operand_length = strlen(operand);

            if (operand_length >= MAX_LINE_LENGTH) {
                set_error(
                    error,
                    line_number,
                    "Operand exceeds maximum length."
                );

                return false;
            }

            strcpy(
                instruction.operands[instruction.operand_count],
                operand
            );

            uppercase(
                instruction.operands[instruction.operand_count]
            );

            instruction.operand_count++;

            if (comma == NULL) {
                break;
            }

            operand = comma + 1;
        }
    }

    if (!validate_instruction(&instruction, error)) {
        return false;
    }

    instructions->items[instructions->count++] = instruction;

    return true;
}

bool parse_source(
    const char *source,
    InstructionList *instructions,
    LabelTable *labels,
    AssemblerError *error
) {
    if (source == NULL || instructions == NULL || labels == NULL) {
        set_error(error, 0, "Invalid parser input.");
        return false;
    }

    instructions->items = NULL;
    instructions->count = 0;
    instructions->capacity = 0;

    labels->items = NULL;
    labels->count = 0;
    labels->capacity = 0;

    if (error != NULL) {
        error->message[0] = '\0';
        error->line_number = 0;
    }

    char *source_copy = malloc(strlen(source) + 1);

    if (source_copy == NULL) {
        set_error(error, 0, "Unable to allocate source buffer.");
        return false;
    }

    strcpy(source_copy, source);

    uint32_t line_number = 0;
    char *line = source_copy;

    while (line != NULL) {
        line_number++;

        char *next_line = strchr(line, '\n');

        if (next_line != NULL) {
            *next_line = '\0';
            next_line++;
        }

        size_t line_length = strlen(line);

        if (line_length > 0 && line[line_length - 1] == '\r') {
            line[line_length - 1] = '\0';
        }

        char *comment = strpbrk(line, ";#");

        if (comment != NULL) {
            *comment = '\0';
        }

        trim(line);

        if (line[0] != '\0') {
            char *colon = strchr(line, ':');

            if (colon != NULL) {
                *colon = '\0';
                trim(line);

                bool valid_label = true;

                if (line[0] == '\0' ||
                    !(isalpha((unsigned char)line[0]) || line[0] == '_')) {
                    valid_label = false;
                }

                for (size_t index = 1; valid_label && line[index] != '\0'; index++) {
                    if (!(isalnum((unsigned char)line[index]) || line[index] == '_')) {
                        valid_label = false;
                    }
                }

                if (!valid_label) {
                    set_error(
                        error,
                        line_number,
                        "Invalid label declaration."
                    );

                    free(source_copy);
                    free_instruction_list(instructions);
                    free_label_table(labels);

                    return false;
                }

                uppercase(line);

                if (!add_label(
                    labels,
                    line,
                    (uint32_t)(instructions->count * INSTRUCTION_SIZE),
                    line_number,
                    error
                )) {
                    free(source_copy);
                    free_instruction_list(instructions);
                    free_label_table(labels);

                    return false;
                }

                char *remaining = colon + 1;
                trim(remaining);

                if (remaining[0] != '\0' &&
                    !parse_instruction(
                        remaining,
                        line_number,
                        instructions,
                        error
                    )) {
                    free(source_copy);
                    free_instruction_list(instructions);
                    free_label_table(labels);

                    return false;
                }
            } else if (!parse_instruction(
                line,
                line_number,
                instructions,
                error
            )) {
                free(source_copy);
                free_instruction_list(instructions);
                free_label_table(labels);

                return false;
            }
        }

        line = next_line;
    }

    free(source_copy);

    return true;
}
