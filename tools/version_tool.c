/*
 * MetaGraph Version Tool
 * Simple utility to display version information
 */

#include "metagraph/version.h"
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>

void metagraph_print_api_version(void);
void metagraph_print_bundle_format(void);
void metagraph_print_build_info(void);
void metagraph_print_features(void);

void metagraph_print_api_version(void) {
    (void)printf("API Version: %d.%d.%d\n", metagraph_version_major(),
                 metagraph_version_minor(), metagraph_version_patch());

    (void)printf("Version String: %s\n", metagraph_version_string());
}

void metagraph_print_bundle_format(void) {
    (void)printf("Bundle Format Version: %d\n",
                 metagraph_bundle_format_version());
    (void)printf("Bundle Format UUID: %s\n", metagraph_bundle_format_uuid());
}

void metagraph_print_build_info(void) {
    (void)printf("Build Info: %s\n", metagraph_build_info());

    metagraph_build_details_t details;
    metagraph_get_build_details(&details);

    (void)printf("Build Timestamp: %s\n",
                 details.timestamp ? details.timestamp : "N/A");

    (void)printf("Commit Hash: %s\n",
                 details.commit_hash ? details.commit_hash : "N/A");

    (void)printf("Branch: %s\n", details.branch ? details.branch : "N/A");
}

void metagraph_print_features(void) {
    // (void)printf("Features:\n");
    // (void)printf("  Versioned Bundles: %s\n",
    //                        METAGRAPH_FEATURE_VERSIONED_BUNDLES ? "Yes" :
    //                        "No");
    // (void)printf("  Delta Patches: %s\n",
    //                        METAGRAPH_FEATURE_DELTA_PATCHES ? "Yes" : "No");
    // (void)printf("  Compression V2: %s\n",
    //                        METAGRAPH_FEATURE_COMPRESSION_V2 ? "Yes" : "No");
}

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;

    (void)printf("MetaGraph Version Tool\n");

    metagraph_print_api_version();

    metagraph_print_bundle_format();

    metagraph_print_build_info();

    metagraph_print_features();

    (void)printf("End of version information.\n");

    return 0;
}
