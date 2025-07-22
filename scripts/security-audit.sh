#!/bin/sh
# Comprehensive security audit script for MetaGraph

set -eu

# Load shared shell library (tools auto-configured)
PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
. "$PROJECT_ROOT/scripts/mg.sh"

print_header() {
    echo "================================================"
    echo "🛡️  MetaGraph Security Audit Suite"
    echo "================================================"
}

print_status() {
    mg_green "[AUDIT] $1"
}

print_warning() {
    mg_yellow "[WARN] $1"
}

print_error() {
    mg_red "[CRITICAL] $1"
}

# Binary security analysis
analyze_binary_security() {
    print_status "🔒 Analyzing binary security features..."

    binary="./build/bin/mg-cli"

    if [ ! -f "$binary" ]; then
        print_error "Binary not found: $binary"
        return 1
    fi

    echo "=== Binary Security Analysis ===" > security-audit.txt

    # Check for security features (Linux/macOS)
    if command -v checksec >/dev/null 2>&1; then
        echo "Checksec Analysis:" >> security-audit.txt
        checksec --file="$binary" >> security-audit.txt
    elif command -v objdump >/dev/null 2>&1; then
        echo "Security Features Check:" >> security-audit.txt

        # Check for stack canaries
        if objdump -d "$binary" | grep -q "__stack_chk_fail"; then
            echo "✅ Stack canaries: ENABLED" >> security-audit.txt
        else
            echo "❌ Stack canaries: DISABLED" >> security-audit.txt
        fi

        # Check for PIE
        if file "$binary" | grep -q "shared object"; then
            echo "✅ PIE (Position Independent Executable): ENABLED" >> security-audit.txt
        else
            echo "❌ PIE: DISABLED" >> security-audit.txt
        fi
    fi

    # Check for debugging symbols
    if objdump -h "$binary" | grep -q "debug"; then
        echo "⚠️  Debug symbols: PRESENT (should be stripped for release)" >> security-audit.txt
    else
        echo "✅ Debug symbols: STRIPPED" >> security-audit.txt
    fi

    print_status "Binary analysis saved to security-audit.txt"
}

# Source code security scan
scan_source_code() {
    print_status "🔍 Scanning source code for security issues..."

    # Semgrep security scan
    if command -v semgrep >/dev/null 2>&1; then
        echo "=== Semgrep Security Scan ===" >> security-audit.txt
        semgrep --config=auto --json --output=semgrep-results.json . || true
        semgrep --config=auto . >> security-audit.txt 2>&1 || true
    else
        print_warning "Semgrep not found. Install with: pip install semgrep"
    fi

    # CodeQL analysis (if available)
    if command -v codeql >/dev/null 2>&1; then
        echo "=== CodeQL Analysis ===" >> security-audit.txt
        codeql database create codeql-db --language=cpp --source-root=. || true
        codeql database analyze codeql-db --format=csv --output=codeql-results.csv || true
    fi

    # Basic grep-based security patterns
    echo "=== Basic Security Pattern Analysis ===" >> security-audit.txt

    # Check for dangerous functions
    dangerous_functions="strcpy strcat sprintf gets scanf"
    for func in $dangerous_functions; do
        if grep -r "$func" src/ include/ 2>/dev/null; then
            echo "⚠️  Found potentially dangerous function: $func" >> security-audit.txt
        fi
    done

    # Check for TODO/FIXME security comments
    if grep -r -i "TODO.*security\|FIXME.*security\|XXX.*security" src/ include/ 2>/dev/null; then
        echo "⚠️  Found security-related TODO/FIXME comments" >> security-audit.txt
    fi

    print_status "Source code scan completed"
}

# Dependency vulnerability scan
scan_dependencies() {
    print_status "📦 Scanning dependencies for vulnerabilities..."

    echo "=== Dependency Analysis ===" >> security-audit.txt

    # List all linked libraries
    binary="./build/bin/mg-cli"

    if [ ! -f "$binary" ]; then
        echo "⚠️  Binary not found for dependency analysis" >> security-audit.txt
        return 0
    fi

    if command -v ldd >/dev/null 2>&1; then
        echo "Linked Libraries:" >> security-audit.txt
        ldd "$binary" >> security-audit.txt 2>&1 || true
    elif command -v otool >/dev/null 2>&1; then
        echo "Linked Libraries (macOS):" >> security-audit.txt
        otool -L "$binary" >> security-audit.txt 2>&1 || true
    fi

    # Check for known vulnerable libraries (basic check)
    if ldd "$binary" 2>/dev/null | grep -q "libssl\|libcrypto"; then
        echo "⚠️  Uses OpenSSL - ensure it's up to date" >> security-audit.txt
    fi
}

# Memory safety analysis
analyze_memory_safety() {
    print_status "🧠 Analyzing memory safety..."

    echo "=== Memory Safety Analysis ===" >> security-audit.txt

    # Check if we have test binaries to run
    if [ ! -f "build/bin/mg_unit_tests" ] && [ ! -f "build/bin/placeholder_test" ]; then
        print_warning "No test binaries found - skipping memory safety analysis"
        echo "⚠️  No test binaries for memory safety analysis" >> security-audit.txt
        echo "    Build with 'cmake -B build && cmake --build build' first" >> security-audit.txt
        return 0
    fi

    # Try to build with sanitizers if clang is available
    if command -v clang >/dev/null 2>&1; then
        print_status "Building with AddressSanitizer..."
        
        # Build with address sanitizer
        if cmake -B build-asan \
            -DCMAKE_BUILD_TYPE=Debug \
            -DMETAGRAPH_SANITIZERS=ON \
            -DCMAKE_C_COMPILER=clang >/dev/null 2>&1; then
            
            if cmake --build build-asan --parallel >/dev/null 2>&1; then
                # Run tests with ASAN
                export ASAN_OPTIONS="abort_on_error=1:halt_on_error=1:print_stats=1"
                
                # Find and run any test binary
                test_binary=$(find build-asan/bin -name '*test*' -type f 2>/dev/null | head -1)
                if [ -n "$test_binary" ] && [ -f "$test_binary" ]; then
                    if "$test_binary" >/dev/null 2>&1; then
                        echo "✅ AddressSanitizer: No memory safety issues detected" >> security-audit.txt
                    else
                        echo "❌ AddressSanitizer: Memory safety issues detected!" >> security-audit.txt
                    fi
                else
                    echo "⚠️  No test binaries found in sanitizer build" >> security-audit.txt
                fi
            else
                echo "⚠️  Failed to build with AddressSanitizer" >> security-audit.txt
            fi
        else
            echo "⚠️  Failed to configure AddressSanitizer build" >> security-audit.txt
        fi
    else
        echo "⚠️  Clang not found - cannot perform sanitizer analysis" >> security-audit.txt
    fi
}

# Cryptographic analysis
analyze_cryptography() {
    print_status "🔐 Analyzing cryptographic implementations..."

    echo "=== Cryptographic Analysis ===" >> security-audit.txt

    # Check for hardcoded keys/secrets
    if grep -r -i "password\|secret\|key\|token" src/ include/ | grep -v "test\|example"; then
        echo "⚠️  Potential hardcoded secrets found - review manually" >> security-audit.txt
    else
        echo "✅ No obvious hardcoded secrets found" >> security-audit.txt
    fi

    # Check for weak random number generation
    if grep -r "rand()\|srand()" src/ include/; then
        echo "⚠️  Found use of weak PRNG (rand/srand) - consider secure alternatives" >> security-audit.txt
    else
        echo "✅ No weak PRNG usage detected" >> security-audit.txt
    fi
}

# Compliance checks
check_compliance() {
    print_status "📋 Checking security compliance..."

    echo "=== Security Compliance Checklist ===" >> security-audit.txt

    # Check for security documentation
    if [ -f "SECURITY.md" ]; then
        echo "✅ Security policy document present" >> security-audit.txt
    else
        echo "❌ Security policy document missing" >> security-audit.txt
    fi

    # Check for vulnerability reporting
    if grep -q "security\|vulnerability" README.md 2>/dev/null; then
        echo "✅ Vulnerability reporting information present" >> security-audit.txt
    else
        echo "❌ Vulnerability reporting information missing" >> security-audit.txt
    fi

    # Check for automated security scanning
    if [ -f ".github/workflows/security.yml" ] || [ -f ".github/workflows/codeql.yml" ]; then
        echo "✅ Automated security scanning configured" >> security-audit.txt
    else
        echo "❌ Automated security scanning not configured" >> security-audit.txt
    fi
}

# Generate security report
generate_report() {
    print_status "📊 Generating comprehensive security report..."

    timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

    cat > security-report.md << EOF
# MetaGraph Security Audit Report

**Generated:** $timestamp
**Auditor:** Automated Security Audit Suite
**Version:** $(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

## Executive Summary

This report contains the results of a comprehensive security audit of the MetaGraph codebase.

## Detailed Findings

$(cat security-audit.txt)

## Recommendations

1. **High Priority:**
   - Address any critical security issues found above
   - Ensure all dependencies are up to date
   - Review and test security-critical code paths

2. **Medium Priority:**
   - Implement additional input validation
   - Consider formal security review for cryptographic operations
   - Add security-focused unit tests

3. **Low Priority:**
   - Document security assumptions and threat model
   - Consider third-party security audit for production use

## Security Checklist

- [ ] All critical and high-severity issues resolved
- [ ] Dependencies scanned and updated
- [ ] Security testing automated in CI/CD
- [ ] Security documentation complete
- [ ] Incident response plan documented

---
*This report was generated automatically. Manual review is recommended.*
EOF

    print_status "Security report generated: security-report.md"
}

# Main execution
main() {
    print_header

    # Ensure we have a build
    if [ ! -d "build" ]; then
        print_status "Building project for security analysis..."
        cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=clang
        cmake --build build --parallel
    elif [ ! -f "build/bin/mg-cli" ]; then
        print_status "Building missing binaries for security analysis..."
        cmake --build build --parallel
    fi

    # Run all security checks
    analyze_binary_security
    scan_source_code
    scan_dependencies
    analyze_memory_safety
    analyze_cryptography
    check_compliance
    generate_report

    echo
    print_status "🎉 Security audit complete!"
    print_status "Review the following files:"
    print_status "  - security-audit.txt (detailed findings)"
    print_status "  - security-report.md (formatted report)"

    # Check if any critical issues were found
    if grep -q "❌\|CRITICAL" security-audit.txt; then
        print_error "Critical security issues found! Review security-audit.txt"
        exit 1
    else
        print_status "✅ No critical security issues detected"
    fi
}

# Run if called directly
if [ "$0" = "${0%/*}/security-audit.sh" ] || [ "$0" = "./security-audit.sh" ] || [ "$0" = "security-audit.sh" ]; then
    main "$@"
fi
