# Source directory CMakeLists.txt

# Core library
add_library(hyperdag
    core/graph.c
    core/node.c
    core/version.c
    runtime/executor.c
    platform/platform.c
)

# Set target properties
set_target_properties(hyperdag PROPERTIES
    C_STANDARD 23
    C_STANDARD_REQUIRED ON
    C_EXTENSIONS OFF
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
)

# Include directories
target_include_directories(hyperdag
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/internal
)

# Platform-specific sources
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_sources(hyperdag PRIVATE platform/linux.c)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    target_sources(hyperdag PRIVATE platform/macos.c)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    target_sources(hyperdag PRIVATE platform/windows.c)
endif()

# Link dependencies
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_link_libraries(hyperdag PRIVATE pthread)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    target_link_libraries(hyperdag PRIVATE ws2_32)
endif()

# Install targets
install(TARGETS hyperdag
    EXPORT HyperdagTargets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../include/
    DESTINATION include
    FILES_MATCHING PATTERN "*.h"
)