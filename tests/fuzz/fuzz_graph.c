/**
 * @file fuzz_graph.c
 * @brief Fuzzing tests for HyperDAG graph operations
 */

#include "hyperdag/hyperdag.h"
#include <stdint.h>
#include <stddef.h>
#include <string.h>

/* Fuzzing harness for graph operations */
int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    if (size < 1) {
        return 0;
    }
    
    /* Use the first byte to determine which operation to test */
    uint8_t operation = data[0] % 4;
    const uint8_t *remaining_data = data + 1;
    size_t remaining_size = size - 1;
    
    hyperdag_graph_t *graph = hyperdag_graph_create(16);
    if (!graph) {
        return 0;
    }
    
    switch (operation) {
        case 0: {
            /* Test node addition with various data */
            if (remaining_size > 0) {
                hyperdag_node_id_t node_id;
                hyperdag_graph_add_node(graph, remaining_data, remaining_size, &node_id);
            }
            break;
        }
        
        case 1: {
            /* Test multiple node additions */
            size_t num_nodes = remaining_size % 32; /* Limit to 32 nodes */
            for (size_t i = 0; i < num_nodes && i < remaining_size; i++) {
                hyperdag_node_id_t node_id;
                hyperdag_graph_add_node(graph, &remaining_data[i], 1, &node_id);
            }
            break;
        }
        
        case 2: {
            /* Test graph with initial capacity based on data */
            if (remaining_size > 0) {
                size_t capacity = remaining_data[0] % 128; /* Limit capacity */
                hyperdag_graph_destroy(graph);
                graph = hyperdag_graph_create(capacity);
                if (graph) {
                    hyperdag_node_id_t node_id;
                    hyperdag_graph_add_node(graph, NULL, 0, &node_id);
                }
            }
            break;
        }
        
        case 3: {
            /* Test mixed operations */
            for (size_t i = 0; i < remaining_size && i < 16; i++) {
                if (remaining_data[i] % 2 == 0) {
                    hyperdag_node_id_t node_id;
                    hyperdag_graph_add_node(graph, &remaining_data[i], 1, &node_id);
                } else {
                    /* Test getting counts */
                    hyperdag_graph_get_node_count(graph);
                    hyperdag_graph_get_edge_count(graph);
                }
            }
            break;
        }
    }
    
    /* Always clean up */
    hyperdag_graph_destroy(graph);
    
    return 0;
}