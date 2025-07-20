/**
 * @file fuzz_node_ops.c
 * @brief Fuzzing tests for HyperDAG node operations
 */

#include "hyperdag/hyperdag.h"
#include <stdint.h>
#include <stddef.h>
#include <string.h>

/* Fuzzing harness for node-specific operations */
int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    if (size < 2) {
        return 0;
    }
    
    hyperdag_graph_t *graph = hyperdag_graph_create(0);
    if (!graph) {
        return 0;
    }
    
    /* Create a few nodes first */
    hyperdag_node_id_t node_ids[8];
    size_t num_nodes = (data[0] % 8) + 1; /* 1-8 nodes */
    
    for (size_t i = 0; i < num_nodes && i + 1 < size; i++) {
        uint8_t node_data = data[i + 1];
        hyperdag_error_t result = hyperdag_graph_add_node(graph, &node_data, 1, &node_ids[i]);
        if (result != HYPERDAG_SUCCESS) {
            break;
        }
    }
    
    /* Test various node operations with remaining data */
    size_t remaining_start = num_nodes + 1;
    for (size_t i = remaining_start; i < size; i += 2) {
        if (i + 1 >= size) break;
        
        uint8_t op = data[i] % 3;
        uint8_t param = data[i + 1];
        
        switch (op) {
            case 0: {
                /* Test adding more nodes */
                hyperdag_node_id_t new_id;
                hyperdag_graph_add_node(graph, &param, 1, &new_id);
                break;
            }
            
            case 1: {
                /* Test getting node/edge counts */
                hyperdag_graph_get_node_count(graph);
                hyperdag_graph_get_edge_count(graph);
                break;
            }
            
            case 2: {
                /* Test adding nodes with different data sizes */
                if (i + 3 < size) {
                    hyperdag_node_id_t new_id;
                    size_t data_size = param % 8; /* Limit data size */
                    hyperdag_graph_add_node(graph, &data[i], data_size, &new_id);
                }
                break;
            }
        }
    }
    
    hyperdag_graph_destroy(graph);
    
    return 0;
}