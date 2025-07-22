#!/bin/sh

# MetaGraph MetaGraph Library
# Modular shell functions for scripts in the MetaGraph project

# Find the scripts directory - this script should always be in the scripts/ directory
# Handle both direct execution and sourcing from git hooks
case "$(basename "$(pwd)")" in
    scripts) _MG_DIR="$(pwd)" ;;
    *)
        # Find the project root and go to scripts from there
        if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
            _MG_DIR="$(git rev-parse --show-toplevel)/scripts"
        else
            # Fallback: resolve symlinks to find the actual scripts directory
            script_path="$0"
            while [ -L "$script_path" ]; do
                link_target="$(readlink "$script_path")"
                case "$link_target" in
                    /*) script_path="$link_target" ;;
                    *) script_path="$(dirname "$script_path")/$link_target" ;;
                esac
            done
            _MG_DIR="$(CDPATH='' cd -- "$(dirname "$script_path")" && pwd)"
            # If we ended up in git-hooks, go back to scripts
            case "$_MG_DIR" in
                */git-hooks) _MG_DIR="$(dirname "$_MG_DIR")" ;;
            esac
        fi
        ;;
esac

# Source all modular utilities
. "$_MG_DIR/lib/output_utils.sh"
. "$_MG_DIR/lib/platform_utils.sh"
. "$_MG_DIR/lib/directory_utils.sh"
. "$_MG_DIR/lib/interactive_utils.sh"
. "$_MG_DIR/lib/tool_detection.sh"

# --- automatic initialization -----------------------------------------------
# Automatically set up tool paths when this library is sourced
# This ensures all scripts have consistent access to development tools
mg_setup_tool_paths
