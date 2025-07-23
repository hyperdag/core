cmake_minimum_required(VERSION 3.28)
project(MetaGraph VERSION 0.1.0 LANGUAGES C)

# -----------------------------------------------------------------------------
# Version extraction
string(REGEX MATCHALL "[0-9]+" _ver "${PROJECT_VERSION}")
list(GET _ver 0 METAGRAPH_VERSION_MAJOR)
list(GET _ver 1 METAGRAPH_VERSION_MINOR)
list(GET _ver 2 METAGRAPH_VERSION_PATCH)
set(METAGRAPH_VERSION_STRING "${PROJECT_VERSION}")
set(METAGRAPH_BUNDLE_FORMAT_VERSION 1 CACHE INTERNAL "Bundle format version")
# -----------------------------------------------------------------------------

# Critical policies for deterministic builds
cmake_policy(SET CMP0135 NEW)  # Timestamp extraction in FetchContent
cmake_policy(SET CMP0141 NEW)  # MSVC debug info format

set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

# Modern CMake features
# Only export compile commands for top-level builds
if(CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
  set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
endif()

# Unity build and IPO (enabled for compatible compilers and generators)
if((CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "Clang")
   AND CMAKE_GENERATOR MATCHES "Ninja|Unix Makefiles")
  set(CMAKE_UNITY_BUILD ON)
  set(CMAKE_UNITY_BUILD_BATCH_SIZE 16)  # Optimal for incremental builds
  set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
endif()

# Development mode flag
option(METAGRAPH_DEV "Enable development mode (warnings as errors)" OFF)
option(METAGRAPH_SANITIZERS "Enable sanitizers in debug builds" OFF)
option(METAGRAPH_WERROR "Treat warnings as errors" OFF)
option(METAGRAPH_FUZZING "Enable fuzzing targets" OFF)
option(METAGRAPH_BUILD_TESTS "Build unit tests" ON)
option(METAGRAPH_BUILD_EXAMPLES "Build examples" OFF)

# Include custom CMake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Handle build info embedding
include(EmbedBuildInfo)

# Generate version header from template
configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/include/metagraph/version.h.in
  ${CMAKE_BINARY_DIR}/generated/metagraph/version.h
  @ONLY
)

# Note: Generated header path will be added to targets in src/CMakeLists.txt

# Verify Git info was populated in reproducible builds
if(METAGRAPH_BUILD_REPRODUCIBLE AND (NOT METAGRAPH_BUILD_COMMIT_HASH))
  message(FATAL_ERROR "EmbedBuildInfo failed to inject Git metadata")
endif()

# Deterministic builds
add_compile_options("$<$<NOT:$<BOOL:${METAGRAPH_BUILD_REPRODUCIBLE}>>:-Wdate-time>")
if(NOT MSVC)
  add_compile_options(-ffile-prefix-map=${CMAKE_SOURCE_DIR}=.)
endif()

# Forward reproducible build flag to consumers
add_compile_definitions($<$<BOOL:${METAGRAPH_BUILD_REPRODUCIBLE}>:METAGRAPH_REPRO_BUILD>)

# Honor SOURCE_DATE_EPOCH for reproducible builds
if(DEFINED ENV{SOURCE_DATE_EPOCH})
    set_property(GLOBAL PROPERTY SOURCE_DATE_EPOCH $ENV{SOURCE_DATE_EPOCH})
elseif(METAGRAPH_BUILD_REPRODUCIBLE)
    message(FATAL_ERROR "Set SOURCE_DATE_EPOCH environment variable for reproducible builds")
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
add_subdirectory(tools)

# # Benchmarks
# if(CMAKE_BUILD_TYPE STREQUAL "Release")
#     add_subdirectory(benchmarks)
# endif()