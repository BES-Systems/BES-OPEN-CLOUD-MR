#!/usr/bin/env bash

VERSION_FILE="VERSION"

if [[ ! -f "$VERSION_FILE" ]]; then
    echo "0.0.1"
    exit
fi

cat "$VERSION_FILE"
