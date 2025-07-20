/**
 * @file version.h
 * @brief Version information for HyperDAG library
 * 
 * This header provides compile-time and runtime version information
 * including API versions, bundle format compatibility, and build details.
 * 
 * @copyright Apache License 2.0 - see LICENSE file for details
 */

#ifndef HYPERDAG_VERSION_H
#define HYPERDAG_VERSION_H

#ifdef __cplusplus
extern "C" {
#endif

// =============================================================================
// API Version Information (from VERSION file)
// =============================================================================

#define HYPERDAG_API_VERSION_MAJOR 0
#define HYPERDAG_API_VERSION_MINOR 1
#define HYPERDAG_API_VERSION_PATCH 0
#define HYPERDAG_API_VERSION_STRING "0.1.0-alpha"

// Legacy compatibility (maps to API version)
#define HYPERDAG_VERSION_MAJOR HYPERDAG_API_VERSION_MAJOR
#define HYPERDAG_VERSION_MINOR HYPERDAG_API_VERSION_MINOR
#define HYPERDAG_VERSION_PATCH HYPERDAG_API_VERSION_PATCH
#define HYPERDAG_VERSION_STRING HYPERDAG_API_VERSION_STRING

// =============================================================================
// Binary Bundle Format Version
// =============================================================================

#define HYPERDAG_BUNDLE_FORMAT_VERSION 1
#define HYPERDAG_BUNDLE_FORMAT_UUID "550e8400-e29b-41d4-a716-446655440000"

// =============================================================================
// Build Information (populated by CMake)
// =============================================================================

#ifndef HYPERDAG_BUILD_TIMESTAMP
#define HYPERDAG_BUILD_TIMESTAMP "@BUILD_TIMESTAMP@"
#endif

#ifndef HYPERDAG_BUILD_COMMIT_HASH
#define HYPERDAG_BUILD_COMMIT_HASH "@GIT_COMMIT_HASH@"
#endif

#ifndef HYPERDAG_BUILD_BRANCH
#define HYPERDAG_BUILD_BRANCH "@GIT_BRANCH@"
#endif

// Fallback to compiler macros if CMake variables not available
#define HYPERDAG_BUILD_DATE __DATE__
#define HYPERDAG_BUILD_TIME __TIME__

// =============================================================================
// Minimum Requirements
// =============================================================================

#define HYPERDAG_MIN_C_STANDARD 23
#define HYPERDAG_MIN_CMAKE_VERSION "3.28"

// =============================================================================
// Feature Flags for Forward Compatibility
// =============================================================================

#define HYPERDAG_FEATURE_VERSIONED_BUNDLES 1
#define HYPERDAG_FEATURE_DELTA_PATCHES 0     // Reserved for future
#define HYPERDAG_FEATURE_COMPRESSION_V2 0    // Reserved for future

// =============================================================================
// Runtime Version API
// =============================================================================

/**
 * @brief Get API major version number
 * @return Major version number
 */
int hyperdag_version_major(void);

/**
 * @brief Get API minor version number
 * @return Minor version number
 */
int hyperdag_version_minor(void);

/**
 * @brief Get API patch version number
 * @return Patch version number
 */
int hyperdag_version_patch(void);

/**
 * @brief Get API version string
 * @return Pointer to static version string (e.g., "0.1.0-alpha")
 */
const char* hyperdag_version_string(void);

/**
 * @brief Get bundle format version
 * @return Bundle format version number
 */
int hyperdag_bundle_format_version(void);

/**
 * @brief Get bundle format UUID
 * @return Pointer to static UUID string
 */
const char* hyperdag_bundle_format_uuid(void);

/**
 * @brief Get build information
 * @return Pointer to static string containing build timestamp and commit
 */
const char* hyperdag_build_info(void);

/**
 * @brief Get detailed build information
 * @param timestamp Output parameter for build timestamp (can be NULL)
 * @param commit_hash Output parameter for git commit hash (can be NULL)
 * @param branch Output parameter for git branch (can be NULL)
 */
void hyperdag_build_details(const char** timestamp, const char** commit_hash, const char** branch);

/**
 * @brief Check if a feature is available
 * @param feature_name Name of the feature to check
 * @return 1 if feature is available, 0 otherwise
 */
int hyperdag_feature_available(const char* feature_name);

/**
 * @brief Check API compatibility
 * @param required_major Required major version
 * @param required_minor Required minor version
 * @param required_patch Required patch version
 * @return 1 if API is compatible, 0 otherwise
 */
int hyperdag_api_compatible(int required_major, int required_minor, int required_patch);

/**
 * @brief Check bundle format compatibility
 * @param bundle_version Bundle format version to check
 * @return 1 if bundle format is supported, 0 otherwise
 */
int hyperdag_bundle_compatible(int bundle_version);

#ifdef __cplusplus
}
#endif

#endif /* HYPERDAG_VERSION_H */
