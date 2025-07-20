# HyperDAG Development Guide for Claude

> **For general development guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md)**

This file contains AI-specific development context and standards for working on HyperDAG with Claude Code.

## Project Overview for AI Development

**Architecture**: Complete (12 features specified)  
**Implementation**: Ready to begin (foundation layer)  
**Quality Standard**: Extreme - Zero tolerance for shortcuts  

### Key Architectural Decisions
- **C23 Modern Practices**: Leverage cutting-edge language features
- **Mathematical Foundation**: Hypergraph theory for N-to-M relationships
- **Third-Party Excellence**: Carefully selected libraries (BLAKE3, mimalloc, uthash)
- **Cross-Platform**: Windows/Linux/macOS with POSIX shell scripts
- **Performance Focus**: Lock-free algorithms, cache optimization, NUMA awareness

## AI Development Standards

### 🤖 Code Generation Principles
1. **Prefer editing existing files** over creating new ones
2. **Never create documentation files** (*.md) unless explicitly requested
3. **Follow existing patterns** - examine surrounding code for conventions
4. **Use C23 features** wherever appropriate (auto, typeof, [[attributes]], etc.)
5. **POSIX shell scripts only** - no bash-isms allowed

### 🧠 Context Awareness
- **Check CONTRIBUTING.md** for detailed coding standards and workflow
- **Reference feature specs** in `docs/features/` for implementation details
- **Use existing libraries** - check `docs/3rd-party.md` for integration patterns
- **Follow naming conventions** - let clang-tidy handle API naming enforcement

### 🛠️ Development Workflow
```bash
# Quick environment setup
./scripts/setup-dev-env.sh

# Development build
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DHYPERDAG_DEV=ON

# Quality validation
./scripts/run-clang-format.sh --fix
cmake --build build --target static-analysis
```

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
