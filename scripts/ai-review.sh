#!/usr/bin/env bash

set -euo pipefail

MODEL="gemma-4-e4b"
LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"


DIFF=$(git diff HEAD)

if [[ -z "$DIFF" ]]; then
    echo "[BES AI] No changes found."
    exit 1
fi


echo "[BES AI] Reviewing code..."


PROMPT="
You are a senior infrastructure engineer reviewing BES OpenCloud.

Analyze this code change.

Focus on:

SECURITY:
- vulnerabilities
- unsafe input
- permissions
- secrets

ARCHITECTURE:
- design problems
- scalability
- maintainability

PERFORMANCE:
- bottlenecks
- unnecessary operations

CODE QUALITY:
- bugs
- bad patterns
- readability

TESTING:
- missing tests
- edge cases

Return:

# Summary

# Critical Issues

# Warnings

# Suggestions

# Test Recommendations


Repository:
BES OpenCloud


Diff:

$DIFF
"


curl -s "$LM_STUDIO_URL" \
-H "Content-Type: application/json" \
-d "$(jq -n \
--arg model "$MODEL" \
--arg prompt "$PROMPT" \
'{
model:$model,
messages:[
{
role:"user",
content:$prompt
}
],
temperature:0.1
}')" \
| jq -r '.choices[0].message.content'
