# EmbedBuildInfo.cmake
# Handles embedding git commit info and timestamps for reproducible builds

option(METAGRAPH_BUILD_REPRODUCIBLE "Embed git/timestamp info for reproducible builds" OFF)

# Initialize with empty values for dev builds
set(METAGRAPH_BUILD_TIMESTAMP "" CACHE INTERNAL "Build timestamp" FORCE)
set(METAGRAPH_BUILD_COMMIT_HASH "" CACHE INTERNAL "Git commit hash" FORCE)
set(METAGRAPH_BUILD_BRANCH "" CACHE INTERNAL "Git branch" FORCE)

if(METAGRAPH_BUILD_REPRODUCIBLE)
  find_package(Git REQUIRED QUIET)
  
  if(NOT GIT_FOUND)
    message(FATAL_ERROR "Git is required for reproducible builds")
  endif()
  
  # Optional: Check for dirty workspace
  execute_process(
    COMMAND ${GIT_EXECUTABLE} diff --quiet
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    RESULT_VARIABLE GIT_DIRTY
  )
  if(GIT_DIRTY AND GIT_DIRTY EQUAL 1)
    message(WARNING "Workspace has uncommitted changes - reproducible build may not be fully reproducible")
  endif()
  
  # Get git commit hash
  execute_process(
    COMMAND ${GIT_EXECUTABLE} rev-parse --short=40 HEAD
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE GIT_HASH
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  
  # Get git branch
  execute_process(
    COMMAND ${GIT_EXECUTABLE} rev-parse --abbrev-ref HEAD
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE GIT_BRANCH
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  
  # Get timestamp
  if(DEFINED ENV{SOURCE_DATE_EPOCH})
    set(BUILD_TS "$ENV{SOURCE_DATE_EPOCH}")
  else()
    string(TIMESTAMP BUILD_TS "%s" UTC)
  endif()
  
  # Set the cache variables with FORCE
  set(METAGRAPH_BUILD_TIMESTAMP "${BUILD_TS}" CACHE INTERNAL "Build timestamp" FORCE)
  set(METAGRAPH_BUILD_COMMIT_HASH "${GIT_HASH}" CACHE INTERNAL "Git commit hash" FORCE)
  set(METAGRAPH_BUILD_BRANCH "${GIT_BRANCH}" CACHE INTERNAL "Git branch" FORCE)
  
  message(STATUS "Embedding build info: ${GIT_BRANCH}@${GIT_HASH} ts=${BUILD_TS}")
endif()