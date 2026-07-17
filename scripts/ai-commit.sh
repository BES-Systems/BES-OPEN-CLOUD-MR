#!/usr/bin/env bash

set -euo pipefail

# ============================================
# BES AI Commit Assistant
# Local LLM powered Git workflow
# ============================================

MODEL="gemma-4-e4b"
LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"

AUTO_CONFIRM=false
RUN_REVIEW=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --yes)
            AUTO_CONFIRM=true
            shift
            ;;
        --review)
            RUN_REVIEW=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done


# --------------------------------------------
# Requirements
# --------------------------------------------

command -v jq >/dev/null || {
    echo "[ERROR] jq is required"
    exit 1
}


# --------------------------------------------
# Check LM Studio
# --------------------------------------------

echo "[BES AI] Checking LM Studio..."

if ! curl -s "$LM_STUDIO_URL" >/dev/null; then
    echo "[ERROR] LM Studio is not running."
    echo "Start the local server first."
    exit 1
fi


# --------------------------------------------
# Git information
# --------------------------------------------

BRANCH=$(git branch --show-current)

FILES=$(git diff HEAD --name-only)

if [[ -z "$FILES" ]]; then
    echo "[BES AI] No changes detected."
    exit 1
fi


DIFF=$(git diff HEAD)


# --------------------------------------------
# Project context
# --------------------------------------------

CONTEXT=""

for FILE in README.md ARCHITECTURE.md ROADMAP.md; do
    if [[ -f "$FILE" ]]; then
        CONTEXT+="
--- $FILE ---
$(cat $FILE)
"
    fi
done


# --------------------------------------------
# Code review
# --------------------------------------------

if [[ "$RUN_REVIEW" == true ]]; then

echo "[BES AI] Running code review..."

REVIEW_PROMPT="
You are a senior software architect.

Review this code change.

Look for:
- bugs
- security problems
- bad architecture
- missing tests
- performance issues

Give a short review.

Files:
$FILES

Diff:
$DIFF
"


curl -s "$LM_STUDIO_URL" \
-H "Content-Type: application/json" \
-d "$(jq -n \
--arg model "$MODEL" \
--arg prompt "$REVIEW_PROMPT" \
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


echo
read -p "Continue? [y/N] " CONTINUE

[[ "$CONTINUE" == "y" ]] || exit 0

fi


# --------------------------------------------
# Generate commit
# --------------------------------------------

echo "[BES AI] Generating commit message..."


PROMPT="
You are a senior open-source maintainer.

Generate a Conventional Commit.

Rules:

Format:

<type>: <short title>

<body>

Types:
feat
fix
refactor
docs
perf
test
build
ci
chore

Requirements:
- title max 72 characters
- explain WHY the change happened
- be professional
- no markdown
- output only the commit message


Repository:
BES OpenCloud

Branch:
$BRANCH


Changed files:
$FILES


Project context:
$CONTEXT


Diff:
$DIFF
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


MESSAGE=$(echo "$RESPONSE" \
| jq -r '.choices[0].message.content')


if [[ -z "$MESSAGE" || "$MESSAGE" == "null" ]]; then
    echo "[ERROR] AI failed generating message"
    exit 1
fi


echo
echo "=============================="
echo " Generated Commit"
echo "=============================="
echo "$MESSAGE"
echo "=============================="
echo


if [[ "$AUTO_CONFIRM" != true ]]; then
    read -p "Commit? [y/N] " CONFIRM
else
    CONFIRM="y"
fi


if [[ "$CONFIRM" != "y" ]]; then
    echo "Cancelled."
    exit 0
fi


# --------------------------------------------
# Commit
# --------------------------------------------

git add .

git commit -m "$MESSAGE"


echo
echo "[BES AI] Commit completed."
