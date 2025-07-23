#!/usr/bin/env bash
# Reject PR if version.h on source branch is *newer* than target release.

set -euo pipefail

SRC_SHA="$1"       # commit SHA to inspect
DST_BRANCH="$2"    # e.g. release/v1.2.3

[[ "$DST_BRANCH" == release/v* ]] || exit 0   # only runs for release targets

dst_ver="${DST_BRANCH#release/v}"

src_ver=$(git show "$SRC_SHA:include/metagraph/version.h" \
          | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)

[[ -z "$src_ver" ]] && exit 0  # nothing to compare

if ! printf '%s\n%s\n' "$dst_ver" "$src_ver" | sort -V -C ; then
  echo "::error::version.h ($src_ver) is newer than target $dst_ver"
  exit 1
fi