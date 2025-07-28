# ScyllaDB GitHub Action [![ScyllaDB Action Tests](https://github.com/azita-abdollahi/scylladb-action/actions/workflows/test.yaml/badge.svg)](https://github.com/azita-abdollahi/scylladb-action/actions/workflows/test.yaml)

A GitHub Action for setting up ScyllaDB in CI/CD pipelines with automatic keyspace and user configuration.

## Features

- 🚀 Single-command ScyllaDB setup
- 🔐 Automatic user creation and security configuration
- 🗃️ Keyspace initialization
- 🧪 Tested with Node.js applications
- 🔄 Supports multiple Node.js versions via matrix strategy

## Usage

### Basic Example

```yaml
- uses: azita-abdollahi/scylladb-action@v1.0.0
  with:
    host: scylla
    keyspace: test_ci
```

### All Options

| Parameter        | Required | Default                          | Description        |
|----------------- |----------|----------------------------------|--------------------|
| `network`        | No       | `bridge`                         | Docker network     |
| `version`        | No       | `latest`                         | ScyllaDB version   |
| `host`           | No       | `scylla`                         | Container hostname |
| `port`           | No       | `9042`                           | CQL port           |
| `username`       | No       | `cassandra`                      | Admin username     |
| `password`       | No       | `cassandra`                      | Admin password   |   
| `keyspace`       | No       | `test`                           | Keyspace name      |
| `replication`    | No       | `{'class':'SimpleStrategy', 'replication_factor':1}`  | Replication config |
| `consistency`    | No       | `QUORUM`                         | Default consistency|level              |

## Testing

Includes comprehensive test suite with:

- User creation/authentication
- CRUD operations validation
- Schema migrations
- Connection resilience

## Requirements

- Docker
- Node.js 18+
- GitHub Actions environment

## License 

This project is licensed under the [Apache License Version 2.0](http://www.apache.org/licenses/).

## Contact

Copyright (c) 2025 Azita Abdollahi

