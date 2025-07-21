# HyperDAG Tools
# Command-line utilities and development tools

# Placeholder for future tools
# add_subdirectory(hyperdag-cli)
# add_subdirectory(hyperdag-inspect)

# For now, create a minimal placeholder
add_executable(hyperdag_version_tool version_tool.c)
target_link_libraries(hyperdag_version_tool hyperdag_placeholder)

# Install tools
install(TARGETS hyperdag_version_tool
    RUNTIME DESTINATION bin
)