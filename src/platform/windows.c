/**
 * @file windows.c
 * @brief Windows-specific platform implementation
 */

#include "platform.h"

#ifdef HYPERDAG_PLATFORM_WINDOWS

#include <windows.h>

int hyperdag_platform_get_cpu_count(void)
{
    SYSTEM_INFO sysinfo;
    GetSystemInfo(&sysinfo);
    return (int)sysinfo.dwNumberOfProcessors;
}

int hyperdag_platform_set_thread_affinity(int thread_id, int cpu_id)
{
    HANDLE thread = OpenThread(THREAD_SET_INFORMATION, FALSE, thread_id);
    if (thread == NULL) {
        return -1;
    }
    
    DWORD_PTR affinity_mask = 1ULL << cpu_id;
    DWORD_PTR result = SetThreadAffinityMask(thread, affinity_mask);
    
    CloseHandle(thread);
    
    return (result != 0) ? 0 : -1;
}

#endif /* HYPERDAG_PLATFORM_WINDOWS */