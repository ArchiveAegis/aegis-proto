#!/bin/bash
# -----------------------------------------------------------------------------
# Script Name: prepare-rust-release.sh
# Description: Prepares the Rust crate for publication by generating the
#              necessary manifest and library entry points.
#
# Usage:       ./scripts/prepare-rust-release.sh <VERSION>
# Example:     ./scripts/prepare-rust-release.sh 0.1.0
# -----------------------------------------------------------------------------

set -e

# Validate arguments
if [ -z "$1" ]; then
    echo "Error: Version argument is required."
    exit 1
fi

VERSION="$1"
# Target directory for the Rust crate
BASE_DIR="gen/rust/proto"

echo "Starting Rust crate preparation for version: ${VERSION}"

# Ensure the target directory exists
if [ ! -d "${BASE_DIR}" ]; then
    echo "Error: Target directory ${BASE_DIR} does not exist. Please run generation task first."
    exit 1
fi

echo "Generating lib.rs..."
echo 'pub mod datasource { pub mod v1 { include!("datasource.v1.rs"); } }' > "${BASE_DIR}/lib.rs"

echo "Generating Cargo.toml..."
cat <<EOF > "${BASE_DIR}/Cargo.toml"
[package]
name = "aegis-proto"
version = "${VERSION}"
edition = "2021"
description = "Aegis Platform Protobuf Definitions"
license = "MIT"
repository = "https://github.com/ArchiveAegis/aegis-proto"

# Critical: Explicitly include generated sources.
# This bypasses default behavior where gitignored files are excluded from the crate.
include = [
    "**/*.rs",
    "README.md"
]

[dependencies]
prost = "0.12"
tonic = "0.10"
prost-types = "0.12"

[lib]
path = "lib.rs"
EOF

if [ -f "README.md" ]; then
    echo "Copying README.md..."
    cp README.md "${BASE_DIR}/"
else
    echo "Warning: README.md not found in root."
fi

echo "Rust crate preparation complete."