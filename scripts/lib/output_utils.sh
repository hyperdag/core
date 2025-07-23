#!/bin/sh

# MetaGraph Output Utilities
# Functions for formatted output, colors, and error handling

# Print error message and exit
mg_die() {
    echo >&2 "$@"
    exit 1
}

# Color output functions
mg_yellow() {
    printf '\033[33m%s\033[0m\n' "$*"
}

mg_green() {
    printf '\033[32m%s\033[0m\n' "$*"
}

mg_red() {
    printf '\033[31m%s\033[0m\n' "$*"
}

mg_blue() {
    printf '\033[34m%s\033[0m\n' "$*"
}
