# Claude Code Assistant Guide for MetaGraph

This document provides essential context and guidelines for AI-assisted development on the MetaGraph project.

## Project Context

MetaGraph is a high-performance C23 library implementing a mathematical hypergraph foundation for asset management systems. The project embodies the principle that "everything is a graph" - from neural networks to game worlds to dependency trees.

### Key Technical Decisions

- **Language**: C23 with bleeding-edge compiler features (GCC 15+, Clang 18+)
- **Architecture**: 12 interconnected features forming a complete system
- **Libraries**: BLAKE3 (cryptography), mimalloc (memory), uthash (data structures), tinycthread (threading)
- **Performance**: Sub-200ms load times for 1GB bundles, lock-free concurrent access
- **Quality**: Zero tolerance for warnings, 100% test coverage, comprehensive static analysis

## Development Guidelines for Claude

### Core Principles

1. **Do exactly what is asked - nothing more, nothing less**
2. **Edit existing files rather than creating new ones**
3. **Never create documentation files unless explicitly requested**
4. **Follow existing patterns and conventions rigorously**
5. **Use C23 features wherever appropriate**

### Code Generation Standards

#### C23 Modern Features

```c
// Use auto for type inference
auto result = metagraph_graph_create(&config, &graph);

// Use typeof for generic programming
#define POOL_ALLOC(pool, type) \
    ((type*)metagraph_pool_alloc(pool, sizeof(type), _Alignof(type)))

// Use [[attributes]] for optimization hints
[[nodiscard]] metagraph_result_t metagraph_graph_add_node(
    metagraph_graph_t* restrict graph,
    const metagraph_node_metadata_t* restrict metadata,
    metagraph_id_t* restrict out_id
);

// Use _BitInt for precise bit widths
typedef _BitInt(128) metagraph_id_t;
typedef _BitInt(40) metagraph_offset_t;  // For files up to 1TB
```

#### Memory Safety

```c
// Always use restrict for pointer parameters
void metagraph_copy_nodes(
    const metagraph_node_t* restrict source,
    metagraph_node_t* restrict dest,
    size_t count
);

// Align structures for atomic operations
typedef struct alignas(64) {  // Cache line aligned
    _Atomic(uint64_t) ref_count;
    metagraph_id_t id;
    // ... rest of structure
} metagraph_node_t;
```

### API Naming Conventions

The project uses lowercase snake_case with module prefixes:

```c
// Pattern: metagraph_[module]_[action]
metagraph_graph_create()
metagraph_graph_destroy()
metagraph_node_add()
metagraph_edge_connect()
metagraph_bundle_load()
metagraph_pool_alloc()
```

Note: API naming is enforced by clang-tidy - let the tools handle compliance.

### Shell Script Requirements

**MANDATORY**: All scripts must be POSIX-compliant - NO bash-isms allowed.

```bash
#!/bin/sh  # NOT #!/bin/bash
set -eu    # NOT set -euo pipefail

# POSIX conditionals only
if [ "$var" = "value" ]; then  # NOT [[ "$var" == "value" ]]
    echo "correct"
fi

# No arrays, no mapfile, no process substitution
# Scripts must work on minimal /bin/sh environments
```

### Quick Reference Commands

```bash
# Development setup
./scripts/setup-dev-env.sh

# Build with all checks
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DMETAGRAPH_DEV=ON
cmake --build build

# Run quality checks
./scripts/run-clang-format.sh --fix
cmake --build build --target static-analysis
ctest --test-dir build --output-on-failure

# Performance profiling
./scripts/profile.sh all
```

## Implementation Roadmap

### Phase 1: Foundation (Current Focus)

- **F.010**: Platform abstraction layer
- **F.011**: Error handling and validation
- Start with these before any other features

### Phase 2: Core Data Structures

- **F.001**: Hypergraph data model
- **F.007**: Asset ID system
- **F.009**: Memory pool management

### Phase 3: I/O and Serialization

- **F.002**: Binary bundle format
- **F.003**: Memory-mapped I/O
- **F.004**: BLAKE3 integrity

### Phase 4: Algorithms and Concurrency

- **F.005**: Graph traversal
- **F.006**: Dependency resolution
- **F.008**: Thread-safe access

### Phase 5: Builder System

- **F.012**: Bundle creation and serialization

## Quality Requirements

### Absolute Requirements - NO EXCEPTIONS

- **100% test coverage** for all functions
- **Zero clang-tidy warnings** - fix, don't suppress
- **Clean sanitizer runs** - ASan, MSan, UBSan, TSan must all pass
- **No memory leaks** - Valgrind must report zero issues
- **Performance targets met** - <5% regression tolerance

### Testing Philosophy

Every function needs:

1. Success case tests
2. Error case tests
3. Edge case tests
4. Concurrent access tests (where applicable)
5. Performance benchmarks (for critical paths)

## Third-Party Integration Notes

### BLAKE3

- Use streaming API for large files
- Enable SIMD optimizations
- Integrate with memory pool for hash contexts

### mimalloc

- Create custom arenas on top of mimalloc
- Use thread-local heaps for hot paths
- Override malloc/free globally in release builds

### uthash

- Wrap in type-safe macros
- Integrate with memory pool
- Use HASH_ADD_KEYPTR for string keys

### tinycthread

- Combine with C11 atomics for lock-free patterns
- Use condition variables sparingly
- Prefer atomic operations over mutexes

## Common Pitfalls to Avoid

1. **Don't assume libraries exist** - always check package.json/CMakeLists.txt first
2. **Don't create new patterns** - study existing code and follow conventions
3. **Don't skip tests** - every function must have comprehensive tests
4. **Don't use non-POSIX shell** - scripts must work on minimal /bin/sh
5. **Don't ignore performance** - profile critical paths and optimize

## Critical Reminders

- **Never create files unless absolutely necessary**
- **Always prefer editing existing files**
- **Never proactively create documentation**
- **Follow C23 best practices rigorously**
- **Let clang-tidy enforce naming conventions**
- **Use Task tool for complex searches**
- **Run linting/type checking after implementation**

## Getting Started

When implementing a new feature:

1. Read the feature specification in `docs/features/`
2. Study existing code for patterns and conventions
3. Implement with comprehensive tests
4. Run all quality checks
5. Profile performance if on critical path

Remember: The goal is mathematical purity, extreme performance, and absolute reliability. Every line of code should reflect these values.
