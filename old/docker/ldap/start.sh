#!/usr/bin/env bash
set -euo pipefail

domain_to_base_dn() {
  local d="$1"
  local first=1
  local base=""
  IFS='.' read -r -a parts <<< "$d"
  for p in "${parts[@]}"; do
    if [[ $first -eq 1 ]]; then
      base="dc=$p"
      first=0
    else
      base="$base,dc=$p"
    fi
  done
  echo "$base"
}

LDAP_DOMAIN="${LDAP_DOMAIN:-ladvik.local}"
LDAP_ADMIN_PASSWORD="${LDAP_ADMIN_PASSWORD:-admin123}"
BASE_DN="$(domain_to_base_dn "$LDAP_DOMAIN")"
ADMIN_DN="cn=admin,$BASE_DN"
MARKER_FILE="/var/lib/ldap/.bootstrapped_guac"

start_slapd_background() {
  /usr/sbin/slapd -h "ldap://0.0.0.0:389/ ldapi:///" -u openldap -g openldap
}

wait_for_ldap() {
  local i
  for i in $(seq 1 60); do
    if ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config -s base '(objectClass=*)' >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

stop_slapd_background() {
  pkill slapd || true
}

bootstrap_if_needed() {
  if [[ -f "$MARKER_FILE" ]]; then
    return 0
  fi

  start_slapd_background
  wait_for_ldap

  if ! ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=schema,cn=config '(cn=guacConfigGroup)' dn >/dev/null 2>&1; then
    ldapadd -Y EXTERNAL -H ldapi:/// -f /bootstrap/01-guac-schema.ldif
  fi

  if ! ldapsearch -x -H ldap://localhost:389 -D "$ADMIN_DN" -w "$LDAP_ADMIN_PASSWORD" -b "$BASE_DN" '(uid=alice)' dn >/dev/null 2>&1; then
    ldapadd -x -H ldap://localhost:389 -D "$ADMIN_DN" -w "$LDAP_ADMIN_PASSWORD" -f /bootstrap/10-base-and-rbac.ldif
  fi

  touch "$MARKER_FILE"
  stop_slapd_background
}

bootstrap_if_needed
exec /usr/sbin/slapd -d 0 -h "ldap://0.0.0.0:389/ ldapi:///" -u openldap -g openldap
