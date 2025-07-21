# HyperDAG Core Library
# Minimal implementation for CI validation

# Add core library when we have source files
# For now, create a placeholder target
add_library(hyperdag_placeholder INTERFACE)
target_include_directories(hyperdag_placeholder INTERFACE
    ${PROJECT_SOURCE_DIR}/include
)

# Install headers
install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/hyperdag
    DESTINATION include
    FILES_MATCHING PATTERN "*.h"
)