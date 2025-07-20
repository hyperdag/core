/**
 * @file bench_graph.c
 * @brief Performance benchmarks for HyperDAG graph operations
 */

#include "hyperdag/hyperdag.h"
#include <stdio.h>
#include <time.h>
#include <stdlib.h>

static double get_time_diff(struct timespec start, struct timespec end)
{
    return (double)(end.tv_sec - start.tv_sec) + 
           (double)(end.tv_nsec - start.tv_nsec) / 1000000000.0;
}

static void benchmark_graph_creation(void)
{
    const size_t num_iterations = 10000;
    struct timespec start, end;
    
    clock_gettime(CLOCK_MONOTONIC, &start);
    
    for (size_t i = 0; i < num_iterations; i++) {
        hyperdag_graph_t *graph = hyperdag_graph_create(0);
        hyperdag_graph_destroy(graph);
    }
    
    clock_gettime(CLOCK_MONOTONIC, &end);
    
    double elapsed = get_time_diff(start, end);
    printf("Graph creation/destruction: %.2f µs per operation\n", 
           (elapsed / num_iterations) * 1000000);
}

static void benchmark_node_addition(void)
{
    const size_t num_nodes = 100000;
    hyperdag_graph_t *graph = hyperdag_graph_create(num_nodes);
    struct timespec start, end;
    
    clock_gettime(CLOCK_MONOTONIC, &start);
    
    for (size_t i = 0; i < num_nodes; i++) {
        hyperdag_node_id_t node_id;
        hyperdag_graph_add_node(graph, NULL, 0, &node_id);
    }
    
    clock_gettime(CLOCK_MONOTONIC, &end);
    
    double elapsed = get_time_diff(start, end);
    printf("Node addition: %.2f µs per operation (%zu nodes)\n", 
           (elapsed / num_nodes) * 1000000, num_nodes);
    
    hyperdag_graph_destroy(graph);
}

int main(void)
{
    printf("HyperDAG Performance Benchmarks\n");
    printf("================================\n\n");
    
    benchmark_graph_creation();
    benchmark_node_addition();
    
    return 0;
}