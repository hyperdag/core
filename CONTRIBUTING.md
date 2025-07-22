# Contributing to MetaGraph

Welcome to MetaGraph! This guide covers everything you need to know to contribute to this high-performance C23 mg-core library.

## Quick Start

### 1. Development Environment Setup

**DevContainer (Recommended)**

The fastest way to get started is using the provided DevContainer configuration:

```bash
# Open in VS Code with DevContainer extension
code .
# Click "Reopen in Container" when prompted
```

The DevContainer provides:
- Pre-configured C23 development environment with Clang 18
- All required tools (CMake, clang-tidy, clang-format, etc.)
- Automatic setup via `./scripts/setup-dev-env.sh --skip-vscode`
- Optimized VS Code settings for C23 development

**Manual Setup**

```bash
# Automated setup (recommended)
./scripts/setup-dev-env.sh

# Or verify existing environment
./scripts/setup-dev-env.sh --verify
```

### 2. Build and Test

```bash
# Development build with all checks
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DMETAGRAPH_DEV=ON -DMETAGRAPH_SANITIZERS=ON
cmake --build build

# Run tests
ctest --test-dir build --output-on-failure
```

### 3. Quality Checks

```bash
# Format code
./scripts/run-clang-format.sh --fix

# Static analysis
cmake --build build --target static-analysis

# Security scan
./scripts/run-gitleaks.sh
```

## Code Quality Standards - EXTREME LEVEL

### 🚫 ABSOLUTELY NO EXCEPTIONS

#### Zero Tolerance Policy
- **NO SKIPPING TESTS**: Every function must have comprehensive unit tests
- **NO DISABLING LINTER CHECKS**: All clang-tidy warnings must be addressed
- **NO BYPASSING GIT HOOKS**: Pre-commit hooks are mandatory gatekeepers
- **NO UNDEFINED BEHAVIOR**: UBSan must pass completely clean
- **NO MEMORY ERRORS**: ASan/MSan violations are unacceptable
- **NO RACE CONDITIONS**: TSan must validate all concurrent code

#### Git Hook Enforcement
```bash
# These hooks are MANDATORY and cannot be bypassed
.git/hooks/pre-commit     # Format, lint, basic tests
.git/hooks/pre-push       # Full test suite, static analysis

# Attempting to bypass with --no-verify is a project violation
```

## 🔥 C23 Excellence Standards

### Modern C23 Features - USE THEM
```c
// ✅ C23 auto keyword for type inference
auto result = METAGRAPH_graph_create(&config, &graph);

// ✅ typeof operator for generic programming
#define GENERIC_POOL_ALLOC(pool, type) \
    ((type*)METAGRAPH_pool_alloc(pool, sizeof(type), _Alignof(type)))

// ✅ [[attributes]] for compiler optimization hints
[[nodiscard]] METAGRAPH_result_t METAGRAPH_graph_add_node(
    METAGRAPH_graph_t* restrict graph,
    const METAGRAPH_node_metadata_t* restrict metadata,
    METAGRAPH_node_t** restrict out_node
);

// ✅ Designated initializers for clear configuration
METAGRAPH_pool_config_t pool_config = {
    .type = METAGRAPH_POOL_TYPE_OBJECT,
    .initial_size = 64 * 1024,
    .max_size = 16 * 1024 * 1024,
    .alignment = _Alignof(METAGRAPH_node_t),
    .allow_growth = true
};

// ✅ _BitInt for precise bit widths
typedef _BitInt(128) METAGRAPH_id_t;

// ✅ constexpr for compile-time constants
constexpr size_t METAGRAPH_MAX_NODES = 1ULL << 32;

// ✅ _Static_assert for compile-time validation
_Static_assert(sizeof(METAGRAPH_id_t) == 16,
    "Asset ID must be exactly 128 bits");
```

### Memory Safety Excellence
```c
// ✅ restrict qualifiers for optimization and safety
void METAGRAPH_copy_nodes(
    const METAGRAPH_node_t* restrict source,
    METAGRAPH_node_t* restrict dest,
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
    METAGRAPH_id_t id;
    // Perfectly aligned for atomic operations
} METAGRAPH_node_header_t;

// ✅ Flexible array members for variable-size structures
typedef struct {
    size_t node_count;
    float weight;
    METAGRAPH_id_t nodes[];  // C99 flexible array member
} METAGRAPH_hyperedge_t;

// ✅ Proper cleanup with __attribute__((cleanup))
__attribute__((cleanup(METAGRAPH_graph_cleanup)))
METAGRAPH_graph_t* graph = NULL;
```

### Atomic Programming Excellence
```c
// ✅ C11 atomics with explicit memory ordering
#include <stdatomic.h>

typedef struct {
    _Atomic(uint64_t) node_count;
    _Atomic(METAGRAPH_node_t*) head_node;
    _Atomic(bool) is_valid;
} METAGRAPH_concurrent_graph_t;

// ✅ Lock-free programming with proper memory ordering
bool METAGRAPH_lockfree_insert_node(
    METAGRAPH_concurrent_graph_t* graph,
    METAGRAPH_node_t* new_node
) {
    METAGRAPH_node_t* expected = atomic_load_explicit(
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
void test_METAGRAPH_graph_add_node_success(void) {
    // Arrange
    METAGRAPH_graph_config_t config = {
        .initial_node_capacity = 16,
        .enable_concurrent_access = false
    };
    METAGRAPH_graph_t* graph = NULL;
    cr_assert_eq(METAGRAPH_graph_create(&config, &graph), METAGRAPH_SUCCESS);

    // Act
    METAGRAPH_node_metadata_t metadata = {
        .name = "test_asset.png",
        .type = METAGRAPH_ASSET_TYPE_TEXTURE,
        .data_size = 4096
    };
    METAGRAPH_node_t* node = NULL;
    METAGRAPH_result_t result = METAGRAPH_graph_add_node(graph, &metadata, &node);

    // Assert
    cr_assert_eq(result, METAGRAPH_SUCCESS);
    cr_assert_not_null(node);
    cr_assert_eq(METAGRAPH_graph_get_node_count(graph), 1);

    // Cleanup
    METAGRAPH_graph_destroy(graph);
}

// ✅ Property-based testing for edge cases
void test_METAGRAPH_graph_stress_many_nodes(void) {
    const size_t NODE_COUNT = 100000;

    METAGRAPH_graph_t* graph = create_test_graph();

    // Add many nodes and verify graph remains consistent
    for (size_t i = 0; i < NODE_COUNT; ++i) {
        add_random_node(graph);
        if (i % 1000 == 0) {
            cr_assert(validate_graph_invariants(graph));
        }
    }

    cr_assert_eq(METAGRAPH_graph_get_node_count(graph), NODE_COUNT);
    METAGRAPH_graph_destroy(graph);
}
```

## 🐚 Shell Script Excellence - POSIX Portability

### MANDATORY Shell Script Standards
```bash
# ✅ Always use POSIX-compliant shebang
#!/bin/sh

# ✅ POSIX-compliant error handling
set -eu  # NOT set -euo pipefail (pipefail is bash-specific)

# ✅ Directory navigation with proper cleanup
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"
# ... do work in project root ...

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

### Why POSIX Portability Matters
- **Linux**: All distributions support POSIX sh
- **macOS**: Works with both bash and zsh (default on modern macOS)
- **Windows WSL2**: Ensures compatibility across different WSL distributions
- **CI/CD**: Works in minimal Docker containers with only `/bin/sh`
- **DevContainers**: Portable across different base images

## 🔧 Development Workflow

### Standard Build Commands

```bash
# Basic release build
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# Development build with all checks
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DMETAGRAPH_DEV=ON -DMETAGRAPH_SANITIZERS=ON

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
ASAN_OPTIONS="abort_on_error=1" ./build/bin/METAGRAPH_unit_tests

# Fuzzing campaign
cmake -DMETAGRAPH_FUZZING=ON -B build-fuzz
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
target_compile_options(METAGRAPH PRIVATE
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

## 📊 Performance Engineering Standards

### Micro-Benchmarking Requirements
```c
// ✅ Every performance-critical function must have benchmarks
CRITERION_BENCHMARK(bench_node_lookup) {
    METAGRAPH_graph_t* graph = create_benchmark_graph(100000);
    METAGRAPH_id_t random_ids[1000];
    generate_random_ids(random_ids, 1000);

    criterion_start_timer();

    for (int i = 0; i < 1000; ++i) {
        METAGRAPH_node_t* node;
        METAGRAPH_graph_find_node(graph, random_ids[i], &node);
    }

    criterion_stop_timer();
    METAGRAPH_graph_destroy(graph);
}
```

### Cache Optimization Requirements
```c
// ✅ Data structure layout optimized for cache lines
typedef struct alignas(64) {  // Cache line aligned
    _Atomic(uint64_t) reference_count;  // Hot data first
    METAGRAPH_id_t id;
    uint32_t type;
    uint32_t flags;
    // Cold data after hot data
    const char* name;
    void* user_data;
} METAGRAPH_node_t;

// ✅ Memory prefetching for traversal
void METAGRAPH_prefetch_next_nodes(METAGRAPH_node_t** nodes, size_t count) {
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
    METAGRAPH_SUCCESS = 0,
    METAGRAPH_ERROR_OUT_OF_MEMORY,
    METAGRAPH_ERROR_INVALID_ARGUMENT,
    METAGRAPH_ERROR_NODE_NOT_FOUND,
    METAGRAPH_ERROR_CIRCULAR_DEPENDENCY,
    METAGRAPH_ERROR_IO_FAILURE,
    METAGRAPH_ERROR_CORRUPTION_DETECTED,
    METAGRAPH_ERROR_CONCURRENT_MODIFICATION
} METAGRAPH_result_t;

// ✅ Error context for debugging
typedef struct {
    METAGRAPH_result_t code;
    const char* file;
    int line;
    const char* function;
    char message[256];
} METAGRAPH_error_context_t;

#define METAGRAPH_RETURN_ERROR(code, ...) \
    return METAGRAPH_set_error_context((code), __FILE__, __LINE__, __func__, __VA_ARGS__)
```

## 📋 Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- Platform abstraction and error handling ([F.010](docs/features/F010-platform-abstraction.md), [F.011](docs/features/F011-error-handling-validation.md))
- Core meta-graph data structures ([F.001](docs/features/F001-core-meta-graph-data-model.md))
- Memory pool management ([F.009](docs/features/F009-memory-pool-management.md))

### Phase 2: I/O System (Weeks 3-5)
- Binary bundle format ([F.002](docs/features/F002-binary-bundle-format.md))
- Memory mapping ([F.003](docs/features/F003-memory-mapped-access.md))
- BLAKE3 integrity ([F.004](docs/features/F004-blake3-integrity-verification.md))

### Phase 3: Algorithms (Weeks 6-7)
- Graph traversal ([F.005](docs/features/F005-efficient-graph-traversal.md))
- Dependency resolution ([F.006](docs/features/F006-dependency-resolution-algorithms.md))

### Phase 4: Concurrency & Builder (Weeks 8-9)
- Thread-safe access ([F.008](docs/features/F008-thread-safe-concurrent-access.md))
- Bundle creation ([F.012](docs/features/F012-bundle-builder-system.md))

## 🚀 Submission Guidelines

### Before Submitting

1. **Run Full Quality Checks**:
   ```bash
   # Format code
   ./scripts/run-clang-format.sh --fix

   # Run all tests with sanitizers
   ctest --test-dir build --output-on-failure

   # Static analysis
   cmake --build build --target static-analysis

   # Security scan
   ./scripts/run-gitleaks.sh
   ```

2. **Verify Cross-Platform Compatibility**:
   ```bash
   # Test POSIX compliance
   ./scripts/check-posix-compliance.sh

   # Docker matrix testing
   ./docker/build-all.sh
   ```

3. **Performance Validation**:
   ```bash
   # Run benchmarks
   ./scripts/run-benchmarks.sh

   # Memory profiling
   ./scripts/profile.sh memory
   ```

### Pull Request Requirements

- **Title**: Clear, descriptive summary
- **Description**: Link to feature specification and implementation details
- **Tests**: Comprehensive unit and integration tests
- **Documentation**: Updated API docs and examples
- **Performance**: Benchmark results for performance-critical changes

### Review Process

1. **Automated Checks**: CI/CD pipeline must pass completely
2. **Code Review**: Minimum 2 approvals from maintainers
3. **Architecture Review**: For significant changes to core design
4. **Performance Review**: For changes affecting critical paths

## 🚀 Release Process

MetaGraph follows a Fort Knox-grade release process with strict validation and security requirements. For detailed information about creating releases, see:

**[Release Process Documentation](docs/RELEASE.md)**

Key points:
- All releases must originate from `release/v*` branches
- Comprehensive quality validation is mandatory
- Version files are managed by `scripts/prepare-release.sh`
- Performance regressions beyond ±5% fail the release
- All artifacts are cryptographically signed

## 📞 Getting Help

- **Questions**: Open GitHub Issues with the `question` label
- **Bugs**: Use the bug report template
- **Features**: Propose new features with the feature request template
- **Security**: Email james@flyingrobots.dev for vulnerabilities

## 📚 Additional Resources

- **[Feature Specifications](docs/features/)**: Complete technical specifications
- **[Third-Party Integration](docs/3rd-party.md)**: Library selection and usage guides
- **[Architecture Overview](README.md#architecture-overview)**: High-level system design
- **[Release Process](docs/RELEASE.md)**: Fort Knox-grade release workflow

---

Thank you for contributing to METAGRAPH! Together we're building the mathematical foundation for next-generation asset management.
