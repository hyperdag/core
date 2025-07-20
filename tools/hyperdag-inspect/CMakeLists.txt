# HyperDAG graph inspection tool

add_executable(hyperdag-inspect
    main.c
)

target_link_libraries(hyperdag-inspect
    PRIVATE hyperdag
)

target_include_directories(hyperdag-inspect
    PRIVATE
        ${CMAKE_SOURCE_DIR}/include
)

# Install the inspection tool
install(TARGETS hyperdag-inspect
    RUNTIME DESTINATION bin
)