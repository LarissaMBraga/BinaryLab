
#include "binary_lab.h"

#include <stdlib.h>
#include <string.h>

static void print_usage(const char *program_name) {
    fprintf(
        stderr,
        "Binary Lab Assembler %s\n\n"
        "Usage:\n"
        "  %s <source.asm> -o <output.bin> [--hex-output <output.hex>]\n\n"
        "Options:\n"
        "  -o, --output       Binary output file\n"
        "  --hex-output       Optional HEX output file\n"
        "  -h, --help         Display this help message\n",
        BINARY_LAB_VERSION,
        program_name
    );
}

static char *read_source_file(
    const char *path,
    AssemblerError *error
) {
    FILE *file = fopen(path, "rb");

    if (file == NULL) {
        set_error(error, 0, "Unable to open source file: %s", path);
        return NULL;
    }

    if (fseek(file, 0, SEEK_END) != 0) {
        set_error(error, 0, "Unable to seek source file: %s", path);
        fclose(file);
        return NULL;
    }

    long file_size = ftell(file);

    if (file_size < 0) {
        set_error(error, 0, "Unable to determine source file size: %s", path);
        fclose(file);
        return NULL;
    }

    if (fseek(file, 0, SEEK_SET) != 0) {
        set_error(error, 0, "Unable to rewind source file: %s", path);
        fclose(file);
        return NULL;
    }

    char *source = malloc((size_t)file_size + 1);

    if (source == NULL) {
        set_error(error, 0, "Unable to allocate source file buffer.");
        fclose(file);
        return NULL;
    }

    size_t bytes_read = fread(source, 1, (size_t)file_size, file);

    if (bytes_read != (size_t)file_size) {
        set_error(error, 0, "Failed to read source file: %s", path);
        free(source);
        fclose(file);
        return NULL;
    }

    source[bytes_read] = '\0';

    if (fclose(file) != 0) {
        set_error(error, 0, "Failed to close source file: %s", path);
        free(source);
        return NULL;
    }

    return source;
}

int main(int argc, char *argv[]) {
    const char *source_path = NULL;
    const char *output_path = NULL;
    const char *hex_output_path = NULL;

    if (argc < 2) {
        print_usage(argv[0]);
        return EXIT_FAILURE;
    }

    for (int index = 1; index < argc; index++) {

        if (strcmp(argv[index], "-h") == 0 ||
            strcmp(argv[index], "--help") == 0) {
            print_usage(argv[0]);
            return EXIT_SUCCESS;
        }

        if (strcmp(argv[index], "--version") == 0) {
            printf("Binary Lab Assembler %s\n", BINARY_LAB_VERSION);
            return EXIT_SUCCESS;
        }


        if (strcmp(argv[index], "-o") == 0 ||
            strcmp(argv[index], "--output") == 0) {
            if (index + 1 >= argc) {
                fprintf(stderr, "Error: missing output file path.\n");
                return EXIT_FAILURE;
            }

            output_path = argv[++index];
            continue;
        }

        if (strcmp(argv[index], "--hex-output") == 0) {
            if (index + 1 >= argc) {
                fprintf(stderr, "Error: missing HEX output file path.\n");
                return EXIT_FAILURE;
            }

            hex_output_path = argv[++index];
            continue;
        }

        if (argv[index][0] == '-') {
            fprintf(stderr, "Error: unknown option: %s\n", argv[index]);
            print_usage(argv[0]);
            return EXIT_FAILURE;
        }

        if (source_path != NULL) {
            fprintf(stderr, "Error: multiple source files provided.\n");
            return EXIT_FAILURE;
        }

        source_path = argv[index];
    }

    if (source_path == NULL || output_path == NULL) {
        fprintf(stderr, "Error: source file and output path are required.\n");
        print_usage(argv[0]);
        return EXIT_FAILURE;
    }

    AssemblerError error = {0};

    InstructionList instructions = {0};
    LabelTable labels = {0};
    MachineCode machine_code = {0};

    char *source = read_source_file(source_path, &error);

    if (source == NULL) {
        goto failure;
    }

    if (!parse_source(source, &instructions, &labels, &error)) {
        goto failure;
    }

    if (!resolve_labels(&instructions, &labels, &error)) {
        goto failure;
    }

    if (!encode_program(&instructions, &machine_code, &error)) {
        goto failure;
    }

    if (!write_binary_file(output_path, &machine_code, &error)) {
        goto failure;
    }

    if (hex_output_path != NULL) {
        if (!write_hex_file(hex_output_path, &machine_code, &error)) {
            goto failure;
        }
    }

    printf(
        "Successfully assembled %s -> %s\n",
        source_path,
        output_path
    );

    printf(
        "Generated %zu instruction(s), %zu byte(s).\n",
        machine_code.count,
        machine_code.count * INSTRUCTION_SIZE
    );

    if (hex_output_path != NULL) {
        printf("HEX output: %s\n", hex_output_path);
    }

    free(source);
    free_instruction_list(&instructions);
    free_label_table(&labels);
    free_machine_code(&machine_code);

    return EXIT_SUCCESS;

failure:
    if (error.line_number > 0) {
        fprintf(
            stderr,
            "Error on line %u: %s\n",
            error.line_number,
            error.message
        );
    } else {
        fprintf(stderr, "Error: %s\n", error.message);
    }

    free(source);
    free_instruction_list(&instructions);
    free_label_table(&labels);
    free_machine_code(&machine_code);

    return EXIT_FAILURE;
}
