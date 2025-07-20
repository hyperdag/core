/**
 * @file result.h
 * @brief Canonical result types and error handling macros for HyperDAG
 * 
 * This header defines the standard error handling patterns used throughout
 * HyperDAG, including result codes, error context, and convenience macros.
 * 
 * @copyright Apache License 2.0 - see LICENSE file for details
 */

#ifndef HYPERDAG_RESULT_H
#define HYPERDAG_RESULT_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Result codes for HyperDAG operations
 * 
 * All HyperDAG functions return one of these codes to indicate success
 * or the specific type of failure encountered.
 */
typedef enum {
    // Success codes (0-99)
    HYPERDAG_SUCCESS = 0,                    ///< Operation completed successfully
    HYPERDAG_SUCCESS_PARTIAL = 1,           ///< Operation partially succeeded
    
    // Memory errors (100-199)
    HYPERDAG_ERROR_OUT_OF_MEMORY = 100,     ///< Memory allocation failed
    HYPERDAG_ERROR_INVALID_ALIGNMENT = 101, ///< Memory alignment requirements not met
    HYPERDAG_ERROR_POOL_EXHAUSTED = 102,    ///< Memory pool has no available space
    HYPERDAG_ERROR_FRAGMENTATION = 103,     ///< Memory too fragmented for allocation
    
    // Parameter errors (200-299)
    HYPERDAG_ERROR_INVALID_ARGUMENT = 200,  ///< Invalid function parameter
    HYPERDAG_ERROR_NULL_POINTER = 201,      ///< Unexpected null pointer
    HYPERDAG_ERROR_INVALID_SIZE = 202,      ///< Size parameter out of valid range
    HYPERDAG_ERROR_INVALID_ALIGNMENT_VALUE = 203, ///< Alignment value is not power of 2
    HYPERDAG_ERROR_BUFFER_TOO_SMALL = 204,  ///< Provided buffer is too small
    
    // Graph structure errors (300-399)
    HYPERDAG_ERROR_NODE_NOT_FOUND = 300,    ///< Node ID not found in graph
    HYPERDAG_ERROR_EDGE_NOT_FOUND = 301,    ///< Edge ID not found in graph
    HYPERDAG_ERROR_NODE_EXISTS = 302,       ///< Node ID already exists
    HYPERDAG_ERROR_EDGE_EXISTS = 303,       ///< Edge ID already exists
    HYPERDAG_ERROR_CIRCULAR_DEPENDENCY = 304, ///< Circular dependency detected
    HYPERDAG_ERROR_GRAPH_CORRUPTED = 305,   ///< Graph internal state is corrupted
    HYPERDAG_ERROR_MAX_NODES_EXCEEDED = 306, ///< Maximum node limit reached
    HYPERDAG_ERROR_MAX_EDGES_EXCEEDED = 307, ///< Maximum edge limit reached
    
    // I/O and bundle errors (400-499)
    HYPERDAG_ERROR_IO_FAILURE = 400,        ///< General I/O operation failed
    HYPERDAG_ERROR_FILE_NOT_FOUND = 401,    ///< File does not exist
    HYPERDAG_ERROR_FILE_ACCESS_DENIED = 402, ///< Insufficient permissions
    HYPERDAG_ERROR_BUNDLE_CORRUPTED = 403,  ///< Bundle data is corrupted
    HYPERDAG_ERROR_BUNDLE_VERSION_MISMATCH = 404, ///< Unsupported bundle version
    HYPERDAG_ERROR_CHECKSUM_MISMATCH = 405, ///< Integrity verification failed
    HYPERDAG_ERROR_COMPRESSION_FAILED = 406, ///< Data compression/decompression failed
    HYPERDAG_ERROR_MMAP_FAILED = 407,       ///< Memory mapping failed
    
    // Concurrency errors (500-599)
    HYPERDAG_ERROR_LOCK_TIMEOUT = 500,      ///< Lock acquisition timed out
    HYPERDAG_ERROR_DEADLOCK_DETECTED = 501, ///< Potential deadlock detected
    HYPERDAG_ERROR_CONCURRENT_MODIFICATION = 502, ///< Concurrent modification detected
    HYPERDAG_ERROR_THREAD_CREATION_FAILED = 503, ///< Thread creation failed
    HYPERDAG_ERROR_ATOMIC_OPERATION_FAILED = 504, ///< Atomic operation failed
    
    // Algorithm errors (600-699)
    HYPERDAG_ERROR_TRAVERSAL_LIMIT_EXCEEDED = 600, ///< Graph traversal depth limit exceeded
    HYPERDAG_ERROR_INFINITE_LOOP_DETECTED = 601, ///< Infinite loop detected in traversal
    HYPERDAG_ERROR_DEPENDENCY_CYCLE = 602,  ///< Dependency cycle prevents resolution
    HYPERDAG_ERROR_TOPOLOGICAL_SORT_FAILED = 603, ///< Topological sort impossible
    
    // System errors (700-799)
    HYPERDAG_ERROR_PLATFORM_NOT_SUPPORTED = 700, ///< Platform not supported
    HYPERDAG_ERROR_FEATURE_NOT_AVAILABLE = 701, ///< Required feature not available
    HYPERDAG_ERROR_RESOURCE_EXHAUSTED = 702, ///< System resource exhausted
    HYPERDAG_ERROR_PERMISSION_DENIED = 703, ///< Operation requires higher privileges
    
    // Internal errors (800-899)
    HYPERDAG_ERROR_INTERNAL_STATE = 800,    ///< Internal state inconsistency
    HYPERDAG_ERROR_ASSERTION_FAILED = 801,  ///< Internal assertion failed
    HYPERDAG_ERROR_NOT_IMPLEMENTED = 802,   ///< Feature not yet implemented
    HYPERDAG_ERROR_VERSION_MISMATCH = 803,  ///< Version compatibility issue
    
    // User-defined error range (900-999)
    HYPERDAG_ERROR_USER_DEFINED_START = 900, ///< Start of user-defined error range
    HYPERDAG_ERROR_USER_DEFINED_END = 999    ///< End of user-defined error range
} hyperdag_result_t;

/**
 * @brief Extended error context for debugging and diagnostics
 * 
 * This structure provides detailed information about errors including
 * source location, custom messages, and optional detail data.
 */
typedef struct {
    hyperdag_result_t code;         ///< Error code
    const char* file;               ///< Source file where error occurred
    int line;                       ///< Source line number
    const char* function;           ///< Function name where error occurred
    char message[256];              ///< Human-readable error message
    void* detail;                   ///< Optional detailed error information
    size_t detail_size;             ///< Size of detail data in bytes
} hyperdag_error_context_t;

/**
 * @brief Check if a result code indicates success
 * @param result The result code to check
 * @return true if the result indicates success, false otherwise
 */
static inline bool hyperdag_result_is_success(hyperdag_result_t result) {
    return result >= HYPERDAG_SUCCESS && result < HYPERDAG_ERROR_OUT_OF_MEMORY;
}

/**
 * @brief Check if a result code indicates an error
 * @param result The result code to check
 * @return true if the result indicates an error, false otherwise
 */
static inline bool hyperdag_result_is_error(hyperdag_result_t result) {
    return result >= HYPERDAG_ERROR_OUT_OF_MEMORY;
}

/**
 * @brief Convert result code to human-readable string
 * @param result The result code to convert
 * @return Pointer to static string describing the result
 */
const char* hyperdag_result_to_string(hyperdag_result_t result);

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
hyperdag_result_t hyperdag_set_error_context(
    hyperdag_result_t code,
    const char* file,
    int line,
    const char* function,
    const char* format,
    ...
) __attribute__((format(printf, 5, 6)));

/**
 * @brief Get error context for current thread
 * @param context Output parameter for error context
 * @return HYPERDAG_SUCCESS if context available, error code otherwise
 */
hyperdag_result_t hyperdag_get_error_context(hyperdag_error_context_t* context);

/**
 * @brief Clear error context for current thread
 */
void hyperdag_clear_error_context(void);

// ============================================================================
// Convenience Macros for Error Handling
// ============================================================================

/**
 * @brief Return success result
 */
#define HYP_OK() (HYPERDAG_SUCCESS)

/**
 * @brief Return error with context information
 * @param code Error code to return
 * @param ... Printf-style format and arguments for error message
 */
#define HYP_ERR(code, ...) \
    hyperdag_set_error_context((code), __FILE__, __LINE__, __func__, __VA_ARGS__)

/**
 * @brief Return error with just the error code (no custom message)
 * @param code Error code to return
 */
#define HYP_ERR_CODE(code) \
    hyperdag_set_error_context((code), __FILE__, __LINE__, __func__, \
                              "%s", hyperdag_result_to_string(code))

/**
 * @brief Check if operation succeeded, return error if not
 * @param expr Expression that returns hyperdag_result_t
 */
#define HYP_CHECK(expr) do { \
    hyperdag_result_t _result = (expr); \
    if (hyperdag_result_is_error(_result)) { \
        return _result; \
    } \
} while (0)

/**
 * @brief Check if operation succeeded, goto cleanup label if not
 * @param expr Expression that returns hyperdag_result_t
 * @param label Cleanup label to jump to on error
 */
#define HYP_CHECK_GOTO(expr, label) do { \
    hyperdag_result_t _result = (expr); \
    if (hyperdag_result_is_error(_result)) { \
        result = _result; \
        goto label; \
    } \
} while (0)

/**
 * @brief Check if pointer is null, return error if so
 * @param ptr Pointer to check
 */
#define HYP_CHECK_NULL(ptr) do { \
    if ((ptr) == NULL) { \
        return HYP_ERR(HYPERDAG_ERROR_NULL_POINTER, \
                      "Null pointer: " #ptr); \
    } \
} while (0)

/**
 * @brief Check if allocation succeeded, return error if not
 * @param ptr Pointer returned from allocation function
 */
#define HYP_CHECK_ALLOC(ptr) do { \
    if ((ptr) == NULL) { \
        return HYP_ERR(HYPERDAG_ERROR_OUT_OF_MEMORY, \
                      "Allocation failed: " #ptr); \
    } \
} while (0)

/**
 * @brief Check if size parameter is valid, return error if not
 * @param size Size parameter to validate
 * @param max_size Maximum allowed size
 */
#define HYP_CHECK_SIZE(size, max_size) do { \
    if ((size) > (max_size)) { \
        return HYP_ERR(HYPERDAG_ERROR_INVALID_SIZE, \
                      "Size %zu exceeds maximum %zu", \
                      (size_t)(size), (size_t)(max_size)); \
    } \
} while (0)

/**
 * @brief Validate pointer and return error with context if null
 * @param ptr Pointer to validate
 * @param name Name of the pointer for error message
 */
#define HYP_VALIDATE_PTR(ptr, name) do { \
    if ((ptr) == NULL) { \
        return HYP_ERR(HYPERDAG_ERROR_NULL_POINTER, \
                      "Required parameter '%s' is null", (name)); \
    } \
} while (0)

/**
 * @brief Assert condition and return error if false (debug builds only)
 * @param condition Condition to check
 * @param message Error message if condition fails
 */
#ifdef NDEBUG
    #define HYP_ASSERT(condition, message) ((void)0)
#else
    #define HYP_ASSERT(condition, message) do { \
        if (!(condition)) { \
            return HYP_ERR(HYPERDAG_ERROR_ASSERTION_FAILED, \
                          "Assertion failed: %s", (message)); \
        } \
    } while (0)
#endif

/**
 * @brief Mark function as not yet implemented
 */
#define HYP_NOT_IMPLEMENTED() \
    HYP_ERR(HYPERDAG_ERROR_NOT_IMPLEMENTED, \
           "Function %s is not yet implemented", __func__)

/**
 * @brief Mark code path as unreachable
 */
#define HYP_UNREACHABLE() \
    HYP_ERR(HYPERDAG_ERROR_INTERNAL_STATE, \
           "Unreachable code executed in %s at %s:%d", \
           __func__, __FILE__, __LINE__)

#ifdef __cplusplus
}
#endif

#endif // HYPERDAG_RESULT_H