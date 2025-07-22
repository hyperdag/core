/**
 * @file version.c
 * @brief Implementation of version information functions
 */

#include "metagraph/version.h"
#include <stdio.h>
#include <string.h>

int metagraph_version_major(void) { return METAGRAPH_API_VERSION_MAJOR; }

int metagraph_version_minor(void) { return METAGRAPH_API_VERSION_MINOR; }

int metagraph_version_patch(void) { return METAGRAPH_API_VERSION_PATCH; }

const char *metagraph_version_string(void) {
    return METAGRAPH_API_VERSION_STRING;
}

int metagraph_bundle_format_version(void) {
    return METAGRAPH_BUNDLE_FORMAT_VERSION;
}

const char *metagraph_bundle_format_uuid(void) {
    return METAGRAPH_BUNDLE_FORMAT_UUID;
}

const char *metagraph_build_info(void) {
    static char build_info[256];
    snprintf(build_info, sizeof(build_info), "Built on %s from %s (%s)",
             METAGRAPH_BUILD_TIMESTAMP, METAGRAPH_BUILD_COMMIT_HASH,
             METAGRAPH_BUILD_BRANCH);
    return build_info;
}

void metagraph_get_build_details(metagraph_build_details_t *details) {
    if (!details) {
        return;
    }
    details->timestamp = METAGRAPH_BUILD_TIMESTAMP;
    details->commit_hash = METAGRAPH_BUILD_COMMIT_HASH;
    details->branch = METAGRAPH_BUILD_BRANCH;
}

int metagraph_feature_available(const char *feature_name) {
    if (!feature_name) {
        return 0;
    }

    if (strcmp(feature_name, "versioned_bundles") == 0) {
        return METAGRAPH_FEATURE_VERSIONED_BUNDLES;
    }
    if (strcmp(feature_name, "delta_patches") == 0) {
        return METAGRAPH_FEATURE_DELTA_PATCHES;
    }
    if (strcmp(feature_name, "compression_v2") == 0) {
        return METAGRAPH_FEATURE_COMPRESSION_V2;
    }

    return 0;
}

int metagraph_api_compatible(const metagraph_version_t *required) {
    if (!required) {
        return 0;
    }

    // Major version must match exactly
    if (required->major != METAGRAPH_API_VERSION_MAJOR) {
        return 0;
    }

    // Minor version must be >= required
    if (METAGRAPH_API_VERSION_MINOR < required->minor) {
        return 0;
    }

    // If minor versions match, patch must be >= required
    if (METAGRAPH_API_VERSION_MINOR == required->minor &&
        METAGRAPH_API_VERSION_PATCH < required->patch) {
        return 0;
    }

    return 1;
}

int metagraph_bundle_compatible(int bundle_version) {
    return bundle_version == METAGRAPH_BUNDLE_FORMAT_VERSION;
}
