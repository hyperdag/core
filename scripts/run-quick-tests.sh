#!/bin/sh
# Run quick tests suitable for pre-commit hook (fast subset)

set -eu

echo "🚀 Running quick tests for pre-commit..."

# Check if we have any tests to run
if [ ! -d "tests" ] && [ ! -f "CMakeLists.txt" ]; then
    echo "⚠️  No tests found - implementation pending"
    echo "✓ Quick tests passed (no tests to run)"
    exit 0
fi

# For now, since we're in the architecture phase, just run basic checks
echo "📋 Running basic sanity checks..."

# Check that all headers compile
HEADER_CHECK=0
if command -v gcc >/dev/null 2>&1; then
    echo "🔍 Checking header compilation..."
    for header in include/mg/*.h; do
        if [ -f "$header" ]; then
            echo "  Checking: $header"
            if ! gcc -std=c23 -fsyntax-only -I include "$header" 2>/dev/null; then
                echo "❌ Header compilation failed: $header"
                HEADER_CHECK=1
            fi
        fi
    done
fi

# Check version header exists
if [ -f "include/metagraph/version.h" ]; then
    echo "🔍 Validating version header..."
    if ! grep -q "#define METAGRAPH_API_VERSION_MAJOR" include/metagraph/version.h; then
        echo "❌ version.h missing METAGRAPH_API_VERSION_MAJOR"
        exit 1
    fi
    if ! grep -q "#define METAGRAPH_API_VERSION_MINOR" include/metagraph/version.h; then
        echo "❌ version.h missing METAGRAPH_API_VERSION_MINOR"
        exit 1
    fi
    if ! grep -q "#define METAGRAPH_API_VERSION_PATCH" include/metagraph/version.h; then
        echo "❌ version.h missing METAGRAPH_API_VERSION_PATCH"
        exit 1
    fi
fi

# Check feature specification consistency
if [ -d "docs/features" ]; then
    echo "🔍 Checking feature specification consistency..."
    FEATURE_COUNT="$(find docs/features -name "F*.md" | wc -l)"
    if [ "$FEATURE_COUNT" -gt 0 ]; then
        echo "  Found $FEATURE_COUNT feature specifications"

        # Check that README.md in features exists and references all features
        if [ -f "docs/features/README.md" ]; then
            for feature_file in docs/features/F*.md; do
                feature_id=$(basename "$feature_file" .md)
                if ! grep -q "$feature_id" docs/features/README.md; then
                    echo "⚠️  Feature $feature_id not referenced in docs/features/README.md"
                fi
            done
        fi
    fi
fi

# Check result.h error code consistency
if [ -f "include/mg/result.h" ]; then
    echo "🔍 Checking error code consistency..."
    if ! grep -q "HYPERDAG_SUCCESS" include/mg/result.h; then
        echo "❌ Missing HYPERDAG_SUCCESS in result.h"
        exit 1
    fi
    if ! grep -q "HYP_OK()" include/mg/result.h; then
        echo "❌ Missing HYP_OK() macro in result.h"
        exit 1
    fi
fi

if [ $HEADER_CHECK -eq 1 ]; then
    echo "❌ Quick tests failed due to header compilation errors"
    exit 1
fi

echo "✓ Quick tests passed"
exit 0
