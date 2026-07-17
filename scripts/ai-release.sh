#!/usr/bin/env bash

set -euo pipefail

# ============================================
# BES AI Release Assistant
# Local LLM powered release generator
# ============================================

MODEL="gemma-4-e4b"
LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"

DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi


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
    echo "[ERROR] LM Studio unavailable"
    exit 1
fi


# --------------------------------------------
# Current version
# --------------------------------------------

if [[ -f VERSION ]]; then
    CURRENT_VERSION=$(cat VERSION)
else
    CURRENT_VERSION="0.0.0"
fi


LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")


if [[ -n "$LAST_TAG" ]]; then

COMMITS=$(git log \
"$LAST_TAG"..HEAD \
--pretty=format:"- %s")

else

COMMITS=$(git log \
--pretty=format:"- %s" \
-n 50)

fi


echo
echo "[BES AI] Current version:"
echo "$CURRENT_VERSION"
echo


# --------------------------------------------
# Generate release
# --------------------------------------------

PROMPT="
You are a senior open-source release manager.

Analyze these commits and create a software release.

Return ONLY JSON:

{
 version: \"x.y.z\",
 title: \"Release title\",
 changelog: \"markdown changelog\"
}


Rules:
- Follow semantic versioning
- Major = breaking changes
- Minor = new features
- Patch = fixes


Current version:

$CURRENT_VERSION


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


VERSION=$(echo "$RESPONSE" \
| jq -r '.choices[0].message.content' \
| jq -r '.version')


TITLE=$(echo "$RESPONSE" \
| jq -r '.choices[0].message.content' \
| jq -r '.title')


CHANGELOG=$(echo "$RESPONSE" \
| jq -r '.choices[0].message.content' \
| jq -r '.changelog')


if [[ "$VERSION" == "null" ]]; then
    echo "[ERROR] Invalid AI response"
    exit 1
fi


echo
echo "=============================="
echo " Release Preview"
echo "=============================="

echo "Version:"
echo "$VERSION"

echo
echo "Title:"
echo "$TITLE"

echo
echo "Changelog:"
echo "$CHANGELOG"

echo "=============================="



if [[ "$DRY_RUN" == true ]]; then
    exit 0
fi



read -p "Create release? [y/N] " CONFIRM


if [[ "$CONFIRM" != "y" ]]; then
    exit 0
fi


# --------------------------------------------
# Write files
# --------------------------------------------


echo "$VERSION" > VERSION


if [[ -f CHANGELOG.md ]]; then

TMP=$(mktemp)

echo "# $VERSION - $TITLE" > "$TMP"
echo >> "$TMP"
echo "$CHANGELOG" >> "$TMP"
echo >> "$TMP"

cat CHANGELOG.md >> "$TMP"

mv "$TMP" CHANGELOG.md

else

cat > CHANGELOG.md <<EOF
# $VERSION - $TITLE

$CHANGELOG
EOF

fi



# --------------------------------------------
# Git release
# --------------------------------------------


git add VERSION CHANGELOG.md


git commit \
-m "release: $VERSION"


git tag \
-a "$VERSION" \
-m "$TITLE"


echo
echo "[BES AI] Release created:"
echo "$VERSION"
