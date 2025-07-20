/**
 * @file test_graph.c
 * @brief Unit tests for HyperDAG graph operations
 */

#include <criterion/criterion.h>
#include "hyperdag/hyperdag.h"

Test(graph, create_destroy) {
    hyperdag_graph_t *graph = hyperdag_graph_create(0);
    cr_assert_not_null(graph, "Graph creation should succeed");
    cr_assert_eq(hyperdag_graph_get_node_count(graph), 0, "New graph should have 0 nodes");
    
    hyperdag_graph_destroy(graph);
}

Test(graph, create_with_capacity) {
    hyperdag_graph_t *graph = hyperdag_graph_create(100);
    cr_assert_not_null(graph, "Graph creation with capacity should succeed");
    cr_assert_eq(hyperdag_graph_get_node_count(graph), 0, "New graph should have 0 nodes");
    
    hyperdag_graph_destroy(graph);
}

Test(graph, destroy_null) {
    /* Should not crash */
    hyperdag_graph_destroy(NULL);
}

Test(graph, add_node) {
    hyperdag_graph_t *graph = hyperdag_graph_create(0);
    cr_assert_not_null(graph);
    
    hyperdag_node_id_t node_id;
    hyperdag_error_t result = hyperdag_graph_add_node(graph, NULL, 0, &node_id);
    
    cr_assert_eq(result, HYPERDAG_SUCCESS, "Adding node should succeed");
    cr_assert_neq(node_id, 0, "Node ID should be non-zero");
    cr_assert_eq(hyperdag_graph_get_node_count(graph), 1, "Graph should have 1 node");
    
    hyperdag_graph_destroy(graph);
}

Test(graph, add_node_with_data) {
    hyperdag_graph_t *graph = hyperdag_graph_create(0);
    cr_assert_not_null(graph);
    
    int test_data = 42;
    hyperdag_node_id_t node_id;
    hyperdag_error_t result = hyperdag_graph_add_node(graph, &test_data, sizeof(test_data), &node_id);
    
    cr_assert_eq(result, HYPERDAG_SUCCESS, "Adding node with data should succeed");
    cr_assert_neq(node_id, 0, "Node ID should be non-zero");
    cr_assert_eq(hyperdag_graph_get_node_count(graph), 1, "Graph should have 1 node");
    
    hyperdag_graph_destroy(graph);
}

Test(graph, add_multiple_nodes) {
    hyperdag_graph_t *graph = hyperdag_graph_create(0);
    cr_assert_not_null(graph);
    
    const size_t num_nodes = 10;
    hyperdag_node_id_t node_ids[num_nodes];
    
    for (size_t i = 0; i < num_nodes; i++) {
        hyperdag_error_t result = hyperdag_graph_add_node(graph, NULL, 0, &node_ids[i]);
        cr_assert_eq(result, HYPERDAG_SUCCESS, "Adding node %zu should succeed", i);
        cr_assert_neq(node_ids[i], 0, "Node ID %zu should be non-zero", i);
    }
    
    cr_assert_eq(hyperdag_graph_get_node_count(graph), num_nodes, 
                 "Graph should have %zu nodes", num_nodes);
    
    /* Verify all IDs are unique */
    for (size_t i = 0; i < num_nodes; i++) {
        for (size_t j = i + 1; j < num_nodes; j++) {
            cr_assert_neq(node_ids[i], node_ids[j], 
                          "Node IDs should be unique");
        }
    }
    
    hyperdag_graph_destroy(graph);
}

Test(graph, null_pointer_checks) {
    hyperdag_node_id_t node_id;
    
    /* Test NULL graph parameter */
    hyperdag_error_t result = hyperdag_graph_add_node(NULL, NULL, 0, &node_id);
    cr_assert_eq(result, HYPERDAG_ERROR_NULL_POINTER, 
                 "NULL graph should return NULL_POINTER error");
    
    /* Test NULL node_id parameter */
    hyperdag_graph_t *graph = hyperdag_graph_create(0);
    result = hyperdag_graph_add_node(graph, NULL, 0, NULL);
    cr_assert_eq(result, HYPERDAG_ERROR_NULL_POINTER, 
                 "NULL node_id should return NULL_POINTER error");
    
    hyperdag_graph_destroy(graph);
}

Test(graph, get_counts_null_graph) {
    cr_assert_eq(hyperdag_graph_get_node_count(NULL), 0, 
                 "Node count for NULL graph should be 0");
    cr_assert_eq(hyperdag_graph_get_edge_count(NULL), 0, 
                 "Edge count for NULL graph should be 0");
}

Test(graph, error_strings) {
    cr_assert_str_eq(hyperdag_error_string(HYPERDAG_SUCCESS), "Success");
    cr_assert_str_eq(hyperdag_error_string(HYPERDAG_ERROR_NULL_POINTER), "Null pointer argument");
    cr_assert_str_eq(hyperdag_error_string(HYPERDAG_ERROR_OUT_OF_MEMORY), "Out of memory");
    cr_assert_str_eq(hyperdag_error_string((hyperdag_error_t)999), "Unknown error");
}