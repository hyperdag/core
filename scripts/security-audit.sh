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

    # Ensure output directory exists
    mkdir -p .ignored

    echo "=== Binary Security Analysis ===" > .ignored/security-audit.txt

    # Check for security features (Linux/macOS)
    if command -v checksec >/dev/null 2>&1; then
        echo "Checksec Analysis:" >> .ignored/security-audit.txt
        checksec --file="$binary" >> .ignored/security-audit.txt
    elif command -v objdump >/dev/null 2>&1; then
        echo "Security Features Check:" >> .ignored/security-audit.txt

        # Check for stack canaries
        if objdump -d "$binary" 2>/dev/null | grep -q "__stack_chk_fail"; then
            echo "✅ Stack canaries: ENABLED" >> .ignored/security-audit.txt
        elif nm "$binary" 2>/dev/null | grep -q "__stack_chk_fail"; then
            echo "✅ Stack canaries: ENABLED" >> .ignored/security-audit.txt
        else
            echo "❌ Stack canaries: DISABLED" >> .ignored/security-audit.txt
        fi

        # Check for PIE
        if file "$binary" | grep -q "shared object"; then
            echo "✅ PIE (Position Independent Executable): ENABLED" >> .ignored/security-audit.txt
        elif file "$binary" | grep -q "Mach-O.*executable.*PIE"; then
            echo "✅ PIE (Position Independent Executable): ENABLED" >> .ignored/security-audit.txt
        elif otool -hv "$binary" 2>/dev/null | grep -q "PIE"; then
            echo "✅ PIE (Position Independent Executable): ENABLED" >> .ignored/security-audit.txt
        else
            echo "❌ PIE: DISABLED" >> .ignored/security-audit.txt
        fi
    fi

    # Check for debugging symbols
    if objdump -h "$binary" | grep -q "debug"; then
        echo "⚠️  Debug symbols: PRESENT (should be stripped for release)" >> .ignored/security-audit.txt
    else
        echo "✅ Debug symbols: STRIPPED" >> .ignored/security-audit.txt
    fi

    print_status "Binary analysis saved to .ignored/security-audit.txt"
}

# Source code security scan
scan_source_code() {
    print_status "🔍 Scanning source code for security issues..."

    # Semgrep security scan
    if command -v semgrep >/dev/null 2>&1; then
        echo "=== Semgrep Security Scan ===" >> .ignored/security-audit.txt
        semgrep --config=auto --json --output=.ignored/semgrep-results.json . || true
        semgrep --config=auto . >> .ignored/security-audit.txt 2>&1 || true
    else
        print_error "Semgrep not found. Run ./scripts/setup-dev-env.sh to install"
        echo "❌ Semgrep security scan: MISSING" >> .ignored/security-audit.txt
        return 1
    fi

    # CodeQL analysis (if available)
    if command -v codeql >/dev/null 2>&1; then
        echo "=== CodeQL Analysis ===" >> .ignored/security-audit.txt
        codeql database create codeql-db --language=cpp --source-root=. || true
        codeql database analyze codeql-db --format=csv --output=codeql-results.csv || true
    fi

    # Basic grep-based security patterns
    echo "=== Basic Security Pattern Analysis ===" >> .ignored/security-audit.txt

    # Check for dangerous functions
    dangerous_functions="strcpy strcat sprintf gets scanf"
    for func in $dangerous_functions; do
        if grep -r "$func" src/ include/ 2>/dev/null; then
            echo "⚠️  Found potentially dangerous function: $func" >> .ignored/security-audit.txt
        fi
    done

    # Check for TODO/FIXME security comments
    if grep -r -i "TODO.*security\|FIXME.*security\|XXX.*security" src/ include/ 2>/dev/null; then
        echo "⚠️  Found security-related TODO/FIXME comments" >> .ignored/security-audit.txt
    fi

    print_status "Source code scan completed"
}

# Dependency vulnerability scan
scan_dependencies() {
    print_status "📦 Scanning dependencies for vulnerabilities..."

    echo "=== Dependency Analysis ===" >> .ignored/security-audit.txt

    # List all linked libraries
    binary="./build/bin/mg-cli"

    if [ ! -f "$binary" ]; then
        echo "⚠️  Binary not found for dependency analysis" >> .ignored/security-audit.txt
        return 0
    fi

    if command -v ldd >/dev/null 2>&1; then
        echo "Linked Libraries:" >> .ignored/security-audit.txt
        ldd "$binary" >> .ignored/security-audit.txt 2>&1 || true
    elif command -v otool >/dev/null 2>&1; then
        echo "Linked Libraries (macOS):" >> .ignored/security-audit.txt
        otool -L "$binary" >> .ignored/security-audit.txt 2>&1 || true
    fi

    # Check for known vulnerable libraries (basic check)
    if ldd "$binary" 2>/dev/null | grep -q "libssl\|libcrypto"; then
        echo "⚠️  Uses OpenSSL - ensure it's up to date" >> .ignored/security-audit.txt
    fi
}

# Memory safety analysis
analyze_memory_safety() {
    print_status "🧠 Analyzing memory safety..."

    echo "=== Memory Safety Analysis ===" >> .ignored/security-audit.txt

    # Check if we have test binaries to run
    if [ ! -f "build/bin/mg_unit_tests" ] && [ ! -f "build/bin/placeholder_test" ]; then
        print_warning "No test binaries found - skipping memory safety analysis"
        echo "⚠️  No test binaries for memory safety analysis" >> .ignored/security-audit.txt
        echo "    Build with 'cmake -B build && cmake --build build' first" >> .ignored/security-audit.txt
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
                        echo "✅ AddressSanitizer: No memory safety issues detected" >> .ignored/security-audit.txt
                    else
                        echo "❌ AddressSanitizer: Memory safety issues detected!" >> .ignored/security-audit.txt
                    fi
                else
                    echo "⚠️  No test binaries found in sanitizer build" >> .ignored/security-audit.txt
                fi
            else
                echo "⚠️  Failed to build with AddressSanitizer" >> .ignored/security-audit.txt
            fi
        else
            echo "⚠️  Failed to configure AddressSanitizer build" >> .ignored/security-audit.txt
        fi
    else
        echo "⚠️  Clang not found - cannot perform sanitizer analysis" >> .ignored/security-audit.txt
    fi
}

# Cryptographic analysis
analyze_cryptography() {
    print_status "🔐 Analyzing cryptographic implementations..."

    echo "=== Cryptographic Analysis ===" >> .ignored/security-audit.txt

    # Check for hardcoded keys/secrets
    if grep -r -i "password\|secret\|key\|token" src/ include/ | grep -v "test\|example"; then
        echo "⚠️  Potential hardcoded secrets found - review manually" >> .ignored/security-audit.txt
    else
        echo "✅ No obvious hardcoded secrets found" >> .ignored/security-audit.txt
    fi

    # Check for weak random number generation
    if grep -r "rand()\|srand()" src/ include/; then
        echo "⚠️  Found use of weak PRNG (rand/srand) - consider secure alternatives" >> .ignored/security-audit.txt
    else
        echo "✅ No weak PRNG usage detected" >> .ignored/security-audit.txt
    fi
}

# Compliance checks
check_compliance() {
    print_status "📋 Checking security compliance..."

    echo "=== Security Compliance Checklist ===" >> .ignored/security-audit.txt

    # Check for security documentation
    if [ -f "SECURITY.md" ]; then
        echo "✅ Security policy document present" >> .ignored/security-audit.txt
    else
        echo "❌ Security policy document missing" >> .ignored/security-audit.txt
    fi

    # Check for vulnerability reporting
    if grep -i -q "security\|vulnerability" README.md 2>/dev/null || [ -f "SECURITY.md" ]; then
        echo "✅ Vulnerability reporting information present" >> .ignored/security-audit.txt
    else
        echo "❌ Vulnerability reporting information missing" >> .ignored/security-audit.txt
    fi

    # Check for automated security scanning
    if [ -f ".github/workflows/security.yml" ] || [ -f ".github/workflows/codeql.yml" ] || grep -q "CodeQL\|codeql" .github/workflows/*.yml 2>/dev/null; then
        echo "✅ Automated security scanning configured" >> .ignored/security-audit.txt
    else
        echo "❌ Automated security scanning not configured" >> .ignored/security-audit.txt
    fi
}

# Generate security report
generate_report() {
    print_status "📊 Generating comprehensive security report..."

    timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

    cat > .ignored/security-report.md << EOF
# MetaGraph Security Audit Report

**Generated:** $timestamp
**Auditor:** Automated Security Audit Suite
**Version:** $(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

## Executive Summary

This report contains the results of a comprehensive security audit of the MetaGraph codebase.

## Detailed Findings

$(cat .ignored/security-audit.txt)

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

    print_status "Security report generated: .ignored/security-report.md"
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
    print_status "  - .ignored/security-audit.txt (detailed findings)"
    print_status "  - .ignored/security-report.md (formatted report)"

    # Check if any critical issues were found
    if grep -q "❌\|CRITICAL" .ignored/security-audit.txt; then
        print_error "Critical security issues found! Review .ignored/security-audit.txt"
        exit 1
    else
        print_status "✅ No critical security issues detected"
    fi
}

# Run if called directly
if [ "$0" = "${0%/*}/security-audit.sh" ] || [ "$0" = "./security-audit.sh" ] || [ "$0" = "security-audit.sh" ]; then
    main "$@"
fi
