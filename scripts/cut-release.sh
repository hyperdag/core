#!/bin/sh
# MetaGraph CI/CD Release Script
# Called by CI after successful merge to main from release branch
# This script creates tags and triggers the release process

set -eu

# Load shared shell library
PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
. "$PROJECT_ROOT/scripts/mg.sh"

# Exit codes
EXIT_NOT_MAIN_BRANCH=1
EXIT_NOT_RELEASE_MERGE=2
EXIT_TAG_EXISTS=3
EXIT_VERSION_MISMATCH=4

fail_with_code() {
    code=$1
    shift
    mg_red "❌ $*"
    exit "$code"
}

check_main_branch() {
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [ "$current_branch" != "main" ]; then
        fail_with_code $EXIT_NOT_MAIN_BRANCH "Not on main branch (current: $current_branch)"
    fi
}

extract_version_from_merge() {
    # Get the latest merge commit message
    merge_msg=$(git log -1 --pretty=%B --grep="^Merge pull request")
    
    # Extract version from merge message
    if echo "$merge_msg" | grep -qE "from .*/release/v[0-9]+\.[0-9]+\.[0-9]+"; then
        version=$(echo "$merge_msg" | grep -oE "release/v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?" | head -1 | sed 's|release/v||')
        echo "$version"
    else
        fail_with_code $EXIT_NOT_RELEASE_MERGE "Latest merge is not from a release branch"
    fi
}

verify_version_files() {
    expected_version=$1
    
    # Check version.h
    header_version=$(grep "#define METAGRAPH_API_VERSION_STRING" include/metagraph/version.h | cut -d'"' -f2)
    if [ "$header_version" != "$expected_version" ]; then
        fail_with_code $EXIT_VERSION_MISMATCH "version.h mismatch: $header_version != $expected_version"
    fi
    
    # Check CMakeLists.txt (without pre-release suffix)
    version_no_rc=$(echo "$expected_version" | cut -d- -f1)
    cmake_version=$(grep "project(MetaGraph VERSION" CMakeLists.txt | sed 's/.*VERSION \([0-9.]*\).*/\1/')
    if [ "$cmake_version" != "$version_no_rc" ]; then
        fail_with_code $EXIT_VERSION_MISMATCH "CMakeLists.txt mismatch: $cmake_version != $version_no_rc"
    fi
}

check_tag_not_exists() {
    version=$1
    if git rev-parse "v$version" >/dev/null 2>&1; then
        fail_with_code $EXIT_TAG_EXISTS "Tag v$version already exists"
    fi
}

create_signed_tag() {
    version=$1
    commit_hash=$(git rev-parse HEAD)
    
    mg_green "Creating signed tag v$version"
    
    # Create annotated tag with release information
    tag_message="Release v$version

Version: $version
Commit: $commit_hash
Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)

This release was automatically tagged by the CI/CD pipeline
after successful merge from release/v$version branch.

For release notes, see CHANGELOG.md"

    # Create the tag (will be signed if GPG is configured)
    if git config --get user.signingkey >/dev/null 2>&1; then
        # GPG signing available
        git tag -s "v$version" -m "$tag_message"
        mg_green "Created signed tag v$version"
    else
        # No GPG, create annotated tag
        git tag -a "v$version" -m "$tag_message"
        mg_green "Created annotated tag v$version (unsigned)"
    fi
}

main() {
    mg_green "🚀 MetaGraph Release Cutter"
    
    # 1. Ensure we're on main
    check_main_branch
    mg_green "✓ On main branch"
    
    # 2. Extract version from merge commit
    version=$(extract_version_from_merge)
    mg_green "✓ Detected release version: $version"
    
    # 3. Verify version files match
    verify_version_files "$version"
    mg_green "✓ Version files match"
    
    # 4. Check tag doesn't exist
    check_tag_not_exists "$version"
    mg_green "✓ Tag v$version does not exist"
    
    # 5. Create signed tag
    create_signed_tag "$version"
    
    # 6. Push tag (triggers release workflow)
    if [ "${CI:-false}" = "true" ]; then
        git push origin "v$version"
        mg_green "✓ Pushed tag v$version"
    else
        mg_yellow "Local mode - tag created but not pushed"
        mg_yellow "Run: git push origin v$version"
    fi
    
    mg_green "🎉 Release v$version tagged successfully!"
    
    # Output for CI
    if [ "${GITHUB_ACTIONS:-false}" = "true" ]; then
        echo "version=$version" >> "$GITHUB_OUTPUT"
        echo "tag=v$version" >> "$GITHUB_OUTPUT"
    fi
}

# Run if called directly
case "${1:-}" in
    --help|-h)
        cat << EOF
Usage: $0

CI/CD release script that creates version tags after successful merge
from release branches to main. This script is typically called by CI.

Prerequisites:
- Must be on main branch
- Latest commit must be merge from release/v* branch
- Version files must match the release version
- Tag must not already exist

The script will:
1. Verify all prerequisites
2. Create annotated (or signed) tag
3. Push tag to trigger release workflow (in CI mode)

Exit codes:
  0 - Success
  1 - Not on main branch
  2 - Not a release merge
  3 - Tag already exists
  4 - Version mismatch
EOF
        ;;
    *)
        main "$@"
        ;;
esac