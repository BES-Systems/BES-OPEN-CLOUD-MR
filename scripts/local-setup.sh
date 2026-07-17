#!/usr/bin/env bash

set -euo pipefail

# ============================================
# BES OpenCloud Local Development Setup
#
# Installs:
# - Java JDK
# - Go
# - Git tools
# - Build dependencies
#
# ============================================

echo "
====================================
 BES OpenCloud Development Setup
====================================
"


# --------------------------------------------
# Detect OS
# --------------------------------------------

OS="$(uname -s)"

echo "[BES SETUP] Detected OS: $OS"



# --------------------------------------------
# Package manager
# --------------------------------------------

install_package() {

    if command -v brew >/dev/null 2>&1; then

        brew install "$@"

    elif command -v apt >/dev/null 2>&1; then

        sudo apt update
        sudo apt install -y "$@"

    elif command -v dnf >/dev/null 2>&1; then

        sudo dnf install -y "$@"

    else

        echo "[ERROR] Unsupported package manager"
        exit 1

    fi

}



# --------------------------------------------
# Install Git
# --------------------------------------------

if ! command -v git >/dev/null; then

    echo "[BES SETUP] Installing Git..."

    install_package git

else

    echo "[OK] Git installed"

fi



# --------------------------------------------
# Install Java
# --------------------------------------------


if command -v java >/dev/null; then

    echo "[OK] Java installed"

    java -version

else

    echo "[BES SETUP] Installing Java JDK..."

    install_package openjdk

fi



# --------------------------------------------
# Install Go
# --------------------------------------------


if command -v go >/dev/null; then

    echo "[OK] Go installed"

    go version

else

    echo "[BES SETUP] Installing Go..."

    install_package go

fi



# --------------------------------------------
# Install build tools
# --------------------------------------------


echo "[BES SETUP] Installing build tools..."


if [[ "$OS" == "Darwin" ]]; then

    brew install \
        cmake \
        ninja \
        pkg-config \
        jq


elif command -v apt >/dev/null; then

    sudo apt install -y \
        build-essential \
        cmake \
        ninja-build \
        pkg-config \
        jq

fi



# --------------------------------------------
# Setup directories
# --------------------------------------------


echo "[BES SETUP] Creating workspace..."


mkdir -p \
    build \
    bin \
    logs \
    docs/generated



# --------------------------------------------
# Verify
# --------------------------------------------


echo "
====================================
 Installation Summary
====================================
"


echo "Git:"
git --version


echo

echo "Java:"
java -version 2>&1 | head -n 1


echo

echo "Go:"
go version


echo

echo "Build tools:"
cmake --version | head -n 1


echo "
====================================
 BES OpenCloud Ready
====================================
"
