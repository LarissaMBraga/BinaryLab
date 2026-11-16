
#include "binary_lab.h"

#include <stdarg.h>
#include <stdio.h>

void set_error(
    AssemblerError *error,
    uint32_t line_number,
    const char *format,
    ...
) {
    if (error == NULL) {
        return;
    }

    error->line_number = line_number;

    if (format == NULL) {
        error->message[0] = '\0';
        return;
    }

    va_list arguments;

    va_start(arguments, format);

    vsnprintf(
        error->message,
        sizeof(error->message),
        format,
        arguments
    );

    va_end(arguments);
}
