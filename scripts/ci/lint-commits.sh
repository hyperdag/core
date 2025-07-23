#!/usr/bin/env bash
# Lints all commit messages in the PR using commitlint (conventional commits).

set -euo pipefail

range="$1"  # e.g. "origin/$BASE_REF...$HEAD_SHA"

npx --yes @commitlint/cli@18 commitlint --from "$(git merge-base "$range")" --to "$HEAD_SHA"