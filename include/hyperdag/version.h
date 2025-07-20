/**
 * @file version.h
 * @brief Version information for HyperDAG library
 */

#ifndef HYPERDAG_VERSION_H
#define HYPERDAG_VERSION_H

#define HYPERDAG_VERSION_MAJOR 1
#define HYPERDAG_VERSION_MINOR 0
#define HYPERDAG_VERSION_PATCH 0
#define HYPERDAG_VERSION_STRING "1.0.0"

/* Build information (populated by CMake) */
#define HYPERDAG_BUILD_DATE __DATE__
#define HYPERDAG_BUILD_TIME __TIME__

#ifdef __cplusplus
extern "C" {
#endif

/**
 * hyperdag_version_major - Get major version number
 * Return: Major version number
 */
int hyperdag_version_major(void);

/**
 * hyperdag_version_minor - Get minor version number
 * Return: Minor version number
 */
int hyperdag_version_minor(void);

/**
 * hyperdag_version_patch - Get patch version number
 * Return: Patch version number
 */
int hyperdag_version_patch(void);

/**
 * hyperdag_build_info - Get build information
 * Return: String containing build date and time
 */
const char *hyperdag_build_info(void);

#ifdef __cplusplus
}
#endif

#endif /* HYPERDAG_VERSION_H */
