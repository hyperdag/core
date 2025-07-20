/**
 * @file main.c
 * @brief HyperDAG command-line interface
 */

#include "hyperdag/hyperdag.h"
#include "hyperdag/version.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void print_version(void)
{
    printf("HyperDAG CLI version %s\n", hyperdag_version());
    printf("%s\n", hyperdag_build_info());
}

static void print_usage(const char *program_name)
{
    printf("Usage: %s [OPTIONS] [COMMAND]\n", program_name);
    printf("\n");
    printf("Commands:\n");
    printf("  version    Show version information\n");
    printf("  help       Show this help message\n");
    printf("\n");
    printf("Options:\n");
    printf("  -h, --help     Show help\n");
    printf("  -v, --version  Show version\n");
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }
    
    const char *command = argv[1];
    
    if (strcmp(command, "version") == 0 || 
        strcmp(command, "-v") == 0 || 
        strcmp(command, "--version") == 0) {
        print_version();
        return 0;
    }
    
    if (strcmp(command, "help") == 0 || 
        strcmp(command, "-h") == 0 || 
        strcmp(command, "--help") == 0) {
        print_usage(argv[0]);
        return 0;
    }
    
    printf("Unknown command: %s\n", command);
    print_usage(argv[0]);
    return 1;
}