# MetaGraph Development Guide for Claude

@import CONTRIBUTING.md
@import docs/3rd-party.md
@import docs/features/README.md

This file contains AI-specific development context and standards for working on MetaGraph with Claude Code.

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

### 🛠️ Quick Commands
```bash
# Environment setup
./scripts/setup-dev-env.sh

# Development build
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DMetaGraph_DEV=ON

# Quality validation
./scripts/run-clang-format.sh --fix
cmake --build build --target static-analysis
```

## AI-Specific Implementation Notes

### Implementation Strategy
1. **Foundation First**: Platform abstraction and error handling (F.010, F.011)
2. **Core Data**: Hypergraph structures and memory management (F.001, F.009)
3. **I/O Systems**: Binary format and memory mapping (F.002, F.003, F.004)
4. **Algorithms**: Traversal and dependency resolution (F.005, F.006)
5. **Concurrency**: Thread-safe access and lock-free optimization (F.008)
6. **Builder**: Asset processing and bundle creation (F.012)

### Third-Party Integration Patterns
- **BLAKE3**: Use streaming API for large bundles, enable SIMD optimizations
- **mimalloc**: Thread-local heaps with custom arenas on top
- **uthash**: Type-safe macros with proper memory management integration
- **tinycthread**: Combined with compiler atomics for lock-free patterns

## Critical AI Development Reminders

**MUST follow without exception:**

- **Do what has been asked; nothing more, nothing less**
- **NEVER create files unless absolutely necessary**
- **ALWAYS prefer editing existing files**
- **NEVER proactively create documentation files** (*.md) unless explicitly requested
- **ABSOLUTELY NO SKIPPING TESTS OR DISABLING LINTER CHECKS**
- **Use C23 language enhancements** wherever possible
- **POSIX shell scripts only** - no bash-isms

## Quality Gates - MANDATORY
- **100% Test Coverage**: Every function must have comprehensive unit tests
- **Zero Warnings**: All clang-tidy warnings must be addressed, never disabled
- **Memory Safety**: ASan/MSan/UBSan must pass completely clean
- **Thread Safety**: TSan must validate all concurrent code
- **Static Analysis**: PVS-Studio and Cppcheck must pass without exceptions

---

*This file provides AI-specific context for developing MetaGraph. For comprehensive development guidelines, build instructions, and contribution standards, see [CONTRIBUTING.md](CONTRIBUTING.md).*
