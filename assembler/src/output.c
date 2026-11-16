
#include "binary_lab.h"

#include <stdlib.h>

bool write_binary_file(
    const char *path,
    const MachineCode *machine_code,
    AssemblerError *error
) {
    if (path == NULL || machine_code == NULL) {
        set_error(error, 0, "Invalid binary output input.");
        return false;
    }

    FILE *file = fopen(path, "wb");

    if (file == NULL) {
        set_error(error, 0, "Unable to open binary output file: %s", path);
        return false;
    }

    for (size_t index = 0; index < machine_code->count; index++) {
        uint16_t word = machine_code->words[index];

        uint8_t bytes[2] = {
            (uint8_t)((word >> 8) & 0xFF),
            (uint8_t)(word & 0xFF)
        };

        if (fwrite(bytes, sizeof(uint8_t), 2, file) != 2) {
            set_error(error, 0, "Failed to write binary output file: %s", path);
            fclose(file);
            return false;
        }
    }

    if (fclose(file) != 0) {
        set_error(error, 0, "Failed to close binary output file: %s", path);
        return false;
    }

    return true;
}

bool write_hex_file(
    const char *path,
    const MachineCode *machine_code,
    AssemblerError *error
) {
    if (path == NULL || machine_code == NULL) {
        set_error(error, 0, "Invalid HEX output input.");
        return false;
    }

    FILE *file = fopen(path, "w");

    if (file == NULL) {
        set_error(error, 0, "Unable to open HEX output file: %s", path);
        return false;
    }

    for (size_t index = 0; index < machine_code->count; index++) {
        uint16_t word = machine_code->words[index];

        if (fprintf(
            file,
            "%02X\n%02X\n",
            (unsigned int)((word >> 8) & 0xFF),
            (unsigned int)(word & 0xFF)
        ) < 0) {
            set_error(error, 0, "Failed to write HEX output file: %s", path);
            fclose(file);
            return false;
        }
    }

    if (fclose(file) != 0) {
        set_error(error, 0, "Failed to close HEX output file: %s", path);
        return false;
    }

    return true;
}

void free_instruction_list(InstructionList *instructions) {
    if (instructions == NULL) {
        return;
    }

    free(instructions->items);

    instructions->items = NULL;
    instructions->count = 0;
    instructions->capacity = 0;
}

void free_label_table(LabelTable *labels) {
    if (labels == NULL) {
        return;
    }

    free(labels->items);

    labels->items = NULL;
    labels->count = 0;
    labels->capacity = 0;
}

void free_machine_code(MachineCode *machine_code) {
    if (machine_code == NULL) {
        return;
    }

    free(machine_code->words);

    machine_code->words = NULL;
    machine_code->count = 0;
    machine_code->capacity = 0;
}
