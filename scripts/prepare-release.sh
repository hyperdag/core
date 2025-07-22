#!/bin/sh
# MetaGraph Release Preparation Script
# Validates release branch is ready for merge to main
# NO AUTO-FIXES - fail fast on any issue

set -eu

# Load shared shell library
PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
. "$PROJECT_ROOT/scripts/mg.sh"

# Exit codes
EXIT_NOT_RELEASE_BRANCH=1
EXIT_DIRTY_WORKTREE=2
EXIT_VERSION_MISMATCH=3
EXIT_VERSION_DOWNGRADE=4
EXIT_QUALITY_FAILED=5
EXIT_FILES_NEED_COMMIT=6

fail_with_code() {
    code=$1
    shift
    mg_red "❌ $*"
    exit "$code"
}

check_release_branch() {
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    
    if ! echo "$current_branch" | grep -qE '^release/v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$'; then
        fail_with_code $EXIT_NOT_RELEASE_BRANCH "Not on a release branch (current: $current_branch)"
    fi
    
    # Extract version from branch name
    version=$(echo "$current_branch" | sed 's|^release/v||')
    echo "$version"
}

check_clean_worktree() {
    if ! git diff --quiet || ! git diff --cached --quiet; then
        fail_with_code $EXIT_DIRTY_WORKTREE "Working tree is dirty. Commit or stash changes first."
    fi
    
    # Also check for untracked files (except .ignored/)
    untracked=$(git ls-files --others --exclude-standard | grep -v "^\.ignored/" || true)
    if [ -n "$untracked" ]; then
        fail_with_code $EXIT_DIRTY_WORKTREE "Untracked files found. Add to git or .gitignore."
    fi
}

get_current_version() {
    # Extract version from version.h
    major=$(grep "#define METAGRAPH_API_VERSION_MAJOR" include/metagraph/version.h | awk '{print $3}')
    minor=$(grep "#define METAGRAPH_API_VERSION_MINOR" include/metagraph/version.h | awk '{print $3}')
    patch=$(grep "#define METAGRAPH_API_VERSION_PATCH" include/metagraph/version.h | awk '{print $3}')
    
    echo "$major.$minor.$patch"
}

check_version_not_downgrade() {
    new_version=$1
    
    # Get latest git tag (ignore RC versions for comparison)
    latest_tag=$(git tag -l 'v*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1 || echo "v0.0.0")
    latest_version=${latest_tag#v}
    
    # Use sort -V to compare versions (handles RC correctly)
    if ! printf '%s\n%s' "$latest_version" "$new_version" | sort -V -C; then
        fail_with_code $EXIT_VERSION_DOWNGRADE "Version $new_version is lower than latest tag $latest_tag"
    fi
    
    # Also check against current version in files
    current_version=$(get_current_version)
    if ! printf '%s\n%s' "$current_version" "$new_version" | sort -V -C; then
        fail_with_code $EXIT_VERSION_DOWNGRADE "Version $new_version is lower than current $current_version"
    fi
}

check_version_files_match() {
    expected_version=$1
    files_updated=false
    
    # Check version.h
    current_version=$(get_current_version)
    if [ "$current_version" != "$expected_version" ]; then
        mg_yellow "Version mismatch in version.h: $current_version != $expected_version"
        files_updated=true
        update_version_header "$expected_version"
    fi
    
    # Check CMakeLists.txt
    cmake_version=$(grep "project(MetaGraph VERSION" CMakeLists.txt | sed 's/.*VERSION \([0-9.]*\).*/\1/')
    if [ "$cmake_version" != "$expected_version" ]; then
        mg_yellow "Version mismatch in CMakeLists.txt: $cmake_version != $expected_version"
        files_updated=true
        update_cmake_version "$expected_version"
    fi
    
    if [ "$files_updated" = true ]; then
        fail_with_code $EXIT_FILES_NEED_COMMIT "Version files updated. Commit them before pushing."
    fi
}

update_version_header() {
    version="$1"
    
    # Parse version components
    major=$(echo "$version" | cut -d. -f1)
    minor=$(echo "$version" | cut -d. -f2)
    patch=$(echo "$version" | cut -d. -f3 | cut -d- -f1)
    
    # Get current git info
    git_hash=$(git rev-parse HEAD)
    git_branch=$(git rev-parse --abbrev-ref HEAD)
    build_timestamp=$(date +%s)
    
    # Update version.h
    sed -i.bak \
        -e "s/#define METAGRAPH_API_VERSION_MAJOR .*/#define METAGRAPH_API_VERSION_MAJOR $major/" \
        -e "s/#define METAGRAPH_API_VERSION_MINOR .*/#define METAGRAPH_API_VERSION_MINOR $minor/" \
        -e "s/#define METAGRAPH_API_VERSION_PATCH .*/#define METAGRAPH_API_VERSION_PATCH $patch/" \
        -e "s/#define METAGRAPH_API_VERSION_STRING .*/#define METAGRAPH_API_VERSION_STRING \"$version\"/" \
        -e "s/#define METAGRAPH_BUILD_TIMESTAMP .*/#define METAGRAPH_BUILD_TIMESTAMP \"$build_timestamp\"/" \
        -e "s/#define METAGRAPH_BUILD_COMMIT_HASH .*/#define METAGRAPH_BUILD_COMMIT_HASH \"$git_hash\"/" \
        -e "s/#define METAGRAPH_BUILD_BRANCH .*/#define METAGRAPH_BUILD_BRANCH \"$git_branch\"/" \
        "$PROJECT_ROOT/include/metagraph/version.h"
    
    rm -f "$PROJECT_ROOT/include/metagraph/version.h.bak"
}

update_cmake_version() {
    version="$1"
    
    sed -i.bak \
        "s/project(MetaGraph VERSION .* LANGUAGES C)/project(MetaGraph VERSION $version LANGUAGES C)/" \
        "$PROJECT_ROOT/CMakeLists.txt"
    
    rm -f "$PROJECT_ROOT/CMakeLists.txt.bak"
}

run_quality_matrix() {
    mg_green "Running full quality matrix..."
    
    # Clean build
    rm -rf "$PROJECT_ROOT/build-release"
    
    # Configure with all checks enabled
    if ! cmake -B "$PROJECT_ROOT/build-release" \
        -DCMAKE_BUILD_TYPE=Release \
        -DMETAGRAPH_WERROR=ON \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON; then
        fail_with_code $EXIT_QUALITY_FAILED "CMake configuration failed"
    fi
    
    # Build
    if ! cmake --build "$PROJECT_ROOT/build-release" --parallel; then
        fail_with_code $EXIT_QUALITY_FAILED "Build failed"
    fi
    
    # Run tests
    if ! (cd "$PROJECT_ROOT/build-release" && ctest --output-on-failure); then
        fail_with_code $EXIT_QUALITY_FAILED "Tests failed"
    fi
    
    # Static analysis
    if ! "$PROJECT_ROOT/scripts/run-clang-tidy.sh"; then
        fail_with_code $EXIT_QUALITY_FAILED "Static analysis failed"
    fi
    
    # Security audit
    if ! "$PROJECT_ROOT/scripts/security-audit.sh"; then
        fail_with_code $EXIT_QUALITY_FAILED "Security audit failed"
    fi
    
    # Performance check (±5% tolerance)
    if [ -f "$PROJECT_ROOT/performance-baseline.txt" ]; then
        "$PROJECT_ROOT/scripts/profile.sh" timing
        
        # Simple check - in production would do proper statistical analysis
        if [ -f "$PROJECT_ROOT/.ignored/timing-analysis.txt" ]; then
            # Extract average time from both files
            baseline_time=$(grep "Real:" performance-baseline.txt | sed 's/.*Real: \([0-9.]*\)s.*/\1/')
            current_time=$(grep "Real:" .ignored/timing-analysis.txt | sed 's/.*Real: \([0-9.]*\)s.*/\1/')
            
            # Calculate percentage difference using awk
            perf_diff=$(awk -v b="$baseline_time" -v c="$current_time" 'BEGIN {
                if (b > 0) {
                    diff = ((c - b) / b) * 100
                    printf "%.1f", diff
                } else {
                    print "0"
                }
            }')
            
            # Check if regression exceeds 5%
            exceeds=$(awk -v d="$perf_diff" 'BEGIN { if (d > 5.0) print "yes"; else print "no" }')
            
            if [ "$exceeds" = "yes" ]; then
                fail_with_code $EXIT_QUALITY_FAILED "Performance regression: ${perf_diff}% (limit: 5%)"
            fi
            
            mg_green "Performance within tolerance: ${perf_diff}%"
        fi
    else
        mg_yellow "No performance baseline found - skipping regression check"
    fi
}

main() {
    mg_green "🔍 MetaGraph Release Preparation Check"
    
    # 1. Check we're on a release branch
    version=$(check_release_branch)
    mg_green "✓ On release branch for version $version"
    
    # 2. Check clean worktree
    check_clean_worktree
    mg_green "✓ Working tree is clean"
    
    # 3. Check version not a downgrade
    check_version_not_downgrade "$version"
    mg_green "✓ Version $version is not a downgrade"
    
    # 4. Check version files match branch
    check_version_files_match "$version"
    mg_green "✓ Version files match branch"
    
    # 5. Run full quality matrix
    run_quality_matrix
    mg_green "✓ All quality checks passed"
    
    mg_green "🎉 Release $version is ready for merge to main!"
}

# Run if called directly OR from pre-push hook
case "$0" in
    */prepare-release.sh|prepare-release.sh|-)
        main "$@"
        ;;
esac