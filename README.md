# MetaGraph

> _Graphs. All. The. Way. Down._

A high-performance C23 library implementing a recursive metagraph foundation where nodes are graphs, edges are graphs, and graphs contain graphs infinitely.

[![CI](https://github.com/meta-graph/core/workflows/CI/badge.svg)](https://github.com/meta-graph/core/actions)
[![Security](https://github.com/meta-graph/core/workflows/Security/badge.svg)](https://github.com/meta-graph/core/actions)
[![SLSA](https://slsa.dev/images/gh-badge-level1.svg)](https://slsa.dev)

## Overview

MetaGraph implements a **recursive metagraph** data structure - not just a hypergraph. In this mathematical foundation:

- **Nodes are graphs** - Every node can contain an entire subgraph
- **Edges are graphs** - Every edge is itself a graph connecting graphs
- **Graphs are graphs** - The structure recurses infinitely

This recursive nature enables profound modeling capabilities: neural networks where neurons are networks, game worlds where objects contain worlds, dependency systems where packages are entire dependency graphs. Built with extreme performance and mathematical purity, MetaGraph provides the foundation for a new paradigm of graph-native computing.

### Key Features

- **Recursive Metagraph**: Nodes and edges are themselves graphs, enabling infinite nesting
- **True Composability**: Any graph can be a node in another graph, any graph can connect other graphs
- **Extreme Performance**: Lock-free algorithms, cache-optimized layouts, <200ms load times for 1GB bundles
- **Memory-Mapped I/O**: Zero-copy loading with pointer hydration and cross-platform support
- **Cryptographic Integrity**: BLAKE3 Merkle trees for tamper detection and verification
- **Modern C23**: Leveraging bleeding-edge language features for safety and performance
- **Thread-Safe Design**: Concurrent access with atomic operations and deadlock prevention

## Quick Start

### Using DevContainer (Recommended)

```bash
# Open in VS Code
code .

# Click "Reopen in Container" when prompted
# Everything is pre-configured and ready to use
```

### Manual Setup

```bash
# Automated environment setup
./scripts/setup-dev-env.sh

# Build the project
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DMETAGRAPH_DEV=ON
cmake --build build

# Run tests
ctest --test-dir build --output-on-failure
```

## Architecture

MetaGraph consists of 12 carefully designed features organized in phases:

```
Foundation Layer:
├── F.010 Platform Abstraction
└── F.011 Error Handling

Core Data Structures:
├── F.001 Recursive Metagraph Model
├── F.007 Asset ID System
└── F.009 Memory Pool Management

I/O and Serialization:
├── F.002 Binary Bundle Format
├── F.003 Memory-Mapped I/O
└── F.004 BLAKE3 Integrity

Algorithms and Concurrency:
├── F.005 Graph Traversal
├── F.006 Dependency Resolution
└── F.008 Thread-Safe Access

Builder System:
└── F.012 Bundle Creation
```

See [Feature Documentation](docs/features/) for detailed specifications.

## Usage Example (Planned API)

```c
#include <metagraph/metagraph.h>

// Create a metagraph
metagraph_graph_config_t config = {
    .initial_node_capacity = 10000,
    .enable_concurrent_access = true,
    .memory_pool_size = 64 * 1024 * 1024  // 64MB
};

metagraph_graph_t* world_graph;
metagraph_graph_create(&config, &world_graph);

// Create a subgraph for a game level (this graph will become a node!)
metagraph_graph_t* level_graph;
metagraph_graph_create(&config, &level_graph);

// Add assets to the level subgraph
metagraph_id_t texture_id, shader_id;
metagraph_node_add_simple(level_graph, "diffuse.png", &texture_id);
metagraph_node_add_simple(level_graph, "shader.glsl", &shader_id);

// Now add the entire level graph as a NODE in the world graph
metagraph_id_t level_node_id;
metagraph_node_add_graph(world_graph, level_graph, "Level_01", &level_node_id);

// Create another subgraph for game logic
metagraph_graph_t* logic_graph;
metagraph_graph_create(&config, &logic_graph);

// The edge connecting levels IS ITSELF A GRAPH
metagraph_graph_t* transition_graph;
metagraph_graph_create(&config, &transition_graph);
metagraph_node_add_simple(transition_graph, "fade_effect", NULL);
metagraph_node_add_simple(transition_graph, "checkpoint_save", NULL);

// Connect level to logic using the transition graph as an edge
metagraph_id_t transition_edge_id;
metagraph_edge_add_graph(world_graph, level_node_id, logic_node_id, 
                         transition_graph, &transition_edge_id);

// Graphs all the way down!
metagraph_graph_destroy(world_graph);
```

## Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| Node Lookup | O(1), <100ns | Hash-based indexing |
| Bundle Loading | >1GB/s | Memory-mapped I/O |
| Concurrent Reads | Linear scaling | Up to 16 threads |
| Memory Overhead | <5% | Efficient packing |
| Load Time (1GB) | <200ms | With integrity checks |

## Development

### Build Requirements

- **Compiler**: GCC 15+, Clang 18+, or MSVC 2022+ (C23 support required)
- **CMake**: 3.28 or higher
- **Platform**: Windows 10+, Linux 5.4+, or macOS 12+

### Building from Source

```bash
# Standard build
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# Development build with sanitizers
cmake -B build -DCMAKE_BUILD_TYPE=Debug \
    -DMETAGRAPH_DEV=ON \
    -DMETAGRAPH_SANITIZERS=ON
cmake --build build

# Run static analysis
cmake --build build --target static-analysis

# Performance profiling
./scripts/profile.sh all
```

### Development Workflow

1. Create feature branch from release branch
   ```bash
   git checkout release/v0.1.0
   git checkout -b feat/123-graph-traversal
   ```

2. Implement with comprehensive tests
   - 100% test coverage required
   - All sanitizers must pass
   - Zero clang-tidy warnings

3. Run quality checks
   ```bash
   ./scripts/run-clang-format.sh --fix
   ctest --test-dir build --output-on-failure
   cmake --build build --target static-analysis
   ```

4. Submit PR following guidelines in [CONTRIBUTING.md](CONTRIBUTING.md)

## Technology Stack

### Core Libraries

| Purpose | Library | License | Integration Status |
|---------|---------|---------|-------------------|
| Cryptography | [BLAKE3](https://github.com/BLAKE3-team/BLAKE3) | CC0/Apache 2.0 | Planned |
| Memory | [mimalloc](https://github.com/microsoft/mimalloc) | MIT | Planned |
| Data Structures | [uthash](https://github.com/troydhanson/uthash) | BSD | Planned |
| Threading | [tinycthread](https://github.com/tinycthread/tinycthread) | Simplified BSD | Planned |

### Platform Features

- **Linux**: io_uring for async I/O, huge pages support
- **Windows**: DirectStorage integration, SEH for error handling
- **macOS**: Grand Central Dispatch, Accelerate framework

## Documentation

- [Contributing Guidelines](CONTRIBUTING.md) - Development standards and workflow
- [Feature Specifications](docs/features/) - Detailed technical documentation
- [Third-Party Integration](docs/3rd-party.md) - Library usage patterns
- [Threat Model](docs/THREAT-MODEL.md) - Security considerations
- [Release Process](docs/RELEASE.md) - Fort Knox-grade release workflow
- [AI Assistant Guide](CLAUDE.md) - Context for Claude Code development

## Project Status

- ✅ **Architecture**: Complete specification of 12 features
- ✅ **Design**: API design and integration patterns defined
- ✅ **Documentation**: Comprehensive technical documentation
- 🚧 **Implementation**: Ready to begin (Phase 1: Foundation)
- ⏳ **Testing**: Pending implementation
- ⏳ **Release**: v0.1.0 planned after implementation

## Related Projects

- **MetaGraph** (this project): Pure mathematical recursive metagraph foundation
- **TurtlGraph** (future): Production system with streaming, CDN, hot reload built on MetaGraph
- **Applications**: Game engines (worlds within worlds), neural networks (networks of networks), package managers (dependencies as graphs), knowledge graphs (concepts containing concept graphs)

## License

Apache License 2.0 - see [LICENSE](LICENSE) for details.

## Security

For security vulnerabilities, please email james@flyingrobots.dev directly rather than using public issue tracker.

## Acknowledgments

MetaGraph emerged from the profound realization that "everything is a graph" - and more importantly, that graphs themselves are made of graphs. From Git commits (graphs of changes) to neural networks (graphs of graphs) to game worlds (graphs containing graph worlds), this recursive insight changes how we model complex systems. This project provides the mathematical foundation for that vision: Graphs. All. The. Way. Down.