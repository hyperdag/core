# StaticAnalysis.cmake - Static analysis tools integration

# clang-tidy
find_program(CLANG_TIDY_PROGRAM clang-tidy)
if(CLANG_TIDY_PROGRAM)
    message(STATUS "clang-tidy found: ${CLANG_TIDY_PROGRAM}")

    # Enable clang-tidy for all targets in development mode
    if(METAGRAPH_DEV)
        # Ensure Unity build is disabled for clang-tidy compatibility
        set(CMAKE_UNITY_BUILD OFF)
        set(CMAKE_C_CLANG_TIDY ${CLANG_TIDY_PROGRAM} 
            --config-file=${CMAKE_SOURCE_DIR}/.clang-tidy
            --header-filter=.*
            -p=${CMAKE_BINARY_DIR})
    endif()

    # Custom target for running clang-tidy manually
    add_custom_target(clang-tidy
        COMMAND ${CLANG_TIDY_PROGRAM}
            -p=${CMAKE_BINARY_DIR}
            --format-style=file
            --header-filter=".*"
            ${CMAKE_SOURCE_DIR}/src/*.c
            ${CMAKE_SOURCE_DIR}/include/**/*.h
        COMMENT "Running clang-tidy analysis"
        VERBATIM
    )
endif()

# Cppcheck
find_program(CPPCHECK_PROGRAM cppcheck)
if(CPPCHECK_PROGRAM)
    message(STATUS "Cppcheck found: ${CPPCHECK_PROGRAM}")

    add_custom_target(cppcheck
        COMMAND ${CPPCHECK_PROGRAM}
            --enable=all
            --error-exitcode=1
            --inline-suppr
            --std=c23
            --suppress=missingIncludeSystem
            --suppress=unmatchedSuppression
            --project=${CMAKE_BINARY_DIR}/compile_commands.json
            --cppcheck-build-dir=${CMAKE_BINARY_DIR}/cppcheck
        COMMENT "Running Cppcheck analysis"
        VERBATIM
    )

    # Create cppcheck build directory
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/cppcheck)
endif()

# Facebook Infer
find_program(INFER_PROGRAM infer)
if(INFER_PROGRAM)
    message(STATUS "Facebook Infer found: ${INFER_PROGRAM}")

    add_custom_target(infer
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/infer-out
        COMMAND ${INFER_PROGRAM} run --compilation-database ${CMAKE_BINARY_DIR}/compile_commands.json
        COMMAND ${INFER_PROGRAM} explore --html
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Running Facebook Infer analysis"
        VERBATIM
    )
endif()

# PVS-Studio (if available)
find_program(PVS_STUDIO_ANALYZER pvs-studio-analyzer)
find_program(PLOG_CONVERTER plog-converter)
if(PVS_STUDIO_ANALYZER AND PLOG_CONVERTER)
    message(STATUS "PVS-Studio found: ${PVS_STUDIO_ANALYZER}")

    add_custom_target(pvs-studio
        COMMAND ${PVS_STUDIO_ANALYZER} analyze
            --output-file ${CMAKE_BINARY_DIR}/PVS-Studio.log
            --source-tree-root ${CMAKE_SOURCE_DIR}
            --exclude-path ${CMAKE_SOURCE_DIR}/tests
            --jobs 8
        COMMAND ${PLOG_CONVERTER}
            -a GA:1,2,3
            -t errorfile
            -o ${CMAKE_BINARY_DIR}/PVS-Studio-report.txt
            ${CMAKE_BINARY_DIR}/PVS-Studio.log
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Running PVS-Studio analysis"
        VERBATIM
    )
endif()

# Frama-C EVA (if available)
find_program(FRAMA_C_PROGRAM frama-c)
if(FRAMA_C_PROGRAM)
    message(STATUS "Frama-C found: ${FRAMA_C_PROGRAM}")

    add_custom_target(frama-c
        COMMAND ${FRAMA_C_PROGRAM}
            -eva
            -eva-precision 11
            -eva-mlevel 4096
            -eva-slevel 1000
            -machdep x86_64
            -cpp-extra-args=-I${CMAKE_SOURCE_DIR}/include
            ${CMAKE_SOURCE_DIR}/src/*.c
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Running Frama-C EVA analysis"
        VERBATIM
    )
endif()

# Include What You Use (IWYU)
find_program(IWYU_PROGRAM include-what-you-use)
if(IWYU_PROGRAM)
    message(STATUS "include-what-you-use found: ${IWYU_PROGRAM}")

    # Enable IWYU for all targets in development mode
    if(METAGRAPH_DEV)
        set(CMAKE_C_INCLUDE_WHAT_YOU_USE ${IWYU_PROGRAM})
    endif()
endif()

# Combine all static analysis targets
add_custom_target(static-analysis
    COMMENT "Running all available static analysis tools"
)

if(TARGET clang-tidy)
    add_dependencies(static-analysis clang-tidy)
endif()

if(TARGET cppcheck)
    add_dependencies(static-analysis cppcheck)
endif()

if(TARGET infer)
    add_dependencies(static-analysis infer)
endif()

if(TARGET pvs-studio)
    add_dependencies(static-analysis pvs-studio)
endif()

if(TARGET frama-c)
    add_dependencies(static-analysis frama-c)
endif()

# Code coverage (gcov/llvm-cov)
option(METAGRAPH_COVERAGE "Enable code coverage" OFF)
if(METAGRAPH_COVERAGE)
    if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
        add_compile_options(-fprofile-arcs -ftest-coverage)
        add_link_options(-lgcov --coverage)
    elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
        add_compile_options(-fprofile-instr-generate -fcoverage-mapping)
        add_link_options(-fprofile-instr-generate)
    endif()

    message(STATUS "Code coverage enabled")
endif()

# Profile-Guided Optimization support
option(METAGRAPH_PGO "Enable Profile-Guided Optimization" OFF)
if(METAGRAPH_PGO AND CMAKE_BUILD_TYPE STREQUAL "Release")
    if(CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "Clang")
        add_compile_options(-fprofile-generate)
        add_link_options(-fprofile-generate)
        message(STATUS "Profile-Guided Optimization (generate phase) enabled")
        message(STATUS "Run your benchmarks, then reconfigure with -DMETAGRAPH_PGO_USE=ON")
    endif()
endif()

option(METAGRAPH_PGO_USE "Use Profile-Guided Optimization data" OFF)
if(METAGRAPH_PGO_USE AND CMAKE_BUILD_TYPE STREQUAL "Release")
    if(CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "Clang")
        add_compile_options(-fprofile-use)
        add_link_options(-fprofile-use)
        message(STATUS "Profile-Guided Optimization (use phase) enabled")
    endif()
endif()
