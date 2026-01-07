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

echo "Current working directory: $(pwd)"
echo "Listing files before preparation:"
ls -lh

GENERATED_FILE=$(find . -maxdepth 1 -name "*.rs" ! -name "lib.rs" -printf "%f\n" | head -n 1)

if [ -z "$GENERATED_FILE" ]; then
    echo "Error: No generated .rs file found in ${BASE_DIR}."
    echo "Files present:"
    ls -R
    exit 1
fi

echo "Detected generated source file: ${GENERATED_FILE}"

echo "Generating lib.rs..."

echo "pub mod datasource { pub mod v1 { include!(\"${GENERATED_FILE}\"); } }" > lib.rs

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
    "${GENERATED_FILE}",
    "lib.rs",
    "README.md"
]

[dependencies]
prost = "0.12"
tonic = "0.10"
prost-types = "0.12"

[lib]
path = "lib.rs"
EOF

echo "Cargo.toml content:"
cat Cargo.toml

echo "Rust crate preparation complete."