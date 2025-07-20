/**
 * @file version.c
 * @brief Version information implementation
 */

#include "hyperdag/version.h"
#include "hyperdag/hyperdag.h"

const char *hyperdag_version(void)
{
    return HYPERDAG_VERSION_STRING;
}

int hyperdag_version_major(void)
{
    return HYPERDAG_VERSION_MAJOR;
}

int hyperdag_version_minor(void)
{
    return HYPERDAG_VERSION_MINOR;
}

int hyperdag_version_patch(void)
{
    return HYPERDAG_VERSION_PATCH;
}

const char *hyperdag_build_info(void)
{
    return "Built on " HYPERDAG_BUILD_DATE " at " HYPERDAG_BUILD_TIME;
}
