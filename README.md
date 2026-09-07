# ScyllaDB GitHub Action [![ScyllaDB Action Tests](https://github.com/azita-abdollahi/scylladb-action/actions/workflows/test.yaml/badge.svg)](https://github.com/azita-abdollahi/scylladb-action/actions/workflows/test.yaml)

A GitHub Action for setting up ScyllaDB in CI/CD pipelines with automatic keyspace and user configuration.

## Features

- 🚀 One-step ScyllaDB startup (Docker action — works wherever Docker is available)
- 🔐 Password authentication with your own superuser (bootstrapped via ScyllaDB's maintenance socket)
- 🗃️ Keyspace created automatically: NetworkTopologyStrategy, replication factor 1
- 🧲 Works both in normal runner jobs and inside container jobs (shared Docker network)
- 🧹 ScyllaDB container is cleaned up automatically when the job ends
- 🧪 Tested against real CRUD workloads (Node.js + express-cassandra) on Node 22 and 26

## Usage

### Basic Example

```yaml
- uses: azita-abdollahi/scylladb-action@v2.0.0
  with:
    host: scylla
    keyspace: test_ci
```

### All Options

| Parameter        | Required | Default                          | Description        |
|----------------- |----------|----------------------------------|--------------------|
| `network`        | No       | `bridge`                         | Docker network     |
| `version`        | No       | `2026.3`                         | ScyllaDB version   |
| `host`           | No       | `scylla`                         | ame clients use to reach the server; localhost for runner jobs |
| `port`           | No       | `9042`                           | Host port mapped to CQL port 9042           |
| `username`       | No       | `admin`                          | Superuser to create|
| `password`       | No       | `admin`                          | Superuser password |   
| `keyspace`       | No       | `test`                           | Keyspace to create |

## Testing

|Setting	                  |                             Value                              |
|---------------------------|----------------------------------------------------------------|
|Contact point	            |   host:9042                                                    | 
|Credentials	              |   username / password inputs                                   |
|Keyspace	                  |   keyspace input                                               |
|Local datacenter	          |   datacenter1 (ScyllaDB default; required by NTS-aware drivers)|

## Requirements

- Docker
- Node.js 22+
- GitHub Actions environment

## License 

This project is licensed under the [Apache License Version 2.0](http://www.apache.org/licenses/).

## Contact

Copyright (c) 2025 Azita Abdollahi

