# Aegis Proto (aegis-proto)

A language-agnostic Interface Definition Language (IDL) repository for the Aegis platform.  
This project serves as the platform’s **Source of Truth**, using **Protocol Buffers** to define all cross-service APIs (RPCs) and data structures (messages).

With an automated CI pipeline, we generate and publish type-safe SDKs for **Go / Rust / TypeScript / Python**, ensuring protocol-level consistency across all microservices.

---

## Features

- **Single Source of Truth (SSOT)**: all protocol changes happen in `proto/`
- **Multi-language SDK publishing**: Go / Rust / TypeScript / Python
- **Type safety**: reduces drift and runtime errors caused by hand-written DTOs/interfaces
- **CI-driven releases**: local `gen/` is for debugging only and must not be committed to `main`

---

## Repository Layout

```text
proto/       # Source .proto files (make all protocol changes here)
gen/         # Locally generated outputs (Go/Python/Rust/TS) for debugging only; do not commit to main
scripts/     # Pre-publish helper scripts (e.g., Rust crate flattening)
Taskfile.yml # Task automation definitions
````

> Convention: **Do not** commit `gen/` to the main branch. Release artifacts are generated and published by CI.

---

## Usage (Choose Your Language)

This repository publishes multi-language SDKs to keep the `datasource.v1` protocol consistent across services.
Select the integration method for your language below.

---

### 1) Go

The Go SDK is published to the `release/go` branch of this repository as an independent Go module.

#### Install

```bash
go get github.com/ArchiveAegis/aegis-proto/go
```

#### Example

```go
package main

import (
	"context"
	"log"

	datasource "github.com/ArchiveAegis/aegis-proto/go/datasource/v1"
	"google.golang.org/grpc"
)

func main() {
	conn, err := grpc.Dial("localhost:50051", grpc.WithInsecure())
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()

	client := datasource.NewDataSourceClient(conn)

	resp, err := client.GetPluginInfo(context.Background(), &datasource.GetPluginInfoRequest{})
	if err != nil {
		log.Printf("Error: %v", err)
		return
	}
	log.Printf("Plugin Name: %s", resp.Name)
}
```

---

### 2) Rust

The Rust crate `aegis-proto` is published on crates.io.
It already integrates `tonic` and `prost`, so you can directly use the generated gRPC client and types.

#### Install

```bash
cargo add aegis-proto
```

#### Example (Flattened module layout: `datasource::v1`)

```rust
use aegis_proto::datasource::v1::data_source_client::DataSourceClient;
use aegis_proto::datasource::v1::GetPluginInfoRequest;
use tonic::transport::Channel;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let channel = Channel::from_static("http://[::1]:50051")
        .connect()
        .await?;

    let mut client = DataSourceClient::new(channel);

    let request = tonic::Request::new(GetPluginInfoRequest {});
    let response = client.get_plugin_info(request).await?;

    println!("RESPONSE={:?}", response);
    Ok(())
}
```

---

### 3) TypeScript (Node.js)

The NPM package `@archiveaegis/aegis-proto` contains TypeScript type definitions and generated gRPC client code.

#### Install

```bash
npm install @archiveaegis/aegis-proto
```

#### Example

```ts
import { DataSourceClient } from "@archiveaegis/aegis-proto";
import { credentials } from "@grpc/grpc-js";

const client = new DataSourceClient(
  "localhost:50051",
  credentials.createInsecure()
);

client.getPluginInfo({}, (err, response) => {
  if (err) {
    console.error(err);
    return;
  }
  console.log("Plugin Info:", response);
});
```

---

### 4) Python

The PyPI package `aegis-proto` provides standard `grpcio`-generated code.

#### Install

```bash
pip install aegis-proto
```

#### Example

```python
import grpc
from datasource.v1 import datasource_pb2, datasource_pb2_grpc

def run() -> None:
    with grpc.insecure_channel("localhost:50051") as channel:
        stub = datasource_pb2_grpc.DataSourceStub(channel)
        response = stub.GetPluginInfo(datasource_pb2.GetPluginInfoRequest())
        print(f"Plugin received: {response.name}")

if __name__ == "__main__":
    run()
```

---

## Development Guide (Local Changes & Debugging)

If you need to update `.proto` definitions or generate code locally for debugging, follow these steps.

### Prerequisites

* **Task**: task runner (see `Taskfile.yml` / `Taskfile.dev`)
* **protoc**: Protocol Buffers compiler (recommended v25.x)
* **Go**: to install `protoc-gen-go` and `protoc-gen-go-grpc`
* **Python 3.x**: for `grpcio-tools`
* **Node.js**: for generating TypeScript code

### Generate Code (Outputs to `gen/`)

```bash
# Generate SDKs for all languages into gen/
task gen

# Generate for a specific language (example: Go)
task gen-go
```

### Clean Generated Files

```bash
task clean
```

---

## Release Process (Release Please)

This repository uses **Release Please** for automated releases:

1. **Pull Request**
   When a PR is merged into the main branch, Release Please analyzes commit messages (following Conventional Commits).

2. **Release PR**
   The bot automatically opens a Release PR containing version bumps and changelog updates.

3. **Publish**
   After merging the Release PR, GitHub Actions triggers an orchestrator workflow that:

   * pushes Go code to the `release/go` branch
   * publishes the Rust crate to crates.io
   * publishes the NPM package to the npm registry
   * publishes the Python package to PyPI

---

## Contributing

* Make all protocol changes in `proto/` only
* Commit messages should follow **Conventional Commits** (e.g., `feat(proto): add FooMessage`)
* For breaking changes, clearly document the migration strategy in the PR description

---

## License

Apache-2.0
