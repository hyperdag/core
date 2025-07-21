# HyperDAG Tests
# Minimal test setup for CI validation

# Create a basic test that always passes for now
add_executable(placeholder_test placeholder_test.c)
target_link_libraries(placeholder_test hyperdag_placeholder)

# Add the test to CTest
add_test(NAME placeholder_test COMMAND placeholder_test)

# Set test properties
set_tests_properties(placeholder_test PROPERTIES
    TIMEOUT 10
    LABELS "unit;placeholder"
)