# MetaGraph Core Library
# Minimal implementation for CI validation

# Core library sources
set(METAGRAPH_SOURCES
    version.c
    error.c
)

# Create the core library with modern CMake patterns
add_library(metagraph STATIC)
target_sources(metagraph PRIVATE ${METAGRAPH_SOURCES})

# Enable position-independent code for shared library compatibility (not MSVC)
if(NOT MSVC)
  set_target_properties(metagraph PROPERTIES POSITION_INDEPENDENT_CODE ON)
endif()

# Propagate C23 requirement
target_compile_features(metagraph PUBLIC c_std_23)

# Configure include directories
target_include_directories(metagraph
  SYSTEM PUBLIC
    $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/generated>
  PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Expose reproducible build flag
target_compile_definitions(metagraph PUBLIC
    $<$<BOOL:${METAGRAPH_BUILD_REPRODUCIBLE}>:METAGRAPH_REPRO_BUILD>
)

# Create modern alias target
add_library(metagraph::metagraph ALIAS metagraph)

# Installation rules
install(TARGETS metagraph
    EXPORT metagraphTargets
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

# Install headers
install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/metagraph
    DESTINATION include
    FILES_MATCHING PATTERN "*.h"
)

# Install generated headers (marked OPTIONAL for first configure)
install(DIRECTORY ${CMAKE_BINARY_DIR}/generated/metagraph
    DESTINATION include
    OPTIONAL
)

# Export targets for find_package support
install(EXPORT metagraphTargets
    FILE metagraphTargets.cmake
    NAMESPACE metagraph::
    DESTINATION lib/cmake/metagraph
)

# Export build-tree targets for add_subdirectory users
export(EXPORT metagraphTargets
       FILE ${CMAKE_BINARY_DIR}/metagraphTargets.cmake
       NAMESPACE metagraph::)

# Generate and install package config files
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/metagraphConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

configure_package_config_file(
    "${CMAKE_SOURCE_DIR}/cmake/metagraphConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/metagraphConfig.cmake"
    INSTALL_DESTINATION lib/cmake/metagraph
    NO_SET_AND_CHECK_MACRO
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/metagraphConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/metagraphConfigVersion.cmake"
    DESTINATION lib/cmake/metagraph
)