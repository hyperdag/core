/**
 * @file platform.h
 * @brief Platform-specific functionality interface
 */

#ifndef HYPERDAG_PLATFORM_H
#define HYPERDAG_PLATFORM_H

#include "../internal/common.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Platform initialization */
int hyperdag_platform_init(void);
void hyperdag_platform_cleanup(void);

/* Memory management */
void *hyperdag_platform_aligned_alloc(size_t alignment, size_t size);
void hyperdag_platform_aligned_free(void *ptr);

/* Thread support */
int hyperdag_platform_get_cpu_count(void);
int hyperdag_platform_set_thread_affinity(int thread_id, int cpu_id);

#ifdef __cplusplus
}
#endif

#endif /* HYPERDAG_PLATFORM_H */