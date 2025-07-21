/*
 * HyperDAG Version Tool
 * Simple utility to display version information
 */

#include <stdio.h>
#include "hyperdag/version.h"

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;
    
    printf("HyperDAG %s\n", HYPERDAG_VERSION_STRING);
    printf("Major: %d\n", HYPERDAG_VERSION_MAJOR);
    printf("Minor: %d\n", HYPERDAG_VERSION_MINOR);
    printf("Patch: %d\n", HYPERDAG_VERSION_PATCH);
    
    return 0;
}