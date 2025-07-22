/*
 * Meta-Graph Version Tool
 * Simple utility to display version information
 */

#include "metagraph/version.h"
#include <stdio.h>

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;

    printf("Meta-Graph %s\n", METAGRAPH_VERSION_STRING);
    printf("Major: %d\n", METAGRAPH_VERSION_MAJOR);
    printf("Minor: %d\n", METAGRAPH_VERSION_MINOR);
    printf("Patch: %d\n", METAGRAPH_VERSION_PATCH);

    return 0;
}
