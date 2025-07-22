/**
 * @file mg-cli.c
 * @brief MetaGraph command-line interface placeholder
 */

#include <stdio.h>
#include <string.h>

// Function with local buffer to trigger stack protection
static void metagraph_process_input(const char *input) {
    char buffer[64]; // Stack buffer that should trigger protection
    if (input) {
        strncpy(buffer, input, sizeof(buffer) - 1);
        buffer[sizeof(buffer) - 1] = '\0';
        (void)printf("Processing: %s\n", buffer);
    }
}

int main(int argc, char *argv[]) {
    (void)printf("MetaGraph CLI - placeholder implementation\n");

    // Use argc/argv to ensure they're not optimized away
    if (argc > 1) {
        metagraph_process_input(argv[1]);
    }

    // Create another stack buffer
    char local_buffer[128];
    snprintf(local_buffer, sizeof(local_buffer), "Version: %s", "0.1.0");
    (void)printf("%s\n", local_buffer);

    return 0;
}
