/**
 * @file graph.c
 * @brief HyperDAG graph implementation
 */

#include "hyperdag/hyperdag.h"
#include "../internal/common.h"
#include "../platform/platform.h"

#include <stdlib.h>
#include <string.h>

/* Default initial capacity */
#define DEFAULT_INITIAL_CAPACITY 16

/* Internal graph structure */
struct hyperdag_graph {
    hyperdag_node_t *nodes;        /* Array of nodes */
    size_t node_count;             /* Current number of nodes */
    size_t node_capacity;          /* Allocated capacity for nodes */
    hyperdag_node_id_t next_id;    /* Next available node ID */
} HYPERDAG_CACHE_ALIGNED;

/* Internal node structure */
struct hyperdag_node {
    hyperdag_node_id_t id;         /* Node identifier */
    void *data;                    /* User data */
    size_t data_size;              /* Size of user data */
    hyperdag_node_id_t *children;  /* Array of child node IDs */
    size_t child_count;            /* Number of children */
    size_t child_capacity;         /* Allocated capacity for children */
    hyperdag_node_id_t *parents;   /* Array of parent node IDs */
    size_t parent_count;           /* Number of parents */
    size_t parent_capacity;        /* Allocated capacity for parents */
    bool is_valid;                 /* Node validity flag */
} HYPERDAG_CACHE_ALIGNED;

HYPERDAG_WARN_UNUSED
static hyperdag_error_t graph_ensure_capacity(hyperdag_graph_t *graph, size_t required_capacity)
{
    HYPERDAG_ASSERT(graph != NULL);
    
    if (graph->node_capacity >= required_capacity) {
        return HYPERDAG_SUCCESS;
    }
    
    size_t new_capacity = graph->node_capacity;
    while (new_capacity < required_capacity) {
        new_capacity *= 2;
    }
    
    hyperdag_node_t *new_nodes = realloc(graph->nodes, 
                                         new_capacity * sizeof(hyperdag_node_t));
    if (HYPERDAG_UNLIKELY(new_nodes == NULL)) {
        return HYPERDAG_ERROR_OUT_OF_MEMORY;
    }
    
    /* Initialize new nodes */
    for (size_t i = graph->node_capacity; i < new_capacity; i++) {
        memset(&new_nodes[i], 0, sizeof(hyperdag_node_t));
        new_nodes[i].is_valid = false;
    }
    
    graph->nodes = new_nodes;
    graph->node_capacity = new_capacity;
    
    return HYPERDAG_SUCCESS;
}

hyperdag_graph_t *hyperdag_graph_create(size_t initial_capacity)
{
    if (initial_capacity == 0) {
        initial_capacity = DEFAULT_INITIAL_CAPACITY;
    }
    
    hyperdag_graph_t *graph = hyperdag_platform_aligned_alloc(HYPERDAG_CACHE_LINE_SIZE, sizeof(hyperdag_graph_t));
    if (HYPERDAG_UNLIKELY(graph == NULL)) {
        return NULL;
    }
    
    graph->nodes = malloc(initial_capacity * sizeof(hyperdag_node_t));
    if (HYPERDAG_UNLIKELY(graph->nodes == NULL)) {
        hyperdag_platform_aligned_free(graph);
        return NULL;
    }
    
    /* Initialize all nodes */
    for (size_t i = 0; i < initial_capacity; i++) {
        memset(&graph->nodes[i], 0, sizeof(hyperdag_node_t));
        graph->nodes[i].is_valid = false;
    }
    
    graph->node_count = 0;
    graph->node_capacity = initial_capacity;
    graph->next_id = 1; /* Start IDs from 1, reserve 0 as invalid */
    
    return graph;
}

void hyperdag_graph_destroy(hyperdag_graph_t *graph)
{
    if (graph == NULL) {
        return;
    }
    
    /* Free all node data and arrays */
    for (size_t i = 0; i < graph->node_capacity; i++) {
        if (graph->nodes[i].is_valid) {
            free(graph->nodes[i].data);
            free(graph->nodes[i].children);
            free(graph->nodes[i].parents);
        }
    }
    
    free(graph->nodes);
    hyperdag_platform_aligned_free(graph);
}

hyperdag_error_t hyperdag_graph_add_node(hyperdag_graph_t *graph,
                                          const void *data,
                                          size_t data_size,
                                          hyperdag_node_id_t *node_id)
{
    HYPERDAG_CHECK_NULL(graph);
    HYPERDAG_CHECK_NULL(node_id);
    
    /* Ensure we have capacity */
    HYPERDAG_CHECK_ERROR(graph_ensure_capacity(graph, graph->node_count + 1));
    
    /* Find the next available slot */
    size_t slot = SIZE_MAX;
    for (size_t i = 0; i < graph->node_capacity; i++) {
        if (!graph->nodes[i].is_valid) {
            slot = i;
            break;
        }
    }
    
    HYPERDAG_ASSERT(slot != SIZE_MAX); /* Should always find a slot */
    
    hyperdag_node_t *node = &graph->nodes[slot];
    memset(node, 0, sizeof(hyperdag_node_t));
    
    node->id = graph->next_id++;
    node->is_valid = true;
    
    /* Copy user data if provided */
    if (data != NULL && data_size > 0) {
        node->data = malloc(data_size);
        if (HYPERDAG_UNLIKELY(node->data == NULL)) {
            node->is_valid = false;
            return HYPERDAG_ERROR_OUT_OF_MEMORY;
        }
        memcpy(node->data, data, data_size);
        node->data_size = data_size;
    }
    
    graph->node_count++;
    *node_id = node->id;
    
    return HYPERDAG_SUCCESS;
}

size_t hyperdag_graph_get_node_count(const hyperdag_graph_t *graph)
{
    if (graph == NULL) {
        return 0;
    }
    return graph->node_count;
}

size_t hyperdag_graph_get_edge_count(const hyperdag_graph_t *graph)
{
    if (graph == NULL) {
        return 0;
    }
    
    size_t edge_count = 0;
    for (size_t i = 0; i < graph->node_capacity; i++) {
        if (graph->nodes[i].is_valid) {
            edge_count += graph->nodes[i].child_count;
        }
    }
    
    return edge_count;
}

const char *hyperdag_error_string(hyperdag_error_t error)
{
    switch (error) {
        case HYPERDAG_SUCCESS:
            return "Success";
        case HYPERDAG_ERROR_NULL_POINTER:
            return "Null pointer argument";
        case HYPERDAG_ERROR_INVALID_ARGUMENT:
            return "Invalid argument";
        case HYPERDAG_ERROR_OUT_OF_MEMORY:
            return "Out of memory";
        case HYPERDAG_ERROR_NODE_NOT_FOUND:
            return "Node not found";
        case HYPERDAG_ERROR_CYCLE_DETECTED:
            return "Cycle detected";
        case HYPERDAG_ERROR_INVALID_OPERATION:
            return "Invalid operation";
        default:
            return "Unknown error";
    }
}
