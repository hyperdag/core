#!/bin/sh
# Check version consistency between CMakeLists.txt and version.h

set -eu

# Load shared shell library (tools auto-configured)
PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
. "$PROJECT_ROOT/scripts/mg.sh"

CMAKE_FILE="CMakeLists.txt"
VERSION_HEADER="include/metagraph/version.h"

if [ ! -f "$CMAKE_FILE" ]; then
    mg_red "ERROR: CMakeLists.txt not found"
    exit 1
fi

if [ ! -f "$VERSION_HEADER" ]; then
    mg_red "ERROR: version.h header not found"
    exit 1
fi

# Extract version from CMakeLists.txt
CMAKE_VERSION=$(grep -E 'project\(MetaGraph VERSION' "$CMAKE_FILE" | sed -E 's/.*VERSION ([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
if [ -z "$CMAKE_VERSION" ]; then
    mg_red "ERROR: Could not extract version from CMakeLists.txt"
    exit 1
fi

# Parse version components
CMAKE_MAJOR=$(echo "$CMAKE_VERSION" | cut -d. -f1)
CMAKE_MINOR=$(echo "$CMAKE_VERSION" | cut -d. -f2)
CMAKE_PATCH=$(echo "$CMAKE_VERSION" | cut -d. -f3)

# Extract versions from header
HEADER_MAJOR=$(grep -E '#define METAGRAPH_API_VERSION_MAJOR' "$VERSION_HEADER" | awk '{print $3}')
HEADER_MINOR=$(grep -E '#define METAGRAPH_API_VERSION_MINOR' "$VERSION_HEADER" | awk '{print $3}')
HEADER_PATCH=$(grep -E '#define METAGRAPH_API_VERSION_PATCH' "$VERSION_HEADER" | awk '{print $3}')
HEADER_STRING=$(grep -E '#define METAGRAPH_API_VERSION_STRING' "$VERSION_HEADER" | awk '{print $3}' | tr -d '"')

# Check consistency
ERRORS=0

if [ "$CMAKE_MAJOR" != "$HEADER_MAJOR" ]; then
    mg_red "ERROR: Major version mismatch: CMake=$CMAKE_MAJOR, header=$HEADER_MAJOR"
    mg_yellow "Hint: Run 'cmake .' in the build directory to regenerate version.h"
    ERRORS=1
fi

if [ "$CMAKE_MINOR" != "$HEADER_MINOR" ]; then
    mg_red "ERROR: Minor version mismatch: CMake=$CMAKE_MINOR, header=$HEADER_MINOR"
    mg_yellow "Hint: Run 'cmake .' in the build directory to regenerate version.h"
    ERRORS=1
fi

if [ "$CMAKE_PATCH" != "$HEADER_PATCH" ]; then
    mg_red "ERROR: Patch version mismatch: CMake=$CMAKE_PATCH, header=$HEADER_PATCH"
    mg_yellow "Hint: Run 'cmake .' in the build directory to regenerate version.h"
    ERRORS=1
fi

if [ "$CMAKE_VERSION" != "$HEADER_STRING" ]; then
    mg_red "ERROR: Version string mismatch: CMake=$CMAKE_VERSION, header=$HEADER_STRING"
    mg_yellow "Hint: Update version.h or run scripts/prepare-release.sh"
    ERRORS=1
fi

if [ $ERRORS -eq 0 ]; then
    mg_green "✓ Version consistency check passed ($CMAKE_VERSION)"
    exit 0
else
    mg_red "❌ Version consistency check failed"
    exit 1
fi