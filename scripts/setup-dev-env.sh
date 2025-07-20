#!/bin/sh
# HyperDAG Development Environment Setup Script
# Installs all required tools, dependencies, and configures git hooks

set -eu

# Load shared shell library
PROJECT_ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
. "$PROJECT_ROOT/scripts/shlib.sh"

PLATFORM="$(get_platform)"
PACKAGE_MANAGER="$(detect_package_manager)"

# =============================================================================
# Tool Installation
# =============================================================================
check_tools() {
    # List of required tools with descriptions
    TOOLS_TO_CHECK="cmake:CMake_build_system clang-format:LLVM_formatter clang-tidy:LLVM_analyzer gitleaks:Secret_scanner"
    
    missing_tools=""
    
    # Check each tool silently
    for tool_spec in $TOOLS_TO_CHECK; do
        tool_name="${tool_spec%:*}"
        tool_desc="${tool_spec#*:}"
        tool_desc="$(echo "$tool_desc" | sed 's/_/ /g')"
        
        if ! check_tool "$tool_name" >/dev/null 2>&1; then
            if [ -z "$missing_tools" ]; then
                echo ""
                red "❌ Missing required development tools:"
            fi
            echo "  • $tool_name ($tool_desc)"
            if [ "$PACKAGE_MANAGER" != "unknown" ]; then
                install_cmd="$(get_install_command "$tool_name")"
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
    if ! is_interactive; then
        echo "❌ Running in non-interactive mode - cannot install tools"
        echo "Use --verify or --dry-run to check what's missing"
        return 1
    fi
    
    # Tools are already in PATH thanks to automatic setup in shlib.sh
    TOOLS_TO_CHECK="cmake:CMake_build_system clang-format:LLVM_formatter clang-tidy:LLVM_analyzer gitleaks:Secret_scanner"
    
    tools_prompted=false
    
    # Check each tool and offer to install if missing
    for tool_spec in $TOOLS_TO_CHECK; do
        tool_name="${tool_spec%:*}"
        tool_desc="${tool_spec#*:}"
        tool_desc="$(echo "$tool_desc" | sed 's/_/ /g')"
        
        if ! check_tool "$tool_name" >/dev/null 2>&1; then
            if [ "$tools_prompted" = false ]; then
                echo ""
                yellow "🔧 Missing development tools - installation available:"
                tools_prompted=true
            fi
            echo ""
            echo "• $tool_name ($tool_desc)"
            install_cmd="$(get_install_command "$tool_name")"
            if ! prompt_install_tool "$tool_name" "$install_cmd" "$tool_desc"; then
                yellow "  ⚠️  Skipping $tool_name - some features may not work"
            fi
        fi
    done
}

# =============================================================================
# Git Hook Installation
# =============================================================================
install_git_hooks() {
    cd "$PROJECT_ROOT"
    
    # Remove any Python pre-commit installation first
    if command -v pre-commit >/dev/null 2>&1; then
        pre-commit uninstall >/dev/null 2>&1 || true
    fi
    
    # Create our bash-based git hooks
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
# HyperDAG Pre-commit Hook
# Runs essential quality checks before allowing commits

set -eu

# Load shared shell library (tools auto-configured)
PROJECT_ROOT="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
. "$PROJECT_ROOT/scripts/shlib.sh"

echo "🔍 Running pre-commit quality checks..."

# Change to project root
cd "$PROJECT_ROOT"

# 1. Check code formatting
echo "📝 Checking code formatting..."
if ! ./scripts/run-clang-format.sh --check; then
    echo "💡 Tip: Run './scripts/run-clang-format.sh --fix' to auto-fix formatting"
    exit 1
fi

# 2. Scan for secrets in staged files
echo "🔒 Scanning for secrets..."
if ! ./scripts/run-gitleaks.sh --staged; then
    exit 1
fi

# 3. Check version consistency
echo "🔢 Checking version consistency..."
if ! ./scripts/check-version-consistency.sh; then
    exit 1
fi

# 4. Check include guards
echo "🛡️  Checking include guards..."
# Only check staged header files
staged_headers=$(git diff --cached --name-only --diff-filter=ACM | grep '\.h$' || true)
if [ -n "$staged_headers" ]; then
    if ! echo "$staged_headers" | xargs ./scripts/check-include-guards.sh; then
        exit 1
    fi
else
    echo "✓ No header files to check"
fi

# 5. API naming conventions are checked by clang-tidy (more robust)
echo "📋 API naming conventions checked by clang-tidy"

# 6. Run quick tests (if any exist)
echo "⚡ Running quick tests..."
if ! ./scripts/run-quick-tests.sh; then
    exit 1
fi

echo "✅ All pre-commit checks passed!"
echo ""
EOF

    cat > .git/hooks/pre-push << 'EOF'
#!/bin/sh
# HyperDAG Pre-push Hook
# Runs comprehensive quality checks before pushing

set -eu

# Load shared shell library (tools auto-configured)
PROJECT_ROOT="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
. "$PROJECT_ROOT/scripts/shlib.sh"

echo "🚀 Running pre-push quality checks..."

# Change to project root
cd "$PROJECT_ROOT"

# 1. Run static analysis (if build exists)
echo "🔍 Running static analysis..."
if ! ./scripts/run-clang-tidy.sh --check; then
    exit 1
fi

# 2. Run full security scan
echo "🔒 Running full security scan..."
if ! ./scripts/run-gitleaks.sh; then
    exit 1
fi

# 3. Run test suite (if build exists)
echo "🧪 Running test suite..."
if [ -d "$PROJECT_ROOT/build" ]; then
    if [ -f "$PROJECT_ROOT/build/Makefile" ] || [ -f "$PROJECT_ROOT/build/build.ninja" ]; then
        echo "Building and testing..."
        if ! cmake --build build; then
            echo "❌ Build failed"
            exit 1
        fi
        if ! ctest --test-dir build --output-on-failure; then
            echo "❌ Tests failed"
            exit 1
        fi
    else
        echo "⚠️  Build directory exists but no build files found"
        echo "Run: cmake -B build"
    fi
else
    echo "⚠️  Build directory not found. Run: cmake -B build"
    echo "Skipping build and test checks..."
fi

echo "✅ All pre-push checks passed!"
echo "🎯 Ready to push to remote repository"
EOF

    # Make hooks executable
    chmod +x .git/hooks/pre-commit .git/hooks/pre-push
    
    # Silent success - only show output if there were problems creating hooks
    if [ ! -x .git/hooks/pre-commit ] || [ ! -x .git/hooks/pre-push ]; then
        echo "❌ Failed to create or make git hooks executable"
        return 1
    fi
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
    prompt_yn "Set $setting_name = $recommended_value?" "Y" true
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

    # Check optional git configuration settings
    optional_configs="
        core.autocrlf:false:preserve_original_line_endings:git_config_--local_core.autocrlf_false
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
        
        current=$(git config --local "$setting" 2>/dev/null || echo "unset")
        if [ "$current" != "$expected" ]; then
            if [ $optional_improvements -eq 0 ]; then
                echo ""
                yellow "🔧 Optional git configuration improvements available:"
            fi
            prompt_git_config "$setting" "$current" "$expected" "$description" "$command"
            optional_improvements=$((optional_improvements + 1))
        fi
    done

    # 5. REQUIRED: Check git commit signing
    current_gpgsign=$(git config --local commit.gpgsign 2>/dev/null || echo "unset")
    current_signingkey=$(git config --local user.signingkey 2>/dev/null || echo "unset")
    
    if [ "$current_gpgsign" != "true" ] || [ "$current_signingkey" = "unset" ]; then
        echo ""
        red "🔒 REQUIRED: Git Commit Signing (NOT CONFIGURED)"
        echo "Signed commits are mandatory for security and authenticity."
        echo "Current gpgsign: $current_gpgsign"
        echo "Current signing key: $current_signingkey"
        echo ""
        red "❌ Git commit signing is not properly configured!"
        echo ""
        echo "To set up commit signing:"
        echo "1. Generate a GPG key: gpg --full-generate-key"
        echo "2. List keys: gpg --list-secret-keys --keyid-format=long"
        echo "3. Configure git: git config --local user.signingkey YOUR_KEY_ID"
        echo "4. Enable signing: git config --local commit.gpgsign true"
        echo ""
        prompt_yn "Do you want to configure commit signing now?" "Y" true
        result=$?
        case $result in
            0) 
                echo "Please follow the steps above to configure GPG signing."
                echo "After setting up GPG, run this script again to verify."
                return 1
                ;;
            1)
                echo ""
                red "⚠️  WARNING: Proceeding without commit signing is not recommended!"
                red "All commits should be signed for security verification."
                prompt_yn "Continue anyway?" "N" true
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
        current_alias=$(git config --local alias.$alias_name 2>/dev/null || echo "unset")
        if [ "$current_alias" != "$alias_cmd" ]; then
            aliases_needed="$aliases_needed $alias_name"
        fi
    done
    
    if [ -n "$aliases_needed" ]; then
        if [ $optional_improvements -eq 0 ]; then
            echo ""
            yellow "🔧 Optional git configuration improvements available:"
        fi
        echo ""
        yellow "• Git aliases (convenience shortcuts)"
        echo "  Missing aliases:$aliases_needed (st=status, co=checkout, br=branch, ci=commit, etc.)"
        prompt_yn "Add helpful git aliases?" "Y" true
        result=$?
        case $result in
            0) git config --local alias.st status
               git config --local alias.co checkout
               git config --local alias.br branch
               git config --local alias.ci commit
               git config --local alias.unstage 'reset HEAD --'
               git config --local alias.last 'log -1 HEAD'
               git config --local alias.visual '!gitk' ;;
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
        -DHYPERDAG_DEV=ON \
        -DHYPERDAG_SANITIZERS=ON \
        -DHYPERDAG_BUILD_TESTS=ON \
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
check_tool_versions() {
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
        if [ "$CMAKE_MAJOR" -lt 3 ] || [ "$CMAKE_MAJOR" -eq 3 -a "$CMAKE_MINOR" -lt 28 ]; then
            version_warnings="$version_warnings\n  • cmake $CMAKE_VERSION is old (need 3.28+ for C23) - consider updating"
        fi
    fi
    
    # Only show output if there are version warnings
    if [ -n "$version_warnings" ]; then
        echo ""
        yellow "⚠️  Tool version warnings:"
        echo -e "$version_warnings"
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
        red "❌ Development environment verification failed:"
        echo -e "$verification_issues"
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
HyperDAG Development Environment Setup

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
        check_tools
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
    check_tool_versions

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
        green "✅ Development environment setup complete!"
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
