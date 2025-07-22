#!/bin/sh

# MetaGraph Directory Utilities
# Directory management functions for scripts

# --- Change Directory ---------------------------------------------------------
# Change directory to a target path, resolving relative paths against the
# project root
#
# Usage: mg_cd <path>
# Example: mg_cd scripts/git-hooks
#
# This function ensures the target path is absolute and changes to it, printing
# the new directory
#
# $1 is the path to change to, relative to the project root
#   If the path is absolute, it uses it directly; otherwise, it resolves it
#   against the project root directory.
#
#   If the path is invalid or cannot be changed to, it prints an error and exits.
mg_cd() {
    target_path="$1"
    project_root="$(mg_get_project_root "$0")"

    # Validate input
    if [ -z "$target_path" ]; then
        echo "Usage: chwd <path>"
        return 1
    fi

    # Check if the path is absolute
    case "$target_path" in
        /*)
            # If it's absolute, use it directly
            target_path="$1"
            ;;
        *)
            # Resolve the absolute path
            target_path="$(mg_get_project_root)/$target_path"
            ;;
    esac

    # Change directory and handle errors
    if ! cd "$target_path"; then
        echo "Failed to change directory to $1"
        exit 1
    else
        pwd
    fi
}

# --- project paths ----------------------------------------------------------
# Get the project root directory from any script location
mg_get_project_root() {
    script_dir="$(CDPATH='' cd -- "$(dirname "$1")" && pwd)"
    case "$script_dir" in
        */scripts)
            # Called from scripts/ directory
            CDPATH='' cd -- "$script_dir/.." && pwd
            ;;
        */.git/hooks)
            # Called from .git/hooks/ directory
            CDPATH='' cd -- "$script_dir/../.." && pwd
            ;;
        *)
            # if .git directory exists, then we are in the project root
            # count make this more robust by checking for other known root
            # artifacts like CMakeLists.txt or README.md
            if [ -d ".git" ]; then
                pwd
                return
            fi
            echo "$script_dir"
            ;;
    esac
}
