#!/usr/bin/env bash

set -euo pipefail

# ============================================
# BES AI Changelog Generator
# Local LLM powered changelog assistant
# ============================================

MODEL="gemma-4-e4b"
LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"


# --------------------------------------------
# Requirements
# --------------------------------------------

command -v jq >/dev/null || {
    echo "[ERROR] jq required"
    exit 1
}


# --------------------------------------------
# Check LM Studio
# --------------------------------------------

echo "[BES AI] Checking LM Studio..."

if ! curl -s "$LM_STUDIO_URL" >/dev/null; then
    echo "[ERROR] LM Studio is not running"
    exit 1
fi


# --------------------------------------------
# Git history
# --------------------------------------------

LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")


if [[ -n "$LAST_TAG" ]]; then

COMMITS=$(git log \
"$LAST_TAG"..HEAD \
--pretty=format:"%h %s")

else

COMMITS=$(git log \
--pretty=format:"%h %s" \
-n 100)

fi


if [[ -z "$COMMITS" ]]; then
    echo "[BES AI] No commits found."
    exit 1
fi


echo "[BES AI] Generating changelog..."



PROMPT="
You are a professional open-source maintainer.

Generate a clean CHANGELOG.md section.

Rules:

- Use Keep a Changelog style.
- Do not mention commit hashes.
- Group changes:

## Added
## Changed
## Fixed
## Removed
## Security

Only include sections that have content.

Do not use markdown code blocks.

Commits:

$COMMITS
"


RESPONSE=$(curl -s "$LM_STUDIO_URL" \
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
temperature:0.2
}')")


CHANGELOG=$(echo "$RESPONSE" \
| jq -r '.choices[0].message.content')



if [[ -z "$CHANGELOG" || "$CHANGELOG" == "null" ]]; then
    echo "[ERROR] AI failed"
    exit 1
fi



echo
echo "=============================="
echo " Generated Changelog"
echo "=============================="
echo "$CHANGELOG"
echo "=============================="
echo


read -p "Update CHANGELOG.md? [y/N] " CONFIRM


if [[ "$CONFIRM" != "y" ]]; then
    exit 0
fi



# --------------------------------------------
# Update file
# --------------------------------------------


if [[ -f CHANGELOG.md ]]; then

TMP=$(mktemp)

echo "$CHANGELOG" > "$TMP"
echo >> "$TMP"

cat CHANGELOG.md >> "$TMP"

mv "$TMP" CHANGELOG.md

else

cat > CHANGELOG.md <<EOF
# Changelog

$CHANGELOG
EOF

fi


echo
echo "[BES AI] CHANGELOG.md updated."
