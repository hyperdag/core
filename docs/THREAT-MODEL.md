# MetaGraph Threat Model

## Executive Summary

MetaGraph processes untrusted binary bundles and user-provided graph data, making it a critical security boundary. This document identifies attack vectors, assets, trust boundaries, and mitigations for the MetaGraph core library.

**Security Goals**: Confidentiality, Integrity, Availability
**Primary Threats**: Malicious bundles, memory corruption, denial of service
**Trust Boundary**: MetaGraph library ↔ Bundle files and user input

## Assets and Trust Boundaries

### Protected Assets
1. **Process Memory** - Prevent corruption, information leakage
2. **System Resources** - CPU, memory, file handles, disk space
3. **Data Integrity** - Graph consistency, bundle authenticity
4. **Application Availability** - Prevent crashes, infinite loops, resource exhaustion

### Trust Boundaries
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Host Process  │────│  MetaGraph Core  │────│  Bundle Files   │
│   (Trusted)     │    │ (Trust Boundary)│    │  (Untrusted)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                        ┌─────────────────┐
                        │   User Input    │
                        │  (Untrusted)    │
                        └─────────────────┘
```

## Threat Categories

### 1. Malicious Bundle Attacks

#### T001: Bundle Header Tampering
**Attacker Goal**: Bypass validation, trigger buffer overflows
**Attack Vector**: Modified magic numbers, invalid sizes, corrupted checksums
**Impact**: Memory corruption, crashes, potential RCE

**Mitigations**:
- ✅ Comprehensive header validation before processing
- ✅ BLAKE3 cryptographic integrity verification
- ✅ Size bounds checking against available memory/disk
- ✅ Format UUID validation for version compatibility

#### T002: Hash Length Extension Attacks
**Attacker Goal**: Forge valid checksums for malicious data
**Attack Vector**: Exploit hash algorithm weaknesses
**Impact**: Bypass integrity checks, corrupt graph data

**Mitigations**:
- ✅ BLAKE3 immune to length extension attacks (unlike SHA-1/SHA-2)
- ✅ Separate header and content hashes prevent cross-contamination
- ✅ Hash verification before any data processing

#### T003: Integer Overflow in Size Fields
**Attacker Goal**: Trigger integer wraparound in memory calculations
**Attack Vector**: Large size values causing allocation wraparound
**Impact**: Buffer overflows, memory corruption

**Mitigations**:
- ✅ Explicit overflow checking using C23 `ckd_add()` functions
- ✅ Maximum size limits enforced at bundle load time
- ✅ 64-bit size fields prevent most practical overflow scenarios

#### T004: Section Offset Manipulation
**Attacker Goal**: Access memory outside allocated regions
**Attack Vector**: Invalid section offsets pointing beyond bundle boundaries
**Impact**: Segmentation faults, information disclosure

**Mitigations**:
- ✅ Bounds checking for all section offsets against total bundle size
- ✅ Memory mapping with guard pages to catch offset errors
- ✅ Pointer validation before dereference in hot paths

### 2. Memory Corruption Attacks

#### T005: Buffer Overflow in Asset Data
**Attacker Goal**: Overwrite adjacent memory structures
**Attack Vector**: Asset content larger than declared size
**Impact**: Code execution, privilege escalation

**Mitigations**:
- ✅ Strict bounds checking in all copy operations
- ✅ AddressSanitizer validation in debug builds
- ✅ Safe string handling using `strncpy_s()` equivalents

#### T006: Use-After-Free in Graph Operations
**Attacker Goal**: Access freed memory containing sensitive data
**Attack Vector**: Concurrent graph modifications during traversal
**Impact**: Information disclosure, corruption, crashes

**Mitigations**:
- ✅ Reference counting for shared graph nodes
- ✅ RCU-style memory reclamation for lock-free operations
- ✅ Memory poisoning in debug builds to catch UAF early

#### T007: Double-Free in Error Paths
**Attacker Goal**: Trigger memory allocator corruption
**Attack Vector**: Error conditions causing multiple cleanup attempts
**Impact**: Heap corruption, potential RCE

**Mitigations**:
- ✅ Consistent ownership patterns with RAII cleanup
- ✅ Memory debugging with mimalloc's double-free detection
- ✅ Automated static analysis with ownership tracking

### 3. Denial of Service Attacks

#### T008: Resource Exhaustion via Large Graphs
**Attacker Goal**: Exhaust system memory or CPU
**Attack Vector**: Bundles with millions of nodes/edges
**Impact**: System unresponsiveness, OOM crashes

**Mitigations**:
- ✅ Configurable memory limits enforced by memory pools
- ✅ Lazy loading of graph sections to limit initial memory usage
- ✅ Memory pressure callbacks for graceful degradation

#### T009: Algorithmic Complexity Attacks
**Attacker Goal**: Trigger worst-case algorithm performance
**Attack Vector**: Carefully crafted graphs causing O(n²) behavior
**Impact**: CPU exhaustion, application timeouts

**Mitigations**:
- ✅ Hash table load factor monitoring to prevent O(n) lookups
- ✅ Timeout mechanisms for graph traversal operations
- ✅ Cycle detection to prevent infinite loops

#### T010: Infinite Loops in Graph Traversal
**Attacker Goal**: Hang application threads indefinitely
**Attack Vector**: Circular references despite DAG constraints
**Impact**: Thread exhaustion, application freeze

**Mitigations**:
- ✅ Visited node tracking in all traversal algorithms
- ✅ Maximum depth limits to bound recursion
- ✅ Cooperative cancellation tokens for long operations

### 4. Information Disclosure Attacks

#### T011: Memory Information Leakage
**Attacker Goal**: Extract sensitive data from process memory
**Attack Vector**: Uninitialized memory or padding bytes in structures
**Impact**: Information disclosure, privacy violation

**Mitigations**:
- ✅ Explicit memory initialization of all allocated structures
- ✅ Memory scanning tools to detect uninitialized reads
- ✅ Structure padding explicitly zeroed in constructors

#### T012: Timing Side-Channel Attacks
**Attacker Goal**: Infer sensitive information from operation timing
**Attack Vector**: Measure hash table lookup times to deduce content
**Impact**: Asset fingerprinting, cache attacks

**Mitigations**:
- ✅ Constant-time comparison functions for cryptographic hashes
- ✅ Random delays in debug builds to detect timing dependencies
- ✅ Hash table design resistant to timing analysis

## Attack Scenarios

### Scenario 1: Malicious Asset Bundle
1. **Setup**: Attacker provides a bundle file with corrupted header
2. **Attack**: Bundle claims 1KB size but contains 1GB of data
3. **Expected Defense**: Header validation rejects bundle before memory allocation
4. **Fallback**: Memory mapping fails safely, error returned to caller

### Scenario 2: Concurrent Graph Modification
1. **Setup**: Application reads graph while another thread modifies it
2. **Attack**: Race condition causes use-after-free on graph node
3. **Expected Defense**: RCU prevents memory reclamation during read
4. **Fallback**: AddressSanitizer detects UAF and terminates safely

### Scenario 3: Resource Exhaustion
1. **Setup**: Bundle contains 10M nodes in a single hyperedge
2. **Attack**: Memory allocation for edge structure exceeds system limits
3. **Expected Defense**: Memory pool limit triggers graceful failure
4. **Fallback**: OOM handler provides diagnostic error message

## Security Testing Strategy

### Static Analysis
- **clang-tidy**: Memory safety, undefined behavior detection
- **PVS-Studio**: Commercial static analysis for complex vulnerabilities
- **Coverity**: Integer overflow and buffer overflow detection

### Dynamic Analysis
- **AddressSanitizer**: Memory corruption detection during execution
- **ThreadSanitizer**: Race condition and data race detection
- **MemorySanitizer**: Uninitialized memory access detection

### Fuzzing
- **libFuzzer**: Structure-aware fuzzing of bundle parsing code
- **AFL++**: Coverage-guided fuzzing with custom dictionaries
- **Property Testing**: Invariant checking during fuzz campaigns

### Penetration Testing
- **Bundle Corpus**: Collection of malformed bundles for validation
- **Stress Testing**: Large graphs under memory pressure
- **Concurrency Testing**: Race condition detection under load

## Incident Response

### Vulnerability Classification
- **Critical**: Remote code execution, privilege escalation
- **High**: Memory corruption, denial of service
- **Medium**: Information disclosure, logic errors
- **Low**: Performance degradation, minor leaks

### Response Timeline
- **Critical**: 24-hour disclosure, immediate patch
- **High**: 72-hour disclosure, patch within 1 week
- **Medium**: 30-day disclosure, patch within 1 month
- **Low**: Next release cycle

### Communication Channels
- **Security Reports**: <james@flyingrobots.dev> (encrypted)
- **Public Disclosure**: GitHub Security Advisories
- **User Notification**: Release notes and security bulletins

## Compliance and Standards

### Security Frameworks
- **SLSA v1.1**: Build provenance and supply chain security
- **CVE**: Common Vulnerabilities and Exposures tracking
- **CWE**: Common Weakness Enumeration reference

### Code Quality
- **MISRA C**: Safety-critical coding standards (subset)
- **SEI CERT C**: Secure coding practices
- **ISO/IEC 27001**: Information security management

---

**Document Version**: 1.0
**Last Updated**: 2025-07-20
**Review Schedule**: Quarterly or after security incidents
**Approved By**: Development Team

*This threat model is a living document and should be updated as new threats emerge or system architecture changes.*
