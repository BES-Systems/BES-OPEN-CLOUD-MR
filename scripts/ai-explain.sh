#!/usr/bin/env bash

set -euo pipefail

# ============================================
# BES AI Explain
# Local LLM code explanation assistant
# ============================================

MODEL="gemma-4-e4b"
LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"


TARGET="${1:-}"


if [[ -z "$TARGET" ]]; then
    echo "Usage:"
    echo "  git aiexplain <file|directory|commit>"
    exit 1
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
    echo "[ERROR] LM Studio is not running"
    exit 1
fi


# --------------------------------------------
# Collect context
# --------------------------------------------

if git rev-parse "$TARGET" >/dev/null 2>&1; then

    echo "[BES AI] Explaining commit..."

    CONTENT=$(git show "$TARGET")

elif [[ -d "$TARGET" ]]; then

    echo "[BES AI] Explaining directory..."

    CONTENT=$(find "$TARGET" \
        -type f \
        \( -name "*.java" \
        -o -name "*.go" \
        -o -name "*.c" \
        -o -name "*.h" \
        -o -name "*.ts" \
        \) \
        -exec sh -c 'echo "--- $1 ---"; cat "$1"' _ {} \;)

elif [[ -f "$TARGET" ]]; then

    echo "[BES AI] Explaining file..."

    CONTENT=$(cat "$TARGET")

else

    echo "[ERROR] Target not found"
    exit 1

fi



# --------------------------------------------
# Project context
# --------------------------------------------

CONTEXT=""

for FILE in \
README.md \
ARCHITECTURE.md \
ROADMAP.md
do

    if [[ -f "$FILE" ]]; then
        CONTEXT+="
--- $FILE ---
$(cat $FILE)
"
    fi

done



# --------------------------------------------
# AI Prompt
# --------------------------------------------


PROMPT="
You are a senior software architect explaining BES OpenCloud.

Explain the provided code.

Structure:

# Purpose
What problem does this solve?

# Architecture
How does it fit into BES OpenCloud?

# Flow
Explain the execution flow step by step.

# Components
Explain important classes/functions/modules.

# Dependencies
Explain external dependencies.

# Risks
Mention possible problems.

# Improvement Ideas
Suggest improvements.

Keep the explanation understandable for:
- developers
- contributors
- future maintainers


Project Context:

$CONTEXT


Code:

$CONTENT
"



# --------------------------------------------
# Call LM Studio
# --------------------------------------------


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
temperature:0.2
}')" \
| jq -r '.choices[0].message.content'
