#!/bin/sh
# Meta-Graph gitleaks wrapper script

set -eu

# Load shared shell library
PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
. "$PROJECT_ROOT/scripts/mg.sh"

# Check for gitleaks and offer to install if missing (only in interactive mode)
if ! mg_tool_exists gitleaks >/dev/null 2>&1; then
    if is_interactive; then
        install_cmd=""
        install_cmd="$(get_install_command gitleaks)"
        if ! prompt_install_tool gitleaks "$install_cmd" "Gitleaks (secret scanner)"; then
            echo "❌ gitleaks is required for security scanning"
            echo "Install it with: $(get_install_command gitleaks)"
            exit 1
        fi
    else
        echo "❌ gitleaks not found and running in non-interactive mode"
        echo "Install it with: $(get_install_command gitleaks)"
        echo "Or run manually: ./scripts/setup-dev-env.sh"
        exit 1
    fi
fi

GITLEAKS="$(command -v gitleaks)"

# Main function
main() {
    scan_mode="detect"
    verbose=false
    staged_only=false

    # Parse arguments
    while [ $# -gt 0 ]; do
        case $1 in
            --staged|-s)
                staged_only=true
                shift
                ;;
            --protect|-p)
                scan_mode="protect"
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
    --staged, -s    Scan only staged files (for pre-commit)
    --protect, -p   Scan uncommitted changes (for pre-push)
    --verbose, -v   Verbose output
    --help, -h      Show this help

EXAMPLES:
    $0 --staged     # Scan staged files before commit
    $0 --protect    # Scan all uncommitted changes before push
    $0              # Full repository scan
EOF
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    cd "$PROJECT_ROOT"

    if [ "$verbose" = true ]; then
        echo "Using gitleaks: $GITLEAKS"
        echo "Scan mode: $scan_mode"
        echo "Staged only: $staged_only"
    fi

    # Build command arguments
    if [ "$staged_only" = true ]; then
        echo "🔍 Scanning staged files for secrets..."
        if [ "$verbose" = true ]; then
            set -- protect --staged --verbose
        else
            set -- protect --staged
        fi
    elif [ "$scan_mode" = "protect" ]; then
        echo "🔍 Scanning uncommitted changes for secrets..."
        if [ "$verbose" = true ]; then
            set -- protect --verbose
        else
            set -- protect
        fi
    else
        echo "🔍 Scanning repository for secrets..."
        if [ "$verbose" = true ]; then
            set -- detect --verbose
        else
            set -- detect
        fi
    fi

    # Run gitleaks
    if "$GITLEAKS" "$@"; then
        echo "✓ No secrets detected"
    else
        exit_code=$?
        echo "❌ Secrets detected in repository!"
        echo ""
        echo "SECURITY ALERT: Potential secrets found. Please:"
        echo "1. Remove any exposed credentials"
        echo "2. Rotate any compromised secrets"
        echo "3. Use environment variables or secure vaults for secrets"
        echo ""
        exit $exit_code
    fi
}

main "$@"
