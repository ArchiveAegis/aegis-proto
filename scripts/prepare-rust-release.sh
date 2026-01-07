#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Error: Version argument is required."
    exit 1
fi

VERSION="$1"
BASE_DIR="gen/rust/proto"
REPO_URL="https://github.com/ArchiveAegis/aegis-proto"

echo "Starting Rust crate preparation for version: ${VERSION}"

if [ ! -d "${BASE_DIR}" ]; then
    echo "Error: Target directory ${BASE_DIR} does not exist. Please run generation task first."
    exit 1
fi

cd "${BASE_DIR}"

echo "Original directory structure:"
find . -maxdepth 3 -not -path '*/.*'

echo "Flattening generated file structure..."
find . -type f -name "*.rs" -not -path "./lib.rs" -exec mv {} . \;

find . -type d -empty -delete

echo "Files after flattening:"
ls -lh

MAIN_FILE=$(find . -maxdepth 1 -name "*.rs" ! -name "lib.rs" ! -name "*tonic*" -printf "%f\n" | head -n 1)
TONIC_FILE=$(find . -maxdepth 1 -name "*tonic.rs" -printf "%f\n" | head -n 1)

if [ -z "$MAIN_FILE" ]; then
    echo "Error: Could not find main generated .rs file."
    exit 1
fi

echo "Detected Main File: ${MAIN_FILE}"
echo "Detected Tonic File: ${TONIC_FILE}"

echo "Generating lib.rs..."

{
    echo "pub mod datasource {"
    echo "    pub mod v1 {"
    echo "        include!(\"${MAIN_FILE}\");"
    if [ -n "$TONIC_FILE" ]; then
        echo "        include!(\"${TONIC_FILE}\");"
    fi
    echo "    }"
    echo "}"
} > lib.rs

if [ -f "../../../README.md" ]; then
    echo "Copying README.md..."
    cp "../../../README.md" .
else
    echo "Warning: README.md not found in project root."
fi

echo "Generating Cargo.toml..."
cat <<EOF > Cargo.toml
[package]
name = "aegis-proto"
version = "${VERSION}"
edition = "2021"
description = "Aegis Platform Protobuf Definitions"
license = "MIT"
repository = "${REPO_URL}"
include = [
    "*.rs",
    "README.md"
]

[dependencies]
prost = "0.12"
tonic = "0.10"
prost-types = "0.12"

[lib]
path = "lib.rs"
EOF

echo "Rust crate preparation complete."