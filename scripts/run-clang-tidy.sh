#!/bin/sh
# Meta-Graph clang-tidy wrapper script

set -eu

# Load shared shell library (tools auto-configured)
PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
. "$PROJECT_ROOT/scripts/mg.sh"

CLANG_TIDY="$(command -v clang-tidy)"
CONFIG_FILE="$PROJECT_ROOT/.clang-tidy"
COMPILE_COMMANDS="$PROJECT_ROOT/build/compile_commands.json"

# Check if config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ .clang-tidy config not found at: $CONFIG_FILE"
    exit 1
fi

# Ensure compilation database exists
ensure_compile_commands() {
    if [ ! -f "$COMPILE_COMMANDS" ]; then
        echo "📁 Compilation database missing, generating it..."
        if [ ! -d "$PROJECT_ROOT/build" ]; then
            echo "🔧 Creating build directory..."
            mkdir -p "$PROJECT_ROOT/build"
        fi
        
        echo "⚙️  Running CMake to generate compile_commands.json..."
        if ! cmake -B "$PROJECT_ROOT/build" \
            -DCMAKE_BUILD_TYPE=Debug \
            -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
            -DMETAGRAPH_DEV=ON >/dev/null 2>&1; then
            mg_red "❌ Failed to generate compilation database with CMake"
            exit 1
        fi
        
        if [ ! -f "$COMPILE_COMMANDS" ]; then
            mg_red "❌ CMake completed but compile_commands.json still missing"
            exit 1
        fi
        
        mg_green "✅ Compilation database generated successfully"
    fi
}

# Find all C source files
find_c_files() {
    find "$PROJECT_ROOT" \
        -name "*.c" \
        | grep -v "/build/" \
        | grep -v "/third_party/" \
        | grep -v "/external/" \
        | sort
}

# Main function
main() {
    check_mode=false
    fix_mode=false
    verbose=false

    # Parse arguments
    while [ $# -gt 0 ]; do
        case $1 in
            --check|-c)
                check_mode=true
                shift
                ;;
            --fix|-f)
                fix_mode=true
                shift
                ;;
            --verbose|-v)
                verbose=true
                shift
                ;;
            --help|-h)
                cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    --check, -c     Run static analysis (don't modify files)
    --fix, -f       Fix issues that can be auto-fixed
    --verbose, -v   Verbose output
    --help, -h      Show this help

EXAMPLES:
    $0 --check      # Run static analysis
    $0 --fix        # Auto-fix issues where possible
EOF
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Default to check mode
    if [ "$check_mode" = false ] && [ "$fix_mode" = false ]; then
        check_mode=true
    fi

    cd "$PROJECT_ROOT"

    # Ensure compilation database exists (generate if missing)
    ensure_compile_commands

    # Create temp file list for portability
    temp_file_list="/tmp/mg_tidy_files_$$"
    find_c_files > "$temp_file_list"

    file_count=$(wc -l < "$temp_file_list")
    if [ "$file_count" -eq 0 ]; then
        echo "✓ No C source files found to analyze"
        rm -f "$temp_file_list"
        return 0
    fi

    if [ "$verbose" = true ]; then
        echo "Using clang-tidy: $CLANG_TIDY"
        echo "Config file: $CONFIG_FILE"
        echo "Compile commands: $COMPILE_COMMANDS"
        echo "Found $file_count C source files"
    fi

    tidy_args="--config-file=$CONFIG_FILE"

    if [ -f "$COMPILE_COMMANDS" ]; then
        tidy_args="$tidy_args -p $PROJECT_ROOT/build"
    fi

    if [ "$fix_mode" = true ]; then
        tidy_args="$tidy_args --fix --fix-errors"
        mg_yellow "🔧 Running clang-tidy with auto-fix..."
    else
        echo "🔍 Running clang-tidy static analysis..."
    fi

    issues=0
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        if [ "$verbose" = true ]; then
            echo "Analyzing: $file"
        fi

        if ! $CLANG_TIDY $tidy_args "$file"; then
            issues=$((issues + 1))
            mg_red "❌ Issues found in: $file"
        elif [ "$verbose" = true ]; then
            mg_green "✓ $file"
        fi
    done < "$temp_file_list"

    rm -f "$temp_file_list"

    if [ $issues -gt 0 ]; then
        mg_red "❌ Found issues in $issues file(s)"
        if [ "$fix_mode" = false ]; then
            echo "Run: $0 --fix (to auto-fix what's possible)"
        fi
        exit 1
    else
        mg_green "✅ All files pass static analysis"
    fi
}

main "$@"
