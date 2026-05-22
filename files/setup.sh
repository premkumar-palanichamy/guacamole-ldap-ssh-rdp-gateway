#!/usr/bin/env bash
# =============================================================================
# setup.sh — Run this ONCE before 'docker compose up'
#
# WHY IS THIS NEEDED?
#   Apache Guacamole ships its PostgreSQL schema (CREATE TABLE statements etc.)
#   INSIDE the Docker image at /opt/guacamole/bin/initdb.sh
#   There is no standalone SQL file in the repo — you must extract it.
#   This script runs the guacamole image (just to output the SQL) and saves
#   the result to init/01_schema.sql so PostgreSQL can auto-run it on first boot.
# =============================================================================

set -euo pipefail   # -e: exit on error  -u: error on unset vars  -o pipefail: catch pipe errors

echo "======================================================"
echo "  Guacamole Gateway — One-time Setup"
echo "======================================================"

# ---- Step 1: Make sure Docker is running ----
# 'docker info' exits non-zero if Docker daemon isn't running
if ! docker info > /dev/null 2>&1; then
  echo "ERROR: Docker is not running. Please start Docker and retry."
  exit 1
fi

# ---- Step 2: Pull the Guacamole image ----
# We need the image locally to run initdb.sh inside it
# Version is pinned (1.5.5) for reproducibility — floating tags like 'latest'
# can break setups silently when Guacamole releases a new version
echo ""
echo "[1/3] Pulling guacamole/guacamole:1.5.5 ..."
docker pull guacamole/guacamole:1.5.5

# ---- Step 3: Extract the PostgreSQL schema SQL ----
# 'docker run --rm' creates a temporary container and removes it after the command
# The command '/opt/guacamole/bin/initdb.sh --postgresql' outputs the schema SQL to stdout
# We redirect (>) that output into our init directory
# PostgreSQL's docker-entrypoint-initdb.d/ will auto-run all .sql files on first start
echo ""
echo "[2/3] Generating Guacamole PostgreSQL schema ..."
mkdir -p init   # create directory if it doesn't exist yet
docker run --rm guacamole/guacamole:1.5.5 \
  /opt/guacamole/bin/initdb.sh --postgresql \
  > init/01_schema.sql

# Verify it was created and is non-empty
if [ ! -s init/01_schema.sql ]; then
  echo "ERROR: Schema file is empty. Something went wrong with the initdb.sh run."
  exit 1
fi

echo "      Written: init/01_schema.sql ($(wc -l < init/01_schema.sql) lines)"

# ---- Step 4: Fix executable permissions ----
echo ""
echo "[3/3] Setting permissions on startup scripts ..."
chmod +x machines/linux-desktop/startup.sh

echo ""
echo "======================================================"
echo "  Setup complete!"
echo ""
echo "  Next steps:"
echo "    docker compose up -d"
echo "    (wait ~60s for services to start)"
echo "    Open: http://localhost:8080/guacamole"
echo ""
echo "  Login:"
echo "    bob   / bob123   → SSH connections"
echo "    alice / alice123 → RDP connection"
echo "======================================================"
