/**
 * @file test_version.c
 * @brief Unit tests for version information
 */

#include <criterion/criterion.h>
#include "hyperdag/hyperdag.h"
#include "hyperdag/version.h"

Test(version, version_string) {
    const char *version = hyperdag_version();
    cr_assert_not_null(version, "Version string should not be NULL");
    cr_assert_str_eq(version, "1.0.0", "Version should be 1.0.0");
}

Test(version, version_components) {
    cr_assert_eq(hyperdag_version_major(), 1, "Major version should be 1");
    cr_assert_eq(hyperdag_version_minor(), 0, "Minor version should be 0");
    cr_assert_eq(hyperdag_version_patch(), 0, "Patch version should be 0");
}

Test(version, build_info) {
    const char *build_info = hyperdag_build_info();
    cr_assert_not_null(build_info, "Build info should not be NULL");
}