cmake_minimum_required(VERSION 3.28)
project(MetaGraph VERSION 1.0.0 LANGUAGES C)

# Critical policies for deterministic builds
cmake_policy(SET CMP0135 NEW)  # Timestamp extraction in FetchContent
set(CMAKE_POLICY_DEFAULT_CMP0141 NEW)  # MSVC debug info format

set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

# Modern CMake features
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_UNITY_BUILD ON)
set(CMAKE_UNITY_BUILD_BATCH_SIZE 16)  # Optimal for incremental builds
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)

# Development mode flag
option(METAGRAPH_DEV "Enable development mode (warnings as errors)" OFF)
option(METAGRAPH_SANITIZERS "Enable sanitizers in debug builds" OFF)
option(METAGRAPH_WERROR "Treat warnings as errors" OFF)
option(METAGRAPH_FUZZING "Enable fuzzing targets" OFF)
option(METAGRAPH_BUILD_TESTS "Build unit tests" ON)
option(METAGRAPH_BUILD_EXAMPLES "Build examples" OFF)

# Include custom CMake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Deterministic builds
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wdate-time")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ffile-prefix-map=${CMAKE_SOURCE_DIR}=.")

# Honor SOURCE_DATE_EPOCH for reproducible builds
if(DEFINED ENV{SOURCE_DATE_EPOCH})
    set_property(GLOBAL PROPERTY SOURCE_DATE_EPOCH $ENV{SOURCE_DATE_EPOCH})
endif()

# Deterministic output directories
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Include compiler flags and sanitizers
include(CompilerFlags)
include(Sanitizers)
include(StaticAnalysis)

# Project directories
add_subdirectory(src)

# Enable testing
if(METAGRAPH_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

# Tools
# add_subdirectory(tools)

# # Benchmarks
# if(CMAKE_BUILD_TYPE STREQUAL "Release")
#     add_subdirectory(benchmarks)
# endif()
