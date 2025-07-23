#!/bin/sh

# MetaGraph Interactive Utilities
# Functions for user interaction and prompts

# Check if we're running interactively
mg_is_interactive() {
    [ -t 0 ] && [ -t 1 ]
}

# Generic Y/n prompt function with proper validation
# Usage: mg_prompt_yn "Question?" && echo "yes" || echo "no"
# Returns 0 (success) for Y/yes, 1 (failure) for N/no, 2 for quit
# In non-interactive mode, always returns 1 (no) for security
mg_prompt_yn() {
    question="${1:-"Continue?"}"
    default="${2:-"Y"}"  # Y or N
    allow_quit="${3:-false}"  # Allow 'q' to quit

    # SECURITY: Never assume yes in non-interactive mode
    if ! mg_is_interactive; then
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
            ""|ESC|esc|Esc)  # ESC key - abort entire script
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
# Usage: mg_prompt_and_execute "Install package?" "apt install foo"
mg_prompt_and_execute() {
    question="$1"
    command="$2"
    default="${3:-"Y"}"

    if mg_prompt_yn "$question" "$default"; then
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
