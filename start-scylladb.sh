#!/bin/sh
set -eo pipefail

# Configuration variables with defaults
DOCKER_NETWORK=${1:-"bridge"}
SCYLLA_VERSION=${2:-"latest"}
SCYLLA_HOST=${3:-"scylla"}
SCYLLA_PORT=${4:-"9042"}
SCYLLA_USERNAME=${5:-"admin"}
SCYLLA_PASSWORD=${6:-"admin"}
KEYSPACE=${7:-"test"}
REPLICATION=${8:-"{'class': 'SimpleStrategy', 'replication_factor': 1}"}
CONSISTENCY_LEVEL=${9:-"QUORUM"}

# Ensure required parameters are set
if [ -z "$KEYSPACE" ]; then
  echo "ERROR: Keyspace name must be specified"
  exit 1
fi

# Log configuration
echo "Starting ScyllaDB with the following configuration:"
echo "  - Network:      ${DOCKER_NETWORK}"
echo "  - Host:         ${SCYLLA_HOST}"
echo "  - Port:         ${SCYLLA_PORT}"
echo "  - Version:      ${SCYLLA_VERSION}"
echo "  - Keyspace:     ${KEYSPACE}"
echo "  - Replication:  ${REPLICATION}"
echo "  - Consistency:  ${CONSISTENCY_LEVEL}"

# Cleanup function
cleanup() {
  echo "Cleaning up..."
  docker rm -f scylla >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Start ScyllaDB container 
echo "Starting ScyllaDB container..."
docker run -d --name scylla \
  --network "${DOCKER_NETWORK}" \
  --hostname "${SCYLLA_HOST}" \
  -p "${SCYLLA_PORT}:9042" \
  --health-cmd "nodetool status" \
  --health-interval "10s" \
  --health-timeout "5s" \
  --health-retries 3 \
  "scylladb/scylla:${SCYLLA_VERSION}" \
  --authenticator PasswordAuthenticator \
  --authorizer CassandraAuthorizer \
  --listen-address 0.0.0.0 \
  --rpc-address 0.0.0.0 \
  --broadcast-rpc-address "${SCYLLA_HOST}" 

echo "Waiting for ScyllaDB to be ready..."
for i in $(seq 1 30); do
    if docker exec scylla cqlsh -u cassandra -p cassandra -e "SELECT release_version FROM system.local;" &> /dev/null; then
        echo "ScyllaDB is ready."
        break
    fi
    echo "ScyllaDB not ready, retrying in 2 seconds... (attempt $i/30)"
    sleep 2
done

# Database initialization
echo "Initializing database..."

# Create keyspace
echo "Creating keyspace '${KEYSPACE}'..."
docker exec scylla cqlsh -u cassandra -p cassandra -e \
  "CREATE KEYSPACE IF NOT EXISTS \"${KEYSPACE}\" WITH replication = ${REPLICATION} AND durable_writes = true;"

# Create admin user
echo "Creating admin user '${SCYLLA_USERNAME}'..."
docker exec scylla cqlsh -u cassandra -p cassandra -e \
  "CREATE ROLE IF NOT EXISTS \"${SCYLLA_USERNAME}\" WITH PASSWORD = '${SCYLLA_PASSWORD}' AND SUPERUSER = true AND LOGIN = true;"

# Grant permissions
echo "Granting permissions..."
docker exec scylla cqlsh -u cassandra -p cassandra -e \
  "GRANT ALL PERMISSIONS ON KEYSPACE \"${KEYSPACE}\" 
   TO \"${SCYLLA_USERNAME}\";"

# Remove default user (if not the same as new admin)
if [ "${SCYLLA_USERNAME}" != "cassandra" ]; then
  echo "Removing default 'cassandra' user..."
  docker exec scylla cqlsh -u "${SCYLLA_USERNAME}" -p "${SCYLLA_PASSWORD}" -e \
    "DROP ROLE IF EXISTS cassandra;"
fi

# Verify setup
echo "Verifying setup..."
docker exec scylla cqlsh -u "${SCYLLA_USERNAME}" -p "${SCYLLA_PASSWORD}" -e \
  "DESCRIBE KEYSPACE \"${KEYSPACE}\";"

echo "ScyllaDB setup completed successfully."
trap - EXIT  

