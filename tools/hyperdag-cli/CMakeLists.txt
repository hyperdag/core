# HyperDAG CLI tool

add_executable(hyperdag-cli
    main.c
)

target_link_libraries(hyperdag-cli
    PRIVATE hyperdag
)

target_include_directories(hyperdag-cli
    PRIVATE
        ${CMAKE_SOURCE_DIR}/include
)

# Install the CLI tool
install(TARGETS hyperdag-cli
    RUNTIME DESTINATION bin
)