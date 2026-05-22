#!/usr/bin/env bash
set -euo pipefail

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker is not running. Start Docker Desktop and retry."
  exit 1
fi

mkdir -p docker/postgres/init

echo "Generating docker/postgres/init/01_schema.sql from guacamole/guacamole:1.5.5 ..."
docker run --rm guacamole/guacamole:1.5.5 \
  /opt/guacamole/bin/initdb.sh --postgresql \
  > docker/postgres/init/01_schema.sql

if [ ! -s docker/postgres/init/01_schema.sql ]; then
  echo "ERROR: Generated schema is empty."
  exit 1
fi

echo "Schema ready: docker/postgres/init/01_schema.sql"

echo "Next: docker compose -f docker-compose.postgres.yml up -d --build"
