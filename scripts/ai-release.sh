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
# Version
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



# --------------------------------------------
# Generate release analysis
# --------------------------------------------


PROMPT="
You are a senior open-source release engineer.

Analyze the commits and recommend a semantic version bump.

Return ONLY valid JSON:

{
  \"bump\": \"major|minor|patch\",
  \"reason\": \"why this bump was chosen\",
  \"version\": \"x.y.z\",
  \"title\": \"release title\",
  \"changelog\": \"markdown changelog\"
}


Semantic version rules:

MAJOR:
- Breaking API changes
- Incompatible architecture changes

MINOR:
- New features
- New subsystems
- New capabilities

PATCH:
- Bug fixes
- Documentation
- Small improvements


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
temperature:0.1
}')")



# Extract JSON from response

JSON=$(echo "$RESPONSE" \
| jq -r '.choices[0].message.content')



# Remove markdown if model adds it

JSON=$(echo "$JSON" \
| sed 's/^```json//g' \
| sed 's/^```//g' \
| sed '/^```$/d')



BUMP=$(echo "$JSON" | jq -r '.bump')
REASON=$(echo "$JSON" | jq -r '.reason')
VERSION=$(echo "$JSON" | jq -r '.version')
TITLE=$(echo "$JSON" | jq -r '.title')
CHANGELOG=$(echo "$JSON" | jq -r '.changelog')



if [[ "$VERSION" == "null" ]]; then

    echo "[ERROR] Invalid AI response"
    echo "$JSON"

    exit 1

fi



# --------------------------------------------
# Preview
# --------------------------------------------


echo
echo "=============================="
echo " BES AI Release Preview"
echo "=============================="

echo
echo "Current:"
echo "$CURRENT_VERSION"

echo
echo "Recommended bump:"
echo "$BUMP"

echo
echo "Reason:"
echo "$REASON"

echo
echo "New version:"
echo "$VERSION"

echo
echo "Title:"
echo "$TITLE"

echo
echo "Changelog:"
echo "$CHANGELOG"

echo
echo "=============================="



if [[ "$DRY_RUN" == true ]]; then
    exit 0
fi



read -p "Create release? [y/N] " CONFIRM


if [[ "$CONFIRM" != "y" ]]; then
    exit 0
fi



# --------------------------------------------
# Update files
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
# Commit + tag
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