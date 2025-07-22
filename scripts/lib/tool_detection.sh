#!/bin/sh

# Meta-Graph Tool Detection and Management
# Functions for detecting, checking, and installing development tools

# Note: Dependencies on output_utils.sh and platform_utils.sh
# These should be loaded by the main script that sources this file

# --- $PATH Management ---------------------------------------------------------
# Automatically detect and add common development tools to PATH
# This runs when shlib.sh is sourced, so all scripts get consistent tool access
mg_setup_tool_paths() {
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
}

# --- tool checking and installation -----------------------------------------
# Check if a tool exists and optionally check version
# This function only outputs messages when there are problems or when verbose is requested
mg_tool_exists() {
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

# Check if a command exists
mg_has_command() {
    command -v "$1" >/dev/null 2>&1
}

# Portable way to check if a file is executable
mg_is_executable() {
    [ -x "$1" ] 2>/dev/null
}

# Prompt user to install a tool
mg_prompt_install_tool() {
    tool_name="$1"
    install_cmd="$2"
    description="${3:-"$tool_name"}"

    echo ""
    echo "🔧 $description is not installed."

    if mg_prompt_yn "Would you like to install it?"; then
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
mg_get_install_command() {
    tool_name="$1"
    pkg_manager="$(mg_detect_package_manager)"

    case "$pkg_manager" in
        brew)
            case "$tool_name" in
                llvm|clang-format|clang-tidy) echo "brew install llvm" ;;
                cmake) echo "brew install cmake" ;;
                gitleaks) echo "brew install gitleaks" ;;
                criterion) echo "brew install criterion" ;;
                shellcheck) echo "brew install shellcheck" ;;
                *) echo "brew install $tool_name" ;;
            esac
            ;;
        apt|apt-get)
            case "$tool_name" in
                llvm|clang-format|clang-tidy) echo "sudo $pkg_manager update && sudo $pkg_manager install -y clang-20 clang-format-20 clang-tidy-20" ;;
                cmake) echo "sudo $pkg_manager update && sudo $pkg_manager install -y cmake" ;;
                gitleaks) echo "curl -sSL https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks-linux-amd64.tar.gz | tar -xz && sudo mv gitleaks /usr/local/bin/" ;;
                criterion) echo "sudo $pkg_manager update && sudo $pkg_manager install -y libcriterion-dev" ;;
                shellcheck) echo "sudo $pkg_manager update && sudo $pkg_manager install -y shellcheck" ;;
                *) echo "sudo $pkg_manager update && sudo $pkg_manager install -y $tool_name" ;;
            esac
            ;;
        yum|dnf)
            case "$tool_name" in
                llvm) echo "sudo $pkg_manager install -y clang clang-tools-extra" ;;
                cmake) echo "sudo $pkg_manager install -y cmake" ;;
                gitleaks) echo "curl -sSL https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks-linux-amd64.tar.gz | tar -xz && sudo mv gitleaks /usr/local/bin/" ;;
                criterion) echo "sudo $pkg_manager install -y criterion-devel" ;;
                shellcheck) echo "sudo $pkg_manager install -y ShellCheck" ;;
                *) echo "sudo $pkg_manager install -y $tool_name" ;;
            esac
            ;;
        choco)
            case "$tool_name" in
                llvm) echo "choco install llvm" ;;
                cmake) echo "choco install cmake" ;;
                gitleaks) echo "choco install gitleaks" ;;
                shellcheck) echo "choco install shellcheck" ;;
                *) echo "choco install $tool_name" ;;
            esac
            ;;
        winget)
            case "$tool_name" in
                llvm) echo "winget install LLVM.LLVM" ;;
                cmake) echo "winget install Kitware.CMake" ;;
                gitleaks) echo "winget install Gitleaks.Gitleaks" ;;
                shellcheck) echo "winget install koalaman.shellcheck" ;;
                *) echo "winget install $tool_name" ;;
            esac
            ;;
        *)
            echo "echo 'Unknown package manager. Please install $tool_name manually.'; exit 1"
            ;;
    esac
}
