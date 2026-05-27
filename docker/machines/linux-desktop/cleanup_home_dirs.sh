#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# Cleanup orphaned home directories for deleted LDAP users
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

LDAP_HOST="${LDAP_HOST:-openldap}"
LDAP_PORT="${LDAP_PORT:-389}"
LDAP_DN="${LDAP_DN:-cn=admin,dc=ladvik,dc=local}"
LDAP_PASS="${LDAP_PASS:-admin123}"

cleanup_orphaned_homes() {
  local retry_count=0
  local max_retries=3

  # Try to connect to LDAP
  while [ $retry_count -lt $max_retries ]; do
    if ldapsearch -x -H ldap://$LDAP_HOST:$LDAP_PORT \
        -D "$LDAP_DN" -w "$LDAP_PASS" \
        -b "ou=users,dc=ladvik,dc=local" >/dev/null 2>&1; then
      break
    fi
    ((retry_count++))
    sleep 1
  done

  if [ $retry_count -ge $max_retries ]; then
    echo "[!] LDAP unavailable, skipping cleanup"
    return 1
  fi

  echo "[*] Cleaning up orphaned home directories..."

  # Get all valid LDAP users
  local valid_users=$(ldapsearch -x -H ldap://$LDAP_HOST:$LDAP_PORT \
    -D "$LDAP_DN" -w "$LDAP_PASS" \
    -b "ou=users,dc=ladvik,dc=local" \
    "(objectClass=posixAccount)" uid 2>/dev/null | \
    grep "^uid:" | sed 's/^uid: //' | sort)

  # Check /home directories
  for homedir in /home/*/; do
    local username=$(basename "$homedir")
    
    # Skip system users and directories we shouldn't delete
    if [[ "$username" == "target" ]] || [[ "$username" == "desktop" ]]; then
      continue
    fi

    # Check if user exists in LDAP
    if ! echo "$valid_users" | grep -q "^${username}$"; then
      echo "[*] Removing orphaned home directory: $homedir (user not in LDAP)"
      rm -rf "$homedir"
    fi
  done

  echo "[+] Home directory cleanup complete"
}

# Run cleanup
cleanup_orphaned_homes || true
