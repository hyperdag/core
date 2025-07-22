# F.001 - Core Hypergraph Data Model

## Feature Overview

The core data structure that this library models is a ___recursive metagraph___–a graph in which everything–nodes, edges–may themselves also be graphs, recursively.

This model provides the fundamental mathematical structure for representing assets and their complex interdependencies.

Nodes? Graphs.
Edges? Graphs.

It's all graphs, all the way down.

## Priority
**Critical** - Foundation for all other features

## Dependencies
- F.010 - Platform Abstraction (memory allocation, basic data types)
- F.011 - Error Handling and Validation (error codes, result types)

## User Stories

### F001.US001 - Create Hypergraph Instance
**As a** system developer
**I want** to create and initialize mg instances
**So that** I can represent complex asset dependency relationships

**Prerequisites:**
- Platform abstraction layer available (F.010)
- Error handling system available (F.011)

**Acceptance Criteria:**
- Can create empty meta-graph with zero nodes and edges
- Hypergraph has unique identifier and metadata
- Memory allocation is tracked and can be freed
- Thread-safe creation and destruction

### F001.US002 - Add Nodes to Hypergraph
**As a** system developer
**I want** to add nodes to a meta-graph with associated metadata
**So that** I can represent individual assets in the dependency graph

**Prerequisites:**
- Hypergraph instance exists
- Asset ID system available (will be F.007)

**Acceptance Criteria:**
- Can add nodes with unique identifiers
- Nodes can store arbitrary metadata (size, type, properties)
- O(1) node lookup by ID using hash table
- Memory efficient storage for large numbers of nodes
- Duplicate node IDs are rejected with clear error

### F001.US003 - Create Hyperedges
**As a** system developer
**I want** to create hyperedges connecting multiple nodes
**So that** I can represent complex dependency relationships where one asset depends on multiple others

**Prerequisites:**
- Nodes exist in meta-graph
- Node IDs are valid and accessible

**Acceptance Criteria:**
- Can create hyperedges connecting 2 or more nodes
- Hyperedges have type information (dependency, reference, etc.)
- Hyperedges can have weights and properties
- Efficient storage and lookup of edge relationships
- Automatic validation that all referenced nodes exist

### F001.US004 - Query Node Relationships
**As a** performance engineer
**I want** to efficiently query node relationships
**So that** dependency resolution and asset loading is fast

**Prerequisites:**
- Hypergraph with nodes and edges exists
- Efficient indexing structures in place

**Acceptance Criteria:**
- O(1) average case node lookup by ID
- O(E) edge enumeration where E is edges per node
- Can query incoming edges (what depends on this node)
- Can query outgoing edges (what this node depends on)
- Lazy evaluation for large graphs

### F001.US005 - Memory Management
**As a** system developer
**I want** deterministic memory management for meta-graphs
**So that** I can use the library in resource-constrained environments

**Prerequisites:**
- Memory pool system available (F.009)
- Platform abstraction for memory operations

**Acceptance Criteria:**

- Clear ownership semantics for all data structures
- No memory leaks in normal operation
- Bounded memory usage with configurable limits
- Efficient memory reuse through pooling
- Memory usage statistics and monitoring

## API Design

```c
// Core data structures
typedef struct mg_graph mg_graph_t;
typedef struct mg_node mg_node_t;
typedef struct mg_edge mg_edge_t;

// Unique identifiers
typedef struct {
    uint64_t high;
    uint64_t low;
} mg_id_t;

// Node metadata
typedef struct {
    mg_id_t id;
    const char* name;
    uint32_t type;
    size_t data_size;
    void* data;
    uint64_t hash;
} mg_node_metadata_t;

// Edge metadata
typedef struct {
    mg_id_t id;
    uint32_t type;
    float weight;
    size_t node_count;
    mg_id_t* nodes;
    void* properties;
} mg_edge_metadata_t;

// Graph operations
mg_result_t mg_graph_create(
    const mg_graph_config_t* config,
    mg_graph_t** out_graph
);

mg_result_t mg_graph_destroy(mg_graph_t* graph);

mg_result_t mg_graph_add_node(
    mg_graph_t* graph,
    const mg_node_metadata_t* metadata,
    mg_node_t** out_node
);

mg_result_t mg_graph_add_edge(
    mg_graph_t* graph,
    const mg_edge_metadata_t* metadata,
    mg_edge_t** out_edge
);

mg_result_t mg_graph_find_node(
    const mg_graph_t* graph,
    mg_id_t node_id,
    mg_node_t** out_node
);

mg_result_t mg_graph_get_incoming_edges(
    const mg_graph_t* graph,
    mg_id_t node_id,
    mg_edge_t*** out_edges,
    size_t* out_count
);

mg_result_t mg_graph_get_outgoing_edges(
    const mg_graph_t* graph,
    mg_id_t node_id,
    mg_edge_t*** out_edges,
    size_t* out_count
);
```

## Data Structure Design

```mermaid
classDiagram
    class Meta-GraphGraph {
        +mg_id_t id
        +uint32_t version
        +size_t node_count
        +size_t edge_count
        +hash_table_t* node_index
        +array_t* edges
        +memory_pool_t* memory_pool
        +create() mg_result_t
        +destroy() mg_result_t
        +add_node() mg_result_t
        +add_edge() mg_result_t
        +find_node() mg_result_t
    }

    class Meta-GraphNode {
        +mg_id_t id
        +const char* name
        +uint32_t type
        +size_t data_size
        +void* data
        +uint64_t hash
        +array_t* incoming_edges
        +array_t* outgoing_edges
    }

    class Meta-GraphEdge {
        +mg_id_t id
        +uint32_t type
        +float weight
        +size_t node_count
        +mg_id_t* nodes
        +void* properties
    }

    class HashTable {
        +bucket_t* buckets
        +size_t bucket_count
        +size_t item_count
        +hash_function_t hash_fn
        +insert() mg_result_t
        +lookup() mg_result_t
        +remove() mg_result_t
    }

    Meta-GraphGraph ||--o{ Meta-GraphNode : contains
    Meta-GraphGraph ||--o{ Meta-GraphEdge : contains
    Meta-GraphGraph ||--|| HashTable : uses
    Meta-GraphEdge }o--o{ Meta-GraphNode : connects
```

## Memory Layout

```mermaid
graph TD
    subgraph "Meta-Graph Graph Memory Layout"
        HEADER[Graph Header<br/>id, version, counts]
        NODE_INDEX[Node Hash Table<br/>O(1) ID lookup]
        NODE_POOL[Node Memory Pool<br/>Fixed-size allocations]
        EDGE_ARRAY[Edge Array<br/>Sequential storage]
        EDGE_POOL[Edge Memory Pool<br/>Variable-size allocations]

        HEADER --> NODE_INDEX
        NODE_INDEX --> NODE_POOL
        NODE_POOL --> EDGE_ARRAY
        EDGE_ARRAY --> EDGE_POOL
    end

    subgraph "Node Structure"
        NODE_META[Node Metadata<br/>id, name, type, hash]
        NODE_DATA[Asset Data<br/>Variable size]
        INCOMING[Incoming Edge List<br/>Dynamic array]
        OUTGOING[Outgoing Edge List<br/>Dynamic array]

        NODE_META --> NODE_DATA
        NODE_META --> INCOMING
        NODE_META --> OUTGOING
    end
```

## Implementation Notes

### Hash Table Design
- Use Robin Hood hashing for consistent performance
- Load factor of 0.75 to balance memory usage and performance
- 64-bit hash function (likely xxHash or similar)
- Automatic resize when load factor exceeded

### Memory Pool Strategy
- Separate pools for nodes and edges to reduce fragmentation
- Fixed-size node allocations for cache efficiency
- Variable-size edge allocations with size classes
- Memory alignment for SIMD operations

### Thread Safety
- Read-write locks for graph modifications
- Atomic operations for reference counting
- Lock-free read paths where possible
- Memory barriers for consistency

## Test Plan

### Unit Tests
1. **Graph Creation/Destruction**
   - Create empty graph and verify initialization
   - Destroy graph and verify memory cleanup
   - Multiple graphs can coexist

2. **Node Operations**
   - Add nodes with various metadata types
   - Lookup nodes by ID with performance validation
   - Reject duplicate node IDs appropriately
   - Handle memory exhaustion gracefully

3. **Edge Operations**
   - Create edges between existing nodes
   - Create hyperedges with multiple nodes
   - Reject edges referencing non-existent nodes
   - Query incoming/outgoing edge relationships

4. **Performance Tests**
   - O(1) node lookup performance with large graphs
   - Memory usage scaling with node/edge count
   - Concurrent read performance under load

### Integration Tests
1. **Memory Management**
   - No memory leaks over extended operation
   - Proper cleanup on error conditions
   - Memory pool efficiency validation

2. **Edge Case Handling**
   - Empty graphs
   - Single node graphs
   - Fully connected graphs
   - Maximum size graphs

### Stress Tests
1. **Large Graph Performance**
   - 1M+ nodes with acceptable performance
   - Complex hyperedges (10+ nodes per edge)
   - Deep dependency chains

2. **Concurrent Access**
   - Multiple readers with single writer
   - Race condition detection
   - Deadlock prevention validation

## Acceptance Criteria Summary

✅ **Functional Requirements:**
- Create/destroy meta-graph instances
- Add nodes with metadata and unique IDs
- Create hyperedges connecting multiple nodes
- Query node relationships efficiently
- Proper error handling for all operations

✅ **Performance Requirements:**
- O(1) average node lookup by ID
- Memory usage scales linearly with content
- No memory leaks in normal operation
- Concurrent read access without blocking

✅ **Quality Requirements:**
- Comprehensive unit test coverage (>95%)
- Documentation for all public APIs
- Valgrind clean memory operations
- Thread safety validation with helgrind

This feature provides the mathematical foundation that all other Meta-Graph features build upon, implementing the core insight from the origin story that "everything is graphs."
