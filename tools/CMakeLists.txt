# MetaGraph Tools
# Command-line utilities and development tools

# Placeholder for future tools
# add_subdirectory(mg-cli)
# add_subdirectory(mg-inspect)

# Create minimal placeholders
add_executable(mg_version_tool version_tool.c)
target_link_libraries(mg_version_tool mg_placeholder)

add_executable(mg-cli mg-cli.c)
target_link_libraries(mg-cli mg_placeholder)

# Benchmark tool for performance validation
add_executable(mg_benchmarks benchmark_tool.c)
target_link_libraries(mg_benchmarks metagraph)

# Install tools
install(TARGETS mg_version_tool mg_benchmarks
    RUNTIME DESTINATION bin
)
