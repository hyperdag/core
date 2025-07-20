# Unit tests CMakeLists.txt

if(NOT CRITERION_FOUND)
    return()
endif()

# Unit test executable
add_executable(hyperdag_unit_tests
    test_graph.c
    test_node.c
    test_version.c
)

# Link against main library and Criterion
target_link_libraries(hyperdag_unit_tests
    PRIVATE
        hyperdag
        ${CRITERION_LIBRARIES}
)

# Include directories
target_include_directories(hyperdag_unit_tests
    PRIVATE
        ${CRITERION_INCLUDE_DIRS}
        ${CMAKE_SOURCE_DIR}/src/internal
)

# Compiler flags for tests
target_compile_options(hyperdag_unit_tests
    PRIVATE
        ${CRITERION_CFLAGS}
)

# Add to CTest
add_test(
    NAME unit_tests
    COMMAND hyperdag_unit_tests --verbose
)

# Set test properties
set_tests_properties(unit_tests PROPERTIES
    TIMEOUT 30
    LABELS "unit"
)