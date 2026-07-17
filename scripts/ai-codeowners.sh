#!/usr/bin/env bash

set -euo pipefail

# ============================================
# BES AI CODEOWNERS Generator
# ============================================

MODEL="gemma-4-e4b"
LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"


OUTPUT=".github/CODEOWNERS"


command -v jq >/dev/null || {
    echo "[ERROR] jq required"
    exit 1
}


if ! curl -s "$LM_STUDIO_URL" >/dev/null; then
    echo "[ERROR] LM Studio unavailable"
    exit 1
fi


echo "[BES AI] Scanning repository..."


TREE=$(find . \
-not -path "./.git/*" \
-maxdepth 2 \
-type d)



FILES=$(git ls-files)



CONTEXT=""

for FILE in README.md ARCHITECTURE.md ROADMAP.md
do

    if [[ -f "$FILE" ]]; then
        CONTEXT+="

--- $FILE ---

$(cat "$FILE")

"
    fi

done



PROMPT="
You are a senior open-source maintainer.

Generate a GitHub CODEOWNERS file.

Repository:
BES OpenCloud


Analyze this structure:

Directories:

$TREE


Files:

$FILES


Project documentation:

$CONTEXT


Rules:

- Output ONLY CODEOWNERS syntax.
- Use GitHub CODEOWNERS format.
- Group ownership logically.
- Use BES-Systems as organization.
- Do not invent individual users.
- Use team names.

Example:

/controller @BES-Systems/backend
/node @BES-Systems/infrastructure

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
}'
))


CODEOWNERS=$(echo "$RESPONSE" \
| jq -r '.choices[0].message.content')



if [[ -z "$CODEOWNERS" || "$CODEOWNERS" == "null" ]]; then
    echo "[ERROR] Invalid AI response"
    exit 1
fi



echo
echo "=============================="
echo " Generated CODEOWNERS"
echo "=============================="

echo "$CODEOWNERS"

echo "=============================="



mkdir -p .github


read -p "Save CODEOWNERS? [y/N] " CONFIRM


if [[ "$CONFIRM" == "y" ]]; then

    echo "$CODEOWNERS" > "$OUTPUT"

    echo "[BES AI] Saved:"
    echo "$OUTPUT"

fi
