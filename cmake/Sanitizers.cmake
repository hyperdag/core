# Sanitizers.cmake - Memory safety and sanitizer configurations

if(NOT HYPERDAG_SANITIZERS)
    return()
endif()

# Only enable sanitizers in Debug/RelWithDebInfo builds
if(NOT CMAKE_BUILD_TYPE MATCHES "Debug|RelWithDebInfo")
    message(STATUS "Sanitizers are only enabled in Debug/RelWithDebInfo builds")
    return()
endif()

# Don't enable sanitizers with MSVC (limited support)
if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    message(WARNING "Sanitizers are not fully supported with MSVC")
    return()
endif()

set(SANITIZER_FLAGS "")

# AddressSanitizer (ASAN) - Default choice
option(HYPERDAG_ASAN "Enable AddressSanitizer" ON)
if(HYPERDAG_ASAN)
    list(APPEND SANITIZER_FLAGS
        -fsanitize=address
        -fsanitize-address-use-after-scope
        -fno-omit-frame-pointer
    )
    message(STATUS "AddressSanitizer enabled")
endif()

# UndefinedBehaviorSanitizer (UBSAN)
option(HYPERDAG_UBSAN "Enable UndefinedBehaviorSanitizer" ON)
if(HYPERDAG_UBSAN)
    list(APPEND SANITIZER_FLAGS
        -fsanitize=undefined
        -fsanitize=float-divide-by-zero
        -fsanitize=float-cast-overflow
        -fsanitize=integer
        -fno-sanitize-recover=all
    )
    message(STATUS "UndefinedBehaviorSanitizer enabled")
endif()

# ThreadSanitizer (TSAN) - Mutually exclusive with ASAN
option(HYPERDAG_TSAN "Enable ThreadSanitizer (excludes ASAN)" OFF)
if(HYPERDAG_TSAN)
    if(HYPERDAG_ASAN)
        message(FATAL_ERROR "ThreadSanitizer and AddressSanitizer are mutually exclusive")
    endif()
    
    list(APPEND SANITIZER_FLAGS -fsanitize=thread)
    message(STATUS "ThreadSanitizer enabled")
endif()

# MemorySanitizer (MSAN) - Clang only, mutually exclusive with ASAN/TSAN
option(HYPERDAG_MSAN "Enable MemorySanitizer (Clang only, excludes ASAN/TSAN)" OFF)
if(HYPERDAG_MSAN)
    if(NOT CMAKE_C_COMPILER_ID STREQUAL "Clang")
        message(FATAL_ERROR "MemorySanitizer is only supported with Clang")
    endif()
    
    if(HYPERDAG_ASAN OR HYPERDAG_TSAN)
        message(FATAL_ERROR "MemorySanitizer is mutually exclusive with ASAN/TSAN")
    endif()
    
    list(APPEND SANITIZER_FLAGS
        -fsanitize=memory
        -fsanitize-memory-track-origins=2
    )
    message(STATUS "MemorySanitizer enabled")
endif()

# Hardware-Assisted Sanitizers (ARM64/Apple Silicon)
if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
    # HWASan - Near-zero overhead on ARM64
    option(HYPERDAG_HWASAN "Enable HWAddressSanitizer (ARM64 only)" OFF)
    if(HYPERDAG_HWASAN)
        if(HYPERDAG_ASAN)
            message(FATAL_ERROR "HWAddressSanitizer and AddressSanitizer are mutually exclusive")
        endif()
        
        list(APPEND SANITIZER_FLAGS -fsanitize=hwaddress)
        message(STATUS "HWAddressSanitizer enabled")
    endif()
    
    # Memory Tagging Extension (MTE) - ARM servers
    option(HYPERDAG_MTE "Enable Memory Tagging Extension (ARM64 servers)" OFF)
    if(HYPERDAG_MTE)
        list(APPEND SANITIZER_FLAGS
            -fsanitize=memtag
            -march=armv8.5-a+memtag
        )
        message(STATUS "Memory Tagging Extension enabled")
    endif()
    
    # ShadowCallStack
    option(HYPERDAG_SHADOW_CALL_STACK "Enable ShadowCallStack (ARM64)" OFF)
    if(HYPERDAG_SHADOW_CALL_STACK)
        list(APPEND SANITIZER_FLAGS
            -fsanitize=shadow-call-stack
            -ffixed-x18  # Reserve x18 for shadow stack
        )
        message(STATUS "ShadowCallStack enabled")
    endif()
endif()

# Apply sanitizer flags
if(SANITIZER_FLAGS)
    add_compile_options(${SANITIZER_FLAGS})
    add_link_options(${SANITIZER_FLAGS})
    
    # Environment setup for sanitizers
    set(ASAN_OPTIONS "abort_on_error=1:halt_on_error=1:print_stats=1")
    set(UBSAN_OPTIONS "abort_on_error=1:halt_on_error=1:print_stacktrace=1")
    set(TSAN_OPTIONS "abort_on_error=1:halt_on_error=1:history_size=7")
    set(MSAN_OPTIONS "abort_on_error=1:halt_on_error=1:print_stats=1")
    
    message(STATUS "Sanitizer flags: ${SANITIZER_FLAGS}")
    message(STATUS "Remember to set environment variables:")
    message(STATUS "  export ASAN_OPTIONS=\"${ASAN_OPTIONS}\"")
    message(STATUS "  export UBSAN_OPTIONS=\"${UBSAN_OPTIONS}\"")
    message(STATUS "  export TSAN_OPTIONS=\"${TSAN_OPTIONS}\"")
    message(STATUS "  export MSAN_OPTIONS=\"${MSAN_OPTIONS}\"")
endif()

# Valgrind support
find_program(VALGRIND_PROGRAM valgrind)
if(VALGRIND_PROGRAM)
    message(STATUS "Valgrind found: ${VALGRIND_PROGRAM}")
    
    # Custom target for Valgrind testing
    add_custom_target(valgrind
        COMMAND ${VALGRIND_PROGRAM}
            --leak-check=full
            --show-leak-kinds=all
            --track-origins=yes
            --verbose
            --log-file=valgrind-out.txt
            $<TARGET_FILE:hyperdag_tests>
        DEPENDS hyperdag_tests
        COMMENT "Running tests under Valgrind"
    )
endif()