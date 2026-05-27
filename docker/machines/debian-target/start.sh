#!/usr/bin/env bash
set -euo pipefail

# Run cleanup of orphaned home directories
/usr/local/bin/cleanup_home_dirs.sh

ssh-keygen -A
exec /usr/sbin/sshd -D -e
