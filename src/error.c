/**
 * @file error.c
 * @brief Implementation of error handling and context management
 *
 * Thread-local error contexts are cached for the lifetime of each thread.
 * The memory is intentionally not freed on thread exit to avoid complexity
 * with thread cleanup handlers. The OS will reclaim the memory when the
 * thread terminates.
 */

#include "metagraph/result.h"
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// C23 thread-local storage for error context
// Note: This memory is cached per-thread and not freed until thread exit
static _Thread_local metagraph_error_context_t *thread_error_context = NULL;

// Get thread-local error context, creating if necessary
static metagraph_error_context_t *metagraph_get_thread_error_context(void) {
    if (!thread_error_context) {
        thread_error_context = calloc(1, sizeof(metagraph_error_context_t));
        // If allocation fails, we can't store error context but that's OK
        // The functions will handle NULL context gracefully
    }
    return thread_error_context;
}

// Error string lookup table
typedef struct {
    metagraph_result_t code;
    const char *message;
} error_string_entry_t;

static const error_string_entry_t METAGRAPH_ERROR_STRINGS[] = {
    // Success codes
    {METAGRAPH_SUCCESS, "Success"},
    {METAGRAPH_SUCCESS_PARTIAL, "Partial success"},
    // Memory errors
    {METAGRAPH_ERROR_OUT_OF_MEMORY, "Out of memory"},
    {METAGRAPH_ERROR_INVALID_ALIGNMENT, "Invalid alignment"},
    {METAGRAPH_ERROR_POOL_EXHAUSTED, "Memory pool exhausted"},
    {METAGRAPH_ERROR_FRAGMENTATION, "Memory too fragmented"},
    // Parameter errors
    {METAGRAPH_ERROR_INVALID_ARGUMENT, "Invalid argument"},
    {METAGRAPH_ERROR_NULL_POINTER, "Null pointer"},
    {METAGRAPH_ERROR_INVALID_SIZE, "Invalid size"},
    {METAGRAPH_ERROR_INVALID_ALIGNMENT_VALUE, "Invalid alignment value"},
    {METAGRAPH_ERROR_BUFFER_TOO_SMALL, "Buffer too small"},
    // Graph structure errors
    {METAGRAPH_ERROR_NODE_NOT_FOUND, "Node not found"},
    {METAGRAPH_ERROR_EDGE_NOT_FOUND, "Edge not found"},
    {METAGRAPH_ERROR_NODE_EXISTS, "Node already exists"},
    {METAGRAPH_ERROR_EDGE_EXISTS, "Edge already exists"},
    {METAGRAPH_ERROR_CIRCULAR_DEPENDENCY, "Circular dependency detected"},
    {METAGRAPH_ERROR_GRAPH_CORRUPTED, "Graph corrupted"},
    {METAGRAPH_ERROR_MAX_NODES_EXCEEDED, "Maximum nodes exceeded"},
    {METAGRAPH_ERROR_MAX_EDGES_EXCEEDED, "Maximum edges exceeded"},
    // I/O and bundle errors
    {METAGRAPH_ERROR_IO_FAILURE, "I/O failure"},
    {METAGRAPH_ERROR_FILE_NOT_FOUND, "File not found"},
    {METAGRAPH_ERROR_FILE_ACCESS_DENIED, "File access denied"},
    {METAGRAPH_ERROR_BUNDLE_CORRUPTED, "Bundle corrupted"},
    {METAGRAPH_ERROR_BUNDLE_VERSION_MISMATCH, "Bundle version mismatch"},
    {METAGRAPH_ERROR_CHECKSUM_MISMATCH, "Checksum mismatch"},
    {METAGRAPH_ERROR_COMPRESSION_FAILED, "Compression failed"},
    {METAGRAPH_ERROR_MMAP_FAILED, "Memory mapping failed"},
    // Concurrency errors
    {METAGRAPH_ERROR_LOCK_TIMEOUT, "Lock timeout"},
    {METAGRAPH_ERROR_DEADLOCK_DETECTED, "Deadlock detected"},
    {METAGRAPH_ERROR_CONCURRENT_MODIFICATION, "Concurrent modification"},
    {METAGRAPH_ERROR_THREAD_CREATION_FAILED, "Thread creation failed"},
    {METAGRAPH_ERROR_ATOMIC_OPERATION_FAILED, "Atomic operation failed"},
    // Algorithm errors
    {METAGRAPH_ERROR_TRAVERSAL_LIMIT_EXCEEDED, "Traversal limit exceeded"},
    {METAGRAPH_ERROR_INFINITE_LOOP_DETECTED, "Infinite loop detected"},
    {METAGRAPH_ERROR_DEPENDENCY_CYCLE, "Dependency cycle"},
    {METAGRAPH_ERROR_TOPOLOGICAL_SORT_FAILED, "Topological sort failed"},
    // System errors
    {METAGRAPH_ERROR_PLATFORM_NOT_SUPPORTED, "Platform not supported"},
    {METAGRAPH_ERROR_FEATURE_NOT_AVAILABLE, "Feature not available"},
    {METAGRAPH_ERROR_RESOURCE_EXHAUSTED, "Resource exhausted"},
    {METAGRAPH_ERROR_PERMISSION_DENIED, "Permission denied"},
    // Internal errors
    {METAGRAPH_ERROR_INTERNAL_STATE, "Internal state error"},
    {METAGRAPH_ERROR_ASSERTION_FAILED, "Assertion failed"},
    {METAGRAPH_ERROR_NOT_IMPLEMENTED, "Not implemented"},
    {METAGRAPH_ERROR_VERSION_MISMATCH, "Version mismatch"},
};

// Ensure table stays in sync with enum
_Static_assert(sizeof(METAGRAPH_ERROR_STRINGS) /
                       sizeof(METAGRAPH_ERROR_STRINGS[0]) ==
                   44,
               "Add new error codes to error_strings table when extending "
               "metagraph_result_t");

#if defined(__has_attribute)
#if __has_attribute(cold) && __has_attribute(const)
#define METAGRAPH_ATTR_COLD_CONST __attribute__((cold, const))
#endif
#endif
#ifndef METAGRAPH_ATTR_COLD_CONST
#define METAGRAPH_ATTR_COLD_CONST
#endif

METAGRAPH_ATTR_COLD_CONST
const char *metagraph_result_to_string(metagraph_result_t result) {
    // Linear search through the table (fine for ~50 entries)
    // If table grows beyond ~200 entries, consider binary search
    const size_t count =
        sizeof(METAGRAPH_ERROR_STRINGS) / sizeof(METAGRAPH_ERROR_STRINGS[0]);
    for (size_t i = 0; i < count; i++) {
        if (METAGRAPH_ERROR_STRINGS[i].code == result) {
            return METAGRAPH_ERROR_STRINGS[i].message;
        }
    }

    // Handle user-defined range
    if (result >= METAGRAPH_ERROR_USER_DEFINED_START &&
        result <= METAGRAPH_ERROR_USER_DEFINED_END) {
        return "User-defined error";
    }

    return "Unknown error";
}

#if defined(__has_attribute)
#if __has_attribute(cold)
#define METAGRAPH_ATTR_COLD __attribute__((cold))
#endif
#endif
#ifndef METAGRAPH_ATTR_COLD
#define METAGRAPH_ATTR_COLD
#endif

/* GCC/Clang printf-format checking for (buff, cap, fmt, va_list) */
#if defined(__has_attribute)
#if __has_attribute(format)
#define METAGRAPH_ATTR_PRINTF_VA(fmt) __attribute__((format(printf, fmt, 0)))
#endif
#endif
#ifndef METAGRAPH_ATTR_PRINTF_VA
#define METAGRAPH_ATTR_PRINTF_VA(fmt)
#endif

// Helper to format error message with truncation handling
METAGRAPH_ATTR_PRINTF_VA(3)
static void metagraph_format_error_message(char *buffer, size_t cap,
                                           const char *format, va_list args) {
    int result = vsnprintf(buffer, cap, format, args);

    // Handle vsnprintf errors and truncation
    if (result < 0) {
        // Encoding error occurred
        static const char error_msg[] = "<format error>";
        const size_t msg_len = sizeof(error_msg) - 1;
        memcpy(buffer, error_msg, msg_len);
        buffer[msg_len] = '\0';
    } else if (result >= (int)cap) {
        // Message was truncated, add ellipsis
        static const char ellipsis[] = "...";
        const size_t ellipsis_len = sizeof(ellipsis) - 1;

        // Only add ellipsis if there's room
        if (cap > ellipsis_len + 1) {
            memcpy(buffer + cap - ellipsis_len - 1, ellipsis, ellipsis_len + 1);
        }
    }
}

METAGRAPH_ATTR_COLD
metagraph_result_t metagraph_set_error_context(
    metagraph_result_t code, const char *file, int line,
    const char *function, // NOLINT(bugprone-easily-swappable-parameters)
    const char *format, ...) {
    // Rationale: parameters are supplied exclusively by macros
    // (__FILE__, __LINE__, __func__), so swap risk is nil.
    metagraph_error_context_t *context = metagraph_get_thread_error_context();
    if (!context) {
        // Can't store context due to allocation failure, but still return the
        // error
        return code;
    }

    // Set basic error information
    context->code = code;
    context->file = file;
    context->line = line;
    context->function = function;

    // Format the error message
    va_list args;
    va_start(args, format);
    metagraph_format_error_message(context->message, sizeof(context->message),
                                   format, args);
    va_end(args);

    // Clear any previous detail data
    // Note: Ownership of detail pointer is caller's responsibility
    context->detail = NULL;
    context->detail_size = 0;

    return code;
}

metagraph_result_t
metagraph_get_error_context(metagraph_error_context_t *context) {
    if (!context) {
        return METAGRAPH_ERROR_NULL_POINTER;
    }

    metagraph_error_context_t *thread_context =
        metagraph_get_thread_error_context();
    if (!thread_context) {
        // No context available (allocation failed), return success with empty
        // context
        memset(context, 0, sizeof(*context));
        context->code = METAGRAPH_SUCCESS;
        return METAGRAPH_SUCCESS;
    }

    // If no error has been set, return success with clear context
    if (thread_context->code == METAGRAPH_SUCCESS) {
        memset(context, 0, sizeof(*context));
        context->code = METAGRAPH_SUCCESS;
        return METAGRAPH_SUCCESS;
    }

    // Copy the error context
    *context = *thread_context;
    return METAGRAPH_SUCCESS;
}

void metagraph_clear_error_context(void) {
    metagraph_error_context_t *context = thread_error_context;
    if (context) {
        memset(context, 0, sizeof(metagraph_error_context_t));
        context->code = METAGRAPH_SUCCESS;
        // Note: We intentionally keep the allocated memory for reuse
        // rather than freeing it. This avoids repeated allocations
        // and the complexity of thread cleanup handlers.
    }
}

// Optional: Call this before thread exit to free the thread-local storage
// Not required as the OS will reclaim memory on thread termination
#ifdef METAGRAPH_EXPOSE_THREAD_CLEANUP
void metagraph_thread_cleanup(void) {
    if (thread_error_context) {
        free(thread_error_context);
        thread_error_context = NULL;
    }
}
#endif
