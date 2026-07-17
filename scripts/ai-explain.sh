#!/usr/bin/env bash

set -euo pipefail

# ============================================
# BES AI Explain
# Local LLM code explanation assistant
#
# Usage:
#   git aiexplain <file|directory|commit>
#   git aiexplain <target> --save
#
# ============================================

MODEL="gemma-4-e4b"
LM_STUDIO_URL="http://localhost:1234/v1/chat/completions"

TARGET=""
SAVE=false


# ============================================
# Arguments
# ============================================

for ARG in "$@"; do
    case "$ARG" in

        --save)
            SAVE=true
            ;;

        *)
            TARGET="$ARG"
            ;;

    esac
done


if [[ -z "$TARGET" ]]; then
    echo "Usage:"
    echo "  git aiexplain <file|directory|commit> [--save]"
    exit 1
fi


# ============================================
# Requirements
# ============================================

command -v jq >/dev/null || {
    echo "[ERROR] jq is required"
    exit 1
}


# ============================================
# LM Studio check
# ============================================

echo "[BES AI] Checking LM Studio..."

if ! curl -s "$LM_STUDIO_URL" >/dev/null; then

    echo "[ERROR] LM Studio is not running."
    echo "Start the local API server first."

    exit 1

fi


# ============================================
# Git repository check
# ============================================

if ! git rev-parse --git-dir >/dev/null 2>&1; then

    echo "[ERROR] Not inside a git repository."

    exit 1

fi



# ============================================
# Collect target content
# ============================================

echo "[BES AI] Loading target: $TARGET"


CONTENT=""


# Commit explanation

if git rev-parse "$TARGET" >/dev/null 2>&1; then

    echo "[BES AI] Target detected as commit"

    CONTENT=$(git show "$TARGET")


# Directory explanation

elif [[ -d "$TARGET" ]]; then

    echo "[BES AI] Target detected as directory"


    while IFS= read -r FILE; do

        CONTENT+="

================================
FILE: $FILE
================================

$(cat "$FILE")

"

    done < <(
        find "$TARGET" \
        -type f \
        \( \
        -name "*.java" -o \
        -name "*.go" -o \
        -name "*.c" -o \
        -name "*.cpp" -o \
        -name "*.h" -o \
        -name "*.rs" -o \
        -name "*.ts" -o \
        -name "*.js" \
        \)
    )


# File explanation

elif [[ -f "$TARGET" ]]; then

    echo "[BES AI] Target detected as file"

    CONTENT=$(cat "$TARGET")


else

    echo "[ERROR] Target not found:"
    echo "$TARGET"

    exit 1

fi



# ============================================
# Load BES context
# ============================================

CONTEXT=""


for FILE in \
README.md \
ARCHITECTURE.md \
ROADMAP.md \
CONTRIBUTING.md

do

    if [[ -f "$FILE" ]]; then

        CONTEXT+="

================================
$FILE
================================

$(cat "$FILE")

"

    fi

done



# ============================================
# AI Prompt
# ============================================


PROMPT="
You are a senior software architect working on BES OpenCloud.

Analyze the provided source code.

The project is an open-source cloud infrastructure platform.

Explain the code for future contributors.

Use this structure:

# Purpose

Explain why this component exists.

# Architecture

Explain where this fits inside BES OpenCloud.

# Execution Flow

Explain how data and control flow through this component.

# Components

Explain important:
- classes
- functions
- modules
- interfaces

# Dependencies

Explain external libraries and services.

# Security Considerations

Mention:
- possible vulnerabilities
- trust boundaries
- unsafe operations

# Performance Considerations

Mention:
- bottlenecks
- scalability issues

# Improvement Ideas

Suggest realistic improvements.

Keep the explanation technical but readable.


BES Project Context:

$CONTEXT


Target:

$TARGET


Source:

$CONTENT

"


# ============================================
# Call AI
# ============================================


echo "[BES AI] Generating explanation..."


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
}'
)")


EXPLANATION=$(echo "$RESPONSE" \
| jq -r '.choices[0].message.content')



if [[ -z "$EXPLANATION" || "$EXPLANATION" == "null" ]]; then

    echo "[ERROR] AI response invalid"

    exit 1

fi



# ============================================
# Display result
# ============================================


echo

echo "================================"
echo " BES AI Explanation"
echo "================================"

echo "$EXPLANATION"

echo "================================"



# ============================================
# Save documentation
# ============================================


if [[ "$SAVE" == true ]]; then


    mkdir -p docs/explanations


    SAFE_NAME=$(echo "$TARGET" \
        | sed 's#[/\\]#-#g' \
        | sed 's/[^a-zA-Z0-9._-]//g')


    OUTPUT="docs/explanations/${SAFE_NAME}.md"



    cat > "$OUTPUT" <<EOF
# BES OpenCloud Explanation

## Target

\`$TARGET\`

---

$EXPLANATION


---

Generated by **BES AI Explain**
EOF



    echo

    echo "[BES AI] Saved documentation:"
    echo "$OUTPUT"


fi
