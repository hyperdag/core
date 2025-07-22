# MetaGraph Core Library
# Minimal implementation for CI validation

# Core library sources
set(METAGRAPH_SOURCES
    version.c
)

# Create the core library
add_library(metagraph STATIC ${METAGRAPH_SOURCES})
target_include_directories(metagraph PUBLIC
    ${PROJECT_SOURCE_DIR}/include
)

# Keep the placeholder for compatibility
add_library(mg_placeholder INTERFACE)
target_link_libraries(mg_placeholder INTERFACE metagraph)

# Install headers
install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/mg
    DESTINATION include
    FILES_MATCHING PATTERN "*.h"
)
