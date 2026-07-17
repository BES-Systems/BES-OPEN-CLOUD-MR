#!/usr/bin/env bash

echo "[BES] Installing repository git aliases..."

git config alias.aicommit '!bash ./scripts/ai-commit.sh'
git config alias.aireview '!bash ./scripts/ai-review.sh'
git config alias.airelease '!bash ./scripts/ai-release.sh'
git config alias.aichangelog '!bash ./scripts/ai-changelog.sh'

echo "[BES] Done."
