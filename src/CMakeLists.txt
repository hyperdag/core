# MetaGraph Core Library
# Minimal implementation for CI validation

# Add core library when we have source files
# For now, create a placeholder target
add_library(mg_placeholder INTERFACE)
target_include_directories(mg_placeholder INTERFACE
    ${PROJECT_SOURCE_DIR}/include
)

# Install headers
install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/mg
    DESTINATION include
    FILES_MATCHING PATTERN "*.h"
)
