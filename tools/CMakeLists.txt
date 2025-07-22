# Meta-Graph Tools
# Command-line utilities and development tools

# Placeholder for future tools
# add_subdirectory(mg-cli)
# add_subdirectory(mg-inspect)

# For now, create a minimal placeholder
add_executable(mg_version_tool version_tool.c)
target_link_libraries(mg_version_tool mg_placeholder)

# Install tools
install(TARGETS mg_version_tool
    RUNTIME DESTINATION bin
)
