# Fuzzing tests CMakeLists.txt

if(NOT HYPERDAG_FUZZING)
    return()
endif()

# Check if we have fuzzing support
if(NOT CMAKE_C_COMPILER_ID STREQUAL "Clang")
    message(WARNING "Fuzzing requires Clang compiler")
    return()
endif()

# Fuzzing flags
set(FUZZ_FLAGS
    -g
    -O1
    -fsanitize=fuzzer,address,undefined
    -fno-omit-frame-pointer
)

# Graph fuzzing target
add_executable(fuzz_graph
    fuzz_graph.c
)

target_link_libraries(fuzz_graph
    PRIVATE hyperdag
)

target_compile_options(fuzz_graph
    PRIVATE ${FUZZ_FLAGS}
)

target_link_options(fuzz_graph
    PRIVATE ${FUZZ_FLAGS}
)

target_include_directories(fuzz_graph
    PRIVATE
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_SOURCE_DIR}/src/internal
)

# Node operations fuzzing target
add_executable(fuzz_node_ops
    fuzz_node_ops.c
)

target_link_libraries(fuzz_node_ops
    PRIVATE hyperdag
)

target_compile_options(fuzz_node_ops
    PRIVATE ${FUZZ_FLAGS}
)

target_link_options(fuzz_node_ops
    PRIVATE ${FUZZ_FLAGS}
)

target_include_directories(fuzz_node_ops
    PRIVATE
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_SOURCE_DIR}/src/internal
)

# Custom fuzzing target
add_custom_target(fuzz
    COMMENT "Running fuzzing tests"
)

add_dependencies(fuzz fuzz_graph fuzz_node_ops)

# Individual fuzzing targets
add_custom_target(fuzz-graph
    COMMAND $<TARGET_FILE:fuzz_graph> -max_total_time=300 -print_final_stats=1
    DEPENDS fuzz_graph
    COMMENT "Fuzzing graph operations for 5 minutes"
)

add_custom_target(fuzz-node-ops
    COMMAND $<TARGET_FILE:fuzz_node_ops> -max_total_time=300 -print_final_stats=1
    DEPENDS fuzz_node_ops
    COMMENT "Fuzzing node operations for 5 minutes"
)