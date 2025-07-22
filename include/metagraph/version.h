/**
 * @file version.h
 * @brief Version information for MetaGraph library
 *
 * This header provides compile-time and runtime version information
 * including API versions, bundle format compatibility, and build details.
 *
 * @copyright Apache License 2.0 - see LICENSE file for details
 */

#ifndef METAGRAPH_VERSION_H
#define METAGRAPH_VERSION_H

#ifdef __cplusplus
extern "C" {
#endif

// =============================================================================
// API Version Information (from CMake project version)
// =============================================================================

#define METAGRAPH_API_VERSION_MAJOR 0
#define METAGRAPH_API_VERSION_MINOR 1
#define METAGRAPH_API_VERSION_PATCH 0
#define METAGRAPH_API_VERSION_STRING "0.1.0"

// Legacy compatibility (maps to API version)
#define METAGRAPH_VERSION_MAJOR METAGRAPH_API_VERSION_MAJOR
#define METAGRAPH_VERSION_MINOR METAGRAPH_API_VERSION_MINOR
#define METAGRAPH_VERSION_PATCH METAGRAPH_API_VERSION_PATCH
#define METAGRAPH_VERSION_STRING METAGRAPH_API_VERSION_STRING

// =============================================================================
// Binary Bundle Format Version
// =============================================================================

#define METAGRAPH_BUNDLE_FORMAT_VERSION 1
#define METAGRAPH_BUNDLE_FORMAT_UUID "550e8400-e29b-41d4-a716-446655440000"

// =============================================================================
// Build Information (populated by CMake)
// =============================================================================

#define METAGRAPH_BUILD_TIMESTAMP "2025-07-22 19:55:05 UTC"
#define METAGRAPH_BUILD_COMMIT_HASH "55a08d1b8c9f5fd8e9cfb267ba535bbe4480acd9"
#define METAGRAPH_BUILD_BRANCH "feat/docker-dev-container-image"

// Fallback to compiler macros if CMake variables not available
#define METAGRAPH_BUILD_DATE __DATE__
#define METAGRAPH_BUILD_TIME __TIME__

// =============================================================================
// Minimum Requirements
// =============================================================================

#define METAGRAPH_MIN_C_STANDARD 23
#define METAGRAPH_MIN_CMAKE_VERSION "3.28"

// =============================================================================
// Feature Flags for Forward Compatibility
// =============================================================================

#define METAGRAPH_FEATURE_VERSIONED_BUNDLES 1
#define METAGRAPH_FEATURE_DELTA_PATCHES 0  // Reserved for future
#define METAGRAPH_FEATURE_COMPRESSION_V2 0 // Reserved for future

// =============================================================================
// Runtime Version API
// =============================================================================

/**
 * @brief Get API major version number
 * @return Major version number
 */
int metagraph_version_major(void);

/**
 * @brief Get API minor version number
 * @return Minor version number
 */
int metagraph_version_minor(void);

/**
 * @brief Get API patch version number
 * @return Patch version number
 */
int metagraph_version_patch(void);

/**
 * @brief Get API version string
 * @return Pointer to static version string (e.g., "0.1.0")
 */
const char *metagraph_version_string(void);

/**
 * @brief Get bundle format version
 * @return Bundle format version number
 */
int metagraph_bundle_format_version(void);

/**
 * @brief Get bundle format UUID
 * @return Pointer to static UUID string
 */
const char *metagraph_bundle_format_uuid(void);

/**
 * @brief Get build information
 * @return Pointer to static string containing build timestamp and commit
 */
const char *metagraph_build_info(void);

/**
 * @brief Build details structure
 */
typedef struct metagraph_build_details_s {
    const char *timestamp;
    const char *commit_hash;
    const char *branch;
} metagraph_build_details_t;

/**
 * @brief Get detailed build information
 * @param details Output structure for build details (must not be NULL)
 */
void metagraph_get_build_details(metagraph_build_details_t *details);

/**
 * @brief Check if a feature is available
 * @param feature_name Name of the feature to check
 * @return 1 if feature is available, 0 otherwise
 */
int metagraph_feature_available(const char *feature_name);

/**
 * @brief Version structure
 */
typedef struct metagraph_version_s {
    int major;
    int minor;
    int patch;
} metagraph_version_t;

/**
 * @brief Check API compatibility
 * @param required Required version
 * @return 1 if API is compatible, 0 otherwise
 */
int metagraph_api_compatible(const metagraph_version_t *required);

/**
 * @brief Check bundle format compatibility
 * @param bundle_version Bundle format version to check
 * @return 1 if bundle format is supported, 0 otherwise
 */
int metagraph_bundle_compatible(int bundle_version);

#ifdef __cplusplus
}
#endif

#endif /* METAGRAPH_VERSION_H */
