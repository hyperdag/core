# Benchmarks CMakeLists.txt

# Simple benchmark executable (can be enhanced with Google Benchmark later)
add_executable(hyperdag_benchmarks
    bench_graph.c
)

target_link_libraries(hyperdag_benchmarks
    PRIVATE hyperdag
)

target_include_directories(hyperdag_benchmarks
    PRIVATE
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_SOURCE_DIR}/src/internal
)

# Optimization flags for benchmarks
target_compile_options(hyperdag_benchmarks
    PRIVATE
        -O3
        -DNDEBUG
)

# Add benchmark target
add_custom_target(benchmark
    COMMAND hyperdag_benchmarks
    DEPENDS hyperdag_benchmarks
    COMMENT "Running HyperDAG benchmarks"
)