#!/bin/sh
# MetaGraph Development Environment Setup Script
# Installs all required tools, dependencies, and configures git hooks

set -eu

# Load shared shell library
PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
. "$PROJECT_ROOT/scripts/mg.sh"

PLATFORM="$(mg_get_platform)"
PACKAGE_MANAGER="$(mg_detect_package_manager)"

# =============================================================================
# Tool Installation
# =============================================================================
mg_tool_exists_check() {
    # List of required tools with descriptions
    TOOLS_TO_CHECK="cmake:CMake_build_system clang-format:LLVM_formatter clang-tidy:LLVM_analyzer gitleaks:Secret_scanner shellcheck:Shell_script_linter semgrep:Security_analyzer"

    missing_tools=""

    # Check each tool silently
    for tool_spec in $TOOLS_TO_CHECK; do
        tool_name="${tool_spec%:*}"
        tool_desc="${tool_spec#*:}"
        tool_desc="$(echo "$tool_desc" | sed 's/_/ /g')"

        if ! mg_tool_exists "$tool_name" >/dev/null 2>&1; then
            if [ -z "$missing_tools" ]; then
                echo ""
                mg_red "❌ Missing required development tools:"
            fi
            echo "  • $tool_name ($tool_desc)"
            if [ "$PACKAGE_MANAGER" != "unknown" ]; then
                install_cmd="$(mg_get_install_command "$tool_name")"
                echo "    Install with: $install_cmd"
            fi
            missing_tools="$missing_tools $tool_name"
        fi
    done

    if [ -n "$missing_tools" ]; then
        echo ""
        echo "To install missing tools:"
        if [ "$PACKAGE_MANAGER" != "unknown" ]; then
            echo "  Run: $0 (interactively)"
        else
            echo "  Install a package manager first:"
            case "$PLATFORM" in
                macos) echo "    Homebrew: https://brew.sh" ;;
                linux) echo "    Use your distribution's package manager (apt, yum, dnf, etc.)" ;;
                windows) echo "    Chocolatey: https://chocolatey.org" ;;
            esac
        fi
        return 1
    fi

    # Silent success - only show output if there were problems
    return 0
}

install_tools() {
    # SECURITY: Only allow installation in interactive mode
    if ! mg_is_interactive; then
        echo "❌ Running in non-interactive mode - cannot install tools"
        echo "Use --verify or --dry-run to check what's missing"
        return 1
    fi

    # Tools are already in PATH thanks to automatic setup in mg.sh
    TOOLS_TO_CHECK="cmake:CMake_build_system clang-format:LLVM_formatter clang-tidy:LLVM_analyzer gitleaks:Secret_scanner shellcheck:Shell_script_linter semgrep:Security_analyzer"

    tools_prompted=false

    # Check each tool and offer to install if missing
    for tool_spec in $TOOLS_TO_CHECK; do
        tool_name="${tool_spec%:*}"
        tool_desc="${tool_spec#*:}"
        tool_desc="$(echo "$tool_desc" | sed 's/_/ /g')"

        if ! mg_tool_exists "$tool_name" >/dev/null 2>&1; then
            if [ "$tools_prompted" = false ]; then
                echo ""
                mg_yellow "🔧 Missing development tools - installation available:"
                tools_prompted=true
            fi
            echo ""
            echo "• $tool_name ($tool_desc)"
            install_cmd="$(mg_get_install_command "$tool_name")"
            if ! mg_prompt_install_tool "$tool_name" "$install_cmd" "$tool_desc"; then
                mg_yellow "  ⚠️  Skipping $tool_name - some features may not work"
            fi
        fi
    done
}

# =============================================================================
# Git Hook Installation
# =============================================================================

# Cross-platform function to create symlinks or copies
install_hook() {
    source_hook="$1"
    target_hook="$2"
    hook_name="$(basename "$source_hook")"

    # Remove existing hook if present
    if [ -f "$target_hook" ]; then
        mg_red "Git hook $hook_name already exists!"
        echo "Please remove it manually before installing new hooks."
        return 1
    fi

    # Try to create symlink first (preferred method)
    if ln -s "../../scripts/git-hooks/$hook_name" "$target_hook" 2>/dev/null; then
        mg_green "  ✓ Linked $hook_name"
        return 0
    fi

    # If symlink fails (Windows without developer mode), try copying
    # Prompt user to copy instead
    mg_yellow "  ⚠️  Symlinks not supported, copying $hook_name instead"
    mg_prompt_and_execute "Copy $hook_name to .git/hooks?" "cp \"$source_hook\" \"$target_hook\""
    result=$?
    if [ $result -gt 0 ]; then
        chmod +x "$target_hook"
        mg_green "  ✓ Copied $hook_name (symlink not available)"
        return 0
    fi

    mg_red "  ❌ Failed to install $hook_name"
    return 1
}

# Check if symlinks are supported (for Windows guidance)
check_symlink_support() {
    test_link_target="$PROJECT_ROOT/.git/test_symlink_target"
    test_link_source="$PROJECT_ROOT/.git/test_symlink"

    # Create a test file
    echo "test" > "$test_link_target"

    # Try to create a symlink
    if ln -s test_symlink_target "$test_link_source" 2>/dev/null; then
        # Clean up
        rm -f "$test_link_source" "$test_link_target"
        return 0
    else
        # Clean up
        rm -f "$test_link_target"
        return 1
    fi
}

install_git_hooks() {

    cd "$PROJECT_ROOT"
    echo "🔗 Installing git hooks..."

    # Check if symlinks are supported
    if ! check_symlink_support; then
        if [ "$PLATFORM" = "windows" ]; then
            echo ""
            mg_yellow "⚠️  Symlinks not available on Windows"
            echo "To enable symlinks on Windows (recommended):"
            echo "1. Enable Developer Mode in Windows Settings"
            echo "2. Or run Git Bash as Administrator"
            echo "3. Or use: git config core.symlinks true"
            echo ""
            return 1
        fi
    fi

    # Make sure git hooks directory exists
    mkdir -p .git/hooks

    # Install each hook
    hooks_installed=0
    hooks_failed=0

    for hook_file in scripts/git-hooks/*; do
        [ -f "$hook_file" ] || continue
        hook_name="$(basename "$hook_file")"
        target_hook=".git/hooks/$hook_name"

        if install_hook "$hook_file" "$target_hook"; then
            hooks_installed=$((hooks_installed + 1))
        else
            hooks_failed=$((hooks_failed + 1))
        fi
    done

    echo "Installed $hooks_installed git hooks"

    if [ $hooks_failed -gt 0 ]; then
        mg_red "❌ Failed to install $hooks_failed git hooks"
        return 1
    fi

    # Verify hooks are executable
    for hook_file in scripts/git-hooks/*; do
        [ -f "$hook_file" ] || continue
        hook_name="$(basename "$hook_file")"
        target_hook=".git/hooks/$hook_name"

        if [ ! -x "$target_hook" ]; then
            mg_red "❌ Hook $hook_name is not executable"
            return 1
        fi
    done
}

# =============================================================================
# Git Configuration
# =============================================================================

# Helper function for optional git config prompts
prompt_git_config() {
    setting_name="$1"
    current_value="$2"
    recommended_value="$3"
    description="$4"
    git_command="$5"

    echo ""
    echo "• $setting_name"
    echo "  Current: $current_value → Recommended: $recommended_value ($description)"
    mg_prompt_yn "Set $setting_name = $recommended_value?" "Y" true
    result=$?
    case $result in
        0) eval "$git_command" ;;
        1) echo "  Skipped" ;;
        2) echo "Setup cancelled."; return 1 ;;
    esac
}

setup_git() {
    cd "$PROJECT_ROOT"

    issues_found=0
    optional_improvements=0

    # Platform-specific git configuration settings
    if [ "$PLATFORM" = "windows" ]; then
        # Windows: Convert LF to CRLF on checkout, CRLF to LF on commit
        autocrlf_setting="true"
        autocrlf_desc="convert_line_endings_for_Windows"
    else
        # Linux/macOS: Keep LF line endings, warn about CRLF
        autocrlf_setting="input"
        autocrlf_desc="preserve_LF_warn_about_CRLF"
    fi

    # Check optional git configuration settings
    optional_configs="
        core.autocrlf:${autocrlf_setting}:${autocrlf_desc}:git_config_--local_core.autocrlf_${autocrlf_setting}
        core.filemode:true:track_executable_permissions:git_config_--local_core.filemode_true
        pull.rebase:false:merge_instead_of_rebase_on_pull:git_config_--local_pull.rebase_false
        init.defaultBranch:main:modern_default_branch_name:git_config_--local_init.defaultBranch_main
    "

    for config_line in $optional_configs; do
        [ -z "$config_line" ] && continue

        setting=$(echo "$config_line" | cut -d: -f1)
        expected=$(echo "$config_line" | cut -d: -f2)
        description=$(echo "$config_line" | cut -d: -f3 | sed 's/_/ /g')
        command=$(echo "$config_line" | cut -d: -f4 | sed 's/_/ /g')

        current=$(git config --"$setting" 2>/dev/null || echo "unset")
        if [ "$current" != "$expected" ]; then
            if [ $optional_improvements -eq 0 ]; then
                echo ""
                mg_yellow "🔧 Optional git configuration improvements available:"
            fi
            prompt_git_config "$setting" "$current" "$expected" "$description" "$command"
            optional_improvements=$((optional_improvements + 1))
        fi
    done

    # 5. REQUIRED: Check git commit signing
    current_gpgsign=$(git config --commit.gpgsign 2>/dev/null || echo "unset")
    current_signingkey=$(git config --user.signingkey 2>/dev/null || echo "unset")

    if [ "$current_gpgsign" != "true" ] || [ "$current_signingkey" = "unset" ]; then
        echo ""
        mg_red "🔒 REQUIRED: Git Commit Signing (NOT CONFIGURED)"
        echo "Signed commits are mandatory for security and authenticity."
        echo "Current gpgsign: $current_gpgsign"
        echo "Current signing key: $current_signingkey"
        echo ""
        mg_red "❌ Git commit signing is not properly configured!"
        echo ""
        echo "To set up commit signing:"
        echo "1. Generate a GPG key: gpg --full-generate-key"
        echo "2. List keys: gpg --list-secret-keys --keyid-format=long"
        echo "3. Configure git: git config --user.signingkey YOUR_KEY_ID"
        echo "4. Enable signing: git config --commit.gpgsign true"
        echo ""
        mg_prompt_yn "Do you want to configure commit signing now?" "Y" true
        result=$?
        case $result in
            0)
                echo "Please follow the steps above to configure GPG signing."
                echo "After setting up GPG, run this script again to verify."
                return 1
                ;;
            1)
                echo ""
                mg_red "⚠️  WARNING: Proceeding without commit signing is not recommended!"
                mg_red "All commits should be signed for security verification."
                mg_prompt_yn "Continue anyway?" "N" true
                continue_result=$?
                case $continue_result in
                    0) echo "⚠️  Continuing without signing (not recommended)" ;;
                    *) echo "Setup cancelled. Please configure commit signing."; return 1 ;;
                esac
                ;;
            2) echo "Setup cancelled."; return 1 ;;
        esac
        issues_found=$((issues_found + 1))
    fi

    # Check git aliases (check if any are missing) - OPTIONAL
    aliases_needed=""
    for alias in st:status co:checkout br:branch ci:commit; do
        alias_name="${alias%:*}"
        alias_cmd="${alias#*:}"
        current_alias=$(git config --alias."${alias_name}" 2>/dev/null || echo "unset")
        if [ "$current_alias" != "$alias_cmd" ]; then
            aliases_needed="$aliases_needed $alias_name"
        fi
    done

    if [ -n "$aliases_needed" ]; then
        if [ $optional_improvements -eq 0 ]; then
            echo ""
            mg_yellow "🔧 Optional git configuration improvements available:"
        fi
        echo ""
        mg_yellow "• Git aliases (convenience shortcuts)"
        echo "  Missing aliases:$aliases_needed (st=status, co=checkout, br=branch, ci=commit, etc.)"
        mg_prompt_yn "Add helpful git aliases?" "Y" true
        result=$?
        case $result in
            0) git config --alias.st status
               git config --alias.co checkout
               git config --alias.br branch
               git config --alias.ci commit
               git config --alias.unstage 'reset HEAD --'
               git config --alias.last 'log -1 HEAD'
               git config --alias.visual '!gitk' ;;
            1) echo "  Skipped" ;;
            2) echo "Setup cancelled."; return 1 ;;
        esac
        optional_improvements=$((optional_improvements + 1))
    fi
}

# =============================================================================
# CMake and Build Setup
# =============================================================================
setup_build_system() {
    cd "$PROJECT_ROOT"

    # Create build directory
    mkdir -p build

    # Configure CMake for development (silently unless there's an error)
    if ! cmake -B build \
        -DCMAKE_BUILD_TYPE=Debug \
        -DMETAGRAPH_DEV=ON \
        -DMETAGRAPH_SANITIZERS=ON \
        -DMETAGRAPH_BUILD_TESTS=ON \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
        -G Ninja >/dev/null 2>&1; then
        echo "❌ CMake configuration failed"
        return 1
    fi

    # Silent success - only speak if there's a problem
}

# =============================================================================
# VSCode Setup
# =============================================================================
setup_vscode() {
    if command -v code >/dev/null 2>&1; then
        # Install extensions from .vscode/extensions.json (silently)
        if [ -f "$PROJECT_ROOT/.vscode/extensions.json" ] && command -v python3 >/dev/null 2>&1; then
            # Extract extension IDs and install them silently
            python3 -c "
import json
with open('$PROJECT_ROOT/.vscode/extensions.json', 'r') as f:
    data = json.load(f)
    for ext in data.get('recommendations', []):
        print(ext)
" | while IFS= read -r extension; do
                [ -z "$extension" ] && continue
                if ! code --install-extension "$extension" --force >/dev/null 2>&1; then
                    echo "⚠️  Failed to install VSCode extension: $extension"
                fi
            done
        fi
        # Silent success - only speak if there are problems
    else
        echo "⚠️  VSCode not found. Please install VSCode and run this script again."
    fi
}

# =============================================================================
# Tool Version Verification
# =============================================================================
mg_tool_exists_versions() {
    version_warnings=""

    # Check clang-format version (need 15+ for C23 support)
    if command -v clang-format >/dev/null 2>&1; then
        CLANG_FORMAT_VERSION=$(clang-format --version | grep -o '[0-9]\+\.[0-9]\+' | head -1)
        MAJOR_VERSION=$(echo "$CLANG_FORMAT_VERSION" | cut -d. -f1)
        if [ "$MAJOR_VERSION" -lt 15 ]; then
            version_warnings="$version_warnings\n  • clang-format $CLANG_FORMAT_VERSION is old (need 15+ for C23) - consider updating"
        fi
    fi

    # Check cmake version (need 3.28+ for C23)
    if command -v cmake >/dev/null 2>&1; then
        CMAKE_VERSION=$(cmake --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        CMAKE_MAJOR=$(echo "$CMAKE_VERSION" | cut -d. -f1)
        CMAKE_MINOR=$(echo "$CMAKE_VERSION" | cut -d. -f2)
        if [ "$CMAKE_MAJOR" -lt 3 ] || { [ "$CMAKE_MAJOR" -eq 3 ] && [ "$CMAKE_MINOR" -lt 28 ]; }; then
            version_warnings="$version_warnings\n  • cmake $CMAKE_VERSION is old (need 3.28+ for C23) - consider updating"
        fi
    fi

    # Only show output if there are version warnings
    if [ -n "$version_warnings" ]; then
        echo ""
        mg_yellow "⚠️  Tool version warnings:"
        printf "%s\n" "$version_warnings"
        echo ""
    fi
}

# =============================================================================
# Verification
# =============================================================================
verify_setup() {
    # Check required tools (POSIX-compliant)
    REQUIRED_TOOLS="cmake ninja clang clang-format clang-tidy git gitleaks"

    missing_tools=""
    verification_issues=""

    for tool in $REQUIRED_TOOLS; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools="$missing_tools $tool"
        fi
    done

    if [ -n "$missing_tools" ]; then
        verification_issues="$verification_issues\n  Missing tools:$missing_tools"
    fi

    # Check git hooks
    if [ -f "$PROJECT_ROOT/.git/hooks/pre-commit" ]; then
        # Check if hooks are executable
        cd "$PROJECT_ROOT"
        if [ ! -x "$PROJECT_ROOT/.git/hooks/pre-commit" ]; then
            verification_issues="$verification_issues\n  Git hooks not executable"
        fi
    else
        verification_issues="$verification_issues\n  Git pre-commit hook not found"
    fi

    # Only show output if there are verification issues
    if [ -n "$verification_issues" ]; then
        echo ""
        mg_red "❌ Development environment verification failed:"
        printf "%s\n" "$verification_issues"
        echo ""
        echo "Run the setup script with appropriate flags to resolve these issues."
        exit 1
    fi

    # Silent success - environment is properly configured
}

# =============================================================================
# Help Function
# =============================================================================
show_help() {
    cat << EOF
MetaGraph Development Environment Setup

Usage: $0 [OPTIONS]

OPTIONS:
    --help, -h          Show this help message
    --dry-run, --check  Check what tools are missing (no installation)
    --verify            Verify complete environment setup
    --deps-only         Install only dependencies
    --git-only          Setup only git configuration
    --build-only        Setup only build system
    --vscode-only       Setup only VSCode
    --skip-deps         Skip dependency installation
    --skip-git          Skip git configuration
    --skip-build        Skip build system setup
    --skip-vscode       Skip VSCode setup

EXAMPLES:
    $0                  Full setup (recommended)
    $0 --dry-run        Check what tools are missing
    $0 --verify         Verify environment is properly configured
    $0 --deps-only      Install only system dependencies
    $0 --skip-deps      Setup everything except system dependencies

This script will:
1. Install required system dependencies (cmake, clang, etc.)
2. Check tool versions for C23 compatibility
3. Install bash-based git hooks (no Python!)
4. Configure git settings and aliases
5. Configure CMake build system
6. Install VSCode extensions (if VSCode is available)
7. Verify the complete setup

For more information, see: docs/development-setup.md
EOF
}

# =============================================================================
# Main Function
# =============================================================================
main() {
    install_deps=true
    setup_git_config=true
    setup_build=true
    setup_vscode_config=true
    verify_only=false
    dry_run=false

    # Parse command line arguments
    while [ $# -gt 0 ]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --verify|--verify-only)
                verify_only=true
                install_deps=false
                setup_git_config=false
                setup_build=false
                setup_vscode_config=false
                ;;
            --dry-run|--check)
                dry_run=true
                install_deps=false
                setup_git_config=false
                setup_build=false
                setup_vscode_config=false
                ;;
            --deps-only)
                setup_git_config=false
                setup_build=false
                setup_vscode_config=false
                ;;
            --git-only)
                install_deps=false
                setup_build=false
                setup_vscode_config=false
                ;;
            --build-only)
                install_deps=false
                setup_git_config=false
                setup_vscode_config=false
                ;;
            --vscode-only)
                install_deps=false
                setup_git_config=false
                setup_build=false
                ;;
            --skip-deps)
                install_deps=false
                ;;
            --skip-git)
                setup_git_config=false
                ;;
            --skip-build)
                setup_build=false
                ;;
            --skip-vscode)
                setup_vscode_config=false
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done

    # Execute setup steps
    if [ "$dry_run" = true ]; then
        mg_tool_exists_check
        exit $?
    fi

    if [ "$verify_only" = true ]; then
        verify_setup
        exit 0
    fi

    if [ "$install_deps" = true ]; then
        install_tools
    fi

    # Always check tool versions for C23 compatibility
    mg_tool_exists_versions

    if [ "$setup_git_config" = true ]; then
        if ! setup_git; then
            # Git config issues should not prevent hook installation
            echo "⚠️  Git configuration had issues, but continuing with hook installation"
        fi
        install_git_hooks
    fi

    if [ "$setup_build" = true ]; then
        setup_build_system
    fi

    if [ "$setup_vscode_config" = true ]; then
        setup_vscode
    fi

    verify_setup

    # Only show next steps if we actually performed setup actions
    if [ "$install_deps" = true ] || [ "$setup_git_config" = true ] || [ "$setup_build" = true ] || [ "$setup_vscode_config" = true ]; then
        echo ""
        mg_green "✅ Development environment setup complete!"
        echo ""
        echo "🎯 Next steps:"
        echo "1. Run 'cmake --build build' to build the project"
        echo "2. Run 'ctest --test-dir build' to run tests (when implemented)"
        echo "3. Open the project in VSCode for the best development experience"
        echo "4. Make a test commit to verify git hooks are working"
        echo "5. Consider updating tools if version check shows old versions"
        echo ""
        echo "📚 For more information, see:"
        echo "   - CLAUDE.md for build system and shell script standards"
        echo "   - docs/features/ for implementation roadmap"
        echo "   - README.md for project overview"
    fi
}

# Run main function with all arguments
main "$@"
