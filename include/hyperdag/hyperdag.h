/**
 * @file hyperdag.h
 * @brief HyperDAG - High-Performance Directed Acyclic Graph Library
 * 
 * A modern C23 library for directed acyclic graph operations with focus on
 * performance, correctness, and scalability.
 * 
 * @version 1.0.0
 * @author HyperDAG Team
 * @date 2025
 */

#ifndef HYPERDAG_H
#define HYPERDAG_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Version information */
#define HYPERDAG_VERSION_MAJOR 1
#define HYPERDAG_VERSION_MINOR 0
#define HYPERDAG_VERSION_PATCH 0

/**
 * hyperdag_version - Get library version information
 * 
 * Returns the version of the HyperDAG library as a string.
 * 
 * Return: Version string in format "major.minor.patch"
 */
const char *hyperdag_version(void);

/* Forward declarations */
typedef struct hyperdag_graph hyperdag_graph_t;
typedef struct hyperdag_node hyperdag_node_t;
typedef struct hyperdag_edge hyperdag_edge_t;

/* Node identifier type */
typedef uint64_t hyperdag_node_id_t;

/* Error codes */
typedef enum {
    HYPERDAG_SUCCESS = 0,
    HYPERDAG_ERROR_NULL_POINTER,
    HYPERDAG_ERROR_INVALID_ARGUMENT,
    HYPERDAG_ERROR_OUT_OF_MEMORY,
    HYPERDAG_ERROR_NODE_NOT_FOUND,
    HYPERDAG_ERROR_CYCLE_DETECTED,
    HYPERDAG_ERROR_INVALID_OPERATION
} hyperdag_error_t;

/**
 * hyperdag_graph_create - Create a new HyperDAG graph
 * @initial_capacity: Initial node capacity (0 for default)
 * 
 * Allocates and initializes a new HyperDAG graph with the specified
 * initial capacity. The graph will automatically grow as needed.
 * 
 * The caller is responsible for freeing the graph with hyperdag_graph_destroy().
 * 
 * Return: Pointer to the new graph, or NULL on allocation failure
 */
hyperdag_graph_t *hyperdag_graph_create(size_t initial_capacity);

/**
 * hyperdag_graph_destroy - Destroy a HyperDAG graph
 * @graph: Graph to destroy (may be NULL)
 * 
 * Frees all memory associated with the graph, including all nodes and edges.
 * It is safe to pass NULL to this function.
 */
void hyperdag_graph_destroy(hyperdag_graph_t *graph);

/**
 * hyperdag_graph_add_node - Add a new node to the graph
 * @graph: Target graph
 * @data: User data to associate with the node (may be NULL)
 * @data_size: Size of the user data
 * @node_id: Output parameter for the new node ID
 * 
 * Adds a new node to the graph with optional user data. The node ID
 * is assigned automatically and returned through the node_id parameter.
 * 
 * Return: HYPERDAG_SUCCESS on success, error code on failure
 */
hyperdag_error_t hyperdag_graph_add_node(hyperdag_graph_t *graph,
                                          const void *data,
                                          size_t data_size,
                                          hyperdag_node_id_t *node_id);

/**
 * hyperdag_graph_add_edge - Add an edge between two nodes
 * @graph: Target graph
 * @from_id: Source node ID
 * @to_id: Target node ID
 * 
 * Adds a directed edge from the source node to the target node.
 * This operation will fail if it would create a cycle in the graph.
 * 
 * Return: HYPERDAG_SUCCESS on success, error code on failure
 */
hyperdag_error_t hyperdag_graph_add_edge(hyperdag_graph_t *graph,
                                          hyperdag_node_id_t from_id,
                                          hyperdag_node_id_t to_id);

/**
 * hyperdag_graph_remove_node - Remove a node from the graph
 * @graph: Target graph
 * @node_id: ID of the node to remove
 * 
 * Removes the specified node and all its associated edges from the graph.
 * 
 * Return: HYPERDAG_SUCCESS on success, error code on failure
 */
hyperdag_error_t hyperdag_graph_remove_node(hyperdag_graph_t *graph,
                                             hyperdag_node_id_t node_id);

/**
 * hyperdag_graph_remove_edge - Remove an edge from the graph
 * @graph: Target graph
 * @from_id: Source node ID
 * @to_id: Target node ID
 * 
 * Removes the directed edge between the specified nodes.
 * 
 * Return: HYPERDAG_SUCCESS on success, error code on failure
 */
hyperdag_error_t hyperdag_graph_remove_edge(hyperdag_graph_t *graph,
                                             hyperdag_node_id_t from_id,
                                             hyperdag_node_id_t to_id);

/**
 * hyperdag_graph_get_node_count - Get the number of nodes in the graph
 * @graph: Target graph
 * 
 * Return: Number of nodes in the graph, or 0 if graph is NULL
 */
size_t hyperdag_graph_get_node_count(const hyperdag_graph_t *graph);

/**
 * hyperdag_graph_get_edge_count - Get the number of edges in the graph
 * @graph: Target graph
 * 
 * Return: Number of edges in the graph, or 0 if graph is NULL
 */
size_t hyperdag_graph_get_edge_count(const hyperdag_graph_t *graph);

/**
 * hyperdag_graph_has_cycle - Check if the graph contains a cycle
 * @graph: Target graph
 * 
 * Performs a cycle detection algorithm to determine if the graph
 * contains any cycles.
 * 
 * Return: true if a cycle is detected, false otherwise
 */
bool hyperdag_graph_has_cycle(const hyperdag_graph_t *graph);

/**
 * hyperdag_graph_topological_sort - Perform topological sort
 * @graph: Target graph
 * @result: Output array for sorted node IDs
 * @result_size: Size of the result array
 * 
 * Performs a topological sort of the graph and stores the result
 * in the provided array. The array must be large enough to hold
 * all nodes in the graph.
 * 
 * Return: HYPERDAG_SUCCESS on success, error code on failure
 */
hyperdag_error_t hyperdag_graph_topological_sort(const hyperdag_graph_t *graph,
                                                  hyperdag_node_id_t *result,
                                                  size_t result_size);

/**
 * hyperdag_error_string - Get human-readable error message
 * @error: Error code
 * 
 * Return: String description of the error code
 */
const char *hyperdag_error_string(hyperdag_error_t error);

#ifdef __cplusplus
}
#endif

#endif /* HYPERDAG_H */
