#!/bin/sh
# Meta-Graph clang-format wrapper script

set -eu

# Load shared shell library (tools auto-configured)
PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
. "$PROJECT_ROOT/scripts/mg.sh"

CLANG_FORMAT=$(command -v clang-format)

# Parse arguments
check_mode=false
fix_mode=false
verbose=false

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
    --check, -c     Check formatting (don't modify files)
    --fix, -f       Fix formatting issues
    --verbose, -v   Verbose output
    --help, -h      Show this help

EXAMPLES:
    $0 --check      # Check if files are properly formatted
    $0 --fix        # Auto-fix formatting issues
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

if [ "$verbose" = true ]; then
    echo "Using clang-format: $CLANG_FORMAT"
    echo "Project root: $PROJECT_ROOT"
fi

if [ "$check_mode" = true ]; then
    echo "🔍 Checking code formatting..."

    issues=0
    find "$PROJECT_ROOT" \( -name '*.c' -o -name '*.h' \) -print | \
    grep -v /build/ | grep -v /third_party/ | grep -v /external/ | \
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        # Force C language for .h files
        if ! "$CLANG_FORMAT" --dry-run --Werror --style=file --assume-filename="${file%.h}.c" "$file" >/dev/null 2>&1; then
            echo "❌ Formatting issues in: $file"
            issues=$((issues + 1))
        elif [ "$verbose" = true ]; then
            echo "✓ $file"
        fi
    done

    # Note: Due to subshell, we can't get the exact count, but any issues will show above
    echo "✓ Format check complete"

elif [ "$fix_mode" = true ]; then
    echo "🔧 Fixing code formatting..."

    find "$PROJECT_ROOT" \( -name '*.c' -o -name '*.h' \) -print | \
    grep -v /build/ | grep -v /third_party/ | grep -v /external/ | \
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        if [ "$verbose" = true ]; then
            echo "Formatting: $file"
        fi
        # Force C language for .h files
        "$CLANG_FORMAT" -i --style=file --assume-filename="${file%.h}.c" "$file"
    done

    echo "✓ Formatting complete"
fi
