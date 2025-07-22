#!/bin/sh

# Meta-Graph Platform Detection Utilities
# Functions for detecting platform and package managers

# --- package manager detection ----------------------------------------------
# Detect the primary package manager for the current platform
mg_detect_package_manager() {
    if mg_has_command brew; then
        echo "brew"
    elif mg_has_command apt; then
        echo "apt"
    elif mg_has_command apt-get; then
        echo "apt-get"
    elif mg_has_command yum; then
        echo "yum"
    elif mg_has_command dnf; then
        echo "dnf"
    elif mg_has_command pacman; then
        echo "pacman"
    elif mg_has_command choco; then
        echo "choco"
    elif mg_has_command winget; then
        echo "winget"
    else
        echo "unknown"
    fi
}

# Get platform name
mg_get_platform() {
    case "$(uname -s)" in
        Linux*)   echo "linux" ;;
        Darwin*)  echo "macos" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

# Check if a command exists (needed by package manager detection)
mg_has_command() {
    command -v "$1" >/dev/null 2>&1
}
