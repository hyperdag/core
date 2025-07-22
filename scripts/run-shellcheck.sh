#!/bin/sh
# Run shellcheck on shell scripts in the project

set -eu

# Source the MetaGraph library
. "$(dirname "$0")/mg.sh"

print_header() {
    mg_blue "================================================"
    mg_blue "🐚 MetaGraph Shell Script Linting with shellcheck"
    mg_blue "================================================"
}

# Check if shellcheck is available
if ! mg_has_command shellcheck; then
    mg_red "❌ shellcheck not found"
    echo "Install with:"
    echo "  macOS: brew install shellcheck"
    echo "  Ubuntu/Debian: sudo apt-get install shellcheck"
    echo "  RHEL/CentOS: sudo yum install ShellCheck"
    echo "  Windows: winget install koalaman.shellcheck"
    exit 1
fi

# Find all shell scripts
find_shell_scripts() {
    # Find shell scripts by shebang or extension
    {
        find . -name "*.sh" -type f
        find . -type f -exec grep -l '^#!/bin/sh\|^#!/bin/bash\|^#!/usr/bin/env sh\|^#!/usr/bin/env bash' {} \; 2>/dev/null
    } | sort -u | grep -v -E '\./build/|\./node_modules/|\.git/' || true
}

# Run shellcheck on specific files or all shell scripts
main() {
    exit_code=0
    files_checked=0
    files_with_issues=0

    if [ $# -gt 0 ]; then
        # Check specific files provided as arguments
        scripts="$*"
    else
        # Check all shell scripts in the project
        print_header
        scripts="$(find_shell_scripts)"
    fi

    if [ -z "$scripts" ]; then
        mg_yellow "⚠️  No shell scripts found to check"
        return 0
    fi

    for script in $scripts; do
        # Skip files that don't exist or aren't readable
        [ -f "$script" ] || continue
        [ -r "$script" ] || continue

        files_checked=$((files_checked + 1))

        # Run shellcheck with appropriate options
        if shellcheck \
            --shell=sh \
            --exclude=SC1091 \
            --exclude=SC2034 \
            --format=gcc \
            "$script"; then
            if [ $# -eq 0 ]; then  # Only show success for full runs
                mg_green "✓ $script"
            fi
        else
            mg_red "❌ $script has issues"
            files_with_issues=$((files_with_issues + 1))
            exit_code=1
        fi
    done

    if [ $# -eq 0 ]; then  # Only show summary for full runs
        echo ""
        if [ $exit_code -eq 0 ]; then
            mg_green "🎉 All $files_checked shell scripts passed shellcheck!"
        else
            mg_red "💥 $files_with_issues of $files_checked shell scripts have issues"
        fi
    fi

    exit $exit_code
}

# Run if called directly
if [ "${0##*/}" = "run-shellcheck.sh" ]; then
    main "$@"
fi
