#!/bin/sh
# HyperDAG Shell Library
# Shared functions for all scripts and git hooks

# --- tool path setup --------------------------------------------------------
# Automatically detect and add common development tools to PATH
# This runs when shlib.sh is sourced, so all scripts get consistent tool access
setup_tool_paths() {
    # LLVM tools (clang-format, clang-tidy, clang)
    if ! command -v clang-format >/dev/null 2>&1; then
        for dir in \
            "/opt/homebrew/opt/llvm/bin" \
            "/usr/local/opt/llvm/bin" \
            "/usr/lib/llvm-20/bin" \
            "/usr/lib/llvm-19/bin" \
            "$HOME/.local/bin" \
            "/c/Program Files/LLVM/bin"
        do
            [ -x "$dir/clang-format" ] && {
                PATH="$dir:$PATH"
                export PATH
                break
            }
        done
    fi
    
    # Add other common tool paths if needed
    # Example: Go tools, Rust tools, etc.
    # if ! command -v go >/dev/null 2>&1; then
    #     [ -x "/usr/local/go/bin/go" ] && {
    #         PATH="/usr/local/go/bin:$PATH"
    #         export PATH
    #     }
    # fi
}

# Legacy function name for backward compatibility
ensure_llvm_tools() {
    setup_tool_paths
}

# --- project paths ----------------------------------------------------------
# Get the project root directory from any script location
get_project_root() {
    script_dir="$(CDPATH= cd -- "$(dirname "$1")" && pwd)"
    case "$script_dir" in
        */scripts)
            # Called from scripts/ directory
            CDPATH= cd -- "$script_dir/.." && pwd
            ;;
        */.git/hooks)
            # Called from .git/hooks/ directory  
            CDPATH= cd -- "$script_dir/../.." && pwd
            ;;
        *)
            # Assume we're already in project root
            echo "$script_dir"
            ;;
    esac
}

# --- package manager detection ----------------------------------------------
# Detect the primary package manager for the current platform
detect_package_manager() {
    if has_command brew; then
        echo "brew"
    elif has_command apt; then
        echo "apt"
    elif has_command apt-get; then
        echo "apt-get"
    elif has_command yum; then
        echo "yum"
    elif has_command dnf; then
        echo "dnf"
    elif has_command pacman; then
        echo "pacman"
    elif has_command choco; then
        echo "choco"
    elif has_command winget; then
        echo "winget"
    else
        echo "unknown"
    fi
}

# Get platform name
get_platform() {
    case "$(uname -s)" in
        Linux*)   echo "linux" ;;
        Darwin*)  echo "macos" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

# --- tool checking and installation -----------------------------------------
# Check if a tool exists and optionally check version
# This function only outputs messages when there are problems or when verbose is requested
check_tool() {
    tool_name="$1"
    version_flag="${2:-"--version"}"
    min_version="${3:-""}"
    verbose="${4:-false}"
    
    if command -v "$tool_name" >/dev/null 2>&1; then
        if [ "$verbose" = true ] && [ -n "$min_version" ] && [ "$version_flag" != "none" ]; then
            # Try to get version and compare if min_version is specified
            version_output="$("$tool_name" "$version_flag" 2>/dev/null | head -1)"
            echo "✓ $tool_name found: $version_output"
        elif [ "$verbose" = true ]; then
            echo "✓ $tool_name found"
        fi
        return 0
    else
        # Always show when tool is missing (this is a problem)
        echo "❌ $tool_name not found"
        return 1
    fi
}

# Prompt user to install a tool
prompt_install_tool() {
    tool_name="$1"
    install_cmd="$2"
    description="${3:-"$tool_name"}"
    
    echo ""
    echo "🔧 $description is not installed."
    
    if prompt_yn "Would you like to install it?"; then
        echo "📦 Installing $tool_name..."
        if eval "$install_cmd"; then
            echo "✅ $tool_name installed successfully"
            return 0
        else
            echo "❌ Failed to install $tool_name"
            return 1
        fi
    else
        echo "⚠️  Skipping $tool_name installation"
        return 1
    fi
}

# Get installation command for a tool based on package manager
get_install_command() {
    tool_name="$1"
    pkg_manager="$(detect_package_manager)"
    
    case "$pkg_manager" in
        brew)
            case "$tool_name" in
                llvm|clang-format|clang-tidy) echo "brew install llvm" ;;
                cmake) echo "brew install cmake" ;;
                gitleaks) echo "brew install gitleaks" ;;
                criterion) echo "brew install criterion" ;;
                *) echo "brew install $tool_name" ;;
            esac
            ;;
        apt|apt-get)
            case "$tool_name" in
                llvm|clang-format|clang-tidy) echo "sudo $pkg_manager update && sudo $pkg_manager install -y clang-20 clang-format-20 clang-tidy-20" ;;
                cmake) echo "sudo $pkg_manager update && sudo $pkg_manager install -y cmake" ;;
                gitleaks) echo "curl -sSL https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks-linux-amd64.tar.gz | tar -xz && sudo mv gitleaks /usr/local/bin/" ;;
                criterion) echo "sudo $pkg_manager update && sudo $pkg_manager install -y libcriterion-dev" ;;
                *) echo "sudo $pkg_manager update && sudo $pkg_manager install -y $tool_name" ;;
            esac
            ;;
        yum|dnf)
            case "$tool_name" in
                llvm) echo "sudo $pkg_manager install -y clang clang-tools-extra" ;;
                cmake) echo "sudo $pkg_manager install -y cmake" ;;
                gitleaks) echo "curl -sSL https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks-linux-amd64.tar.gz | tar -xz && sudo mv gitleaks /usr/local/bin/" ;;
                criterion) echo "sudo $pkg_manager install -y criterion-devel" ;;
                *) echo "sudo $pkg_manager install -y $tool_name" ;;
            esac
            ;;
        choco)
            case "$tool_name" in
                llvm) echo "choco install llvm" ;;
                cmake) echo "choco install cmake" ;;
                gitleaks) echo "choco install gitleaks" ;;
                *) echo "choco install $tool_name" ;;
            esac
            ;;
        winget)
            case "$tool_name" in
                llvm) echo "winget install LLVM.LLVM" ;;
                cmake) echo "winget install Kitware.CMake" ;;
                gitleaks) echo "winget install Gitleaks.Gitleaks" ;;
                *) echo "winget install $tool_name" ;;
            esac
            ;;
        *)
            echo "echo 'Unknown package manager. Please install $tool_name manually.'; exit 1"
            ;;
    esac
}

# --- common utilities --------------------------------------------------------
# Print error message and exit
die() {
    echo >&2 "$@"
    exit 1
}

# Color output functions
yellow() {
    echo "\033[33m$*\033[0m"
}

green() {
    echo "\033[32m$*\033[0m"
}

red() {
    echo "\033[31m$*\033[0m"
}

blue() {
    echo "\033[34m$*\033[0m"
}

# Check if a command exists
has_command() {
    command -v "$1" >/dev/null 2>&1
}

# Portable way to check if a file is executable
is_executable() {
    [ -x "$1" ] 2>/dev/null
}

# Check if we're running interactively
is_interactive() {
    [ -t 0 ] && [ -t 1 ]
}

# Generic Y/n prompt function with proper validation
# Usage: prompt_yn "Question?" && echo "yes" || echo "no"
# Returns 0 (success) for Y/yes, 1 (failure) for N/no, 2 for quit
# In non-interactive mode, always returns 1 (no) for security
prompt_yn() {
    question="${1:-"Continue?"}"
    default="${2:-"Y"}"  # Y or N
    allow_quit="${3:-false}"  # Allow 'q' to quit
    
    # SECURITY: Never assume yes in non-interactive mode
    if ! is_interactive; then
        echo "Non-interactive mode: assuming 'no' for: $question"
        return 1
    fi
    
    # Create clear, comprehensive prompt text
    if [ "$allow_quit" = true ]; then
        case "$default" in
            [Yy]*) prompt_text="[Y/y/1 = yes, N/n/0 = no, Q/q/Esc = quit]" ;;
            [Nn]*) prompt_text="[Y/y/1 = yes, N/n/0 = no (default), Q/q/Esc = quit]" ;;
            *) prompt_text="[Y/y/1 = yes, N/n/0 = no, Q/q/Esc = quit]" ;;
        esac
    else
        case "$default" in
            [Yy]*) prompt_text="[Y/y/1 = yes (default), N/n/0 = no, Esc = abort]" ;;
            [Nn]*) prompt_text="[Y/y/1 = yes, N/n/0 = no (default), Esc = abort]" ;;
            *) prompt_text="[Y/y/1 = yes, N/n/0 = no, Esc = abort]" ;;
        esac
    fi
    
    while true; do
        printf "%s %s " "$question" "$prompt_text"
        read -r response
        
        # Handle empty response (use default)
        if [ -z "$response" ]; then
            case "$default" in
                [Yy]*) return 0 ;;
                [Nn]*) return 1 ;;
            esac
        fi
        
        # Check response - handle all valid inputs
        case "$response" in
            [Yy]|[Yy][Ee][Ss]|1) return 0 ;;
            [Nn]|[Nn][Oo]|0) return 1 ;;
            [Qq]|[Qq][Uu][Ii][Tt])
                if [ "$allow_quit" = true ]; then
                    return 2
                else
                    echo "Invalid input. Please try again."
                fi
                ;;
            $'\033'|ESC|esc|Esc)  # ESC key - abort entire script
                echo ""
                echo "❌ Setup aborted by user (ESC pressed)"
                exit 130  # Standard exit code for Ctrl+C/abort
                ;;
            *) 
                echo "Invalid input. Please use the options shown above."
                ;;
        esac
    done
}

# Execute a command with Y/n prompt
# Usage: prompt_and_execute "Install package?" "apt install foo"
prompt_and_execute() {
    question="$1"
    command="$2"
    default="${3:-"Y"}"
    
    if prompt_yn "$question" "$default"; then
        echo "Executing: $command"
        if eval "$command"; then
            echo "✅ Command completed successfully"
            return 0
        else
            echo "❌ Command failed with exit code $?"
            return 1
        fi
    else
        echo "⚠️  Skipped"
        return 1
    fi
}

# --- automatic initialization -----------------------------------------------
# Automatically set up tool paths when this library is sourced
# This ensures all scripts have consistent access to development tools
setup_tool_paths