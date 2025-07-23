#!/usr/bin/env bash
# Fail-fast rules for source/target branch combinations.

set -euo pipefail

SRC="$1"   # head ref
DST="$2"   # base ref

die() { echo "::error::$*"; exit 1; }

case "$SRC" in
  release/v*)
    [[ "$DST" == "main" ]] || die "release/* must target main."
    ;;
  fix/*)
    true ;; # fix/* can target anything
  feat/*)
    [[ "$DST" == release/v* ]] \
      || die "feat/* must target a release/vX.Y.Z branch."
    [[ "$SRC" =~ ^feat/[0-9]+-[a-z0-9._-]+$ ]] \
      || die "feat/* name must be feat/{issue#}-{slug}."
    ;;
  *)
    die "Branch must begin with release/, fix/, or feat/."
    ;;
esac

if [[ "$DST" == "main" && ! "$SRC" =~ ^(release|fix)/ ]]; then
  die "Only release/* or fix/* may target main."
fi