#!/bin/sh
# Check version consistency between VERSION file and version.h

set -eu

VERSION_FILE="VERSION"
VERSION_HEADER="include/hyperdag/version.h"

if [ ! -f "$VERSION_FILE" ]; then
    echo "ERROR: VERSION file not found"
    exit 1
fi

if [ ! -f "$VERSION_HEADER" ]; then
    echo "ERROR: version.h header not found"
    exit 1
fi

# Extract versions from VERSION file
eval "$(grep -E '^HYPERDAG_API_VERSION_(MAJOR|MINOR|PATCH)=' "$VERSION_FILE")"
eval "$(grep -E '^HYPERDAG_API_VERSION_STRING=' "$VERSION_FILE")"
eval "$(grep -E '^HYPERDAG_BUNDLE_FORMAT_VERSION=' "$VERSION_FILE")"
eval "$(grep -E '^HYPERDAG_BUNDLE_FORMAT_UUID=' "$VERSION_FILE")"

# Extract versions from header file
HEADER_MAJOR=$(grep -E '#define HYPERDAG_API_VERSION_MAJOR' "$VERSION_HEADER" | awk '{print $3}')
HEADER_MINOR=$(grep -E '#define HYPERDAG_API_VERSION_MINOR' "$VERSION_HEADER" | awk '{print $3}')
HEADER_PATCH=$(grep -E '#define HYPERDAG_API_VERSION_PATCH' "$VERSION_HEADER" | awk '{print $3}')
HEADER_STRING=$(grep -E '#define HYPERDAG_API_VERSION_STRING' "$VERSION_HEADER" | awk '{print $3}' | tr -d '"')
HEADER_BUNDLE_VERSION=$(grep -E '#define HYPERDAG_BUNDLE_FORMAT_VERSION' "$VERSION_HEADER" | awk '{print $3}')
HEADER_BUNDLE_UUID=$(grep -E '#define HYPERDAG_BUNDLE_FORMAT_UUID' "$VERSION_HEADER" | awk '{print $3}' | tr -d '"')

# Check consistency
ERRORS=0

if [ "$HYPERDAG_API_VERSION_MAJOR" != "$HEADER_MAJOR" ]; then
    echo "ERROR: API major version mismatch: VERSION=$HYPERDAG_API_VERSION_MAJOR, header=$HEADER_MAJOR"
    ERRORS=1
fi

if [ "$HYPERDAG_API_VERSION_MINOR" != "$HEADER_MINOR" ]; then
    echo "ERROR: API minor version mismatch: VERSION=$HYPERDAG_API_VERSION_MINOR, header=$HEADER_MINOR"
    ERRORS=1
fi

if [ "$HYPERDAG_API_VERSION_PATCH" != "$HEADER_PATCH" ]; then
    echo "ERROR: API patch version mismatch: VERSION=$HYPERDAG_API_VERSION_PATCH, header=$HEADER_PATCH"
    ERRORS=1
fi

if [ "$HYPERDAG_API_VERSION_STRING" != "$HEADER_STRING" ]; then
    echo "ERROR: API version string mismatch: VERSION=$HYPERDAG_API_VERSION_STRING, header=$HEADER_STRING"
    ERRORS=1
fi

if [ "$HYPERDAG_BUNDLE_FORMAT_VERSION" != "$HEADER_BUNDLE_VERSION" ]; then
    echo "ERROR: Bundle format version mismatch: VERSION=$HYPERDAG_BUNDLE_FORMAT_VERSION, header=$HEADER_BUNDLE_VERSION"
    ERRORS=1
fi

if [ "$HYPERDAG_BUNDLE_FORMAT_UUID" != "$HEADER_BUNDLE_UUID" ]; then
    echo "ERROR: Bundle format UUID mismatch: VERSION=$HYPERDAG_BUNDLE_FORMAT_UUID, header=$HEADER_BUNDLE_UUID"
    ERRORS=1
fi

if [ $ERRORS -eq 0 ]; then
    echo "✓ Version consistency check passed"
    exit 0
else
    echo "❌ Version consistency check failed"
    exit 1
fi
