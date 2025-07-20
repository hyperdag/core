# HyperDAG - High-Performance Directed Acyclic Graph Library

[![CI](https://github.com/hyperdag/hyperdag-core/workflows/CI/badge.svg)](https://github.com/hyperdag/hyperdag-core/actions)
[![Security](https://github.com/hyperdag/hyperdag-core/workflows/Security/badge.svg)](https://github.com/hyperdag/hyperdag-core/actions)

A high-performance C23 library for directed acyclic graph operations with focus on memory safety, performance, and modern development practices.

## What is HyperDAG?

HyperDAG provides efficient data structures and algorithms for working with directed acyclic graphs (DAGs). It's designed for applications that need:

- **Fast graph operations**: Node creation, edge manipulation, topological sorting
- **Memory safety**: Built with comprehensive sanitizer coverage and safe memory management
- **Scalability**: Optimized for large graphs with thousands of nodes
- **Modern C**: Written in C23 with contemporary safety and performance practices

## Core Features

### Graph Operations
- Create and destroy graphs with automatic memory management
- Add/remove nodes with optional user data
- Add/remove directed edges with cycle detection
- Topological sort for dependency resolution
- Graph validation and cycle detection

### Performance
- Cache-aligned data structures for optimal memory access
- Platform-specific optimizations
- Sub-microsecond operations for common tasks
- Efficient memory layout with minimal overhead

### Safety & Quality
- Memory safety validated with AddressSanitizer and UBSan
- Comprehensive test suite with fuzzing
- Static analysis with multiple tools
- Zero-tolerance policy for undefined behavior

## Quick Start

### Installation

```bash
git clone https://github.com/hyperdag/hyperdag-core.git
cd hyperdag-core
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

### Basic Usage

```c
#include "hyperdag/hyperdag.h"

int main() {
    // Create a new graph
    hyperdag_graph_t *graph = hyperdag_graph_create(0);
    if (!graph) return 1;
    
    // Add some nodes
    hyperdag_node_id_t node1, node2, node3;
    hyperdag_graph_add_node(graph, NULL, 0, &node1);
    hyperdag_graph_add_node(graph, NULL, 0, &node2);
    hyperdag_graph_add_node(graph, NULL, 0, &node3);
    
    // Add edges: node1 -> node2 -> node3
    hyperdag_graph_add_edge(graph, node1, node2);
    hyperdag_graph_add_edge(graph, node2, node3);
    
    // Check for cycles (should be false)
    bool has_cycle = hyperdag_graph_has_cycle(graph);
    
    // Get topological ordering
    size_t node_count = hyperdag_graph_get_node_count(graph);
    hyperdag_node_id_t *sorted = malloc(node_count * sizeof(hyperdag_node_id_t));
    hyperdag_graph_topological_sort(graph, sorted, node_count);
    
    // Clean up
    free(sorted);
    hyperdag_graph_destroy(graph);
    return 0;
}
```

## API Reference

### Graph Management
- `hyperdag_graph_create()` - Create a new graph
- `hyperdag_graph_destroy()` - Free graph memory
- `hyperdag_graph_get_node_count()` - Get number of nodes
- `hyperdag_graph_get_edge_count()` - Get number of edges

### Node Operations
- `hyperdag_graph_add_node()` - Add a node with optional data
- `hyperdag_graph_remove_node()` - Remove a node and its edges

### Edge Operations
- `hyperdag_graph_add_edge()` - Add a directed edge (with cycle check)
- `hyperdag_graph_remove_edge()` - Remove an edge

### Graph Analysis
- `hyperdag_graph_has_cycle()` - Check for cycles
- `hyperdag_graph_topological_sort()` - Get topological ordering

## Building

### Requirements
- C23-compatible compiler (GCC 13+, Clang 17+, MSVC 2022+)
- CMake 3.28+
- Optional: Criterion testing framework

### Build Options
```bash
# Debug build with sanitizers
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DHYPERDAG_SANITIZERS=ON

# Release build with optimizations
cmake -B build -DCMAKE_BUILD_TYPE=Release

# Development build with all checks
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DHYPERDAG_DEV=ON
```

### Testing
```bash
# Build and run tests
cmake --build build
ctest --test-dir build

# Run specific test suites
./build/bin/hyperdag_unit_tests
./build/bin/hyperdag_integration_tests
```

## Performance

Typical performance on modern hardware:

| Operation | Time |
|-----------|------|
| Graph creation | ~1 µs |
| Node addition | ~0.4 µs |
| Edge addition | ~0.6 µs |
| Cycle detection | ~2 ms (100k nodes) |
| Topological sort | ~3 ms (100k nodes) |

## Use Cases

HyperDAG is suitable for:

- **Build systems**: Dependency resolution and parallel execution planning
- **Task scheduling**: Job dependency management and execution ordering
- **Data pipelines**: Processing workflow definition and optimization
- **Package management**: Dependency resolution and conflict detection
- **Academic research**: Graph algorithm development and testing

## Development

### Project Structure
```
├── include/hyperdag/     # Public API headers
├── src/
│   ├── core/            # Core graph implementation
│   ├── platform/        # Platform-specific code
│   └── internal/        # Internal utilities
├── tests/               # Test suites
├── tools/               # CLI utilities
└── docs/                # Documentation
```

### Contributing
1. Ensure all tests pass: `ctest --test-dir build`
2. Run static analysis: `cmake --build build --target static-analysis`
3. Follow the existing code style
4. Add tests for new functionality

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

Built with modern C23 standards and comprehensive safety practices.