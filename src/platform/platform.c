/**
 * @file platform.c
 * @brief Platform-agnostic implementation
 */

#include "platform.h"
#include <stdlib.h>

int hyperdag_platform_init(void)
{
    /* Common initialization */
    return 0;
}

void hyperdag_platform_cleanup(void)
{
    /* Common cleanup */
}

void *hyperdag_platform_aligned_alloc(size_t alignment, size_t size)
{
#if defined(_WIN32)
    return _aligned_malloc(size, alignment);
#elif defined(__APPLE__) || defined(__linux__)
    void *ptr = NULL;
    if (posix_memalign(&ptr, alignment, size) != 0) {
        return NULL;
    }
    return ptr;
#else
    /* Fallback to regular malloc */
    (void)alignment;
    return malloc(size);
#endif
}

void hyperdag_platform_aligned_free(void *ptr)
{
#if defined(_WIN32)
    _aligned_free(ptr);
#else
    free(ptr);
#endif
}