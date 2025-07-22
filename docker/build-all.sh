#!/bin/bash
# Build script for testing across multiple Docker environments

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Array of Docker images to test
IMAGES=(
    "gcc:13"
    "gcc:14"
    "gcc:15"
    "silkeh/clang:17"
    "silkeh/clang:18"
    "silkeh/clang:dev"
)

# Build configurations to test
BUILD_TYPES=("Debug" "Release")
SANITIZER_CONFIGS=("OFF" "ASAN" "UBSAN")

# Function to test a single configuration
test_config() {
    local image=$1
    local build_type=$2
    local sanitizer=$3
    local container_name
    container_name="mg-test-$(echo "$image" | tr '/:' '-')-${build_type,,}-${sanitizer,,}"

    print_status "Testing $image with $build_type build and $sanitizer sanitizers"

    # Prepare CMake flags
    local cmake_flags="-DCMAKE_BUILD_TYPE=$build_type -DMETAGRAPH_WERROR=ON"

    if [[ "$sanitizer" == "ASAN" ]]; then
        cmake_flags="$cmake_flags -DMETAGRAPH_SANITIZERS=ON -DMETAGRAPH_ASAN=ON -DMETAGRAPH_UBSAN=OFF"
    elif [[ "$sanitizer" == "UBSAN" ]]; then
        cmake_flags="$cmake_flags -DMETAGRAPH_SANITIZERS=ON -DMETAGRAPH_ASAN=OFF -DMETAGRAPH_UBSAN=ON"
    fi

    # Run the test in Docker
    if docker run --rm \
        --name "$container_name" \
        -v "$(pwd):/workspace" \
        -w /workspace \
        "$image" \
        bash -c "
            set -euo pipefail

            # Install dependencies if needed
            if command -v apt-get >/dev/null; then
                apt-get update >/dev/null 2>&1
                apt-get install -y cmake pkg-config libcriterion-dev git >/dev/null 2>&1 || true
            elif command -v apk >/dev/null; then
                apk add --no-cache cmake pkgconfig criterion-dev git >/dev/null 2>&1 || true
            fi

            # Configure and build
            echo 'Configuring...'
            cmake -B build-docker $cmake_flags

            echo 'Building...'
            cmake --build build-docker --parallel

            echo 'Testing...'
            export ASAN_OPTIONS='abort_on_error=1:halt_on_error=1:print_stats=1'
            export UBSAN_OPTIONS='abort_on_error=1:halt_on_error=1:print_stacktrace=1'

            # Run unit tests if they exist
            if [[ -f build-docker/bin/METAGRAPH_unit_tests ]]; then
                ./build-docker/bin/mg_unit_tests
            fi

            # Run CLI test
            if [[ -f build-docker/bin/mg-cli ]]; then
                ./build-docker/bin/mg-cli version
            fi

            # Clean up
            rm -rf build-docker
        "; then
        print_status "✅ $image ($build_type, $sanitizer) - PASSED"
        return 0
    else
        print_error "❌ $image ($build_type, $sanitizer) - FAILED"
        return 1
    fi
}

# Main execution
main() {
    print_status "Starting Meta-Graph Docker build matrix"
    print_status "Testing ${#IMAGES[@]} images with ${#BUILD_TYPES[@]} build types and ${#SANITIZER_CONFIGS[@]} sanitizer configs"

    local total_tests=0
    local passed_tests=0
    local failed_tests=0

    for image in "${IMAGES[@]}"; do
        for build_type in "${BUILD_TYPES[@]}"; do
            for sanitizer in "${SANITIZER_CONFIGS[@]}"; do
                # Skip sanitizers in Release builds for faster testing
                if [[ "$build_type" == "Release" && "$sanitizer" != "OFF" ]]; then
                    continue
                fi

                total_tests=$((total_tests + 1))

                if test_config "$image" "$build_type" "$sanitizer"; then
                    passed_tests=$((passed_tests + 1))
                else
                    failed_tests=$((failed_tests + 1))
                fi

                echo # Add spacing between tests
            done
        done
    done

    # Summary
    echo "========================================"
    print_status "Build Matrix Summary"
    echo "Total tests: $total_tests"
    echo -e "Passed: ${GREEN}$passed_tests${NC}"
    echo -e "Failed: ${RED}$failed_tests${NC}"

    if [[ $failed_tests -eq 0 ]]; then
        print_status "🎉 All tests passed!"
        exit 0
    else
        print_error "💥 $failed_tests tests failed"
        exit 1
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
