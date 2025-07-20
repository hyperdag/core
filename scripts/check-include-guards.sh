#!/bin/sh
# Check that all header files have proper include guards

set -eu

ERRORS=0

echo "🔍 Checking include guards..."

for header in "$@"; do
    if [ ! -f "$header" ]; then
        continue
    fi

    echo "  Checking: $header"

    # Generate expected include guard name
    # Convert path to uppercase, replace / and . with _
    GUARD_NAME=$(echo "$header" | tr '[:lower:]' '[:upper:]' | sed 's/[\/\.]/_/g' | sed 's/^INCLUDE_//')

    # Check for #ifndef GUARD_NAME
    if ! grep -q "^#ifndef $GUARD_NAME" "$header"; then
        echo "❌ Missing or incorrect #ifndef guard in $header (expected: $GUARD_NAME)"
        ERRORS=1
        continue
    fi

    # Check for #define GUARD_NAME
    if ! grep -q "^#define $GUARD_NAME" "$header"; then
        echo "❌ Missing or incorrect #define guard in $header (expected: $GUARD_NAME)"
        ERRORS=1
        continue
    fi

    # Check for #endif comment
    if ! grep -q "^#endif.*$GUARD_NAME" "$header"; then
        echo "❌ Missing or incorrect #endif comment in $header (expected: $GUARD_NAME)"
        ERRORS=1
        continue
    fi

    echo "  ✓ Include guard correct: $GUARD_NAME"
done

if [ $ERRORS -eq 0 ]; then
    echo "✓ All include guards are correct"
    exit 0
else
    echo "❌ Include guard check failed"
    exit 1
fi
