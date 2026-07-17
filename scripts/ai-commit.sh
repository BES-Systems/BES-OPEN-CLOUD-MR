#!/usr/bin/env bash

set -e

MODEL="gemma-4-e4b"
LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"

if git diff --quiet && git diff --cached --quiet; then
    echo "No changes detected."
    exit 1
fi

echo "[BES AI] Analyzing changes..."

DIFF=$(git diff HEAD)

PROMPT="
You are a senior software engineer.

Analyze this git diff and generate a professional Conventional Commit message.

Rules:
- Format:
  <type>: <short description>

- Types:
  feat     new feature
  fix      bug fix
  refactor code restructuring
  docs     documentation
  perf     performance
  test     tests
  build    build system
  ci       CI/CD
  chore    maintenance

- Keep it under 72 characters.
- Only output the commit message.
- No markdown.

Git diff:

$DIFF
"

RESPONSE=$(curl -s "$LM_STUDIO_URL" \
-H "Content-Type: application/json" \
-d "{
  \"model\": \"$MODEL\",
  \"messages\": [
    {
      \"role\": \"user\",
      \"content\": $(echo "$PROMPT" | jq -Rs .)
    }
  ],
  \"temperature\": 0.2
}")


MESSAGE=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

echo
echo "Generated commit:"
echo "-----------------"
echo "$MESSAGE"
echo "-----------------"
echo

read -p "Commit with this message? [y/N] " CONFIRM

if [[ "$CONFIRM" != "y" ]]; then
    echo "Cancelled."
    exit 0
fi

git add .

git commit -m "$MESSAGE"

echo "[BES AI] Commit completed."
