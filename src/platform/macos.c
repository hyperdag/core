/**
 * @file macos.c
 * @brief macOS-specific platform implementation
 */

#include "platform.h"

#ifdef HYPERDAG_PLATFORM_MACOS

#include <unistd.h>
#include <sys/sysctl.h>
#include <mach/thread_policy.h>
#include <mach/thread_act.h>
#include <pthread.h>

int hyperdag_platform_get_cpu_count(void)
{
    int cpu_count;
    size_t size = sizeof(cpu_count);
    
    if (sysctlbyname("hw.ncpu", &cpu_count, &size, NULL, 0) != 0) {
        return (int)sysconf(_SC_NPROCESSORS_ONLN);
    }
    
    return cpu_count;
}

int hyperdag_platform_set_thread_affinity(int thread_id, int cpu_id)
{
    thread_affinity_policy_data_t policy = { cpu_id };
    thread_port_t mach_thread = pthread_mach_thread_np(pthread_self());
    
    return thread_policy_set(mach_thread, THREAD_AFFINITY_POLICY,
                           (thread_policy_t)&policy, 1);
}

#endif /* HYPERDAG_PLATFORM_MACOS */