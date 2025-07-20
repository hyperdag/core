#!/bin/bash
# Advanced performance profiling script for HyperDAG

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}🚀 HyperDAG Performance Profiling Suite${NC}"
    echo -e "${BLUE}===================================================${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are available
check_dependencies() {
    local deps=("perf" "valgrind" "gprof" "time")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_warning "Missing dependencies: ${missing[*]}"
        print_status "Install with: sudo apt-get install linux-perf valgrind gprof time"
        print_status "On macOS: brew install valgrind (perf not available)"
    fi
}

# Build optimized version for profiling
build_for_profiling() {
    print_status "Building optimized version with profiling symbols..."
    
    cmake -B build-profile \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DHYPERDAG_PGO=ON \
        -DCMAKE_C_FLAGS="-pg -fno-omit-frame-pointer" \
        -DCMAKE_EXE_LINKER_FLAGS="-pg"
        
    cmake --build build-profile --parallel
}

# Performance profiling with perf (Linux only)
profile_with_perf() {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_warning "perf profiling is only available on Linux"
        return
    fi
    
    print_status "🔥 Running perf profiling..."
    
    # Record performance data
    perf record -g --call-graph=dwarf -o perf.data \
        ./build-profile/bin/hyperdag_benchmarks
    
    # Generate reports
    perf report -i perf.data --stdio > perf-report.txt
    perf annotate -i perf.data --stdio > perf-annotate.txt
    
    # Generate flame graph if available
    if command -v flamegraph >/dev/null 2>&1; then
        perf script -i perf.data | flamegraph > flamegraph.svg
        print_status "Flame graph generated: flamegraph.svg"
    fi
    
    print_status "Perf reports generated: perf-report.txt, perf-annotate.txt"
}

# Memory profiling with Valgrind
profile_with_valgrind() {
    print_status "🧠 Running Valgrind memory profiling..."
    
    # Memcheck for memory errors
    valgrind --tool=memcheck \
        --leak-check=full \
        --show-leak-kinds=all \
        --track-origins=yes \
        --verbose \
        --log-file=valgrind-memcheck.log \
        ./build-profile/bin/hyperdag_benchmarks
    
    # Cachegrind for cache profiling
    valgrind --tool=cachegrind \
        --cache-sim=yes \
        --branch-sim=yes \
        --cachegrind-out-file=cachegrind.out \
        ./build-profile/bin/hyperdag_benchmarks
    
    # Callgrind for call graph profiling
    valgrind --tool=callgrind \
        --callgrind-out-file=callgrind.out \
        ./build-profile/bin/hyperdag_benchmarks
    
    print_status "Valgrind reports generated: valgrind-memcheck.log, cachegrind.out, callgrind.out"
}

# CPU profiling with gprof
profile_with_gprof() {
    print_status "📊 Running gprof CPU profiling..."
    
    # Run the program to generate gmon.out
    ./build-profile/bin/hyperdag_benchmarks
    
    # Generate profile report
    gprof ./build-profile/bin/hyperdag_benchmarks gmon.out > gprof-report.txt
    
    print_status "gprof report generated: gprof-report.txt"
}

# Benchmark timing analysis
benchmark_timing() {
    print_status "⏱️  Running detailed timing analysis..."
    
    # Multiple runs for statistical significance
    local runs=10
    local times=()
    
    for ((i=1; i<=runs; i++)); do
        print_status "Run $i/$runs..."
        local time_result
        time_result=$(/usr/bin/time -f "%e %U %S %M" ./build-profile/bin/hyperdag_benchmarks 2>&1 >/dev/null | tail -1)
        times+=("$time_result")
    done
    
    # Calculate statistics
    echo "Timing Results (Real User System MaxRSS):" > timing-analysis.txt
    printf '%s\n' "${times[@]}" >> timing-analysis.txt
    
    # Calculate averages (basic awk processing)
    awk '{
        real+=$1; user+=$2; sys+=$3; mem+=$4; count++
    } END {
        printf "Averages over %d runs:\n", count
        printf "Real: %.3fs, User: %.3fs, System: %.3fs, Peak Memory: %.0fKB\n", 
               real/count, user/count, sys/count, mem/count
    }' timing-analysis.txt >> timing-analysis.txt
    
    print_status "Timing analysis saved to: timing-analysis.txt"
}

# Profile-Guided Optimization
run_pgo() {
    print_status "🎯 Running Profile-Guided Optimization..."
    
    # Phase 1: Generate profile data
    cmake -B build-pgo-gen \
        -DCMAKE_BUILD_TYPE=Release \
        -DHYPERDAG_PGO=ON \
        -DCMAKE_C_FLAGS="-fprofile-generate" \
        -DCMAKE_EXE_LINKER_FLAGS="-fprofile-generate"
    
    cmake --build build-pgo-gen --parallel
    
    # Run benchmarks to generate profile data
    ./build-pgo-gen/bin/hyperdag_benchmarks
    
    # Phase 2: Use profile data for optimization
    cmake -B build-pgo-use \
        -DCMAKE_BUILD_TYPE=Release \
        -DHYPERDAG_PGO_USE=ON \
        -DCMAKE_C_FLAGS="-fprofile-use" \
        -DCMAKE_EXE_LINKER_FLAGS="-fprofile-use"
    
    cmake --build build-pgo-use --parallel
    
    # Compare performance
    print_status "Comparing PGO vs non-PGO performance..."
    echo "=== Without PGO ===" > pgo-comparison.txt
    ./build-profile/bin/hyperdag_benchmarks >> pgo-comparison.txt
    echo "=== With PGO ===" >> pgo-comparison.txt
    ./build-pgo-use/bin/hyperdag_benchmarks >> pgo-comparison.txt
    
    print_status "PGO comparison saved to: pgo-comparison.txt"
}

# Fuzzing with address sanitizer
run_fuzzing() {
    print_status "🐛 Running fuzzing tests..."
    
    # Build fuzzing targets
    cmake -B build-fuzz \
        -DCMAKE_BUILD_TYPE=Debug \
        -DHYPERDAG_FUZZING=ON \
        -DCMAKE_C_COMPILER=clang
    
    cmake --build build-fuzz --parallel
    
    # Create corpus directories
    mkdir -p fuzz-corpus/{graph,node-ops}
    
    # Run fuzzing for a short time (production would run longer)
    timeout 60 ./build-fuzz/tests/fuzz/fuzz_graph -max_total_time=60 fuzz-corpus/graph/ || true
    timeout 60 ./build-fuzz/tests/fuzz/fuzz_node_ops -max_total_time=60 fuzz-corpus/node-ops/ || true
    
    print_status "Fuzzing completed. Corpus saved in fuzz-corpus/"
}

# Main execution
main() {
    print_header
    
    local profile_type="${1:-all}"
    
    check_dependencies
    
    case "$profile_type" in
        "perf")
            build_for_profiling
            profile_with_perf
            ;;
        "valgrind")
            build_for_profiling
            profile_with_valgrind
            ;;
        "gprof")
            build_for_profiling
            profile_with_gprof
            ;;
        "timing")
            build_for_profiling
            benchmark_timing
            ;;
        "pgo")
            run_pgo
            ;;
        "fuzz")
            run_fuzzing
            ;;
        "all")
            build_for_profiling
            benchmark_timing
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                profile_with_perf
            fi
            profile_with_valgrind
            profile_with_gprof
            run_pgo
            run_fuzzing
            ;;
        *)
            echo "Usage: $0 [perf|valgrind|gprof|timing|pgo|fuzz|all]"
            exit 1
            ;;
    esac
    
    print_status "✅ Profiling complete! Check generated reports."
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi