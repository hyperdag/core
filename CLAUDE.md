# HyperDAG Development Guide

## Project Status

**Architecture**: Complete (12 features specified)  
**Implementation**: Ready to begin (foundation layer)  
**Quality Standard**: Extreme - Zero tolerance for shortcuts  

## Build System & Infrastructure

- Modern CMake 3.28+ configuration with C23 compliance
- Comprehensive compiler flag optimization for GCC/Clang/MSVC
- Multi-platform sanitizer integration (ASAN, UBSAN, TSAN, MSAN, HWASan)
- Static analysis tool integration (clang-tidy, Cppcheck, PVS-Studio)

## Security & Quality Assurance

- SLSA v1.1 cryptographic provenance implementation
- Comprehensive security policy and vulnerability reporting procedures
- Advanced fuzzing infrastructure with libFuzzer
- Memory safety validation with multiple sanitizers

## Developer Experience

- VSCode integration with full C23 IntelliSense support
- GitHub Codespaces and DevContainer configuration
- Pre-commit hooks with automated quality enforcement
- Docker-based build matrix for comprehensive compiler testing

## Testing & Performance

- Criterion testing framework integration
- Performance benchmarking and regression detection
- Continuous fuzzing with coverage analysis
- Profile-guided optimization automation

# Code Quality Standards - EXTREME LEVEL

## 🚫 ABSOLUTELY NO EXCEPTIONS

### Zero Tolerance Policy
- **NO SKIPPING TESTS**: Every function must have comprehensive unit tests
- **NO DISABLING LINTER CHECKS**: All clang-tidy warnings must be addressed
- **NO BYPASSING GIT HOOKS**: Pre-commit hooks are mandatory gatekeepers
- **NO UNDEFINED BEHAVIOR**: UBSan must pass completely clean
- **NO MEMORY ERRORS**: ASan/MSan violations are unacceptable
- **NO RACE CONDITIONS**: TSan must validate all concurrent code

### Git Hook Enforcement
```bash
# These hooks are MANDATORY and cannot be bypassed
.git/hooks/pre-commit     # Format, lint, basic tests
.git/hooks/pre-push       # Full test suite, static analysis
.git/hooks/commit-msg     # Conventional commit format

# Attempting to bypass with --no-verify is a project violation
```

## 🔥 C23 Excellence Standards

### Modern C23 Features - USE THEM
```c
// ✅ C23 auto keyword for type inference
auto result = hyperdag_graph_create(&config, &graph);

// ✅ typeof operator for generic programming
#define GENERIC_POOL_ALLOC(pool, type) \
    ((type*)hyperdag_pool_alloc(pool, sizeof(type), _Alignof(type)))

// ✅ [[attributes]] for compiler optimization hints
[[nodiscard]] hyperdag_result_t hyperdag_graph_add_node(
    hyperdag_graph_t* restrict graph,
    const hyperdag_node_metadata_t* restrict metadata,
    hyperdag_node_t** restrict out_node
);

// ✅ Designated initializers for clear configuration
hyperdag_pool_config_t pool_config = {
    .type = HYPERDAG_POOL_TYPE_OBJECT,
    .initial_size = 64 * 1024,
    .max_size = 16 * 1024 * 1024,
    .alignment = _Alignof(hyperdag_node_t),
    .allow_growth = true
};

// ✅ _BitInt for precise bit widths
typedef _BitInt(128) hyperdag_id_t;

// ✅ constexpr for compile-time constants
constexpr size_t HYPERDAG_MAX_NODES = 1ULL << 32;

// ✅ _Static_assert for compile-time validation
_Static_assert(sizeof(hyperdag_id_t) == 16, 
    "Asset ID must be exactly 128 bits");

// ✅ Anonymous structs and unions for clean APIs
typedef struct {
    hyperdag_id_t id;
    union {
        struct { uint64_t high, low; };
        uint8_t bytes[16];
    };
} hyperdag_content_hash_t;
```

### Memory Safety Excellence
```c
// ✅ restrict qualifiers for optimization and safety
void hyperdag_copy_nodes(
    const hyperdag_node_t* restrict source,
    hyperdag_node_t* restrict dest,
    size_t count
) {
    // Compiler can optimize knowing no aliasing
    for (size_t i = 0; i < count; ++i) {
        dest[i] = source[i];
    }
}

// ✅ _Alignas for optimal memory layout
typedef struct alignas(_Alignof(max_align_t)) {
    _Atomic(uint64_t) reference_count;
    hyperdag_id_t id;
    // Perfectly aligned for atomic operations
} hyperdag_node_header_t;

// ✅ Flexible array members for variable-size structures
typedef struct {
    size_t node_count;
    float weight;
    hyperdag_id_t nodes[];  // C99 flexible array member
} hyperdag_hyperedge_t;

// ✅ Proper cleanup with __attribute__((cleanup))
__attribute__((cleanup(hyperdag_graph_cleanup)))
hyperdag_graph_t* graph = NULL;
```

### Atomic Programming Excellence
```c
// ✅ C11 atomics with explicit memory ordering
#include <stdatomic.h>

typedef struct {
    _Atomic(uint64_t) node_count;
    _Atomic(hyperdag_node_t*) head_node;
    _Atomic(bool) is_valid;
} hyperdag_concurrent_graph_t;

// ✅ Lock-free programming with proper memory ordering
bool hyperdag_lockfree_insert_node(
    hyperdag_concurrent_graph_t* graph,
    hyperdag_node_t* new_node
) {
    hyperdag_node_t* expected = atomic_load_explicit(
        &graph->head_node, memory_order_acquire
    );
    
    do {
        new_node->next = expected;
    } while (!atomic_compare_exchange_weak_explicit(
        &graph->head_node, &expected, new_node,
        memory_order_release, memory_order_relaxed
    ));
    
    atomic_fetch_add_explicit(&graph->node_count, 1, memory_order_relaxed);
    return true;
}
```

## 🧪 Testing Excellence - NO COMPROMISES

### Test Coverage Requirements
- **Unit Tests**: 100% line coverage, 95% branch coverage
- **Integration Tests**: All feature interactions validated
- **Stress Tests**: Memory pressure, high concurrency, edge cases
- **Fuzz Tests**: All input parsers, 24-hour campaigns minimum
- **Platform Tests**: Windows/Linux/macOS matrix validation

### Test Structure Standards
```c
// ✅ Test naming convention: test_[module]_[function]_[scenario]
void test_hyperdag_graph_add_node_success(void) {
    // Arrange
    hyperdag_graph_config_t config = {
        .initial_node_capacity = 16,
        .enable_concurrent_access = false
    };
    hyperdag_graph_t* graph = NULL;
    cr_assert_eq(hyperdag_graph_create(&config, &graph), HYPERDAG_SUCCESS);
    
    // Act
    hyperdag_node_metadata_t metadata = {
        .name = "test_asset.png",
        .type = HYPERDAG_ASSET_TYPE_TEXTURE,
        .data_size = 4096
    };
    hyperdag_node_t* node = NULL;
    hyperdag_result_t result = hyperdag_graph_add_node(graph, &metadata, &node);
    
    // Assert
    cr_assert_eq(result, HYPERDAG_SUCCESS);
    cr_assert_not_null(node);
    cr_assert_eq(hyperdag_graph_get_node_count(graph), 1);
    
    // Cleanup
    hyperdag_graph_destroy(graph);
}

// ✅ Property-based testing for edge cases
void test_hyperdag_graph_stress_many_nodes(void) {
    const size_t NODE_COUNT = 100000;
    
    hyperdag_graph_t* graph = create_test_graph();
    
    // Add many nodes and verify graph remains consistent
    for (size_t i = 0; i < NODE_COUNT; ++i) {
        add_random_node(graph);
        if (i % 1000 == 0) {
            cr_assert(validate_graph_invariants(graph));
        }
    }
    
    cr_assert_eq(hyperdag_graph_get_node_count(graph), NODE_COUNT);
    hyperdag_graph_destroy(graph);
}
```

## 🐚 Shell Script Excellence - POSIX Portability

### MANDATORY Shell Script Standards
```bash
# ✅ Always use POSIX-compliant shebang
#!/bin/sh

# ✅ POSIX-compliant error handling
set -eu  # NOT set -euo pipefail (pipefail is bash-specific)

# ✅ Use pushd/popd for ALL directory changes
SCRIPT_DIR="$(pushd "$(dirname "$0")" >/dev/null && pwd && popd >/dev/null)"
PROJECT_ROOT="$(pushd "$SCRIPT_DIR/.." >/dev/null && pwd && popd >/dev/null)"

# ✅ Directory navigation with proper cleanup
pushd "$PROJECT_ROOT" >/dev/null
# ... do work in project root ...
popd >/dev/null  # ALWAYS match pushd with popd

# ✅ POSIX-compliant conditionals
if [ "$variable" = "value" ]; then  # NOT [[ ]]
    echo "POSIX compliant"
fi

# ✅ POSIX-compliant loops and case statements
for file in *.c; do
    case "$file" in
        *.h) echo "Header: $file" ;;
        *.c) echo "Source: $file" ;;
        *) echo "Other: $file" ;;
    esac
done

# ✅ Portable command detection
if command -v gcc >/dev/null 2>&1; then
    echo "GCC found"
fi

# ❌ AVOID bashisms
# Don't use: [[ ]], arrays, mapfile, ${BASH_SOURCE[0]}, &>/dev/null
# Don't use: set -o pipefail, $'strings', <()
```

### Directory Management Excellence
```bash
# ✅ ALWAYS use pushd/popd pattern - NEVER use cd
# This ensures proper cleanup even on script exit

# Basic pattern
pushd "$TARGET_DIR" >/dev/null
# ... work in target directory ...
popd >/dev/null

# Error handling pattern
pushd "$TARGET_DIR" >/dev/null
if ! some_command; then
    echo "Error occurred"
    popd >/dev/null  # CRITICAL: cleanup before exit
    exit 1
fi
popd >/dev/null

# Complex pattern with multiple directories
pushd "$PROJECT_ROOT" >/dev/null

if [ -d "build" ]; then
    pushd "build" >/dev/null
    make all
    popd >/dev/null
fi

# Final cleanup
popd >/dev/null
```

### Cross-Platform Compatibility
```bash
# ✅ Portable temp file creation
temp_file="/tmp/hyperdag_$$"  # Use $$ for unique PID

# ✅ Portable file listing (avoid mapfile)
find . -name "*.c" > "$temp_file"
while IFS= read -r file; do
    [ -z "$file" ] && continue
    process_file "$file"
done < "$temp_file"
rm -f "$temp_file"

# ✅ Platform detection
case "$(uname -s)" in
    Linux*)   PLATFORM=linux ;;
    Darwin*)  PLATFORM=macos ;;
    MINGW*)   PLATFORM=windows ;;
    *)        PLATFORM=unknown ;;
esac

# ✅ Tool detection across platforms
find_tool() {
    for path in tool /usr/bin/tool /usr/local/bin/tool /opt/homebrew/bin/tool; do
        if command -v "$path" >/dev/null 2>&1; then
            echo "$path"
            return 0
        fi
    done
    echo "Tool not found" >&2
    return 1
}
```

### Why POSIX Portability Matters
- **Linux**: All distributions support POSIX sh
- **macOS**: Works with both bash and zsh (default on modern macOS)
- **Windows WSL2**: Ensures compatibility across different WSL distributions
- **CI/CD**: Works in minimal Docker containers with only `/bin/sh`
- **DevContainers**: Portable across different base images

### Enforcement
- ALL shell scripts MUST pass `shellcheck` with POSIX compliance
- Scripts MUST work on Ubuntu, macOS, and Windows WSL2
- Pre-commit hooks verify POSIX compliance
- No bashisms allowed - zero tolerance policy

## 🔧 Third-Party Integration Excellence

### BLAKE3 Integration Standards
```c
// ✅ Streaming hash computation for large bundles
typedef struct {
    blake3_hasher hasher;
    bool initialized;
    size_t bytes_processed;
} hyperdag_blake3_context_t;

// ✅ RAII pattern for automatic cleanup
__attribute__((cleanup(blake3_cleanup)))
hyperdag_blake3_context_t hash_ctx = {0};

hyperdag_result_t hyperdag_compute_bundle_hash(
    const void* data, size_t size, uint8_t hash_out[BLAKE3_OUT_LEN]
) {
    blake3_hasher hasher;
    blake3_hasher_init(&hasher);
    
    // Stream processing for memory efficiency
    const uint8_t* bytes = (const uint8_t*)data;
    const size_t CHUNK_SIZE = 64 * 1024;
    
    for (size_t offset = 0; offset < size; offset += CHUNK_SIZE) {
        size_t chunk_size = (size - offset < CHUNK_SIZE) ? 
            (size - offset) : CHUNK_SIZE;
        blake3_hasher_update(&hasher, bytes + offset, chunk_size);
    }
    
    blake3_hasher_finalize(&hasher, hash_out, BLAKE3_OUT_LEN);
    return HYPERDAG_SUCCESS;
}
```

### mimalloc Integration Standards
```c
// ✅ Thread-local heaps for isolation
thread_local mi_heap_t* tl_graph_heap = NULL;

void* hyperdag_graph_alloc(size_t size) {
    if (!tl_graph_heap) {
        tl_graph_heap = mi_heap_new();
    }
    return mi_heap_malloc(tl_graph_heap, size);
}

// ✅ Arena allocation on top of mimalloc
typedef struct {
    mi_heap_t* heap;
    uint8_t* arena_base;
    size_t arena_size;
    _Atomic(size_t) arena_offset;
} hyperdag_arena_t;

void* hyperdag_arena_alloc_aligned(
    hyperdag_arena_t* arena, size_t size, size_t alignment
) {
    size_t current_offset = atomic_load(&arena->arena_offset);
    size_t aligned_offset = (current_offset + alignment - 1) & ~(alignment - 1);
    size_t new_offset = aligned_offset + size;
    
    if (new_offset > arena->arena_size) {
        return NULL;  // Arena exhausted
    }
    
    // Atomic compare-and-swap for thread safety
    if (atomic_compare_exchange_strong(&arena->arena_offset, 
                                       &current_offset, new_offset)) {
        return arena->arena_base + aligned_offset;
    }
    
    // Retry if CAS failed
    return hyperdag_arena_alloc_aligned(arena, size, alignment);
}
```

### uthash Integration Standards
```c
// ✅ Type-safe hash table macros
#define HYPERDAG_DECLARE_HASH_TYPE(name, key_type, value_type) \
    typedef struct name##_entry { \
        key_type key; \
        value_type value; \
        UT_hash_handle hh; \
    } name##_entry_t; \
    \
    typedef struct { \
        name##_entry_t* entries; \
        size_t count; \
    } name##_table_t;

HYPERDAG_DECLARE_HASH_TYPE(node_table, hyperdag_id_t, hyperdag_node_t*)

// ✅ Memory-safe hash operations
hyperdag_result_t node_table_insert(
    node_table_t* table, 
    hyperdag_id_t key, 
    hyperdag_node_t* value
) {
    node_table_entry_t* entry = hyperdag_graph_alloc(sizeof(*entry));
    if (!entry) return HYPERDAG_ERROR_OUT_OF_MEMORY;
    
    entry->key = key;
    entry->value = value;
    
    HASH_ADD(hh, table->entries, key, sizeof(key), entry);
    table->count++;
    
    return HYPERDAG_SUCCESS;
}
```

## 📊 Performance Engineering Standards

### Micro-Benchmarking Requirements
```c
// ✅ Every performance-critical function must have benchmarks
CRITERION_BENCHMARK(bench_node_lookup) {
    hyperdag_graph_t* graph = create_benchmark_graph(100000);
    hyperdag_id_t random_ids[1000];
    generate_random_ids(random_ids, 1000);
    
    criterion_start_timer();
    
    for (int i = 0; i < 1000; ++i) {
        hyperdag_node_t* node;
        hyperdag_graph_find_node(graph, random_ids[i], &node);
    }
    
    criterion_stop_timer();
    hyperdag_graph_destroy(graph);
}
```

### Cache Optimization Requirements
```c
// ✅ Data structure layout optimized for cache lines
typedef struct alignas(64) {  // Cache line aligned
    _Atomic(uint64_t) reference_count;  // Hot data first
    hyperdag_id_t id;
    uint32_t type;
    uint32_t flags;
    // Cold data after hot data
    const char* name;
    void* user_data;
} hyperdag_node_t;

// ✅ Memory prefetching for traversal
void hyperdag_prefetch_next_nodes(hyperdag_node_t** nodes, size_t count) {
    for (size_t i = 0; i < count; ++i) {
        __builtin_prefetch(nodes[i], 0, 3);  // Prefetch for read, high temporal locality
    }
}
```

## 🛡️ Error Handling Excellence

### Result Type Pattern
```c
// ✅ Comprehensive error handling with context
typedef enum {
    HYPERDAG_SUCCESS = 0,
    HYPERDAG_ERROR_OUT_OF_MEMORY,
    HYPERDAG_ERROR_INVALID_ARGUMENT,
    HYPERDAG_ERROR_NODE_NOT_FOUND,
    HYPERDAG_ERROR_CIRCULAR_DEPENDENCY,
    HYPERDAG_ERROR_IO_FAILURE,
    HYPERDAG_ERROR_CORRUPTION_DETECTED,
    HYPERDAG_ERROR_CONCURRENT_MODIFICATION
} hyperdag_result_t;

// ✅ Error context for debugging
typedef struct {
    hyperdag_result_t code;
    const char* file;
    int line;
    const char* function;
    char message[256];
} hyperdag_error_context_t;

#define HYPERDAG_RETURN_ERROR(code, ...) \
    return hyperdag_set_error_context((code), __FILE__, __LINE__, __func__, __VA_ARGS__)
```

## 🔍 Static Analysis Excellence

### clang-tidy Configuration
```yaml
# .clang-tidy - NO EXCEPTIONS TO THESE RULES
Checks: '
  *,
  -altera-*,
  -fuchsia-*,
  -google-readability-todo,
  -hicpp-signed-bitwise,
  -modernize-use-trailing-return-type
'
WarningsAsErrors: '*'
HeaderFilterRegex: '(include|src)/.*\.(h|hpp)$'
```

### Required Compiler Flags
```cmake
# CMakeLists.txt - MANDATORY compiler flags
target_compile_options(hyperdag PRIVATE
    # Maximum warning level
    $<$<COMPILE_LANG_AND_ID:C,GNU,Clang>:-Wall -Wextra -Wpedantic -Werror>
    $<$<COMPILE_LANG_AND_ID:C,MSVC>:/W4 /WX>
    
    # C23 specific warnings
    $<$<COMPILE_LANG_AND_ID:C,GNU,Clang>:-Wc23-extensions>
    
    # Security hardening
    $<$<COMPILE_LANG_AND_ID:C,GNU,Clang>:-D_FORTIFY_SOURCE=2>
    $<$<COMPILE_LANG_AND_ID:C,GNU,Clang>:-fstack-protector-strong>
    
    # Performance optimization
    $<$<CONFIG:Release>:-O3 -DNDEBUG -flto>
    $<$<CONFIG:Debug>:-O0 -g3 -fsanitize=address,undefined>
)
```

## 🚀 Continuous Integration Excellence

### Pre-commit Hook Standards
```bash
#!/bin/bash
# .git/hooks/pre-commit - MANDATORY QUALITY GATE

set -euo pipefail

# Format all code with clang-format
echo "🔧 Formatting code..."
find src include -name "*.c" -o -name "*.h" | xargs clang-format -i

# Run static analysis
echo "🔍 Running static analysis..."
cmake --build build --target clang-tidy-check

# Run fast unit tests
echo "🧪 Running unit tests..."
ctest --test-dir build --parallel 4 --timeout 10 --label-regex "unit"

# Verify no memory leaks in test suite
echo "🛡️  Checking for memory leaks..."
ASAN_OPTIONS="abort_on_error=1" ctest --test-dir build --label-regex "unit"

echo "✅ All quality checks passed!"
```

### Documentation Standards
```c
/**
 * @brief Adds a node to the hypergraph with comprehensive validation
 * 
 * This function performs the following operations:
 * 1. Validates input parameters for correctness
 * 2. Checks for duplicate node IDs
 * 3. Allocates memory using the graph's memory pool
 * 4. Updates internal data structures atomically
 * 5. Maintains graph invariants
 * 
 * @param[in] graph The target hypergraph (must be non-NULL)
 * @param[in] metadata Node metadata including ID and type (must be non-NULL)
 * @param[out] out_node Pointer to store the created node (may be NULL)
 * 
 * @return HYPERDAG_SUCCESS on success
 * @return HYPERDAG_ERROR_INVALID_ARGUMENT if parameters are invalid
 * @return HYPERDAG_ERROR_OUT_OF_MEMORY if allocation fails
 * @return HYPERDAG_ERROR_NODE_EXISTS if node ID already exists
 * 
 * @pre graph must be initialized via hyperdag_graph_create()
 * @pre metadata->id must be unique within the graph
 * @post Graph node count increases by 1 on success
 * @post Graph remains in valid state on failure
 * 
 * @thread_safety This function is thread-safe when called concurrently
 * @performance O(1) average case, O(n) worst case due to hash collisions
 * 
 * @example
 * @code{.c}
 * hyperdag_node_metadata_t metadata = {
 *     .id = compute_asset_id("texture.png"),
 *     .name = "texture.png",
 *     .type = HYPERDAG_ASSET_TYPE_TEXTURE
 * };
 * 
 * hyperdag_node_t* node;
 * hyperdag_result_t result = hyperdag_graph_add_node(graph, &metadata, &node);
 * if (result != HYPERDAG_SUCCESS) {
 *     handle_error(result);
 * }
 * @endcode
 */
[[nodiscard]] hyperdag_result_t hyperdag_graph_add_node(
    hyperdag_graph_t* restrict graph,
    const hyperdag_node_metadata_t* restrict metadata,
    hyperdag_node_t** restrict out_node
);
```

---

This Code Quality section establishes HyperDAG as having the most rigorous development standards possible - worthy of the epic development environment we've built!

# Development Workflow

## Automated Development Environment Setup

### Quick Start (Recommended)

```bash
# Complete development environment setup
./scripts/setup-dev-env.sh

# Verify existing environment
./scripts/setup-dev-env.sh --verify

# Check what tools are missing
./scripts/setup-dev-env.sh --dry-run
```

The setup script provides:
- **Automated Tool Installation**: cmake, clang-format, clang-tidy, gitleaks, etc.
- **Bash-Based Git Hooks**: Quality enforcement with proper failure behavior
- **POSIX Compliance**: Works on Linux/macOS/Windows WSL2
- **Interactive Configuration**: Git settings with Y/n prompts
- **"Silence is Golden"**: Only outputs problems/warnings
- **Security Hardening**: Never auto-installs in non-interactive mode

### Environment Options

```bash
# Setup specific components
./scripts/setup-dev-env.sh --deps-only      # Just install tools
./scripts/setup-dev-env.sh --git-only       # Just configure git + hooks
./scripts/setup-dev-env.sh --build-only     # Just setup build system
./scripts/setup-dev-env.sh --vscode-only    # Just configure VSCode

# Skip specific components  
./scripts/setup-dev-env.sh --skip-deps      # Skip tool installation
./scripts/setup-dev-env.sh --skip-vscode    # Skip VSCode setup (for containers)
```

### DevContainer Integration

```json
// .devcontainer/devcontainer.json automatically runs:
"postCreateCommand": "./scripts/setup-dev-env.sh --skip-vscode"
```

## Commands & Build Options

### Standard Build Commands

```bash
# Basic release build
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# Development build with all checks
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DHYPERDAG_DEV=ON -DHYPERDAG_SANITIZERS=ON

# Static analysis
cmake --build build --target static-analysis

# Performance profiling
./scripts/profile.sh all

# Security audit
./scripts/security-audit.sh
```

### Testing Commands

```bash
# Run all tests
ctest --test-dir build --output-on-failure

# Unit tests with sanitizers
ASAN_OPTIONS="abort_on_error=1" ./build/bin/hyperdag_unit_tests

# Fuzzing campaign
cmake -DHYPERDAG_FUZZING=ON -B build-fuzz
./build-fuzz/tests/fuzz/fuzz_graph -max_total_time=3600
```

### Docker Matrix Testing

```bash
# Test across all supported compilers
./docker/build-all.sh

# Individual compiler testing
docker run --rm -v $(pwd):/workspace gcc:15 \
  bash -c "cd /workspace && cmake -B build && cmake --build build"
```

## Integration with Third-Party Libraries

### Dependency Management
```cmake
# Third-party dependencies - see docs/3rd-party.md for detailed analysis
add_subdirectory(3rdparty/mimalloc)
add_subdirectory(3rdparty/blake3)

# Header-only libraries
target_include_directories(hyperdag PRIVATE 
    3rdparty/uthash/include
    3rdparty/tinycthread
)

# Platform abstraction
add_subdirectory(src/platform)
```

### Library Integration Guidelines
- **BLAKE3**: Use streaming API for large bundles, enable SIMD optimizations
- **mimalloc**: Thread-local heaps with custom arenas on top
- **uthash**: Type-safe macros with proper memory management integration
- **tinycthread**: Combined with compiler atomics for lock-free patterns

## Third-Party Pitfalls to Avoid

### BLAKE3 Gotchas
- **Thread Safety**: Hasher contexts are not thread-safe - use separate instances
- **Large Files**: Always use streaming API to avoid memory exhaustion
- **SIMD Flags**: Compile with `-mavx2` or `-msse4.1` for performance

### mimalloc Integration
- **Thread Isolation**: Use separate heaps for different subsystems
- **NUMA Binding**: Enable on multi-socket systems with `mi_option_set()`
- **Statistics**: Monitor with `mi_heap_get_stats()` for memory pressure

### uthash Best Practices
- **Memory Integration**: Replace default malloc/free with our pool allocators
- **Iteration Safety**: Use `HASH_ITER` for concurrent-safe iteration
- **Custom Hash**: Consider custom hash functions for asset ID patterns

## AI Development Notes

### Reproducibility

This development approach demonstrates:

- **Hypergraph Foundation**: Mathematical structure for complex asset dependencies
- **C23 Modernization**: Cutting-edge language features with broad compatibility
- **Third-Party Excellence**: Careful library selection with detailed integration guides
- **Quality Excellence**: Extreme standards with zero tolerance for shortcuts
- **Performance Focus**: Cache-aware, lock-free, NUMA-optimized architecture

### Implementation Strategy

1. **Foundation First**: Platform abstraction and error handling (F.010, F.011)
2. **Core Data**: Hypergraph structures and memory management (F.001, F.009)
3. **I/O Systems**: Binary format and memory mapping (F.002, F.003, F.004)
4. **Algorithms**: Traversal and dependency resolution (F.005, F.006)
5. **Concurrency**: Thread-safe access and lock-free optimization (F.008)
6. **Builder**: Asset processing and bundle creation (F.012)

# important-instruction-reminders

**CRITICAL**: The following reminders MUST be followed without exception:

## Code Standards - NO SHORTCUTS
- Do what has been asked; nothing more, nothing less
- NEVER create files unless they're absolutely necessary for achieving your goal
- ALWAYS prefer editing an existing file to creating a new one
- NEVER proactively create documentation files (*.md) or README files unless explicitly requested
- ABSOLUTELY NO SKIPPING TESTS OR DISABLING LINTER CHECKS OR GIT HOOKS
- Take advantage of C23 language enhancements whenever possible

## Quality Gates - MANDATORY
- **100% Test Coverage**: Every function must have comprehensive unit tests
- **Zero Warnings**: All clang-tidy warnings must be addressed, never disabled
- **Memory Safety**: ASan/MSan/UBSan must pass completely clean
- **Thread Safety**: TSan must validate all concurrent code
- **Static Analysis**: PVS-Studio and Cppcheck must pass without exceptions

## Third-Party Integration Excellence
- Follow integration guides in docs/3rd-party.md exactly
- Use BLAKE3 streaming API for all hash operations
- Implement mimalloc with custom arenas for specialized allocation patterns
- Use uthash with type-safe macros and proper memory integration
- Combine tinycthread with compiler atomics for lock-free performance

## Performance Standards
- **O(1) Lookups**: Hash-based node access required
- **Cache Optimization**: 64-byte alignment for hot data structures
- **NUMA Awareness**: Memory binding for multi-socket systems
- **Lock-Free Reads**: Atomic operations for high-frequency access
- **Streaming I/O**: Platform-specific optimizations (DirectStorage, io_uring)

## Documentation Excellence
- Every public function requires comprehensive Doxygen documentation
- Include @pre, @post, @thread_safety, @performance annotations
- Provide complete code examples in documentation
- Document memory ownership and lifetime expectations
- Explain error conditions and recovery strategies

## Contact

For questions about the AI-assisted development process:

- **Email**: james@flyingrobots.dev
- **Project Issues**: GitHub Issues for technical questions
- **AI Development**: Reference this CLAUDE.md for context
- **Security Reports**: Use encrypted communication for vulnerabilities

---

*This file documents the AI-assisted development process for HyperDAG with emphasis on extreme quality standards and modern C23 practices. Every guideline is mandatory and non-negotiable.*
