/**
 * @file linux.c
 * @brief Linux-specific platform implementation
 */

#include "platform.h"

#ifdef HYPERDAG_PLATFORM_LINUX

#include <unistd.h>
#include <sched.h>

int hyperdag_platform_get_cpu_count(void)
{
    return (int)sysconf(_SC_NPROCESSORS_ONLN);
}

int hyperdag_platform_set_thread_affinity(int thread_id, int cpu_id)
{
    cpu_set_t cpu_set;
    CPU_ZERO(&cpu_set);
    CPU_SET(cpu_id, &cpu_set);
    
    return sched_setaffinity(thread_id, sizeof(cpu_set), &cpu_set);
}

#endif /* HYPERDAG_PLATFORM_LINUX */