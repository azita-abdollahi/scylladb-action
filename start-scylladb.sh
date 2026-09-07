#!/bin/sh
set -eu

# GitHub passes action inputs to Docker actions as INPUT_<NAME> env vars.
NETWORK="${INPUT_NETWORK:-bridge}"
VERSION="${INPUT_VERSION:-latest}"
HOST="${INPUT_HOST:-scylla}"
PORT="${INPUT_PORT:-9042}"
USERNAME="${INPUT_USERNAME:-admin}"
PASSWORD="${INPUT_PASSWORD:-admin}"
KEYSPACE="${INPUT_KEYSPACE:-test}"

CONTAINER=scylla

if [ -z "$KEYSPACE" ]; then
  echo "::error::keyspace must not be empty"
  exit 1
fi
case "$PASSWORD" in *"'"*)
  echo "::error::password must not contain single quotes (it is interpolated into CQL)"
  exit 1
esac

echo "Starting ScyllaDB ${VERSION} on network '${NETWORK}', reachable as ${HOST}:${PORT}"
echo "  superuser: ${USERNAME}, keyspace: ${KEYSPACE}"

docker rm -f "$CONTAINER" >/dev/null 2>&1 || true

cleanup() { docker rm -f "$CONTAINER" >/dev/null 2>&1 || true; }
trap cleanup EXIT

# Start ScyllaDB container 
echo "Starting ScyllaDB container..."
docker run -d --name "$CONTAINER" \
  --network "$NETWORK" \
  --hostname "$HOST" \
  -p "${PORT}:9042" \
  "scylladb/scylla:${VERSION}" \
  --authenticator PasswordAuthenticator \
  --authorizer CassandraAuthorizer \
  --listen-address 0.0.0.0 \
  --rpc-address 0.0.0.0 \
  --broadcast-rpc-address "$HOST"

# 1) Wait for the maintenance socket 
echo "Waiting for ScyllaDB maintenance socket..."
i=1
until docker exec "$CONTAINER" cqlsh /var/lib/scylla/cql.m \
        -e "SELECT release_version FROM system.local;" >/dev/null 2>&1; do
  if [ "$i" -ge 60 ]; then
    echo "::error::ScyllaDB did not become ready in time"
    docker logs "$CONTAINER" || true
    exit 1
  fi
  echo "  not ready yet ($i/60)"
  i=$((i + 1))
  sleep 3
done

# 2) Create the requested superuser
echo "Creating superuser '${USERNAME}'..."
docker exec "$CONTAINER" cqlsh /var/lib/scylla/cql.m -e \
  "CREATE ROLE IF NOT EXISTS \"${USERNAME}\" WITH PASSWORD = '${PASSWORD}' AND SUPERUSER = true AND LOGIN = true;"

echo "Waiting for authenticated CQL access..."
i=1
until docker exec "$CONTAINER" cqlsh -u "$USERNAME" -p "$PASSWORD" \
        -e "SELECT release_version FROM system.local;" >/dev/null 2>&1; do
  if [ "$i" -ge 30 ]; then
    echo "::error::could not authenticate as '${USERNAME}'"
    docker logs "$CONTAINER" || true
    exit 1
  fi
  echo "  not ready yet ($i/30)"
  i=$((i + 1))
  sleep 2
done

# 3) Create the keyspace.
echo "Creating keyspace '${KEYSPACE}'..."
docker exec "$CONTAINER" cqlsh -u "$USERNAME" -p "$PASSWORD" -e \
  "CREATE KEYSPACE IF NOT EXISTS \"${KEYSPACE}\"
   WITH replication = {'class': 'NetworkTopologyStrategy', 'replication_factor': 1}
   AND tablets = {'enabled': false};"

# 4) Verify
docker exec "$CONTAINER" cqlsh -u "$USERNAME" -p "$PASSWORD" -e "DESCRIBE KEYSPACE \"${KEYSPACE}\";"

echo "ScyllaDB is up and ready."
trap - EXIT   