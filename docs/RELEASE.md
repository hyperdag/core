# MetaGraph Release Process

This document describes the Fort Knox-grade release process for MetaGraph. This process ensures deterministic builds, comprehensive validation, and cryptographic attestation of all releases.

## Overview

The MetaGraph release process follows a strict workflow designed to prevent accidental releases, ensure quality, and maintain a complete audit trail. The process is fail-fast: any issue immediately halts the release.

## Release Workflow

### 1. Feature Development

All development happens on feature branches:
- Branch from `main` with descriptive names (e.g., `feat/hypergraph-traversal`)
- Follow conventional commit format
- Ensure all commits pass pre-commit hooks

### 2. Create Release Branch

When ready to prepare a release:

```bash
# Create release branch from main
git checkout main
git pull origin main
git checkout -b release/v0.1.0

# For release candidates
git checkout -b release/v0.1.0-rc1
```

Release branch naming:
- **Format**: `release/vMAJOR.MINOR.PATCH[-PRERELEASE]`
- **Examples**: `release/v0.1.0`, `release/v1.0.0-rc1`, `release/v2.3.4-beta`

### 3. Prepare Release

Run the release preparation script:

```bash
./scripts/prepare-release.sh
```

This script performs comprehensive validation:

#### Pre-flight Checks
1. **Branch Validation**: Ensures you're on a `release/v*` branch
2. **Clean Worktree**: No uncommitted changes or untracked files
3. **Version Validation**: Version must be higher than latest tag and current version
4. **Version Consistency**: All version files must match the branch version

#### Quality Matrix
1. **Clean Release Build**: Full rebuild with `-DCMAKE_BUILD_TYPE=Release`
2. **Test Suite**: All tests must pass with no failures
3. **Static Analysis**: clang-tidy must report zero issues
4. **Security Audit**: All security checks must pass
5. **Performance Check**: No regressions beyond ±5% tolerance

If any check fails, the script exits with a specific error code:
- `1`: Not on a release branch
- `2`: Dirty working tree
- `3`: Version mismatch in files
- `4`: Version downgrade detected
- `5`: Quality check failed
- `6`: Version files were updated (commit needed)

### 4. Commit Version Updates

If the script updates version files:

```bash
git add include/metagraph/version.h CMakeLists.txt
git commit -m "chore: bump version to v0.1.0

Prepare for v0.1.0 release

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 5. Push and Create PR

```bash
# Push the release branch
git push -u origin release/v0.1.0

# Create PR to main
gh pr create --base main --title "Release v0.1.0" \
  --body "## Release v0.1.0

### Changes
- Feature: Hypergraph data model implementation
- Feature: Binary bundle format
- Enhancement: Thread-safe graph operations

### Validation
- [x] All tests passing
- [x] Static analysis clean
- [x] Security audit passed
- [x] Performance within tolerance
- [x] Version files updated

### Release Checklist
- [ ] Approved by @CODEOWNER
- [ ] CI/CD pipeline green
- [ ] CHANGELOG.md updated
- [ ] Migration guide (if breaking changes)

🤖 Generated with [Claude Code](https://claude.ai/code)"
```

### 6. Merge to Main

Only release branches can merge to main:
1. PR must be approved by CODEOWNERS
2. All CI checks must pass
3. No direct commits to main allowed

### 7. Tag and Release

After merging to main, CI automatically:

1. **Creates Git Tag**: `v0.1.0` signed with GPG
2. **Builds Release Artifacts**:
   - Source tarball with SHA256 checksum
   - Binary packages for each platform
   - SBOM (Software Bill of Materials)
3. **Signs Artifacts**: Using cosign with OIDC identity
4. **Creates GitHub Release**: With all artifacts and signatures
5. **Publishes Documentation**: Updates docs site

## Version Management

### Version Files

Version information is stored in:
- `include/metagraph/version.h`: API version and build info
- `CMakeLists.txt`: Project version for CMake

### Version Format

MetaGraph follows [Semantic Versioning](https://semver.org/):
- **MAJOR**: Incompatible API changes
- **MINOR**: Backwards-compatible functionality
- **PATCH**: Backwards-compatible bug fixes
- **PRERELEASE**: Optional (e.g., `-rc1`, `-beta`)

### Version Comparison

The release script uses `sort -V` for proper semantic version comparison, correctly handling:
- `0.9.0` < `0.10.0` (numeric comparison)
- `1.0.0-rc1` < `1.0.0` (pre-release ordering)
- `2.0.0-alpha` < `2.0.0-beta` < `2.0.0`

## Performance Baselines

Performance baselines are machine-specific and not stored in git:

```bash
# Create baseline for your machine
./scripts/profile.sh timing
cp .ignored/timing-analysis.txt performance-baseline.txt

# Baseline is used by prepare-release.sh
# Regression > 5% will fail the release
```

## Security Requirements

All releases must pass security audit:
- **Stack Canaries**: Required on all binaries
- **PIE/ASLR**: Position Independent Executables
- **FORTIFY_SOURCE**: Buffer overflow protection
- **Secure Flags**: No executable stacks, full RELRO
- **Dependency Scan**: No known vulnerabilities

## CI/CD Integration

### Pre-push Hook

The pre-push hook automatically runs `prepare-release.sh` on release branches:

```bash
# Automatically triggered when pushing release/* branches
git push origin release/v0.1.0
# Hook runs prepare-release.sh before push
```

### GitHub Actions

Release workflow (`/.github/workflows/release.yml`):
1. Triggered on push to `main` with version tag
2. Builds deterministic artifacts
3. Runs full test matrix
4. Generates and signs SBOM
5. Creates GitHub release
6. Notifies maintainers

## Rollback Procedure

If issues are discovered post-release:

1. **Revert Merge**: Create revert PR immediately
2. **Investigate**: Root cause analysis
3. **Fix Forward**: Patch on new release branch
4. **Expedited Release**: Follow same process with higher urgency

## Release Checklist

Before starting a release:
- [ ] All planned features merged
- [ ] No open security issues
- [ ] Documentation updated
- [ ] CHANGELOG.md prepared
- [ ] Performance baseline current
- [ ] Team notification sent

During release:
- [ ] Release branch created
- [ ] prepare-release.sh passes
- [ ] Version files committed
- [ ] PR created and approved
- [ ] CI/CD pipeline green

Post-release:
- [ ] Tag created automatically
- [ ] Artifacts published
- [ ] Documentation deployed
- [ ] Announcement sent

## Troubleshooting

### Common Issues

**Working tree is dirty**
```bash
# Check status
git status

# Stash changes if needed
git stash

# Or commit changes
git add -A && git commit -m "..."
```

**Version mismatch**
```bash
# Script will show which files need updating
# After script updates them:
git add include/metagraph/version.h CMakeLists.txt
git commit -m "chore: bump version files"
```

**Performance regression**
```bash
# Update baseline if legitimate
./scripts/profile.sh timing
cp .ignored/timing-analysis.txt performance-baseline.txt

# Or investigate regression
./scripts/profile.sh memory
```

**Security audit failure**
```bash
# Check specific failure
cat .ignored/security-audit.txt

# Common fixes:
# - Stack canaries: Add buffer operations
# - PIE: Check CMAKE_POSITION_INDEPENDENT_CODE
```

## Exit Codes Reference

| Code | Meaning | Resolution |
|------|---------|------------|
| 0 | Success | Ready to push |
| 1 | Not on release branch | Create release/v* branch |
| 2 | Dirty worktree | Commit or stash changes |
| 3 | Version mismatch | Commit updated files |
| 4 | Version downgrade | Use higher version |
| 5 | Quality check failed | Fix the specific issue |
| 6 | Files need commit | Commit version updates |

## Advanced Topics

### Deterministic Builds

Releases are built with:
- `SOURCE_DATE_EPOCH`: Reproducible timestamps
- `-ffile-prefix-map`: Strip build paths
- Sorted inputs: Consistent file ordering
- Pinned dependencies: Exact versions

### Cryptographic Attestation

All artifacts include:
- **SHA256 checksums**: For integrity
- **GPG signatures**: For authenticity
- **SBOM**: Complete dependency tree
- **Cosign signatures**: OIDC-based signing

### Emergency Release

For critical security fixes:
1. Create `hotfix/v*` branch from affected tag
2. Apply minimal fix
3. Follow standard release process
4. Backport to main if applicable

## Summary

The MetaGraph release process prioritizes:
1. **Safety**: Fail-fast validation prevents bad releases
2. **Quality**: Comprehensive checks ensure stability
3. **Security**: Cryptographic attestation and audit trail
4. **Reproducibility**: Deterministic builds enable verification

This Fort Knox approach ensures every release meets the highest standards of quality and security.