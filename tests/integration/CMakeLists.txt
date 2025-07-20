# Integration tests CMakeLists.txt

if(NOT CRITERION_FOUND)
    return()
endif()

# Integration test executable
add_executable(hyperdag_integration_tests
    test_integration.c
)

# Link against main library and Criterion
target_link_libraries(hyperdag_integration_tests
    PRIVATE
        hyperdag
        ${CRITERION_LIBRARIES}
)

# Include directories
target_include_directories(hyperdag_integration_tests
    PRIVATE
        ${CRITERION_INCLUDE_DIRS}
        ${CMAKE_SOURCE_DIR}/src/internal
)

# Compiler flags for tests
target_compile_options(hyperdag_integration_tests
    PRIVATE
        ${CRITERION_CFLAGS}
)

# Add to CTest
add_test(
    NAME integration_tests
    COMMAND hyperdag_integration_tests --verbose
)

# Set test properties
set_tests_properties(integration_tests PROPERTIES
    TIMEOUT 60
    LABELS "integration"
)