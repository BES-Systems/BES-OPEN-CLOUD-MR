#!/usr/bin/env bash

echo "[BES] Installing repository git aliases..."

git config alias.aicommit '!bash ./scripts/ai-commit.sh'
git config alias.aireview '!bash ./scripts/ai-review.sh'

echo "[BES] Done."
