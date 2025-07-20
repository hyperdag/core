# Tests CMakeLists.txt

# Find Criterion testing framework
find_package(PkgConfig QUIET)
if(PKG_CONFIG_FOUND)
    pkg_check_modules(CRITERION criterion)
endif()

if(NOT CRITERION_FOUND)
    # Try to find Criterion manually
    find_path(CRITERION_INCLUDE_DIR criterion/criterion.h)
    find_library(CRITERION_LIBRARY criterion)
    
    if(CRITERION_INCLUDE_DIR AND CRITERION_LIBRARY)
        set(CRITERION_FOUND TRUE)
        set(CRITERION_INCLUDE_DIRS ${CRITERION_INCLUDE_DIR})
        set(CRITERION_LIBRARIES ${CRITERION_LIBRARY})
    endif()
endif()

if(CRITERION_FOUND)
    message(STATUS "Criterion testing framework found")
    
    # Unit tests
    add_subdirectory(unit)
    
    # Integration tests
    add_subdirectory(integration)
    
    # Create test target
    add_custom_target(test-all
        COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
        DEPENDS hyperdag_unit_tests hyperdag_integration_tests
        COMMENT "Running all tests"
    )
else()
    message(WARNING "Criterion testing framework not found - tests will not be built")
    message(STATUS "Install Criterion: sudo apt install libcriterion-dev (Ubuntu) or brew install criterion (macOS)")
endif()

# Fuzzing tests (requires Clang with fuzzing support)
if(HYPERDAG_FUZZING)
    add_subdirectory(fuzz)
endif()

# Benchmarks
add_subdirectory(benchmarks)