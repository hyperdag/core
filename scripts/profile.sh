#!/bin/sh
# Advanced performance profiling script for MetaGraph

set -eu

# Load shared shell library (tools auto-configured)
PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
. "$PROJECT_ROOT/scripts/mg.sh"

print_header() {
    echo "==================================================="
    echo "🚀 MetaGraph Performance Profiling Suite"
    echo "==================================================="
}

# Check if required tools are available
check_dependencies() {
    deps="perf valgrind gprof time"
    missing=""

    for dep in $deps; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            if [ -z "$missing" ]; then
                missing="$dep"
            else
                missing="$missing $dep"
            fi
        fi
    done

    if [ -n "$missing" ]; then
        mg_yellow "[WARN] Missing dependencies: $missing"
        echo "[INFO] Install with: sudo apt-get install linux-perf valgrind gprof time"
        echo "[INFO] On macOS: brew install valgrind (perf not available)"
    fi
}

# Build optimized version for profiling
build_for_profiling() {
    echo "[INFO] Building optimized version with profiling symbols..."

    cmake -B build-profile \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DMETAGRAPH_PGO=ON \
        -DCMAKE_C_FLAGS="-pg -fno-omit-frame-pointer" \
        -DCMAKE_EXE_LINKER_FLAGS="-pg"

    cmake --build build-profile --parallel
}

# Performance profiling with perf (Linux only)
profile_with_perf() {
    # Portable OS detection
    if [ "$(uname -s)" != "Linux" ]; then
        mg_yellow "[WARN] perf profiling is only available on Linux"
        return
    fi

    echo "[INFO] 🔥 Running perf profiling..."

    # Record performance data
    perf record -g --call-graph=dwarf -o perf.data \
        ./build-profile/bin/mg_benchmarks

    # Generate reports
    perf report -i perf.data --stdio > perf-report.txt
    perf annotate -i perf.data --stdio > perf-annotate.txt

    # Generate flame graph if available
    if command -v flamegraph >/dev/null 2>&1; then
        perf script -i perf.data | flamegraph > flamegraph.svg
        echo "[INFO] Flame graph generated: flamegraph.svg"
    fi

    echo "[INFO] Perf reports generated: perf-report.txt, perf-annotate.txt"
}

# Memory profiling with Valgrind
profile_with_valgrind() {
    echo "[INFO] 🧠 Running Valgrind memory profiling..."

    # Memcheck for memory errors
    valgrind --tool=memcheck \
        --leak-check=full \
        --show-leak-kinds=all \
        --track-origins=yes \
        --verbose \
        --log-file=valgrind-memcheck.log \
        ./build-profile/bin/mg_benchmarks

    # Cachegrind for cache profiling
    valgrind --tool=cachegrind \
        --cache-sim=yes \
        --branch-sim=yes \
        --cachegrind-out-file=cachegrind.out \
        ./build-profile/bin/mg_benchmarks

    # Callgrind for call graph profiling
    valgrind --tool=callgrind \
        --callgrind-out-file=callgrind.out \
        ./build-profile/bin/mg_benchmarks

    echo "[INFO] Valgrind reports generated: valgrind-memcheck.log, cachegrind.out, callgrind.out"
}

# CPU profiling with gprof
profile_with_gprof() {
    echo "[INFO] 📊 Running gprof CPU profiling..."

    # Run the program to generate gmon.out
    ./build-profile/bin/mg_benchmarks

    # Generate profile report
    gprof ./build-profile/bin/mg_benchmarks gmon.out > gprof-report.txt

    echo "[INFO] gprof report generated: gprof-report.txt"
}

# Benchmark timing analysis
benchmark_timing() {
    echo "[INFO] ⏱️  Running detailed timing analysis..."

    # Multiple runs for statistical significance
    runs=10
    times_file="timing-results.tmp"

    # Clear the temporary file
    true > "$times_file"

    i=1
    while [ $i -le $runs ]; do
        echo "[INFO] Run $i/$runs..."
        time_result=$(/usr/bin/time -f "%e %U %S %M" ./build-profile/bin/mg_benchmarks 2>&1 >/dev/null | tail -1)
        printf '%s\n' "$time_result" >> "$times_file"
        i=$((i + 1))
    done

    # Calculate statistics
    echo "Timing Results (Real User System MaxRSS):" > timing-analysis.txt
    cat "$times_file" >> timing-analysis.txt

    # Calculate averages (basic awk processing)
    awk '{
        real+=$1; user+=$2; sys+=$3; mem+=$4; count++
    } END {
        printf "Averages over %d runs:\n", count
        printf "Real: %.3fs, User: %.3fs, System: %.3fs, Peak Memory: %.0fKB\n",
               real/count, user/count, sys/count, mem/count
    }' "$times_file" >> timing-analysis.txt

    # Clean up temporary file
    rm -f "$times_file"

    echo "[INFO] Timing analysis saved to: timing-analysis.txt"
}

# Profile-Guided Optimization
run_pgo() {
    echo "[INFO] 🎯 Running Profile-Guided Optimization..."

    # Phase 1: Generate profile data
    cmake -B build-pgo-gen \
        -DCMAKE_BUILD_TYPE=Release \
        -DMETAGRAPH_PGO=ON \
        -DCMAKE_C_FLAGS="-fprofile-generate" \
        -DCMAKE_EXE_LINKER_FLAGS="-fprofile-generate"

    cmake --build build-pgo-gen --parallel

    # Run benchmarks to generate profile data
    ./build-pgo-gen/bin/mg_benchmarks

    # Phase 2: Use profile data for optimization
    cmake -B build-pgo-use \
        -DCMAKE_BUILD_TYPE=Release \
        -DMETAGRAPH_PGO_USE=ON \
        -DCMAKE_C_FLAGS="-fprofile-use" \
        -DCMAKE_EXE_LINKER_FLAGS="-fprofile-use"

    cmake --build build-pgo-use --parallel

    # Compare performance
    echo "[INFO] Comparing PGO vs non-PGO performance..."
    {
        echo "=== Without PGO ==="
        ./build-profile/bin/mg_benchmarks
        echo "=== With PGO ==="
        ./build-pgo-use/bin/mg_benchmarks
    } > pgo-comparison.txt

    echo "[INFO] PGO comparison saved to: pgo-comparison.txt"
}

# Fuzzing with address sanitizer
run_fuzzing() {
    echo "[INFO] 🐛 Running fuzzing tests..."

    # Build fuzzing targets
    cmake -B build-fuzz \
        -DCMAKE_BUILD_TYPE=Debug \
        -DMETAGRAPH_FUZZING=ON \
        -DCMAKE_C_COMPILER=clang

    cmake --build build-fuzz --parallel

    # Create corpus directories
    mkdir -p fuzz-corpus/graph fuzz-corpus/node-ops

    # Run fuzzing for a short time (production would run longer)
    timeout 60 ./build-fuzz/tests/fuzz/fuzz_graph -max_total_time=60 fuzz-corpus/graph/ || true
    timeout 60 ./build-fuzz/tests/fuzz/fuzz_node_ops -max_total_time=60 fuzz-corpus/node-ops/ || true

    echo "[INFO] Fuzzing completed. Corpus saved in fuzz-corpus/"
}

# Main execution
main() {
    print_header

    profile_type="${1:-all}"

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
            if [ "$(uname -s)" = "Linux" ]; then
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

    echo "[INFO] ✅ Profiling complete! Check generated reports."
}

# Run if called directly
case "$0" in
    */profile.sh|profile.sh)
        main "$@"
        ;;
esac
