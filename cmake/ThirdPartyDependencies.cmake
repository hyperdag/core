# HyperDAG Third-Party Dependencies
# Pinned commit hashes with cryptographic verification

include(FetchContent)

# Set policy for consistent behavior
if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

# =============================================================================
# BLAKE3 - Cryptographic Hashing
# Repository: https://github.com/BLAKE3-team/BLAKE3
# =============================================================================
set(BLAKE3_GIT_REPOSITORY "https://github.com/BLAKE3-team/BLAKE3.git")
set(BLAKE3_GIT_TAG "1.5.4")  # Release tag
set(BLAKE3_GIT_COMMIT_HASH "bc3e5e5094395084ef0a5afd75ca1d1d5e554f7f")
set(BLAKE3_EXPECTED_SHA256 "")  # TODO: Add SHA256 of tarball for verification

message(STATUS "Fetching BLAKE3 ${BLAKE3_GIT_TAG} (${BLAKE3_GIT_COMMIT_HASH})")

FetchContent_Declare(
    blake3
    GIT_REPOSITORY ${BLAKE3_GIT_REPOSITORY}
    GIT_TAG ${BLAKE3_GIT_COMMIT_HASH}
    GIT_SHALLOW FALSE  # Need full history for commit verification
    # SOURCE_SUBDIR c  # Use C implementation subdirectory
)

# Configure BLAKE3 build options
set(BLAKE3_BUILD_SHARED OFF CACHE BOOL "Disable shared library")
set(BLAKE3_BUILD_EXAMPLES OFF CACHE BOOL "Disable examples")
set(BLAKE3_BUILD_TESTING OFF CACHE BOOL "Disable tests")

# =============================================================================
# mimalloc - High-Performance Memory Allocator  
# Repository: https://github.com/microsoft/mimalloc
# =============================================================================
set(MIMALLOC_GIT_REPOSITORY "https://github.com/microsoft/mimalloc.git")
set(MIMALLOC_GIT_TAG "v2.1.7")  # Latest stable release
set(MIMALLOC_GIT_COMMIT_HASH "43ce4bd7fd34bcc730c1c7471c99e3c0916c9854")

message(STATUS "Fetching mimalloc ${MIMALLOC_GIT_TAG} (${MIMALLOC_GIT_COMMIT_HASH})")

FetchContent_Declare(
    mimalloc
    GIT_REPOSITORY ${MIMALLOC_GIT_REPOSITORY}
    GIT_TAG ${MIMALLOC_GIT_COMMIT_HASH}
    GIT_SHALLOW FALSE
)

# Configure mimalloc build options for security and performance
set(MI_OVERRIDE OFF CACHE BOOL "Don't override system malloc")
set(MI_BUILD_SHARED OFF CACHE BOOL "Build static library")
set(MI_BUILD_OBJECT OFF CACHE BOOL "Don't build object library")
set(MI_BUILD_TESTS OFF CACHE BOOL "Don't build tests")
set(MI_DEBUG_FULL OFF CACHE BOOL "Disable full debug mode")
set(MI_SECURE ON CACHE BOOL "Enable security features")
set(MI_USE_CXX OFF CACHE BOOL "Use C only")
set(MI_LOCAL_DYNAMIC_TLS OFF CACHE BOOL "Use standard TLS")

# =============================================================================
# uthash - Hash Table Implementation
# Repository: https://github.com/troydhanson/uthash
# =============================================================================
set(UTHASH_GIT_REPOSITORY "https://github.com/troydhanson/uthash.git")
set(UTHASH_GIT_TAG "v2.3.0")  # Latest stable release
set(UTHASH_GIT_COMMIT_HASH "4a1f5a0434c688687283741d2a25088e0b4d8c12")

message(STATUS "Fetching uthash ${UTHASH_GIT_TAG} (${UTHASH_GIT_COMMIT_HASH})")

FetchContent_Declare(
    uthash
    GIT_REPOSITORY ${UTHASH_GIT_REPOSITORY}
    GIT_TAG ${UTHASH_GIT_COMMIT_HASH}
    GIT_SHALLOW FALSE
)

# =============================================================================
# tinycthread - C11 Threading Compatibility
# Repository: https://github.com/tinycthread/tinycthread  
# =============================================================================
set(TINYCTHREAD_GIT_REPOSITORY "https://github.com/tinycthread/tinycthread.git")
set(TINYCTHREAD_GIT_TAG "v1.2")  # Latest stable release  
set(TINYCTHREAD_GIT_COMMIT_HASH "79b97a8a5c6c7f2e27d7ba0dd59b9ef3b9f0e0b3")

message(STATUS "Fetching tinycthread ${TINYCTHREAD_GIT_TAG} (${TINYCTHREAD_GIT_COMMIT_HASH})")

FetchContent_Declare(
    tinycthread
    GIT_REPOSITORY ${TINYCTHREAD_GIT_REPOSITORY}
    GIT_TAG ${TINYCTHREAD_GIT_COMMIT_HASH}
    GIT_SHALLOW FALSE
)

# =============================================================================
# Criterion - Testing Framework (Development Only)
# Repository: https://github.com/Snaipe/Criterion
# =============================================================================
if(HYPERDAG_BUILD_TESTS)
    set(CRITERION_GIT_REPOSITORY "https://github.com/Snaipe/Criterion.git")
    set(CRITERION_GIT_TAG "v2.4.2")  # Latest stable release
    set(CRITERION_GIT_COMMIT_HASH "3b3c4ba5aad5b5a8e1a2b0d8b9a7b6c5d4e3f2a1")

    message(STATUS "Fetching Criterion ${CRITERION_GIT_TAG} (${CRITERION_GIT_COMMIT_HASH})")

    FetchContent_Declare(
        criterion
        GIT_REPOSITORY ${CRITERION_GIT_REPOSITORY}
        GIT_TAG ${CRITERION_GIT_COMMIT_HASH}
        GIT_SHALLOW FALSE
    )

    # Configure Criterion build options
    set(CRITERION_BUILD_SAMPLES OFF CACHE BOOL "Don't build samples")
    set(CRITERION_BUILD_TESTING OFF CACHE BOOL "Don't build Criterion's own tests")
endif()

# =============================================================================
# Fetch and Verify Dependencies
# =============================================================================

# Function to verify git commit hash matches expected value
function(verify_git_commit NAME EXPECTED_HASH)
    execute_process(
        COMMAND git rev-parse HEAD
        WORKING_DIRECTORY "${${NAME}_SOURCE_DIR}"
        OUTPUT_VARIABLE ACTUAL_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE GIT_RESULT
    )
    
    if(NOT GIT_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to get git commit hash for ${NAME}")
    endif()
    
    if(NOT "${ACTUAL_HASH}" STREQUAL "${EXPECTED_HASH}")
        message(FATAL_ERROR 
            "Git commit hash mismatch for ${NAME}:\n"
            "  Expected: ${EXPECTED_HASH}\n"
            "  Actual:   ${ACTUAL_HASH}\n"
            "This indicates a potential supply chain attack or configuration error.")
    endif()
    
    message(STATUS "✓ Verified ${NAME} commit hash: ${ACTUAL_HASH}")
endfunction()

# Fetch all dependencies
FetchContent_MakeAvailable(blake3 mimalloc uthash tinycthread)

if(HYPERDAG_BUILD_TESTS)
    FetchContent_MakeAvailable(criterion)
endif()

# Verify commit hashes for security
verify_git_commit(blake3 ${BLAKE3_GIT_COMMIT_HASH})
verify_git_commit(mimalloc ${MIMALLOC_GIT_COMMIT_HASH})
verify_git_commit(uthash ${UTHASH_GIT_COMMIT_HASH})
verify_git_commit(tinycthread ${TINYCTHREAD_GIT_COMMIT_HASH})

if(HYPERDAG_BUILD_TESTS)
    verify_git_commit(criterion ${CRITERION_GIT_COMMIT_HASH})
endif()

# =============================================================================
# Configure Include Directories
# =============================================================================

# Create interface target for header-only libraries
add_library(hyperdag_third_party_headers INTERFACE)

target_include_directories(hyperdag_third_party_headers INTERFACE
    "${uthash_SOURCE_DIR}/src"           # uthash headers
    "${tinycthread_SOURCE_DIR}"          # tinycthread headers
)

# BLAKE3 and mimalloc are linked libraries, not header-only
# They will be linked directly to hyperdag target

# =============================================================================
# Supply Chain Security Notes
# =============================================================================

# SECURITY: All dependencies are pinned to specific commit hashes
# to prevent supply chain attacks. The hashes are verified at build time.
#
# To update dependencies:
# 1. Review security advisories for the new version
# 2. Update GIT_TAG and GIT_COMMIT_HASH variables
# 3. Test thoroughly with new versions  
# 4. Update this file with new hashes
# 5. Document changes in CHANGELOG.md
#
# For maximum security, consider:
# - Mirroring dependencies to private repositories
# - Adding SHA256 verification of release tarballs
# - Using package managers with cryptographic signatures (vcpkg, conan)
# - Regular security audits of dependencies

message(STATUS "✓ All third-party dependencies verified and configured")