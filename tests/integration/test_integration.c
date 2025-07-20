/**
 * @file test_integration.c
 * @brief Integration tests for HyperDAG
 */

#include <criterion/criterion.h>
#include "hyperdag/hyperdag.h"

Test(integration, basic_workflow) {
    /* Basic integration test workflow */
    hyperdag_graph_t *graph = hyperdag_graph_create(0);
    cr_assert_not_null(graph);
    
    /* Add some nodes */
    hyperdag_node_id_t node1, node2, node3;
    cr_assert_eq(hyperdag_graph_add_node(graph, NULL, 0, &node1), HYPERDAG_SUCCESS);
    cr_assert_eq(hyperdag_graph_add_node(graph, NULL, 0, &node2), HYPERDAG_SUCCESS);
    cr_assert_eq(hyperdag_graph_add_node(graph, NULL, 0, &node3), HYPERDAG_SUCCESS);
    
    cr_assert_eq(hyperdag_graph_get_node_count(graph), 3);
    
    hyperdag_graph_destroy(graph);
}