#!/usr/bin/env bash
# =============================================================================
# setup-postgres.sh — Run this ONCE before 'docker compose ... up --build'
#
# WHAT IT DOES:
#   Guacamole ships its PostgreSQL schema inside the Docker image.
#   This script runs the image and captures that schema into:
#     docker/postgres/init/schema_file.sql
#
# WHEN TO RUN:
#   Once before the first build/up.
#   Run again only if schema_file.sql is missing or deleted.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SCHEMA_DIR="docker/postgres/init"
SCHEMA_FILE="$SCHEMA_DIR/schema_file.sql"
TMP_FILE="$SCHEMA_DIR/.schema_file.sql.tmp"

echo "======================================================"
echo "  Guacamole Gateway — One-time Setup"
echo "======================================================"

# Check Docker is available and running.
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker CLI not found in PATH."
  exit 1
fi

if ! docker info > /dev/null 2>&1; then
  echo "ERROR: Docker is not running. Please start Docker Desktop and try again."
  exit 1
fi

# Pull image first so schema generation is deterministic and explicit.
echo ""
echo "[1/2] Pulling guacamole/guacamole:1.5.5..."
docker pull guacamole/guacamole:1.5.5

# Generate PostgreSQL schema from the Guacamole image.
echo ""
echo "[2/2] Generating PostgreSQL schema from Guacamole image..."
mkdir -p "$SCHEMA_DIR"
docker run --rm guacamole/guacamole:1.5.5 \
  /opt/guacamole/bin/initdb.sh --postgresql \
  > "$TMP_FILE"

if [ ! -s "$TMP_FILE" ]; then
  rm -f "$TMP_FILE"
  echo "ERROR: Schema file is empty. Something went wrong with the initdb.sh run."
  exit 1
fi

mv "$TMP_FILE" "$SCHEMA_FILE"
LINES=$(wc -l < "$SCHEMA_FILE")

echo "      Written: $SCHEMA_FILE ($LINES lines)"

echo ""
echo "======================================================"
echo "  Setup complete! Next steps:"
echo ""
echo "  1. docker compose -f docker-compose.postgres.openldap.yml up -d --build"
echo "  2. Open http://localhost:8080/guacamole"
echo ""
echo "  LDAP users:"
echo "    bob   / Bob@123"
echo "    alice / Alice@123"
echo "======================================================"
