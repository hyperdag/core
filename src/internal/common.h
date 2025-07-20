/**
 * @file common.h
 * @brief Internal common definitions and utilities
 */

#ifndef HYPERDAG_INTERNAL_COMMON_H
#define HYPERDAG_INTERNAL_COMMON_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <assert.h>

/* Compiler-specific attributes */
#if defined(__GNUC__) || defined(__clang__)
    #define HYPERDAG_LIKELY(x)       __builtin_expect(!!(x), 1)
    #define HYPERDAG_UNLIKELY(x)     __builtin_expect(!!(x), 0)
    #define HYPERDAG_FORCE_INLINE    __attribute__((always_inline)) inline
    #define HYPERDAG_NO_INLINE       __attribute__((noinline))
    #define HYPERDAG_PURE            __attribute__((pure))
    #define HYPERDAG_CONST           __attribute__((const))
    #define HYPERDAG_HOT             __attribute__((hot))
    #define HYPERDAG_COLD            __attribute__((cold))
    #define HYPERDAG_MALLOC          __attribute__((malloc))
    #define HYPERDAG_WARN_UNUSED     __attribute__((warn_unused_result))
#else
    #define HYPERDAG_LIKELY(x)       (x)
    #define HYPERDAG_UNLIKELY(x)     (x)
    #define HYPERDAG_FORCE_INLINE    inline
    #define HYPERDAG_NO_INLINE
    #define HYPERDAG_PURE
    #define HYPERDAG_CONST
    #define HYPERDAG_HOT
    #define HYPERDAG_COLD
    #define HYPERDAG_MALLOC
    #define HYPERDAG_WARN_UNUSED
#endif

/* Memory alignment */
#define HYPERDAG_CACHE_LINE_SIZE 64
#define HYPERDAG_ALIGN(x) __attribute__((aligned(x)))
#define HYPERDAG_CACHE_ALIGNED HYPERDAG_ALIGN(HYPERDAG_CACHE_LINE_SIZE)

/* Static assertions */
#define HYPERDAG_STATIC_ASSERT(cond, msg) _Static_assert(cond, msg)

/* Debugging macros */
#ifdef NDEBUG
    #define HYPERDAG_ASSERT(x) ((void)0)
    #define HYPERDAG_DEBUG_ONLY(x) ((void)0)
#else
    #define HYPERDAG_ASSERT(x) assert(x)
    #define HYPERDAG_DEBUG_ONLY(x) (x)
#endif

/* Memory utilities */
#define HYPERDAG_ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]))
#define HYPERDAG_CONTAINER_OF(ptr, type, member) \
    ((type *)((char *)(ptr) - offsetof(type, member)))

/* Error handling */
#define HYPERDAG_CHECK_NULL(ptr) \
    do { \
        if (HYPERDAG_UNLIKELY((ptr) == NULL)) { \
            return HYPERDAG_ERROR_NULL_POINTER; \
        } \
    } while (0)

#define HYPERDAG_CHECK_ERROR(expr) \
    do { \
        hyperdag_error_t _err = (expr); \
        if (HYPERDAG_UNLIKELY(_err != HYPERDAG_SUCCESS)) { \
            return _err; \
        } \
    } while (0)

/* C23 features detection */
#if __STDC_VERSION__ >= 202311L
    #define HYPERDAG_HAS_C23 1
    #define HYPERDAG_TYPEOF(x) typeof(x)
    #define HYPERDAG_EMPTY_INIT {}
#else
    #define HYPERDAG_HAS_C23 0
    #define HYPERDAG_TYPEOF(x) __typeof__(x)
    #define HYPERDAG_EMPTY_INIT {0}
#endif

/* Branch prediction for C23 */
#if HYPERDAG_HAS_C23 && defined(__has_c_attribute)
    #if __has_c_attribute(likely)
        #define HYPERDAG_C23_LIKELY [[likely]]
        #define HYPERDAG_C23_UNLIKELY [[unlikely]]
    #else
        #define HYPERDAG_C23_LIKELY
        #define HYPERDAG_C23_UNLIKELY
    #endif
#else
    #define HYPERDAG_C23_LIKELY
    #define HYPERDAG_C23_UNLIKELY
#endif

/* Platform detection */
#if defined(__linux__)
    #define HYPERDAG_PLATFORM_LINUX 1
#elif defined(__APPLE__)
    #define HYPERDAG_PLATFORM_MACOS 1
#elif defined(_WIN32)
    #define HYPERDAG_PLATFORM_WINDOWS 1
#else
    #define HYPERDAG_PLATFORM_UNKNOWN 1
#endif

/* Thread safety annotations (for Clang thread safety analysis) */
#if defined(__clang__) && defined(__has_attribute)
    #if __has_attribute(guarded_by)
        #define HYPERDAG_GUARDED_BY(x) __attribute__((guarded_by(x)))
        #define HYPERDAG_REQUIRES(x) __attribute__((requires_capability(x)))
        #define HYPERDAG_ACQUIRE(x) __attribute__((acquire_capability(x)))
        #define HYPERDAG_RELEASE(x) __attribute__((release_capability(x)))
        #define HYPERDAG_NO_THREAD_SAFETY_ANALYSIS __attribute__((no_thread_safety_analysis))
    #else
        #define HYPERDAG_GUARDED_BY(x)
        #define HYPERDAG_REQUIRES(x)
        #define HYPERDAG_ACQUIRE(x)
        #define HYPERDAG_RELEASE(x)
        #define HYPERDAG_NO_THREAD_SAFETY_ANALYSIS
    #endif
#else
    #define HYPERDAG_GUARDED_BY(x)
    #define HYPERDAG_REQUIRES(x)
    #define HYPERDAG_ACQUIRE(x)
    #define HYPERDAG_RELEASE(x)
    #define HYPERDAG_NO_THREAD_SAFETY_ANALYSIS
#endif

#endif /* HYPERDAG_INTERNAL_COMMON_H */
