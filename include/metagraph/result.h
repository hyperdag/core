/**
 * @file result.h
 * @brief Canonical result types and error handling macros for MetaGraph
 *
 * This header defines the standard error handling patterns used throughout
 * MetaGraph, including result codes, error context, and convenience macros.
 *
 * @copyright Apache License 2.0 - see LICENSE file for details
 */

#ifndef METAGRAPH_RESULT_H
#define METAGRAPH_RESULT_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Result codes for MetaGraph operations
 *
 * All MetaGraph functions return one of these codes to indicate success
 * or the specific type of failure encountered.
 */
typedef enum {
    // Success codes (0-99)
    METAGRAPH_SUCCESS = 0,         ///< Operation completed successfully
    METAGRAPH_SUCCESS_PARTIAL = 1, ///< Operation partially succeeded

    // Memory errors (100-199)
    METAGRAPH_ERROR_OUT_OF_MEMORY = 100, ///< Memory allocation failed
    METAGRAPH_ERROR_INVALID_ALIGNMENT =
        101, ///< Memory alignment requirements not met
    METAGRAPH_ERROR_POOL_EXHAUSTED =
        102, ///< Memory pool has no available space
    METAGRAPH_ERROR_FRAGMENTATION =
        103, ///< Memory too fragmented for allocation

    // Parameter errors (200-299)
    METAGRAPH_ERROR_INVALID_ARGUMENT = 200, ///< Invalid function parameter
    METAGRAPH_ERROR_NULL_POINTER = 201,     ///< Unexpected null pointer
    METAGRAPH_ERROR_INVALID_SIZE = 202, ///< Size parameter out of valid range
    METAGRAPH_ERROR_INVALID_ALIGNMENT_VALUE =
        203, ///< Alignment value is not power of 2
    METAGRAPH_ERROR_BUFFER_TOO_SMALL = 204, ///< Provided buffer is too small

    // Graph structure errors (300-399)
    METAGRAPH_ERROR_NODE_NOT_FOUND = 300,      ///< Node ID not found in graph
    METAGRAPH_ERROR_EDGE_NOT_FOUND = 301,      ///< Edge ID not found in graph
    METAGRAPH_ERROR_NODE_EXISTS = 302,         ///< Node ID already exists
    METAGRAPH_ERROR_EDGE_EXISTS = 303,         ///< Edge ID already exists
    METAGRAPH_ERROR_CIRCULAR_DEPENDENCY = 304, ///< Circular dependency detected
    METAGRAPH_ERROR_GRAPH_CORRUPTED =
        305, ///< Graph internal state is corrupted
    METAGRAPH_ERROR_MAX_NODES_EXCEEDED = 306, ///< Maximum node limit reached
    METAGRAPH_ERROR_MAX_EDGES_EXCEEDED = 307, ///< Maximum edge limit reached

    // I/O and bundle errors (400-499)
    METAGRAPH_ERROR_IO_FAILURE = 400,         ///< General I/O operation failed
    METAGRAPH_ERROR_FILE_NOT_FOUND = 401,     ///< File does not exist
    METAGRAPH_ERROR_FILE_ACCESS_DENIED = 402, ///< Insufficient permissions
    METAGRAPH_ERROR_BUNDLE_CORRUPTED = 403,   ///< Bundle data is corrupted
    METAGRAPH_ERROR_BUNDLE_VERSION_MISMATCH =
        404,                                 ///< Unsupported bundle version
    METAGRAPH_ERROR_CHECKSUM_MISMATCH = 405, ///< Integrity verification failed
    METAGRAPH_ERROR_COMPRESSION_FAILED =
        406, ///< Data compression/decompression failed
    METAGRAPH_ERROR_MMAP_FAILED = 407, ///< Memory mapping failed

    // Concurrency errors (500-599)
    METAGRAPH_ERROR_LOCK_TIMEOUT = 500,      ///< Lock acquisition timed out
    METAGRAPH_ERROR_DEADLOCK_DETECTED = 501, ///< Potential deadlock detected
    METAGRAPH_ERROR_CONCURRENT_MODIFICATION =
        502, ///< Concurrent modification detected
    METAGRAPH_ERROR_THREAD_CREATION_FAILED = 503,  ///< Thread creation failed
    METAGRAPH_ERROR_ATOMIC_OPERATION_FAILED = 504, ///< Atomic operation failed

    // Algorithm errors (600-699)
    METAGRAPH_ERROR_TRAVERSAL_LIMIT_EXCEEDED =
        600, ///< Graph traversal depth limit exceeded
    METAGRAPH_ERROR_INFINITE_LOOP_DETECTED =
        601, ///< Infinite loop detected in traversal
    METAGRAPH_ERROR_DEPENDENCY_CYCLE =
        602, ///< Dependency cycle prevents resolution
    METAGRAPH_ERROR_TOPOLOGICAL_SORT_FAILED =
        603, ///< Topological sort impossible

    // System errors (700-799)
    METAGRAPH_ERROR_PLATFORM_NOT_SUPPORTED = 700, ///< Platform not supported
    METAGRAPH_ERROR_FEATURE_NOT_AVAILABLE =
        701, ///< Required feature not available
    METAGRAPH_ERROR_RESOURCE_EXHAUSTED = 702, ///< System resource exhausted
    METAGRAPH_ERROR_PERMISSION_DENIED =
        703, ///< Operation requires higher privileges

    // Internal errors (800-899)
    METAGRAPH_ERROR_INTERNAL_STATE = 800,   ///< Internal state inconsistency
    METAGRAPH_ERROR_ASSERTION_FAILED = 801, ///< Internal assertion failed
    METAGRAPH_ERROR_NOT_IMPLEMENTED = 802,  ///< Feature not yet implemented
    METAGRAPH_ERROR_VERSION_MISMATCH = 803, ///< Version compatibility issue

    // User-defined error range (900-999)
    METAGRAPH_ERROR_USER_DEFINED_START =
        900, ///< Start of user-defined error range
    METAGRAPH_ERROR_USER_DEFINED_END = 999 ///< End of user-defined error range
} metagraph_result_t;

/**
 * @brief Extended error context for debugging and diagnostics
 *
 * This structure provides detailed information about errors including
 * source location, custom messages, and optional detail data.
 */
typedef struct {
    metagraph_result_t code; ///< Error code
    const char *file;        ///< Source file where error occurred
    int line;                ///< Source line number
    const char *function;    ///< Function name where error occurred
    char message
        [256]; ///< Human-readable error message  //
               ///< NOLINT(cppcoreguidelines-avoid-magic-numbers,readability-magic-numbers)
    void *detail;       ///< Optional detailed error information
    size_t detail_size; ///< Size of detail data in bytes
} metagraph_error_context_t;

/**
 * @brief Check if a result code indicates success
 * @param result The result code to check
 * @return true if the result indicates success, false otherwise
 */
static inline bool metagraph_result_is_success(metagraph_result_t result) {
    return (result >= METAGRAPH_SUCCESS &&
            result < METAGRAPH_ERROR_OUT_OF_MEMORY) !=
           0; // NOLINT(readability-implicit-bool-conversion)
}

/**
 * @brief Check if a result code indicates an error
 * @param result The result code to check
 * @return true if the result indicates an error, false otherwise
 */
static inline bool metagraph_result_is_error(metagraph_result_t result) {
    return result >= METAGRAPH_ERROR_OUT_OF_MEMORY;
}

/**
 * @brief Convert result code to human-readable string
 * @param result The result code to convert
 * @return Pointer to static string describing the result
 */
const char *metagraph_result_to_string(metagraph_result_t result);

/**
 * @brief Set error context for current thread
 * @param code Error code
 * @param file Source file name
 * @param line Source line number
 * @param function Function name
 * @param format Printf-style format string for message
 * @param ... Arguments for format string
 * @return The error code passed in (for convenience)
 */
metagraph_result_t
metagraph_set_error_context(metagraph_result_t code, const char *file, int line,
                            const char *function, const char *format, ...)
    __attribute__((format(printf, 5, 6)));

/**
 * @brief Get error context for current thread
 * @param context Output parameter for error context
 * @return METAGRAPH_SUCCESS if context available, error code otherwise
 */
metagraph_result_t
metagraph_get_error_context(metagraph_error_context_t *context);

/**
 * @brief Clear error context for current thread
 */
void metagraph_clear_error_context(void);

// ============================================================================
// Convenience Macros for Error Handling
// ============================================================================

/**
 * @brief Return success result
 */
#define METAGRAPH_OK() (METAGRAPH_SUCCESS)

/**
 * @brief Return error with context information
 * @param code Error code to return
 * @param ... Printf-style format and arguments for error message
 */
#define METAGRAPH_ERR(code, ...)                                               \
    metagraph_set_error_context((code), __FILE__, __LINE__, __func__,          \
                                __VA_ARGS__)

/**
 * @brief Return error with just the error code (no custom message)
 * @param code Error code to return
 */
#define METAGRAPH_ERR_CODE(code)                                               \
    metagraph_set_error_context((code), __FILE__, __LINE__, __func__, "%s",    \
                                metagraph_result_to_string(code))

/**
 * @brief Check if operation succeeded, return error if not
 * @param expr Expression that returns metagraph_result_t
 */
#define METAGRAPH_CHECK(expr)                                                  \
    do {                                                                       \
        metagraph_result_t _result = (expr);                                   \
        if (metagraph_result_is_error(_result)) {                              \
            return _result;                                                    \
        }                                                                      \
    } while (0)

/**
 * @brief Check if operation succeeded, goto cleanup label if not
 * @param expr Expression that returns metagraph_result_t
 * @param label Cleanup label to jump to on error
 */
#define METAGRAPH_CHECK_GOTO(expr, label)                                      \
    do {                                                                       \
        metagraph_result_t _result = (expr);                                   \
        if (metagraph_result_is_error(_result)) {                              \
            result = _result;                                                  \
            goto label;                                                        \
        }                                                                      \
    } while (0)

/**
 * @brief Check if pointer is null, return error if so
 * @param ptr Pointer to check
 */
#define METAGRAPH_CHECK_NULL(ptr)                                              \
    do {                                                                       \
        if ((ptr) == NULL) {                                                   \
            return METAGRAPH_ERR(METAGRAPH_ERROR_NULL_POINTER,                 \
                                 "Null pointer: " #ptr);                       \
        }                                                                      \
    } while (0)

/**
 * @brief Check if allocation succeeded, return error if not
 * @param ptr Pointer returned from allocation function
 */
#define METAGRAPH_CHECK_ALLOC(ptr)                                             \
    do {                                                                       \
        if ((ptr) == NULL) {                                                   \
            return METAGRAPH_ERR(METAGRAPH_ERROR_OUT_OF_MEMORY,                \
                                 "Allocation failed: " #ptr);                  \
        }                                                                      \
    } while (0)

/**
 * @brief Check if size parameter is valid, return error if not
 * @param size Size parameter to validate
 * @param max_size Maximum allowed size
 */
#define METAGRAPH_CHECK_SIZE(size, max_size)                                   \
    do {                                                                       \
        if ((size) > (max_size)) {                                             \
            return METAGRAPH_ERR(METAGRAPH_ERROR_INVALID_SIZE,                 \
                                 "Size %zu exceeds maximum %zu",               \
                                 (size_t)(size), (size_t)(max_size));          \
        }                                                                      \
    } while (0)

/**
 * @brief Validate pointer and return error with context if null
 * @param ptr Pointer to validate
 * @param name Name of the pointer for error message
 */
#define METAGRAPH_VALIDATE_PTR(ptr, name)                                      \
    do {                                                                       \
        if ((ptr) == NULL) {                                                   \
            return METAGRAPH_ERR(METAGRAPH_ERROR_NULL_POINTER,                 \
                                 "Required parameter '%s' is null", (name));   \
        }                                                                      \
    } while (0)

/**
 * @brief Assert condition and return error if false (debug builds only)
 * @param condition Condition to check
 * @param message Error message if condition fails
 */
#ifdef NDEBUG
#define METAGRAPH_ASSERT(condition, message) ((void)0)
#else
#define METAGRAPH_ASSERT(condition, message)                                   \
    do {                                                                       \
        if (!(condition)) {                                                    \
            return METAGRAPH_ERR(METAGRAPH_ERROR_ASSERTION_FAILED,             \
                                 "Assertion failed: %s", (message));           \
        }                                                                      \
    } while (0)
#endif

/**
 * @brief Mark function as not yet implemented
 */
#define METAGRAPH_NOT_IMPLEMENTED()                                            \
    METAGRAPH_ERR(METAGRAPH_ERROR_NOT_IMPLEMENTED,                             \
                  "Function %s is not yet implemented", __func__)

/**
 * @brief Mark code path as unreachable
 */
#define METAGRAPH_UNREACHABLE()                                                \
    METAGRAPH_ERR(METAGRAPH_ERROR_INTERNAL_STATE,                              \
                  "Unreachable code executed in %s at %s:%d", __func__,        \
                  __FILE__, __LINE__)

#ifdef __cplusplus
}
#endif

#endif // METAGRAPH_RESULT_H
