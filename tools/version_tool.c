/*
 * MetaGraph Version Tool
 * Simple utility to display version information
 */

#include "metagraph/result.h"
#include "metagraph/version.h"
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>

metagraph_result_t metagraph_printf(const char *fmt, ...) {
    METAGRAPH_CHECK_NULL(fmt);

    va_list args;
    va_start(args, fmt);
    int result = vprintf(fmt, args);
    va_end(args);

    if (result < 0) {
        return METAGRAPH_ERR(METAGRAPH_ERROR_IO_FAILURE,
                             "printf failed with error code %d", result);
    }

    return METAGRAPH_OK();
}

#define METAGRAPH_PRINT(fmt, ...)                                              \
    METAGRAPH_CHECK(metagraph_printf(fmt, __VA_ARGS__));

metagraph_result_t metagraph_print_version(void) {
    METAGRAPH_PRINT("Major: %d\n", METAGRAPH_VERSION_MAJOR);
    METAGRAPH_PRINT("Minor: %d\n", METAGRAPH_VERSION_MINOR);
    METAGRAPH_PRINT("Patch: %d\n", METAGRAPH_VERSION_PATCH);
    return METAGRAPH_OK();
}

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;

    METAGRAPH_PRINT("MetaGraph %s\n", METAGRAPH_VERSION_STRING);
    METAGRAPH_CHECK(metagraph_print_version());

    return 0;
}
